#!/bin/bash
# Prompts user for handoff with Yes/No/Remind options
# Styled dialog matching Claude CLI aesthetic

TRANSCRIPT_PATH="$1"
SESSION_ID="$2"
FLAG_FILE="/tmp/handoff-triggered-${SESSION_ID}"
SNOOZE_FILE="/tmp/handoff-snooze-${SESSION_ID}"

# Show styled dialog matching Claude aesthetic with vibrant cyberpunk vibes
RESULT=$(powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Vibrant colors matching the CC-ACM header aesthetic
\$bgColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
\$fgColor = [System.Drawing.Color]::FromArgb(230, 230, 235)
\$mutedColor = [System.Drawing.Color]::FromArgb(160, 160, 170)
\$accentColor = [System.Drawing.Color]::FromArgb(255, 140, 80)
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

# Header with emoji
\$header = New-Object System.Windows.Forms.Label
\$header.Location = New-Object System.Drawing.Point(15, 15)
\$header.AutoSize = \$true
\$header.Text = '⚡ Context Getting Full! ⚡'
\$header.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 12)
\$header.ForeColor = \$accentColor
\$form.Controls.Add(\$header)

# Message
\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(15, 45)
\$label.AutoSize = \$true
\$label.Text = 'You''re at 60% context. Start a fresh session with a summary?'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = \$mutedColor
\$form.Controls.Add(\$label)

# Buttons with clearer labels
\$yesBtn = New-Object System.Windows.Forms.Button
\$yesBtn.Location = New-Object System.Drawing.Point(15, 90)
\$yesBtn.Size = New-Object System.Drawing.Size(120, 35)
\$yesBtn.Text = 'Let''s Go! 🚀'
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
\$remindBtn.Text = 'Give me 5 🕐'
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
\$noBtn.Text = 'Not Now'
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
" 2>/dev/null | tr -d '\r')

case "$RESULT" in
    "Yes")
        # Continue with handoff
        ;;
    "Remind")
        # Set snooze for 5 minutes, remove the permanent flag
        rm -f "$FLAG_FILE"
        echo $(($(date +%s) + 300)) > "$SNOOZE_FILE"
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
\$label.Text = '⚡ Generating handoff summary...`n`nThis might take a few seconds'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 80)
\$label.TextAlign = 'MiddleCenter'
\$progressForm.Controls.Add(\$label)

\$progressForm.Show()
\$progressForm.Refresh()
" 2>/dev/null &
PROGRESS_PID=$!

# Extract conversation from JSONL
CONVERSATION=$(cat "$TRANSCRIPT_PATH" | grep -E '"type":"(user|assistant)"' | \
    python3 -c "
import sys, json
msgs = []
for line in sys.stdin:
    try:
        d = json.loads(line)
        role = d.get('type', '')
        content = d.get('message', {}).get('content', '')
        if isinstance(content, list):
            content = ' '.join([c.get('text', '') for c in content if isinstance(c, dict)])
        if role in ('user', 'assistant') and content:
            msgs.append(f'{role.upper()}: {content[:500]}')
    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        pass
print('\n'.join(msgs[-20:]))
" 2>/dev/null)

# Generate handoff via claude -p
HANDOFF=$(echo "$CONVERSATION" | claude -p "Generate a concise handoff summary (under 500 tokens) for continuing this conversation. Include: current task, progress made, next steps, key decisions. Format as markdown." 2>/dev/null)

# Close progress dialog
kill $PROGRESS_PID 2>/dev/null || true
pkill -f "CC-ACM.*progressForm" 2>/dev/null || true

if [ -z "$HANDOFF" ]; then
    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Failed to generate handoff', 'Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi

# Save handoff with header explaining context
cat > /tmp/claude-handoff.txt << EOF
# 🔄 Context Handoff from Previous Session

This is an automatic handoff summary generated by CC-ACM when your previous session reached 60% context.

---

$HANDOFF

---

*Generated by CC-ACM (Claude Code Automatic Context Manager)*
EOF

# Open new Warp tab with claude + handoff
powershell.exe -Command "
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport(\"user32.dll\")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport(\"user32.dll\")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@

\$proc = Get-Process warp | Where-Object { \$_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (\$proc) {
    [Win32]::ShowWindow(\$proc.MainWindowHandle, 9) | Out-Null
    Start-Sleep -Milliseconds 100
    [Win32]::SetForegroundWindow(\$proc.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 200

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait('^+t')
    Start-Sleep -Milliseconds 500

    Set-Clipboard -Value 'claude --append-system-prompt \"\`$(cat /tmp/claude-handoff.txt)\"'
    [System.Windows.Forms.SendKeys]::SendWait('^v')
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
}
" 2>/dev/null
