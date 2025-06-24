#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "pydantic-ai-slim[openai]",
#   "pyperclip",
#   "rich",
# ]
# ///
"""Read text from clipboard, correct it using a local Ollama model, and write the result back to the clipboard.

Usage:
    python fix_my_text_ollama.py

Environment variables:
    OLLAMA_HOST: The host of the Ollama server. Default is "http://localhost:11434".


Example:
    OLLAMA_HOST=http://pc.local:11434 python fix_my_text_ollama.py

Pro-tip:
    Use Keyboard Maestro to run this script on a hotkey.
"""

import sys
import os

import pyperclip
from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.providers.openai import OpenAIProvider
from rich.console import Console
import time
from rich.panel import Panel
from rich.status import Status

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")


def main():
    """
    Main function to read from clipboard, correct text using a local Ollama model,
    and write the result back to the clipboard.
    """
    console = Console()

    with Status("[bold blue]Reading text from clipboard...", console=console) as status:
        original_text = pyperclip.paste()

    if not original_text or not original_text.strip():
        console.print("❌ [bold red]Clipboard is empty. Nothing to correct.")
        sys.exit(0)

    console.print(
        Panel(
            original_text,
            title="[bold cyan]📋 Original Text",
            border_style="cyan",
            padding=(1, 2),
        )
    )

    # 1. Configure the model to point to your local Ollama instance.
    # We use the OpenAIProvider but change the base_url to our local server.
    ollama_provider = OpenAIProvider(base_url=f"{OLLAMA_HOST}/v1")
    ollama_model = OpenAIModel(
        model_name="gemma3:latest",  # The specific Ollama model you want to use
        provider=ollama_provider,
    )

    # 2. Create a PydanticAI Agent with the custom model and instructions.
    corrector_agent = Agent(
        model=ollama_model,
        instructions="""
        You are an expert editor. Your task is to correct the grammar and spelling of the provided text.
        Do not change the meaning or tone of the original text.
        Only return the corrected text, with no additional commentary, pleasantries, or markdown formatting.
        """,
    )

    try:
        # 3. Run the agent with the clipboard content.
        t_start = time.monotonic()
        with Status(
            "[bold yellow]🤖 Processing text with Ollama model...", console=console
        ):
            result = corrector_agent.run_sync(original_text)
            corrected_text = result.output
        t_end = time.monotonic()

        # 4. Copy the corrected text back to the clipboard.
        pyperclip.copy(corrected_text)

        console.print(
            Panel(
                corrected_text,
                title="[bold green]✨ Corrected Text",
                border_style="green",
                padding=(1, 2),
            )
        )

        console.print(
            f"✅ [bold green]Success! Corrected text has been copied to your clipboard. [bold yellow](took {t_end - t_start:.2f} seconds)"
        )

    except Exception as e:
        console.print(f"❌ [bold red]An unexpected error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
