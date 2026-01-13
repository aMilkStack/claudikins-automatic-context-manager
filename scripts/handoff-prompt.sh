#!/bin/bash
# Prompts user for handoff with Yes/No/Remind options
# Styled dialog matching Claude CLI aesthetic

TRANSCRIPT_PATH="$1"
SESSION_ID="$2"
FLAG_FILE="/tmp/handoff-triggered-${SESSION_ID}"
SNOOZE_FILE="/tmp/handoff-snooze-${SESSION_ID}"

# Load configuration (if exists)
CONFIG_FILE="$HOME/.claude/cc-acm.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Set defaults if not configured
THRESHOLD="${THRESHOLD:-60}"
SNOOZE_DURATION="${SNOOZE_DURATION:-300}"
SUMMARY_TOKENS="${SUMMARY_TOKENS:-500}"
DIALOG_STYLE="${DIALOG_STYLE:-vibrant}"

# Show styled dialog matching Claude aesthetic with vibrant cyberpunk vibes
RESULT=$(powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Colors based on dialog style (vibrant or minimal)
\$bgColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
if ('$DIALOG_STYLE' -eq 'minimal') {
    \$fgColor = [System.Drawing.Color]::FromArgb(210, 210, 215)
    \$mutedColor = [System.Drawing.Color]::FromArgb(140, 140, 150)
    \$accentColor = [System.Drawing.Color]::FromArgb(217, 119, 87)
} else {
    # Vibrant colors matching the CC-ACM header aesthetic
    \$fgColor = [System.Drawing.Color]::FromArgb(230, 230, 235)
    \$mutedColor = [System.Drawing.Color]::FromArgb(160, 160, 170)
    \$accentColor = [System.Drawing.Color]::FromArgb(255, 140, 80)
}
\$pinkAccent = [System.Drawing.Color]::FromArgb(255, 120, 200)
\$btnBg = [System.Drawing.Color]::FromArgb(39, 39, 42)

\$form = New-Object System.Windows.Forms.Form
\$form.Text = 'Claude'
\$form.Size = New-Object System.Drawing.Size(420, 180)
\$form.StartPosition = 'CenterScreen'
\$form.FormBorderStyle = 'FixedDialog'
\$form.MaximizeBox = \$false
\$form.MinimizeBox = \$false
\$form.BackColor = \$bgColor
\$form.ForeColor = \$fgColor
\$form.TopMost = \$true

# Header
\$header = New-Object System.Windows.Forms.Label
\$header.Location = New-Object System.Drawing.Point(15, 15)
\$header.AutoSize = \$true
\$header.Text = 'CONTEXT ALERT ($THRESHOLD%)'
\$header.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 12)
\$header.ForeColor = \$accentColor
\$form.Controls.Add(\$header)

# Message
\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(15, 45)
\$label.AutoSize = \$true
\$label.Text = 'Session context usage has reached $THRESHOLD%. Generate summary and open a fresh session?'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = \$mutedColor
\$form.Controls.Add(\$label)

# Buttons
\$yesBtn = New-Object System.Windows.Forms.Button
\$yesBtn.Location = New-Object System.Drawing.Point(15, 90)
\$yesBtn.Size = New-Object System.Drawing.Size(120, 35)
\$yesBtn.Text = 'YES'
\$yesBtn.FlatStyle = 'Flat'
\$yesBtn.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
\$yesBtn.BackColor = \$accentColor
\$yesBtn.ForeColor = \$bgColor
\$yesBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$yesBtn.Add_Click({ \$form.Tag = 'Yes'; \$form.Close() })
\$form.Controls.Add(\$yesBtn)
\$form.AcceptButton = \$yesBtn

\$remindBtn = New-Object System.Windows.Forms.Button
\$remindBtn.Location = New-Object System.Drawing.Point(145, 90)
\$remindBtn.Size = New-Object System.Drawing.Size(120, 35)
\$remindBtn.Text = 'IN 5 MIN'
\$remindBtn.FlatStyle = 'Flat'
\$remindBtn.Font = New-Object System.Drawing.Font('Segoe UI', 9)
\$remindBtn.BackColor = \$btnBg
\$remindBtn.ForeColor = \$fgColor
\$remindBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$remindBtn.Add_Click({ \$form.Tag = 'Remind'; \$form.Close() })
\$form.Controls.Add(\$remindBtn)

\$noBtn = New-Object System.Windows.Forms.Button
\$noBtn.Location = New-Object System.Drawing.Point(275, 90)
\$noBtn.Size = New-Object System.Drawing.Size(120, 35)
\$noBtn.Text = 'DISMISS'
\$noBtn.FlatStyle = 'Flat'
\$noBtn.Font = New-Object System.Drawing.Font('Segoe UI', 9)
\$noBtn.BackColor = \$btnBg
\$noBtn.ForeColor = \$mutedColor
\$noBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$noBtn.Add_Click({ \$form.Tag = 'No'; \$form.Close() })
\$form.Controls.Add(\$noBtn)
\$form.CancelButton = \$noBtn

\$form.Add_Shown({\$form.Activate()})
[void]\$form.ShowDialog()
\$form.Tag
" 2>&1 | tr -d '\r')

# Check if dialog failed to open
if [ -z "$RESULT" ]; then
    echo "CC-ACM: Dialog failed to open. Check PowerShell/WinForms availability." >&2
    exit 1
fi

case "$RESULT" in
    "Yes")
        # Continue with handoff
        ;;
    "Remind")
        # Set snooze for configured duration, remove the permanent flag
        rm -f "$FLAG_FILE"
        echo $(($(date +%s) + SNOOZE_DURATION)) > "$SNOOZE_FILE"
        exit 0
        ;;
    *)
        # No or closed - keep flag so we don't ask again
        exit 0
        ;;
esac

# Find transcript if not provided
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    # Use null-delimited find for paths with spaces
    TRANSCRIPT_PATH=$(find ~/.claude/projects -name "*.jsonl" -type f -printf '%T@\0%p\0' 2>/dev/null | \
        sort -z -n | tail -z -n 1 | cut -z -d$'\0' -f2 | tr -d '\0')
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Could not find transcript file', 'Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi

# Cleanup function for progress dialog
cleanup_progress() {
    kill $PROGRESS_PID 2>/dev/null || true
}
trap cleanup_progress EXIT

# Show progress indicator
powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

\$progressForm = New-Object System.Windows.Forms.Form
\$progressForm.Text = 'CC-ACM'
\$progressForm.Size = New-Object System.Drawing.Size(400, 140)
\$progressForm.StartPosition = 'CenterScreen'
\$progressForm.FormBorderStyle = 'FixedDialog'
\$progressForm.MaximizeBox = \$false
\$progressForm.MinimizeBox = \$false
\$progressForm.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
\$progressForm.TopMost = \$true

\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(20, 30)
\$label.Size = New-Object System.Drawing.Size(360, 60)
\$label.Text = 'Generating handoff summary...`n`nThis might take a few seconds'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 80)
\$label.TextAlign = 'MiddleCenter'
\$progressForm.Controls.Add(\$label)

\$progressForm.Show()
\$progressForm.Refresh()
" 2>/dev/null &
PROGRESS_PID=$!

# Gather context for handoff
# 1. Extract recent conversation (smarter truncation)
CONVERSATION=$(cat "$TRANSCRIPT_PATH" | grep -E '"type":"(user|assistant)"' | \
    python3 -c "
import sys, json
msgs = []
total_chars = 0
MAX_CHARS = 15000  # ~3-4k tokens worth of context

for line in sys.stdin:
    try:
        d = json.loads(line)
        role = d.get('type', '')
        content = d.get('message', {}).get('content', '')
        if isinstance(content, list):
            content = ' '.join([c.get('text', '') for c in content if isinstance(c, dict)])
        if role in ('user', 'assistant') and content:
            msgs.append((role, content))
    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        pass

# Take recent messages up to MAX_CHARS
recent = []
for role, content in reversed(msgs):
    if total_chars + len(content) > MAX_CHARS:
        break
    recent.insert(0, f'{role.upper()}: {content}')
    total_chars += len(content)

print('\n\n'.join(recent))
" 2>/dev/null)

# 2. Get git context if available
GIT_CONTEXT=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    GIT_STATUS=$(git status --short 2>/dev/null | head -20)
    GIT_RECENT=$(git log --oneline -5 2>/dev/null)

    if [ -n "$GIT_STATUS" ] || [ -n "$GIT_RECENT" ]; then
        GIT_CONTEXT="

GIT CONTEXT:
Branch: $GIT_BRANCH

Modified files:
$GIT_STATUS

Recent commits:
$GIT_RECENT
"
    fi
fi

# 3. Generate handoff with improved prompt
CLAUDE_STDERR=$(mktemp)
HANDOFF=$(cat << EOF | claude -p 2>"$CLAUDE_STDERR"
You are generating a handoff summary for a developer who reached their context limit and needs to continue in a fresh session.

Analyze the conversation below and create a strategic handoff summary (under $SUMMARY_TOKENS tokens) that includes:

1. **Current Objective** - What is the main goal/task being worked on?
2. **Progress So Far** - What has been accomplished? What works?
3. **Active Work** - What was being done right before the handoff?
4. **Key Decisions** - Important architectural or implementation decisions made
5. **Next Steps** - Concrete actions to take when resuming
6. **Context to Remember** - Patterns, conventions, or constraints established

Format as clear, scannable markdown. Be specific and actionable.

CONVERSATION:
$CONVERSATION
$GIT_CONTEXT
EOF
)

# Close progress dialog (trap handles cleanup on exit)
cleanup_progress

if [ -z "$HANDOFF" ]; then
    ERROR_DETAIL=""
    if [ -s "$CLAUDE_STDERR" ]; then
        ERROR_DETAIL=$(head -c 200 "$CLAUDE_STDERR")
    fi
    rm -f "$CLAUDE_STDERR"

    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Failed to generate handoff.`n`n$ERROR_DETAIL', 'CC-ACM Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi
rm -f "$CLAUDE_STDERR"

# Save handoff to skill file
HANDOFF_SKILL="$HOME/.claude/skills/acm-handoff/SKILL.md"
mkdir -p "$(dirname "$HANDOFF_SKILL")"

cat > "$HANDOFF_SKILL" << EOF
---
name: acm-handoff
description: Context handoff from a previous Claude Code session that reached $THRESHOLD% context usage. Use this to understand what was being worked on and continue seamlessly from where the previous session left off.
---

# Context Handoff from Previous Session

This session was started via CC-ACM (Claude Code Automatic Context Manager) after the previous session reached **$THRESHOLD% context usage**.

## Previous Session Summary

$HANDOFF

## How to Use This Context

- Review the summary above to understand what was being worked on
- Continue the work from where it was left off
- The summary was automatically generated to preserve context
- You now have a fresh context window with full headroom

---

*Handoff generated automatically by CC-ACM v1.0*
*To configure CC-ACM settings, use: /acm:config*
EOF

# Open new Warp tab with claude command using Warp launch configuration
# SessionStart hook will automatically detect and invoke the handoff
if ! powershell.exe -Command "Start-Process 'warp://launch/cc-acm-handoff'" 2>/dev/null; then
    echo "CC-ACM: Handoff saved to ~/.claude/skills/acm-handoff/SKILL.md" >&2
    echo "CC-ACM: Start a new Claude session and use /acm:handoff to continue" >&2
fi
