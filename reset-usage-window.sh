#!/usr/bin/env bash

set -euo pipefail

: "${CLAUDE_TOKEN:?Set CLAUDE_TOKEN to your Claude subscription OAuth token (sk-ant-oat01-...)}"

# --retry-max-time bounds the whole retry timer. Without it, curl obeys the
# Retry-After header the API sends with a 429 (--retry-delay does not cap that)
# and can sleep for hours; --max-time only bounds one attempt, not the waits.
#
# -v --trace-time stamps every attempt, so a long Retry-After wait shows up as a
# gap between timestamps instead of a silently stalled step. curl prints the
# Authorization header verbatim, so the trace is buffered to a file and redacted
# before it reaches the log; Actions masks the secret too, but don't lean on that
# alone. (A `2> >(sed ...)` pipe would stream live, but it flushes asynchronously
# and can reorder or drop lines -- useless in a diagnostic log.)
trace=$(mktemp)
trap 'sed "s/Authorization: Bearer .*/Authorization: Bearer ***REDACTED***/" "$trace" >&2; rm -f "$trace"' EXIT

response=$(curl -sS -v --trace-time -w '\n%{http_code}' \
  --retry 3 --retry-delay 5 --retry-max-time 60 --connect-timeout 10 --max-time 120 \
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
  }' 2>"$trace") || { echo "curl failed (exit $?): could not reach the Anthropic API (DNS/connection/timeout after retries)"; exit 1; }

# last line is the status code curl appended via -w; everything before it is the response body
http_code=$(tail -n1 <<< "$response")
body=$(sed '$d' <<< "$response")

echo "$body"
echo "HTTP $http_code"

[ "$http_code" = "200" ]
