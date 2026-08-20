# Reset Claude usage window

Claude subscriptions have 5-hour usage windows that start on first use. This repo pings Claude
with a single "test" message at 00:00, 06:00, 12:00 and 18:00 UTC so the window starts *before*
the workday and resets mid-day instead of mid-work.

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

- Times are UTC (Romania is UTC+2/+3, so runs land at 02:00/08:00/14:00/20:00 or 03:00/... local).
- GitHub disables cron workflows on repos with no activity for 60 days — an occasional commit keeps it alive.
