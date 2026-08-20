#!/usr/bin/env bash
# Sends a minimal "test" message to the cheapest Claude model (Haiku) using a
# subscription OAuth token, so the 5-hour usage window starts ticking.
#
# Usage:
#   CLAUDE_TOKEN=sk-ant-oat01-... bash reset-usage-window.sh
set -euo pipefail

: "${CLAUDE_TOKEN:?Set CLAUDE_TOKEN to your Claude subscription OAuth token (sk-ant-oat01-...)}"

response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

# Subscription auth = OAuth bearer token + the oauth beta header
# (an API key would instead go on "x-api-key:" and bill per-token, NOT touch the subscription window).
# The "system" line mimics Claude Code's identity, which subscription tokens expect.
# Thinking is explicitly disabled: redundant on Haiku (opt-in there), but keeps thinking off
# if the model is ever swapped for a newer one where thinking is on by default.
# --retry covers transient failures (timeouts, 429, 5xx) so a blip doesn't skip the window start.
http_code=$(curl -sS -o "$response_file" -w '%{http_code}' \
  --retry 3 --retry-delay 5 --connect-timeout 10 --max-time 120 \
  https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLAUDE_TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -d '{
    "model": "claude-haiku-4-5",
    "max_tokens": 1,
    "thinking": {"type": "disabled"},
    "system": "You are Claude Code, Anthropic'\''s official CLI for Claude.",
    "messages": [{"role": "user", "content": "test"}]
  }')

echo "HTTP $http_code"
cat "$response_file"
echo

[ "$http_code" = "200" ]
