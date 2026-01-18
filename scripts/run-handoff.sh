#!/bin/bash
# Claudikins ACM - Run handoff
# Called by Claude after user confirms handoff
# Generates summary and opens new session

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config
CONFIG_FILE="$HOME/.claude/claudikins-acm.conf"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Find most recent transcript
TRANSCRIPT=$(find ~/.claude/projects -name "*.jsonl" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
    echo "ERROR: Could not find transcript file" >&2
    exit 1
fi

echo "Capturing structured state..."

# Capture structured state (replaces prose summary)
export TRANSCRIPT
STATE_FILE=$("$SCRIPT_DIR/capture-state.sh" "$(pwd)" "$TRANSCRIPT")

if [ ! -f "$STATE_FILE" ]; then
    echo "ERROR: Failed to capture state" >&2
    exit 1
fi

# Generate human-readable handoff.md from structured state
HANDOFF_DIR=".claude/claudikins-acm"
mkdir -p "$HANDOFF_DIR"
HANDOFF_FILE="$HANDOFF_DIR/handoff.md"

cat > "$HANDOFF_FILE" << EOF
# Claudikins ACM Handoff

*Generated: $(date)*

## Current Objective
$(jq -r '.context.current_objective // "Not captured"' "$STATE_FILE")

## Active Todos
$(jq -r '.context.active_todos[] | "- [\(.status)] \(.content)"' "$STATE_FILE" 2>/dev/null || echo "None")

## Recent Files Modified
$(jq -r '.context.key_files_modified[]' "$STATE_FILE" 2>/dev/null | head -5 || echo "None")

## Git Status
Branch: $(jq -r '.git.branch // "unknown"' "$STATE_FILE")

---
*Full state: .claude/claudikins-acm/handoff-state.json*
*Use /acm:handoff to review this context*
EOF

echo "Handoff saved to: $HANDOFF_FILE"

# Launch new terminal with claude
echo "Opening new session..."

CWD="$(pwd)"
LAUNCHED=false

launch_terminal() {
    # Windows (native - Git Bash, PowerShell, etc.)
    if [ -n "$WINDIR" ] && [ -z "$WSL_DISTRO_NAME" ]; then
        if command -v wt.exe &> /dev/null; then
            # Windows Terminal - new tab (works with Git Bash, PowerShell, etc.)
            if [ -n "$MSYSTEM" ]; then
                # Running in Git Bash/MSYS2 - open Git Bash tab
                wt.exe -w 0 new-tab --title "Claude" -d "$CWD" bash -c "claude"
            else
                # PowerShell
                wt.exe -w 0 new-tab --title "Claude" -d "$CWD" pwsh -NoExit -c "claude"
            fi
            LAUNCHED=true
        elif [ -n "$MSYSTEM" ]; then
            # Git Bash without Windows Terminal - new window
            start "" "git-bash" -c "cd '$CWD' && claude && exec bash"
            LAUNCHED=true
        else
            # Plain PowerShell - new window
            powershell.exe -Command "Start-Process pwsh -ArgumentList '-NoExit','-c','cd \"$CWD\"; claude'"
            LAUNCHED=true
        fi
        return
    fi

    # WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        if command -v wt.exe &> /dev/null; then
            # Windows Terminal with WSL tab
            wt.exe -w 0 new-tab --title "Claude" -- wsl.exe bash -c "cd '$CWD' && claude"
            LAUNCHED=true
        elif pgrep -x "warp" > /dev/null 2>&1 || pgrep -f "Warp.exe" > /dev/null 2>&1; then
            # Warp on WSL - uses SendKeys (see README for details)
            powershell.exe -Command "
                Add-Type -AssemblyName System.Windows.Forms
                \$warp = Get-Process -Name 'Warp' -ErrorAction SilentlyContinue
                if (\$warp) {
                    [Microsoft.VisualBasic.Interaction]::AppActivate(\$warp.Id)
                    Start-Sleep -Milliseconds 300
                    [System.Windows.Forms.SendKeys]::SendWait('^+t')
                    Start-Sleep -Milliseconds 500
                    Set-Clipboard 'cd $CWD && claude'
                    [System.Windows.Forms.SendKeys]::SendWait('^v')
                    Start-Sleep -Milliseconds 200
                    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
                }
            " 2>/dev/null
            LAUNCHED=true
        fi
        return
    fi

    # macOS
    if [ "$(uname)" = "Darwin" ]; then
        case "$TERM_PROGRAM" in
            "iTerm.app")
                osascript <<EOF
tell application "iTerm"
    tell current window
        create tab with default profile
        tell current session
            write text "cd '$CWD' && claude"
        end tell
    end tell
end tell
EOF
                LAUNCHED=true
                ;;
            "Apple_Terminal"|"")
                osascript <<EOF
tell application "Terminal"
    activate
    tell application "System Events" to keystroke "t" using command down
    delay 0.3
    do script "cd '$CWD' && claude" in front window
end tell
EOF
                LAUNCHED=true
                ;;
            "WarpTerminal")
                # Warp supports CLI
                open -a "Warp" "$CWD"
                sleep 0.5
                osascript -e 'tell application "System Events" to keystroke "t" using command down'
                LAUNCHED=true
                ;;
        esac
        return
    fi

    # Linux
    if [ "$(uname)" = "Linux" ]; then
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal --tab --working-directory="$CWD" -- bash -c "claude; exec bash"
            LAUNCHED=true
        elif command -v konsole &> /dev/null; then
            konsole --new-tab --workdir "$CWD" -e bash -c "claude; exec bash"
            LAUNCHED=true
        elif command -v xfce4-terminal &> /dev/null; then
            xfce4-terminal --tab --working-directory="$CWD" -e "bash -c 'claude; exec bash'"
            LAUNCHED=true
        elif command -v kitty &> /dev/null; then
            kitty @ launch --type=tab --cwd="$CWD" bash -c "claude; exec bash"
            LAUNCHED=true
        fi
        return
    fi
}

launch_terminal

# Fallback - copy to clipboard and show message
if [ "$LAUNCHED" = false ]; then
    CMD="cd '$CWD' && claude"

    # Try to copy to clipboard
    if command -v pbcopy &> /dev/null; then
        echo "$CMD" | pbcopy
    elif command -v xclip &> /dev/null; then
        echo "$CMD" | xclip -selection clipboard
    elif command -v xsel &> /dev/null; then
        echo "$CMD" | xsel --clipboard
    elif command -v clip.exe &> /dev/null; then
        echo "$CMD" | clip.exe
    fi

    echo ""
    echo "Open a new terminal and run:"
    echo "  $CMD"
    echo ""
    echo "(Command copied to clipboard if available)"
    echo "The handoff will load automatically via SessionStart hook."
fi

echo "Handoff complete!"
