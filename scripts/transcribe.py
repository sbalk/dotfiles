#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "wyoming==1.7.1",
#   "pyaudio",  # We need PyAudio to access the microphone
# ]
# ///
import argparse
import asyncio
import logging
import wave
from datetime import datetime
import signal

import pyaudio
from wyoming.asr import (
    Transcript,
    Transcribe,
    TranscriptChunk,
    TranscriptStart,
    TranscriptStop,
)
from wyoming.audio import AudioChunk, AudioStart, AudioStop
from wyoming.client import AsyncClient

# --- Configuration ---
# You can override these on the command line if needed
SERVER_IP = "192.168.1.143"
SERVER_PORT = 10300

# --- PyAudio Configuration ---
FORMAT = pyaudio.paInt16
CHANNELS = 1  # mono
RATE = 16000
CHUNK_SIZE = 1024

# --- Recording Configuration ---
# Save the raw microphone input to a WAV file so we can inspect it later.
OUTPUT_WAV = f"recording_{datetime.now().strftime('%Y%m%d_%H%M%S')}.wav"


def list_input_devices(pa: pyaudio.PyAudio) -> None:
    """Print a numbered list of available input devices."""
    print("Available input devices:")
    for i in range(pa.get_device_count()):
        info = pa.get_device_info_by_index(i)
        if info.get("maxInputChannels", 0) > 0:
            print(f"  {i}: {info['name']} (channels={info['maxInputChannels']})")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Stream microphone audio to a Wyoming server and record locally."
    )
    parser.add_argument(
        "--device-index",
        type=int,
        default=None,
        help="Index of the PyAudio input device to use.",
    )
    parser.add_argument(
        "--list-devices",
        action="store_true",
        help="List available audio input devices and exit.",
    )
    parser.add_argument(
        "--server-ip", default=SERVER_IP, help="Wyoming server IP address."
    )
    parser.add_argument(
        "--server-port", type=int, default=SERVER_PORT, help="Wyoming server port."
    )
    parser.add_argument("--log-file", help="Path to log file (default: stdout only).")
    parser.add_argument(
        "--debug", action="store_true", help="Enable debug-level logging."
    )
    return parser.parse_args()


async def run_transcription(args, logger, p, stop_event):
    """The main transcription logic, designed to be cancelled."""
    client = AsyncClient.from_uri(f"tcp://{args.server_ip}:{args.server_port}")
    stream = None
    wav_file = None
    send_task = None
    recv_task = None

    try:
        await client.connect()
        logger.info("Connection established")
        print("Connection successful. Listening... (Press Ctrl+C to stop)")

        stream = p.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=RATE,
            input=True,
            frames_per_buffer=CHUNK_SIZE,
            input_device_index=args.device_index,
        )

        logger.debug("Opening WAV file %s", OUTPUT_WAV)
        wav_file = wave.open(OUTPUT_WAV, "wb")
        wav_file.setnchannels(CHANNELS)
        wav_file.setsampwidth(2)
        wav_file.setframerate(RATE)

        async def send_audio():
            """Read from mic and send to server."""
            logger.debug("Sending Transcribe request")
            await client.write_event(Transcribe().event())
            logger.debug("Sending AudioStart")
            await client.write_event(AudioStart(rate=RATE, width=2, channels=1).event())
            counter = 0
            try:
                while not stop_event.is_set():
                    chunk = await asyncio.to_thread(stream.read, CHUNK_SIZE)
                    wav_file.writeframes(chunk)
                    logger.debug("Sending AudioChunk size=%d", len(chunk))
                    await client.write_event(
                        AudioChunk(
                            rate=RATE, width=2, channels=CHANNELS, audio=chunk
                        ).event()
                    )
                    counter += 1
                    if counter % 100 == 0:
                        print(
                            f"Recorded {counter * CHUNK_SIZE / RATE:.1f} s",
                            end="\r",
                            flush=True,
                        )
            finally:
                logger.debug("Sending AudioStop")
                await client.write_event(AudioStop().event())

        async def receive_text():
            """Receive transcription events until connection close or final transcript."""
            while True:
                event = await client.read_event()
                if event is None:
                    logger.debug("Server closed the connection")
                    break
                if Transcript.is_type(event.type):
                    transcript = Transcript.from_event(event)
                    print(transcript.text, flush=True)
                    logger.info("Transcript [final]: %s", transcript.text)
                    break
                elif TranscriptChunk.is_type(event.type):
                    chunk = TranscriptChunk.from_event(event)
                    print(chunk.text, end="", flush=True)
                    logger.debug("Transcript chunk: %s", chunk.text)
                elif TranscriptStart.is_type(event.type):
                    logger.debug("Received TranscriptStart")
                elif TranscriptStop.is_type(event.type):
                    logger.debug("Received TranscriptStop")
                    break
                else:
                    logger.debug("Received non-transcript event type=%s", event.type)

        send_task = asyncio.create_task(send_audio())
        recv_task = asyncio.create_task(receive_text())

        await asyncio.gather(send_task, recv_task)

    finally:
        logger.info("run_transcription finally block reached.")
        if stream:
            stream.stop_stream()
            stream.close()
        if wav_file:
            wav_file.close()
            logger.debug("Closed WAV file")
            print(f"Saved recording to {OUTPUT_WAV}")

        await client.disconnect()


async def main() -> None:
    """Sets up logging, arguments, and the main asyncio loop."""
    args = parse_args()

    # Configure logging
    log_level = logging.DEBUG if args.debug else logging.INFO
    handlers = [logging.StreamHandler()]
    if args.log_file:
        handlers.append(logging.FileHandler(args.log_file, mode="w"))
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        handlers=handlers,
    )
    logger = logging.getLogger(__name__)

    # Init PyAudio early so we can list devices if requested
    p = pyaudio.PyAudio()

    if args.list_devices:
        list_input_devices(p)
        p.terminate()
        return

    device_index = args.device_index
    if device_index is not None:
        print(f"Using input device index {device_index}")

    loop = asyncio.get_running_loop()
    stop_event = asyncio.Event()

    def shutdown_handler():
        print("\nStopping... (Ctrl+C)")
        logger.info("Shutdown signal received.")
        stop_event.set()

    loop.add_signal_handler(signal.SIGINT, shutdown_handler)
    loop.add_signal_handler(signal.SIGTERM, shutdown_handler)

    try:
        await run_transcription(args, logger, p, stop_event)
    except asyncio.CancelledError:
        pass
    finally:
        p.terminate()
        print("Done.")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
