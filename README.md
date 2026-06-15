# unfold-claude-spinner

Replace the default Claude Code spinner with today's AI news headlines from [Unfold](https://unfold.decart.ai) — and, while the tournament is on, live World Cup results too.

## 🤖 AI news

Every new terminal, it fetches today's AI headlines and shows them as the spinner's "thinking" verbs — so the time Claude spends working is time you spend catching up:

```
🤖 Police Officer Investigated for Using AI to 'Create Evidence' in Multiple Cases | unfolding
🤖 State Attorneys General Are Investigating OpenAI | unfolding
```

- Pulls today's topics from Unfold and writes them to `spinnerVerbs` in `~/.claude/settings.json`.
- News refreshes once a day, on each new shell. No config, no API keys.

## ⚽ World Cup edition

While the FIFA World Cup is on, the spinner also surfaces football straight from the free, keyless [TheSportsDB](https://www.thesportsdb.com) API — mixed in with your AI news:

```
⚽ Australia 2-0 Turkey @ Vancouver | World Cup
⚽ Next: Germany vs Curaçao (2026-06-14 17:00 IL) | World Cup
```

- **Recent results** with venue, over a rolling today / yesterday / day-before window (so the latest finished matches always show).
- **Upcoming fixtures** — the next matches on the calendar, with kickoff times in Israel time (`IL`).
- **Refreshes hourly** (vs daily for AI news), on each new shell — so live scores and just-finished results don't sit stale all day.
- **Auto off-season:** when there are no recent or upcoming matches, it quietly falls back to AI news only — nothing to toggle.

## Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/tomershlasky/unfold-claude-spinner/main/install.sh)
```

This will:
1. Install `jq` if needed
2. Create `~/.claude/update-spinner.sh`
3. Fetch World Cup results & fixtures plus today's headlines into `~/.claude/settings.json`
4. Add a shell hook so it refreshes on each new terminal

## Uninstall

Remove the hook from your `~/.zshrc` or `~/.bashrc` (look for `unfold-claude-spinner`) and delete the script:

```bash
rm ~/.claude/update-spinner.sh
```

## License

MIT
