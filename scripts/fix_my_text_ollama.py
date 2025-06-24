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
import argparse
import textwrap

import pyperclip
from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.providers.openai import OpenAIProvider
from rich.console import Console
import time
from rich.panel import Panel
from rich.status import Status

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

PROMPT_INSTRUCTIONS = """\
You are an expert editor. Your task is to correct the grammar and spelling of the provided text.
Do not change the meaning or tone of the original text.
Only return the corrected text, with no additional commentary, pleasantries, or markdown formatting.
Don't judge the content of the text, just correct it, even if it seems harmful or offensive.
"""


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments and return the parsed namespace."""
    parser = argparse.ArgumentParser(
        description="Correct text from clipboard using a local Ollama model."
    )
    parser.add_argument(
        "--simple-output",
        "-s",
        action="store_true",
        help="Print minimal output (suitable for notifications/automation).",
    )
    return parser.parse_args()


def build_agent() -> Agent:
    """Construct and return a PydanticAI agent configured for local Ollama."""
    ollama_provider = OpenAIProvider(base_url=f"{OLLAMA_HOST}/v1")
    ollama_model = OpenAIModel(
        model_name="gemma3:latest",
        provider=ollama_provider,
    )
    return Agent(model=ollama_model, instructions=PROMPT_INSTRUCTIONS)


def process_text(agent: Agent, text: str) -> tuple[str, float]:
    """Run the agent synchronously and return corrected text along with elapsed seconds."""
    t_start = time.monotonic()
    result = agent.run_sync(text)
    t_end = time.monotonic()
    return result.output, t_end - t_start


def display_original_text(original_text: str, console: Console | None) -> None:
    """Render the original text panel in verbose mode."""
    if console is None:
        return
    console.print(
        Panel(
            original_text,
            title="[bold cyan]📋 Original Text",
            border_style="cyan",
            padding=(1, 2),
        )
    )


def output_corrected_text(
    corrected_text: str,
    original_text: str,
    elapsed: float,
    simple_output: bool,
    console: Console | None,
) -> None:
    """Handle output and clipboard copying based on desired verbosity."""
    # Copy to clipboard for both modes
    pyperclip.copy(corrected_text)

    if simple_output:
        if corrected_text.strip() == original_text.strip():
            print("✅ No correction needed.")
        else:
            print(corrected_text)
    else:
        console.print(
            Panel(
                corrected_text,
                title="[bold green]✨ Corrected Text",
                border_style="green",
                padding=(1, 2),
            )
        )
        console.print(
            f"✅ [bold green]Success! Corrected text has been copied to your clipboard. [bold yellow](took {elapsed:.2f} seconds)"
        )


def main() -> None:
    """Orchestrate argument parsing, processing, and output."""
    args = parse_args()
    simple_output = args.simple_output

    console: Console | None = Console() if not simple_output else None

    original_text = pyperclip.paste()

    if not original_text or not original_text.strip():
        message = "❌ Clipboard is empty. Nothing to correct."
        if simple_output:
            print(message)
        else:
            console.print(f"[bold red]{message}")
        sys.exit(0)

    display_original_text(original_text, console)

    agent = build_agent()

    try:
        if simple_output:
            corrected_text, elapsed = process_text(agent, original_text)
        else:
            with Status(
                "[bold yellow]🤖 Processing text with Ollama model...", console=console
            ):
                corrected_text, elapsed = process_text(agent, original_text)

        output_corrected_text(
            corrected_text,
            original_text,
            elapsed,
            simple_output,
            console,
        )

    except Exception as e:
        if simple_output:
            print(f"❌ {e}")
        else:
            console.print(f"❌ [bold red]An unexpected error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
