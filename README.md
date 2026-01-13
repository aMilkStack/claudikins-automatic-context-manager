![CC-ACM Header](assets/header.png)

# Claude Code Automatic Context Manager

Automatic context handoff for Claude Code. When context usage hits 60%, a dialog prompts you to generate a summary and continue in a fresh session.

**Requirements**: Claude Code CLI, WSL, Warp terminal, Python 3.

## What It Does

1. Statusline monitors context usage
2. At 60% (configurable), a dialog appears
3. Click YES - generates a summary via `claude -p`
4. Summary saved to `/acm:handoff` skill
5. New Warp tab opens with `claude`
6. SessionStart hook auto-loads the handoff

## Installation

```bash
./install.sh
```

**Manual step required**: Add the SessionStart hook to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-start-acm.sh"
          }
        ]
      }
    ]
  }
}
```

If you already have hooks, merge this into the existing `hooks` object.

## How It Works

```
Statusline runs every 300ms
    │
    └─ Context >= 60%?
           │
           YES → handoff-prompt.sh (background)
                    │
                    ├─ Dialog appears (retro ASCII style)
                    │
                    ├─ [YES] → claude -p generates summary
                    │          → Writes to ~/.claude/skills/acm-handoff/SKILL.md
                    │          → Opens new Warp tab (Ctrl+Shift+T)
                    │          → Pastes "claude" + Enter
                    │          → SessionStart hook fires
                    │          → Claude auto-invokes /acm:handoff
                    │
                    ├─ [SNOOZE] → Asks again in 5 min (configurable)
                    │
                    └─ [DISMISS] → Won't ask again this session
```

## File Structure

```
~/.claude/
├── scripts/
│   └── handoff-prompt.sh      # Dialog + handoff generation
├── hooks/
│   └── session-start-acm.sh   # Detects handoff, tells Claude to load it
├── skills/
│   ├── acm-config/SKILL.md    # /acm:config - interactive settings
│   └── acm-handoff/SKILL.md   # /acm:handoff - handoff content (rewritten each time)
├── settings.json              # Must contain SessionStart hook (see above)
├── statusline-command.sh      # Includes CC-ACM trigger logic
└── cc-acm.conf                # Config file (threshold, snooze, etc.)
```

## Configuration

Use `/acm:config` in Claude for interactive setup, or edit `~/.claude/cc-acm.conf`:

```bash
THRESHOLD=60           # Context % to trigger (50-90)
SNOOZE_DURATION=300    # Seconds before re-prompting (60-3600)
SUMMARY_TOKENS=500     # Max tokens for summary (200-2000)
```

## Technical Details

**Dialog**: PowerShell WinForms, borderless with ASCII `░▒▓` borders. Retro palette matching the header pixel art.

**Warp Launch**: Uses SendKeys - focuses Warp, Ctrl+Shift+T for new tab, clipboard paste "claude", Enter. AppActivate ensures correct window even if you click elsewhere.

**Hook**: Checks if `~/.claude/skills/acm-handoff/SKILL.md` exists and contains real content. If so, injects context telling Claude to immediately invoke `/acm:handoff`.

**Summary Generation**: Extracts recent conversation from transcript, includes git context if available, sends to `claude -p` for summarisation.

## Platform

WSL + Warp on Windows only. The dialog uses PowerShell WinForms, the tab launch uses Windows-specific SendKeys and AppActivate.

Other platforms (native Linux, macOS) would need different implementations for the dialog and terminal launch.

## Uninstall

```bash
./uninstall.sh
```

Removes scripts, hooks, skills, config, and temp files. Restores statusline from backup if available.

## Troubleshooting

**Dialog doesn't appear**: Check PowerShell/WinForms availability in WSL.

**New tab doesn't open**: Warp must be running. Check process name is `warp`.

**Hook doesn't fire**: Verify hook is in `settings.json` (not a separate `hooks.json`), and matcher is `startup`.

**Claude doesn't auto-load handoff**: Check `/acm:handoff` skill exists with real content (not "No Active Handoff").

