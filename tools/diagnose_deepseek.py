"""Use the metered relay to inspect DeepSeek response shape without saving content."""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from experiments.run_matrix import start_relay


def inspect_response(payload: dict) -> dict:
    choice = (payload.get("choices") or [{}])[0]
    message = choice.get("message") or {}
    content = message.get("content") or ""
    if isinstance(content, list):
        content = "\n".join(str(item.get("text", "")) for item in content
                             if isinstance(item, dict))
    usage = payload.get("usage") or {}
    completion = usage.get("completion_tokens_details") or {}
    return {
        "http_status": 200,
        "finish_reason": choice.get("finish_reason"),
        "content_chars": len(str(content)),
        "reasoning_chars": len(message.get("reasoning_content") or ""),
        "completion_tokens": usage.get("completion_tokens"),
        "reasoning_tokens": completion.get("reasoning_tokens"),
        "provider_cost": usage.get("cost"),
    }


def main() -> int:
    log_path = ROOT / "experiments" / "deepseek_probe_usage.jsonl"
    relay = start_relay(log_path, budget_cny=0.10, request_reserve_cny=0.02)
    cases = (
        ("enable_thinking_false", {"enable_thinking": False}),
        ("thinking_disabled", {"thinking": {"type": "disabled"}}),
    )
    try:
        for name, params in cases:
            body = {
                "model": "deepseek-v4.1-flash-1017",
                "messages": [{"role": "user", "content": "Reply exactly: DS_PROBE_OK"}],
                "temperature": 0,
                "max_tokens": 128,
                **params,
            }
            request = urllib.request.Request(
                "http://127.0.0.1:8765/v1/chat/completions",
                data=json.dumps(body).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            try:
                with urllib.request.urlopen(request, timeout=240) as response:
                    result = inspect_response(json.loads(response.read().decode("utf-8")))
            except urllib.error.HTTPError as error:
                result = {"http_status": error.code, "error_type": "upstream_http_error"}
            print(json.dumps({"probe": name, **result}, ensure_ascii=True))
    finally:
        relay.terminate()
        try:
            relay.wait(timeout=5)
        except Exception:
            relay.kill()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
