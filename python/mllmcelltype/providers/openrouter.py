"""OpenRouter provider module for LLMCellType."""

import json
import time

import requests

from ..logger import write_log


def process_openrouter(prompt: str, model: str, api_key: str) -> list[str]:
    """Process request using OpenRouter API, which provides access to various LLM models.

    Args:
        prompt: The prompt to send to the API
        model: The model name (e.g., 'openai/gpt-4o', 'anthropic/claude-3-opus')
        api_key: OpenRouter API key

    Returns:
        List[str]: Processed responses, one per cluster

    """
    write_log(f"Starting OpenRouter API request with model: {model}")

    # Check if API key is provided and not empty
    if not api_key:
        error_msg = "OpenRouter API key is missing or empty"
        write_log(f"ERROR: {error_msg}")
        raise ValueError(error_msg)

    # OpenRouter API endpoint
    url = "https://openrouter.ai/api/v1/chat/completions"
    write_log(f"Using model: {model}")

    # Process all input at once instead of chunks
    input_lines = prompt.split("\n")
    cutnum = 1  # Always use 1 chunk

    write_log(f"Processing {cutnum} chunks of input")

    # Split input into chunks if needed
    if cutnum > 1:
        chunk_size = len(input_lines) // cutnum
        if len(input_lines) % cutnum > 0:
            chunk_size += 1
        chunks = [input_lines[i : i + chunk_size] for i in range(0, len(input_lines), chunk_size)]
    else:
        chunks = [input_lines]

    # Process each chunk
    all_results = []
    for i, chunk in enumerate(chunks):
        write_log(f"Processing chunk {i + 1} of {cutnum}")

        # Prepare the request body
        # Ensure model ID is in the correct format for OpenRouter (provider/model)
        # If model doesn't contain a slash, it's likely not in the correct format
        if (
            "/" not in model
            and not model.startswith("anthropic/")
            and not model.startswith("openai/")
            and not model.startswith("meta-llama/")
            and not model.startswith("mistralai/")
        ):
            write_log(
                f"Warning: Model ID '{model}' may not be in the correct format for OpenRouter. Expected format: 'provider/model'"
            )

        body = {
            "model": model,
            "messages": [{"role": "user", "content": "\n".join(chunk)}],
        }

        write_log("Sending API request...")
        # Make the API request
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            "HTTP-Referer": "https://github.com/cafferychen777/mLLMCelltype",  # Optional for rankings
            "X-Title": "mLLMCelltype",  # Optional for rankings
        }

        max_retries = 3
        retry_delay = 2

        for attempt in range(max_retries):
            try:
                response = requests.post(
                    url=url, headers=headers, data=json.dumps(body), timeout=30
                )

                # Check for errors
                if response.status_code != 200:
                    error_message = response.json()
                    write_log(
                        f"ERROR: OpenRouter API request failed: {error_message.get('error', {}).get('message', 'Unknown error')}"
                    )

                    # If rate limited, wait and retry
                    if response.status_code == 429 and attempt < max_retries - 1:
                        wait_time = retry_delay * (2**attempt)
                        write_log(f"Rate limited. Waiting {wait_time} seconds before retrying...")
                        time.sleep(wait_time)
                        continue

                    response.raise_for_status()

                # Parse the response
                content = response.json()
                res = content["choices"][0]["message"]["content"].strip().split("\n")
                write_log(f"Got response with {len(res)} lines")
                write_log(f"Raw response from OpenRouter:\n{res}")

                all_results.extend(res)
                break  # Success, exit retry loop

            except Exception as e:
                write_log(f"Error during API call (attempt {attempt + 1}/{max_retries}): {str(e)}")
                if attempt < max_retries - 1:
                    wait_time = retry_delay * (2**attempt)
                    write_log(f"Waiting {wait_time} seconds before retrying...")
                    time.sleep(wait_time)
                else:
                    raise

    write_log("All chunks processed successfully")
    # Clean up results (remove commas at the end of lines)
    return [line.rstrip(",") for line in all_results]
