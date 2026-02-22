# klod-status-line

A powerline-styled status line for Claude Code with Tokyo Night colors.

Shows your workspace info at a glance with classic powerline arrow separators between colored segments.

```
 dir: Projects  branch: main*  ◆ model: Opus 4.6  ⏱ session: 2h15m  ◉ context: ━━━━──── 55%  ● battery: 85%
```

## Segments

| Segment | Icon | Description | Color |
|---------|------|-------------|-------|
| dir | folder | Current directory name | Blue on navy |
| branch | git | Git branch + dirty indicator (`*`) | Green on dark navy |
| model | ◆ | Active Claude model | Pink on deep navy |
| session | ⏱ | Session duration | Cyan on dark |
| context | ◉ | Context window usage with progress bar | Adaptive (green/orange/red) |
| todos | ✎ | TODO/FIXME/XXX count in source files | Orange (only shown if > 0) |
| battery | ● | Battery level (macOS) | Adaptive (green/orange/red) |

### Context bar

The context segment includes a mini progress bar (`━━━━────`) that fills as context usage increases. Colors shift automatically:

- **< 50%** — muted blue (plenty of room)
- **50-79%** — orange (getting warm)
- **80%+** — red (close to the limit)

### Battery

Same adaptive coloring:
- **> 50%** — green
- **20-50%** — orange
- **< 20%** — red

## Requirements

- **Bash 4+**
- **jq** (for JSON parsing)
- A terminal font with **Powerline glyphs** (e.g., any [Nerd Font](https://www.nerdfonts.com/))
- **macOS** for battery segment (auto-hidden on Linux/Windows)

## Installation

### Quick install

```bash
git clone https://github.com/EthanGabis/klod-status-line.git
cd klod-status-line
./install.sh
```

Restart Claude Code. Done.

### Manual install

1. Clone the repo:

```bash
git clone https://github.com/EthanGabis/klod-status-line.git ~/.claude/klod-status-line
```

2. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/klod-status-line/klod-status-line.sh",
    "refresh": 150
  }
}
```

3. Restart Claude Code.

### With claude-pulse (dual status line)

klod-status-line works great as line 1 with [claude-pulse](https://github.com/NoobyGains/claude-pulse) as line 2 for usage/rate-limit tracking:

```
 dir: Projects  branch: main*  ◆ model: Opus 4.6  ⏱ session: 2h15m  ◉ context: ━━━━──── 55%
Session ━━━━ 19% 3h 13m | Weekly ━━━━ 80% R:1h 13m | Sonnet ━━━━ 100% R:12pm
```

1. Install claude-pulse:

```bash
git clone https://github.com/NoobyGains/claude-pulse.git ~/.claude/claude-pulse
python3 ~/.claude/claude-pulse/claude_status.py --install
```

2. Run the klod installer (it auto-detects claude-pulse):

```bash
cd klod-status-line
./install.sh
```

This sets up `klod-combined.sh` which pipes stdin to both scripts and outputs both lines.

To configure claude-pulse theme/bars:

```bash
python3 ~/.claude/claude-pulse/claude_status.py --theme mono --bar-size small
```

## Customization

### Changing the theme

Edit `klod-status-line.sh` — each segment's colors are defined as RGB values in the `add_seg` calls:

```bash
# add_seg  bg_r bg_g bg_b   fg_r fg_g fg_b   "content"
add_seg    47   51   77     130  170  255     " dir: ${dir_name} "
```

- First 3 numbers = background color (RGB)
- Next 3 numbers = text color (RGB)

### Adding/removing segments

Add a new segment anywhere before the render loop:

```bash
add_seg 47 51 77  130 170 255  " icon label: ${value} "
```

Remove a segment by deleting or commenting out its `add_seg` line.

### Changing the separator

The separator character is defined at the top of the render section:

```bash
SEP=$'\xee\x82\xb0'  # U+E0B0 powerline right arrow
```

Other options:
- `$'\xee\x82\xb2'` — thin arrow (U+E0B2)
- `$'\xee\x82\xb4'` — rounded right (U+E0B4)

## How it works

Claude Code pipes JSON session data via stdin to the status line command on every update (~150ms). The script:

1. Parses the JSON with `jq` to extract model, directory, context window data
2. Gathers additional info (git status, session duration, battery, TODOs)
3. Builds an array of colored segments
4. Renders them with powerline arrow separators using ANSI truecolor escape codes
5. Outputs a single line to stdout

## License

MIT
