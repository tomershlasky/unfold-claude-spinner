# unfold-claude-spinner

Replace the default Claude Code spinner with today's AI news from [Unfold](https://unfold.decart.ai).

## Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/tomershlasky/unfold-claude-spinner/main/install.sh)
```

This will:
1. Install `jq` if needed
2. Create `~/.claude/update-spinner.sh`
3. Fetch today's headlines into `~/.claude/settings.json`
4. Add a shell hook so it refreshes on each new terminal

## Manual refresh

```bash
~/.claude/update-spinner.sh
```

## Uninstall

Remove the hook from your `~/.zshrc` or `~/.bashrc` (look for `unfold-claude-spinner`) and delete the script:

```bash
rm ~/.claude/update-spinner.sh
```

## License

MIT
