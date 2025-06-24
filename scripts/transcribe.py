#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "wyoming",
#   "pyaudio",  # We need PyAudio to access the microphone
# ]
# ///
import asyncio

import pyaudio
from wyoming.asr import Transcript
from wyoming.audio import AudioChunk, AudioStart, AudioStop
from wyoming.client import AsyncClient

# --- Configuration ---
SERVER_IP = "192.168.1.143"
SERVER_PORT = 10300

# --- PyAudio Configuration ---
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
CHUNK_SIZE = 1024


async def main() -> None:
    """Connect to Wyoming server and perform live transcription."""
    uri = f"tcp://{SERVER_IP}:{SERVER_PORT}"
    print(f"Connecting to Wyoming server at {uri}")

    try:
        async with AsyncClient.from_uri(uri) as client:
            print("Connection successful. Listening... (Press Ctrl+C to stop)")

            # --- Set up PyAudio ---
            p = pyaudio.PyAudio()
            stream = p.open(
                format=FORMAT,
                channels=CHANNELS,
                rate=RATE,
                input=True,
                frames_per_buffer=CHUNK_SIZE,
            )

            # --- Coroutines for sending and receiving ---
            async def send_audio():
                """Read from mic and send to server."""
                await client.write_event(
                    AudioStart(rate=RATE, width=2, channels=1).event()
                )
                while True:
                    chunk = await asyncio.to_thread(stream.read, CHUNK_SIZE)
                    await client.write_event(AudioChunk(audio=chunk).event())

            async def receive_text():
                """Receive transcriptions from server."""
                while True:
                    event = await client.read_event()
                    if event is None:
                        break

                    if Transcript.is_type(event.type):
                        transcript = Transcript.from_event(event)
                        # The text is buffered, so we use print with flush
                        print(transcript.text, end="", flush=True)

            try:
                # Run both tasks concurrently
                await asyncio.gather(send_audio(), receive_text())
            except KeyboardInterrupt:
                # User pressed Ctrl+C
                print("\nStopping...")
            finally:
                # Clean up PyAudio
                print("Closing audio stream.")
                await client.write_event(AudioStop().event())
                stream.stop_stream()
                stream.close()
                p.terminate()
                print("Done.")

    except ConnectionRefusedError:
        print(
            f"Connection refused. Is the server running and firewall open on port {SERVER_PORT}?"
        )
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
