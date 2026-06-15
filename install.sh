#!/usr/bin/env bash
set -euo pipefail

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

API_BASE="https://unfold.decart.ai/api"
WC_API="https://www.thesportsdb.com/api/v1/json/3"
WC_LEAGUE="4429"   # FIFA World Cup
SETTINGS="$HOME/.claude/settings.json"
NEWS_STAMP="$HOME/.claude/.spinner-news-stamp"
NEWS_CACHE="$HOME/.claude/.spinner-news-cache"
WC_STAMP="$HOME/.claude/.spinner-wc-stamp"
WC_CACHE="$HOME/.claude/.spinner-wc-cache"
DATE=$(date -u +%Y-%m-%d)          # AI news refreshes once a day
HOUR_KEY=$(date -u +%Y-%m-%d-%H)   # World Cup refreshes once an hour

# decide what's stale: news daily, World Cup hourly
news_stale=1
if [ -f "$NEWS_STAMP" ] && [ "$(cat "$NEWS_STAMP")" = "$DATE" ]; then news_stale=0; fi
wc_stale=1
if [ -f "$WC_STAMP" ] && [ "$(cat "$WC_STAMP")" = "$HOUR_KEY" ]; then wc_stale=0; fi

# nothing to do if both sources are still fresh
[ "$news_stale" -eq 0 ] && [ "$wc_stale" -eq 0 ] && exit 0

# --- World Cup: results + upcoming fixtures (hourly) ---
if [ "$wc_stale" -eq 1 ]; then
  # rolling window: today / yesterday / day-before (BSD on macOS, GNU on Linux)
  date_back() { date -u -v-"$1"d +%Y-%m-%d 2>/dev/null || date -u -d "$1 days ago" +%Y-%m-%d; }
  D0="$DATE"; D1="$(date_back 1)"; D2="$(date_back 2)"

  # fetch recent World Cup results within the window (with venue city)
  WC_RAW=$(curl -sf "$WC_API/eventspastleague.php?id=$WC_LEAGUE") || WC_RAW=""
  if [ -n "$WC_RAW" ]; then
    WC_RESULTS=$(echo "$WC_RAW" | jq -c --arg d0 "$D0" --arg d1 "$D1" --arg d2 "$D2" '
      [ .events[]?
        | select(.dateEvent==$d0 or .dateEvent==$d1 or .dateEvent==$d2)
        | select(.intHomeScore != null and .intAwayScore != null)
        | "⚽ \(.strHomeTeam) \(.intHomeScore)-\(.intAwayScore) \(.strAwayTeam)"
          + (if (.strCity // "") != "" then " @ " + (.strCity | split(",")[0]) else "" end)
          + " | World Cup" ]')
  else
    WC_RESULTS="[]"
  fi
  [ -z "$WC_RESULTS" ] && WC_RESULTS="[]"

  # fetch upcoming World Cup fixtures (next few)
  WCN_RAW=$(curl -sf "$WC_API/eventsnextleague.php?id=$WC_LEAGUE") || WCN_RAW=""
  if [ -n "$WCN_RAW" ]; then
    WC_FIXTURES=$(echo "$WCN_RAW" | jq -c '
      [ .events[]?
        | select((.strHomeTeam // "") != "" and (.strAwayTeam // "") != "")
        | "⚽ Next: \(.strHomeTeam) vs \(.strAwayTeam) (\(.dateEvent)\(if (.strTime // "") != "" then " " + .strTime[0:5] else "" end)) | World Cup" ][0:5]')
  else
    WC_FIXTURES="[]"
  fi
  [ -z "$WC_FIXTURES" ] && WC_FIXTURES="[]"

  # combine results + upcoming fixtures, then cache & stamp this hour
  WC_ITEMS=$(jq -n --argjson r "$WC_RESULTS" --argjson f "$WC_FIXTURES" '$r + $f')
  echo "$WC_ITEMS" > "$WC_CACHE"
  echo "$HOUR_KEY" > "$WC_STAMP"
else
  WC_ITEMS=$( [ -f "$WC_CACHE" ] && cat "$WC_CACHE" || echo "[]" )
fi
[ -z "$WC_ITEMS" ] && WC_ITEMS="[]"

# --- AI news topics (daily) ---
if [ "$news_stale" -eq 1 ]; then
  # fetch today's AI-news topic titles, then cache & stamp today
  NEWS_ITEMS=$(curl -sf "$API_BASE/digests/$DATE/topics" \
    | jq -c '[.topics[]?.title // empty | "🤖 " + . + " | unfolding"]') || NEWS_ITEMS="[]"
  [ -z "$NEWS_ITEMS" ] && NEWS_ITEMS="[]"
  echo "$NEWS_ITEMS" > "$NEWS_CACHE"
  echo "$DATE" > "$NEWS_STAMP"
else
  NEWS_ITEMS=$( [ -f "$NEWS_CACHE" ] && cat "$NEWS_CACHE" || echo "[]" )
fi
[ -z "$NEWS_ITEMS" ] && NEWS_ITEMS="[]"

# merge World Cup items (results + fixtures) first, then AI-news topics
ITEMS=$(jq -n --argjson wc "$WC_ITEMS" --argjson news "$NEWS_ITEMS" '$wc + $news')

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
info "Fetching World Cup results & today's AI news..."
bash "$UPDATE_SCRIPT" && ok "Spinner updated" || err "First update failed (no digest for today yet?)"

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

# detect shell — add to the user's login shell rc file
case "${SHELL:-}" in
  */zsh)  add_hook "$HOME/.zshrc" ;;
  */bash) add_hook "$HOME/.bashrc" ;;
  *)      add_hook "$HOME/.zshrc"; add_hook "$HOME/.bashrc" ;;
esac

echo ""
ok "Done! Your Claude Code spinner refreshes World Cup results hourly and today's AI news daily, on each new shell."
