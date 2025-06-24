#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "wyoming==1.7.1",
#   "pyaudio",  # We need PyAudio to access the microphone
#   "rich",  # For nice terminal output
#   "pyperclip",
# ]
# ///
import argparse
import asyncio
import logging
import signal
import wave
from contextlib import contextmanager, nullcontext
from datetime import datetime
from typing import Generator
import os

import pyaudio
import pyperclip
from rich.console import Console
from rich.live import Live
from rich.text import Text
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
SERVER_IP = "192.168.1.143"
SERVER_PORT = 10300
FORMAT = pyaudio.paInt16
CHANNELS = 1  # mono
RATE = 16000
CHUNK_SIZE = 1024

# --- Helper Functions & Context Managers ---


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
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
    parser.add_argument(
        "--save-recording",
        action="store_true",
        help="Save the microphone audio to a timestamped WAV file.",
    )
    parser.add_argument(
        "--clipboard",
        action="store_true",
        help="Copy the final transcript to the clipboard.",
    )
    return parser.parse_args()


def setup_logging(args: argparse.Namespace) -> logging.Logger:
    """Set up logging to console and optionally a file."""
    log_level = logging.DEBUG if args.debug else logging.WARN
    handlers = [logging.StreamHandler()]
    if args.log_file:
        handlers.append(logging.FileHandler(args.log_file, mode="w"))
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        handlers=handlers,
    )
    return logging.getLogger(__name__)


@contextmanager
def pyaudio_context() -> Generator[pyaudio.PyAudio, None, None]:
    """Context manager for PyAudio lifecycle."""
    p = pyaudio.PyAudio()
    try:
        yield p
    finally:
        p.terminate()


@contextmanager
def open_pyaudio_stream(
    p: pyaudio.PyAudio, *args, **kwargs
) -> Generator[pyaudio.Stream, None, None]:
    """Context manager for a PyAudio stream that ensures it's properly closed."""
    stream = p.open(*args, **kwargs)
    try:
        yield stream
    finally:
        stream.stop_stream()
        stream.close()


def list_input_devices(pa: pyaudio.PyAudio, console: Console) -> None:
    """Print a numbered list of available input devices."""
    console.print("[bold]Available input devices:[/bold]")
    for i in range(pa.get_device_count()):
        info = pa.get_device_info_by_index(i)
        if info.get("maxInputChannels", 0) > 0:
            console.print(f"  [yellow]{i}[/yellow]: {info['name']}")


# --- Core Application Logic ---


async def send_audio(
    client: AsyncClient,
    stream: pyaudio.Stream,
    wav_file: wave.Wave_write | None,
    stop_event: asyncio.Event,
    logger: logging.Logger,
    console: Console,
):
    """Read from mic, write to WAV, and send to server."""
    logger.debug("Sending Transcribe request")
    await client.write_event(Transcribe().event())
    logger.debug("Sending AudioStart")
    await client.write_event(AudioStart(rate=RATE, width=2, channels=CHANNELS).event())

    try:
        with Live(
            Text("Streaming...", style="blue"),
            console=console,
            transient=True,
            refresh_per_second=10,
        ) as live:
            counter = 0
            while not stop_event.is_set():
                chunk = await asyncio.to_thread(stream.read, CHUNK_SIZE)
                if wav_file:
                    wav_file.writeframes(chunk)

                logger.debug("Sending AudioChunk size=%d", len(chunk))
                await client.write_event(
                    AudioChunk(
                        rate=RATE, width=2, channels=CHANNELS, audio=chunk
                    ).event()
                )
                counter += 1
                live.update(
                    Text(
                        f"Streaming... ({counter * CHUNK_SIZE / RATE:.1f}s)",
                        style="blue",
                    )
                )
    finally:
        logger.debug("Sending AudioStop")
        await client.write_event(AudioStop().event())


async def receive_text(
    client: AsyncClient,
    logger: logging.Logger,
    console: Console,
    args: argparse.Namespace,
):
    """Receive transcription events and handle final transcript."""
    transcript_text = ""
    while True:
        event = await client.read_event()
        if event is None:
            logger.debug("Server closed the connection")
            break
        if Transcript.is_type(event.type):
            transcript = Transcript.from_event(event)
            transcript_text = transcript.text
            console.print(f"\n[bold green]Transcript:[/bold green] {transcript_text}")
            logger.info("Transcript [final]: %s", transcript_text)
            break
        elif TranscriptChunk.is_type(event.type):
            chunk = TranscriptChunk.from_event(event)
            console.print(chunk.text, end="")
            logger.debug("Transcript chunk: %s", chunk.text)
        elif TranscriptStart.is_type(event.type):
            logger.debug("Received TranscriptStart")
        elif TranscriptStop.is_type(event.type):
            logger.debug("Received TranscriptStop")
            break
        else:
            logger.debug("Received non-transcript event type=%s", event.type)

    if args.clipboard and transcript_text:
        try:
            pyperclip.copy(transcript_text)
            logger.info("Copied transcript to clipboard.")
            console.print("[italic green]Copied to clipboard.[/italic green]")
        except pyperclip.PyperclipException as e:
            logger.error("Could not copy to clipboard: %s", e)
            console.print(
                f"[bold red]Error:[/bold red] Could not copy to clipboard: {e}"
            )


async def run_transcription(
    args: argparse.Namespace,
    logger: logging.Logger,
    p: pyaudio.PyAudio,
    stop_event: asyncio.Event,
    console: Console,
):
    """Connects to server and manages transcription lifecycle."""
    uri = f"tcp://{args.server_ip}:{args.server_port}"
    logger.info("Connecting to Wyoming server at %s", uri)
    console.print(f"Connecting to Wyoming server at [cyan]{uri}[/cyan]...")

    client = AsyncClient.from_uri(uri)
    output_wav = (
        f"recording_{datetime.now().strftime('%Y%m%d_%H%M%S')}.wav"
        if args.save_recording
        else None
    )

    try:
        await client.connect()
        logger.info("Connection established")
        console.print("[green]Connection successful.[/green] Listening...")

        wav_manager = wave.open(output_wav, "wb") if output_wav else nullcontext()

        with (
            open_pyaudio_stream(
                p,
                format=FORMAT,
                channels=CHANNELS,
                rate=RATE,
                input=True,
                frames_per_buffer=CHUNK_SIZE,
                input_device_index=args.device_index,
            ) as stream,
            wav_manager as wav_file,
        ):
            if output_wav:
                logger.debug("Opening WAV file %s", output_wav)
                wav_file.setnchannels(CHANNELS)
                wav_file.setsampwidth(2)
                wav_file.setframerate(RATE)

            send_task = asyncio.create_task(
                send_audio(client, stream, wav_file, stop_event, logger, console)
            )
            recv_task = asyncio.create_task(receive_text(client, logger, console, args))

            await asyncio.gather(send_task, recv_task)

    finally:
        logger.info("run_transcription finally block reached.")
        if output_wav:
            logger.debug("Closed WAV file")
            console.print(f"Saved recording to [cyan]{output_wav}[/cyan]")

        await client.disconnect()


async def main() -> None:
    """Sets up logging, arguments, and the main asyncio loop."""
    args = parse_args()
    logger = setup_logging(args)
    console = Console()

    with pyaudio_context() as p:
        if args.list_devices:
            list_input_devices(p, console)
            return

        if args.device_index is not None:
            console.print(
                f"Using input device index [bold yellow]{args.device_index}[/bold yellow]"
            )

        loop = asyncio.get_running_loop()
        stop_event = asyncio.Event()

        def shutdown_handler():
            console.print("\n[yellow]Stopping... (Ctrl+C)[/yellow]")
            logger.info("Shutdown signal received.")
            stop_event.set()

        loop.add_signal_handler(signal.SIGINT, shutdown_handler)
        loop.add_signal_handler(signal.SIGTERM, shutdown_handler)

        try:
            await run_transcription(args, logger, p, stop_event, console)
        except asyncio.CancelledError:
            pass
        except ConnectionRefusedError:
            console.print(
                f"[bold red]Connection refused.[/bold red] Is the server running and firewall open on port {args.server_port}?"
            )
        except Exception as e:
            logger.exception("Unhandled exception: %s", e)
            console.print(f"[bold red]An error occurred:[/bold red] {e}")
        finally:
            console.print("[bold]Done.[/bold]")


if __name__ == "__main__":
    # This try/except is for a fast Ctrl+C before the loop starts
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
