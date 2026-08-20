# Reset Claude usage window

Claude subscriptions have 5-hour usage windows that start on first use. This repo pings Claude
with a single "test" message at 03:00, 08:00, 13:00 and 18:00 **Romania time** (Europe/Bucharest).
The schedule is anchored on the 08:00 work start and steps +5h to match the window length, so
windows always run 08-13 and 13-18: the reset lands at 13:00 (lunch), never mid-work.

## Setup

1. Get a long-lived subscription OAuth token: run `claude setup-token` in a terminal
   (it prints a `sk-ant-oat01-...` token tied to your Claude subscription).
2. In the GitHub repo: Settings -> Secrets and variables -> Actions -> New repository secret.
   Name: `CLAUDE_TOKEN`, value: the token from step 1.

## How it works

- `.github/workflows/reset-usage-window.yml` runs on the cron schedule (plus manual runs via
  the "Run workflow" button in the Actions tab).
- `reset-usage-window.sh` sends one `test` message with `max_tokens: 1` to `claude-haiku-4-5`
  (the cheapest model), authenticated with the OAuth bearer token + `anthropic-beta: oauth-2025-04-20`
  header. That counts as subscription usage, which starts the 5-hour window.

## Test manually

```bash
CLAUDE_TOKEN=sk-ant-oat01-... bash reset-usage-window.sh
```

Prints the HTTP status and the raw JSON response; exits non-zero on any non-200.

## Notes

- GitHub cron is UTC-only and has no timezone option, so the workflow schedules both possible
  UTC hours (UTC+2 winter / UTC+3 summer) and a guard step checks the actual Europe/Bucharest
  hour, skipping the ping when it isn't 03/08/13/18 local. DST is handled automatically.
- Manual runs (workflow_dispatch) always ping, regardless of time.
- GitHub can delay cron runs by a few minutes; in the rare case a run is delayed past the top of
  the hour boundary (>1h late), the guard skips it and the next slot catches up.
- GitHub disables cron workflows on repos with no activity for 60 days — an occasional commit keeps it alive.
