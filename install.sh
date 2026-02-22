#!/bin/bash
# klod-status-line installer
set -e

INSTALL_DIR="$HOME/.claude/klod-status-line"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Installing klod-status-line..."

# Copy scripts to ~/.claude/klod-status-line/
mkdir -p "$INSTALL_DIR"
cp klod-status-line.sh "$INSTALL_DIR/klod-status-line.sh"
cp klod-combined.sh "$INSTALL_DIR/klod-combined.sh"
chmod +x "$INSTALL_DIR/klod-status-line.sh" "$INSTALL_DIR/klod-combined.sh"

# Update paths in combined script to use install directory
sed -i.bak "s|bash .*/statusline-powerline-custom.sh|bash $INSTALL_DIR/klod-status-line.sh|g" "$INSTALL_DIR/klod-combined.sh"
rm -f "$INSTALL_DIR/klod-combined.sh.bak"

# Check for claude-pulse (optional second line)
PULSE_PATH=""
if [ -f "$HOME/.claude/claude-pulse/claude_status.py" ]; then
  PULSE_PATH="$HOME/.claude/claude-pulse/claude_status.py"
elif command -v python3 >/dev/null 2>&1; then
  echo ""
  echo "Optional: Install claude-pulse for usage bars on a second line."
  echo "  git clone https://github.com/NoobyGains/claude-pulse.git ~/.claude/claude-pulse"
  echo ""
fi

# Update combined script python path
if [ -n "$PULSE_PATH" ]; then
  PYTHON_PATH=$(command -v python3 2>/dev/null || echo "/usr/bin/python3")
  sed -i.bak "s|/Library/Developer/CommandLineTools/usr/bin/python3|$PYTHON_PATH|g" "$INSTALL_DIR/klod-combined.sh"
  sed -i.bak "s|\"/Users/[^\"]*claude-pulse/claude_status.py\"|\"$PULSE_PATH\"|g" "$INSTALL_DIR/klod-combined.sh"
  rm -f "$INSTALL_DIR/klod-combined.sh.bak"
fi

# Update settings.json
if [ -f "$SETTINGS_FILE" ]; then
  # Check if statusLine already exists
  if python3 -c "import json; d=json.load(open('$SETTINGS_FILE')); print('statusLine' in d)" 2>/dev/null | grep -q True; then
    # Update existing statusLine
    python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    d = json.load(f)
d['statusLine'] = {
    'type': 'command',
    'command': 'bash $INSTALL_DIR/klod-combined.sh',
    'refresh': 150
}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(d, f, indent=2)
print('Updated statusLine in settings.json')
"
  else
    # Add statusLine
    python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    d = json.load(f)
d['statusLine'] = {
    'type': 'command',
    'command': 'bash $INSTALL_DIR/klod-combined.sh',
    'refresh': 150
}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(d, f, indent=2)
print('Added statusLine to settings.json')
"
  fi
else
  echo "Creating settings.json..."
  mkdir -p "$HOME/.claude"
  cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "statusLine": {
    "type": "command",
    "command": "bash INSTALL_DIR_PLACEHOLDER/klod-combined.sh",
    "refresh": 150
  }
}
SETTINGS
  sed -i.bak "s|INSTALL_DIR_PLACEHOLDER|$INSTALL_DIR|g" "$SETTINGS_FILE"
  rm -f "$SETTINGS_FILE.bak"
fi

echo ""
echo "klod-status-line installed successfully!"
echo ""
echo "  Scripts: $INSTALL_DIR/"
echo "  Config:  $SETTINGS_FILE"
echo ""
echo "Restart Claude Code to see your new status line."
echo ""
echo "Standalone (without claude-pulse):"
echo "  Edit $SETTINGS_FILE and change the command to:"
echo "  bash $INSTALL_DIR/klod-status-line.sh"
