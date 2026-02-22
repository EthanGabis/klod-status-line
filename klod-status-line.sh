#!/bin/bash
# Custom powerline-styled statusline with original data fields
# Classic pointy powerline arrows between flowing segments
# Tokyo Night theme

input=$(cat)

# Extract values from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$current_dir" ] && current_dir=$(pwd)
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
usage=$(echo "$input" | jq '.context_window.current_usage // null')
session_id=$(echo "$input" | jq -r '.session_id // "default"')
dir_name=$(basename "$current_dir")

# Git branch + dirty
branch_value=""
if [ -d "$current_dir/.git" ] || git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$current_dir" -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ -n "$branch" ]; then
    if ! git -C "$current_dir" -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false diff --quiet 2>/dev/null || \
       ! git -C "$current_dir" -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false diff --cached --quiet 2>/dev/null; then
      branch_value="${branch}*"
    else
      branch_value="${branch}"
    fi
  fi
fi

# Context window %
context_pct=0
usage=$(echo "$input" | jq '.context_window.current_usage // null')
if [ "$usage" != "null" ] && [ -n "$usage" ]; then
  input_tokens=$(echo "$usage" | jq '.input_tokens // 0')
  cache_creation=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
  cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
  ctx_current=$(( input_tokens + cache_creation + cache_read ))
  ctx_size=$(echo "$input" | jq '.context_window.context_window_size // 0')
  if [ "$ctx_size" -gt 0 ] && [ "$ctx_current" -gt 0 ]; then
    context_pct=$(( ctx_current * 100 / ctx_size ))
  fi
fi

# Time
current_time=$(date +%H:%M 2>/dev/null || echo "00:00")

# Session duration
session_start_file="/tmp/claude_session_${session_id}"
session_duration="0m"
if [ -f "$session_start_file" ]; then
  session_start=$(cat "$session_start_file" 2>/dev/null || echo "0")
else
  date +%s > "$session_start_file" 2>/dev/null
  session_start=$(date +%s)
fi
current_epoch=$(date +%s)
if [ "$session_start" -gt 0 ] && [ "$current_epoch" -gt 0 ]; then
  duration_seconds=$(( current_epoch - session_start ))
  duration_minutes=$(( duration_seconds / 60 ))
  duration_hours=$(( duration_minutes / 60 ))
  duration_mins_remainder=$(( duration_minutes % 60 ))
  if [ $duration_hours -gt 0 ]; then
    session_duration="${duration_hours}h${duration_mins_remainder}m"
  else
    session_duration="${duration_minutes}m"
  fi
fi

# ── Powerline rendering (classic pointy arrows) ─────────────────────
RST="\033[0m"
SEP=$'\xee\x82\xb0'  # U+E0B0 powerline right arrow (raw UTF-8 bytes)

# Collect segments as arrays: bg_r;bg_g;bg_b  fg_r;fg_g;fg_b  "content"
seg_bg=()
seg_fg=()
seg_text=()

add_seg() {
  seg_bg+=("$1;$2;$3")
  seg_fg+=("$4;$5;$6")
  seg_text+=("$7")
}

# Tokyo Night segments
#   dir: deep navy bg, blue text
ICON_DIR=$'\xef\x81\xbb'  # U+F07B nerd font folder icon
add_seg 47 51 77   130 170 255  " ${ICON_DIR} dir: ${dir_name} "

# branch: darker navy, green text
if [ -n "$branch_value" ]; then
  ICON_BRANCH=$'\xef\x90\xa6'  # U+F0426 nerd font git-branch icon
add_seg 30 32 48   195 232 141  " ${ICON_BRANCH} branch: ${branch_value} "
fi

# model: deepest bg, pink text
add_seg 25 27 41   252 167 234  " ◆ model: ${model_name} "

# session: dark bg, cyan text
add_seg 34 36 54   134 225 252  " ⏱ session: ${session_duration} "

# context bar: color based on usage level
# Build a mini progress bar: filled ━ and empty ─
ctx_bar_width=8
ctx_filled=$(( context_pct * ctx_bar_width / 100 ))
[ "$ctx_filled" -gt "$ctx_bar_width" ] && ctx_filled=$ctx_bar_width
ctx_empty=$(( ctx_bar_width - ctx_filled ))
ctx_bar=""
for (( b=0; b<ctx_filled; b++ )); do ctx_bar+="━"; done
for (( b=0; b<ctx_empty; b++ )); do ctx_bar+="─"; done
if [ "$context_pct" -ge 80 ]; then
  add_seg 60 40 40   247 118 142  " ◉ context: ${ctx_bar} ${context_pct}% "
elif [ "$context_pct" -ge 50 ]; then
  add_seg 50 45 35   255 158 100  " ◉ context: ${ctx_bar} ${context_pct}% "
else
  add_seg 41 46 66   134 144 184  " ◉ context: ${ctx_bar} ${context_pct}% "
fi

# ── Render classic powerline ─────────────────────────────────────────
out=""
count=${#seg_bg[@]}

for (( i=0; i<count; i++ )); do
  IFS=';' read -r br bg bb <<< "${seg_bg[$i]}"
  IFS=';' read -r fr fg fb <<< "${seg_fg[$i]}"

  BG="\033[48;2;${br};${bg};${bb}m"
  FG="\033[38;2;${fr};${fg};${fb}m"

  # Segment content
  out+="${BG}${FG}${seg_text[$i]}"

  # Arrow separator: current bg color as fg, next bg color as bg (or reset if last)
  if [ $((i + 1)) -lt $count ]; then
    IFS=';' read -r nbr nbg nbb <<< "${seg_bg[$((i+1))]}"
    NEXT_BG="\033[48;2;${nbr};${nbg};${nbb}m"
    SEP_FG="\033[38;2;${br};${bg};${bb}m"
    out+="${NEXT_BG}${SEP_FG}${SEP}"
  else
    SEP_FG="\033[38;2;${br};${bg};${bb}m"
    out+="${RST}${SEP_FG}${SEP}${RST}"
  fi
done

printf "%b" "$out"
