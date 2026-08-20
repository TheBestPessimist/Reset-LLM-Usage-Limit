# Reset Claude usage window

Sends a dummy message to the cheapest Claude model (Haiku) using a subscription OAuth token (not API token), so the 5-hour usage window starts ticking.
Thinking is explicitly disabled.

This repo pings Claude with a single dummy message at 03:00, 08:00, 13:00 and 18:00 **Romania time** (Europe/Bucharest).
The schedule is created to work with my 08-16 schedule.

## Setup

1. Get a long-lived subscription OAuth token: run `claude setup-token` in a terminal
   (it prints a `sk-ant-oat01-...` token tied to your Claude subscription).
2. In the GitHub repo: Settings -> Secrets and variables -> Actions -> New repository secret.
   Name: `CLAUDE_TOKEN`, value: the token from step 1.

## How it works

- `.github/workflows/reset-usage-window.yml` runs on the cron schedule
- `reset-usage-window.sh` pings the anthropic API

## Test manually

```bash
CLAUDE_TOKEN=sk-ant-oat01-... bash reset-usage-window.sh
```

Prints the HTTP status and the raw JSON response; exits non-zero on any non-200.

## Notes

- GitHub cron is UTC-only and has no timezone option, so the workflow schedules both possible UTC hours (UTC+2 winter / UTC+3 summer) and a guard step checks the actual Europe/Bucharest hour, skipping the ping when it isn't 03/08/13/18 local. DST is handled automatically.
- Manual runs always ping, regardless of time.
