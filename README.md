![CC-ACM Header](assets/header.png)

# CC-ACM (Claude Code Automatic Context Manager)

Automatic context handoff for Claude Code. When your session hits 60% context usage, a dialog prompts you to generate a summary and open a fresh session with full context.

**For authenticated Claude Code CLI users** - Uses your logged-in session via `claude -p` (no API keys, no cost per handoff). This is a productivity tool for Pro/Teams users, not an API wrapper.

## Features

- **Auto-trigger at 60%** - Statusline monitors context usage (configurable)
- **Yes / In 5 min / Dismiss** - Snooze support for when you're mid-task (duration configurable)
- **Seamless handoff** - Summary generated via `claude -p`, new tab opens with `--append-system-prompt`
- **Dark themed UI** - Vibrant cyberpunk or minimal styles
- **Interactive config** - Use `/acm:config` to customize settings through Claude
- **Clean uninstaller** - Easy removal with `./uninstall.sh`

## How It Works

```
Statusline (every 300ms)
    │
    └─ at 60% → handoff-prompt.sh
                    │
                    ├─ [YES] → Generate summary → Write to /acm:handoff skill → Open new tab
                    │          SessionStart hook → "Use /acm:handoff" → Claude loads context
                    │
                    ├─ [IN 5 MIN] → Snooze, asks again after configured duration
                    │
                    └─ [DISMISS] → Won't ask again this session
```

### The Handoff Flow

1. **Context reaches threshold** - Dialog appears when you hit configured % (default 60%)
2. **Click YES** - Summary is generated using `claude -p` with your auth
3. **Summary written to skill** - Saved to `~/.claude/skills/acm-handoff/SKILL.md`
4. **New session opens** - Fresh Claude tab launches automatically
5. **SessionStart hook runs** - Detects handoff and prompts Claude to use it
6. **Claude loads context** - Uses `/acm:handoff` skill containing your summary

## Installation

```bash
# Run the install script
./install.sh
```

This will:
1. Copy scripts to `~/.claude/scripts/`
2. Install SessionStart hook to `~/.claude/hooks/`
3. Install acm-handoff skill to `~/.claude/skills/`
4. Register the hook in `~/.claude/hooks.json`
5. Update your statusline to trigger at configured threshold
6. Back up existing files

## Manual Installation

1. Copy `scripts/handoff-prompt.sh` to `~/.claude/scripts/`
2. Make executable: `chmod +x ~/.claude/scripts/handoff-prompt.sh`
3. Add the trigger logic to your statusline (see `statusline-patch.sh`)

## Architecture

```
cc-acm/
├── scripts/
│   └── handoff-prompt.sh        # Main script: dialog + handoff generation
├── .claude/
│   ├── hooks/
│   │   └── session-start-acm.sh  # SessionStart hook for auto-loading handoff
│   └── hooks.json                 # Hook registration config
├── skills/
│   ├── acm-config/
│   │   └── SKILL.md               # Interactive configuration skill
│   └── acm-handoff/
│       └── SKILL.md               # Dynamic handoff skill (rewritten each handoff)
├── install.sh                     # Installer
└── uninstall.sh                   # Uninstaller
```

### Skills

**`/acm:config`** - Interactive configuration
Guides you through customizing CC-ACM settings with friendly Q&A. Configures threshold, snooze duration, summary length, and dialog style.

**`/acm:handoff`** - Context handoff
Dynamically written during handoff. Contains the summary from your previous session. SessionStart hook prompts Claude to use this automatically when starting a new session after handoff.

## Configuration

### Interactive Configuration (Recommended)

Use the `/acm:config` skill in Claude Code for an interactive setup:

```bash
# In any Claude Code session
/acm:config
```

Claude will guide you through customizing:
- **Trigger threshold** (50-90%, default: 60%)
- **Snooze duration** (1-60 minutes, default: 5)
- **Summary token length** (200-2000, default: 500)
- **Dialog style** (vibrant or minimal)

Settings are saved to `~/.claude/cc-acm.conf` and apply immediately to new sessions.

### Manual Configuration

Alternatively, create/edit `~/.claude/cc-acm.conf`:

```bash
# CC-ACM Configuration
THRESHOLD=60
SNOOZE_DURATION=300
SUMMARY_TOKENS=500
DIALOG_STYLE=vibrant
```

### Viewing Current Config

```bash
cat ~/.claude/cc-acm.conf
```

## Requirements (WSL/Warp - Default)

- Claude Code CLI
- WSL with Warp terminal (uses PowerShell for dialogs)
- Python 3 (for transcript parsing)

## Platform Support

**Primary Platform (Fully Supported):**
- **WSL + Warp Terminal** - Tested on Windows 11 + WSL2 + Warp

**Other Platforms (In Development):**

| Platform | Dialog | New Tab | Status |
|----------|--------|---------|--------|
| [Linux (Zenity)](platforms/linux-zenity/) | Zenity GTK | gnome-terminal | In Development |
| [macOS](platforms/macos/) | osascript | iTerm2/Terminal | In Development |
| [Generic](platforms/generic/) | Text prompt | Manual | In Development |

To try a platform variant, copy the `handoff-prompt.sh` from the relevant `platforms/` folder instead of the default one. Contributions and testing feedback welcome!

## Uninstall

To completely remove CC-ACM:

```bash
./uninstall.sh
```

This will:
- Remove the handoff script
- Restore your original statusline
- Delete configuration and temp files

## License

MIT
