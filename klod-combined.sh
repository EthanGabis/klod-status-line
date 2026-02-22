#!/bin/bash
# klod-status-line combined wrapper
#   Line 1: klod powerline segments
#   Line 2: claude-pulse usage bars (optional)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
input=$(cat)

# Line 1: klod powerline
line1=$(echo "$input" | bash "$SCRIPT_DIR/klod-status-line.sh" 2>/dev/null)

# Line 2: claude-pulse (optional — only if installed)
PULSE_SCRIPT="$HOME/.claude/claude-pulse/claude_status.py"
if [ -f "$PULSE_SCRIPT" ]; then
  PYTHON=$(command -v python3 2>/dev/null || echo "python3")
  line2=$( echo "$input" | "$PYTHON" "$PULSE_SCRIPT" 2>/dev/null)
  printf "%b\n" "$line1"
  printf "%s\n" "$line2"
else
  printf "%b\n" "$line1"
fi
