# unfold-claude-spinner

Replace the default Claude Code spinner with recent World Cup results plus today's AI news from [Unfold](https://unfold.decart.ai).

## ⚽ World Cup edition

While the FIFA World Cup is on, the spinner also surfaces football straight from the free, keyless [TheSportsDB](https://www.thesportsdb.com) API — mixed in with your AI news:

```
⚽ Australia 2-0 Turkey @ Vancouver | World Cup
⚽ Next: Germany vs Curaçao (2026-06-14 17:00) | World Cup
```

- **Recent results** with venue, over a rolling today / yesterday / day-before window (so the latest finished matches always show).
- **Upcoming fixtures** — the next matches on the calendar.
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
