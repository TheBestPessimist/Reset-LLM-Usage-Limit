#!/usr/bin/env bash

set -euo pipefail

: "${CLAUDE_TOKEN:?Set CLAUDE_TOKEN to your Claude subscription OAuth token (sk-ant-oat01-...)}"

response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

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
    "system": "a",
    "messages": [{"role": "user", "content": "a"}]
  }')

echo "HTTP $http_code"
cat "$response_file"
echo

[ "$http_code" = "200" ]
