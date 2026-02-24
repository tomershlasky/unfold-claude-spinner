#!/usr/bin/env bash
set -euo pipefail

SPINNER_API="https://unfold.decart.ai/api/spinner"
SETTINGS="$HOME/.claude/settings.json"
UPDATE_SCRIPT="$HOME/.claude/update-spinner.sh"

# --- helpers ---
has()  { command -v "$1" &>/dev/null; }
info() { printf '\033[1;34m▸\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m✗\033[0m %s\n' "$1" >&2; }

# --- ensure jq ---
if ! has jq; then
  info "Installing jq..."
  if has brew; then brew install jq
  elif has apt-get; then sudo apt-get install -y jq
  else err "Please install jq first: https://jqlang.github.io/jq/download/"; exit 1; fi
fi

mkdir -p "$HOME/.claude"

# --- create the update script ---
cat > "$UPDATE_SCRIPT" << 'UPDATER'
#!/usr/bin/env bash
set -euo pipefail

SPINNER_API="https://unfold.decart.ai/api/spinner"
SETTINGS="$HOME/.claude/settings.json"

# fetch spinner items
ITEMS=$(curl -sf "$SPINNER_API" | jq -r '.items // empty') || { echo "Spinner API unreachable, skipping update"; exit 0; }
[ -z "$ITEMS" ] && exit 0

COUNT=$(echo "$ITEMS" | jq 'length')
[ "$COUNT" -lt 2 ] && exit 0

# build the spinnerVerbs object
SPINNER_OBJ=$(jq -n --argjson items "$ITEMS" '{"mode":"replace","verbs":$items}')

# create settings if missing
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

# merge into settings
UPDATED=$(jq --argjson sv "$SPINNER_OBJ" '.spinnerVerbs = $sv' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"
UPDATER
chmod +x "$UPDATE_SCRIPT"
ok "Created $UPDATE_SCRIPT"

# --- run it once ---
info "Fetching today's spinner items..."
bash "$UPDATE_SCRIPT" && ok "Spinner updated" || err "First update failed (API may not be deployed yet)"

# --- add shell hook to .zshrc / .bashrc ---
HOOK='# unfold-claude-spinner: refresh on new shell
[ -x "$HOME/.claude/update-spinner.sh" ] && "$HOME/.claude/update-spinner.sh" &>/dev/null &'

add_hook() {
  local rc="$1"
  if [ -f "$rc" ] && grep -q "unfold-claude-spinner" "$rc"; then
    return
  fi
  printf '\n%s\n' "$HOOK" >> "$rc"
  ok "Added auto-update hook to $rc"
}

# detect shell
if [ -n "${ZSH_VERSION:-}" ] || [ "$SHELL" = */zsh ]; then
  add_hook "$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ] || [ "$SHELL" = */bash ]; then
  add_hook "$HOME/.bashrc"
else
  add_hook "$HOME/.zshrc"
  add_hook "$HOME/.bashrc"
fi

echo ""
ok "Done! Your Claude Code spinner will update with today's AI news on each new shell."
info "Manual refresh: ~/.claude/update-spinner.sh"
