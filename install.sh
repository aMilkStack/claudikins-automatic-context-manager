#!/bin/bash
# Claude Handoff - Installation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
STATUSLINE="$CLAUDE_DIR/statusline-command.sh"

# Colors for output
ORANGE='\033[38;5;208m'
PINK='\033[38;5;205m'
GREEN='\033[38;5;120m'
CYAN='\033[38;5;51m'
GRAY='\033[38;5;240m'
RESET='\033[0m'
BOLD='\033[1m'

# ASCII art banner matching the header vibes
echo -e "${ORANGE}${BOLD}"
cat << "EOF"
   ╔═══════════════════════════════════════════════════╗
   ║                                                   ║
   ║     ██████╗ ██████╗      █████╗  ██████╗███████╗ ║
   ║    ██╔════╝██╔════╝     ██╔══██╗██╔════╝██╔════╝ ║
   ║    ██║     ██║   ███╗   ███████║██║     █████╗   ║
   ║    ██║     ██║    ██║   ██╔══██║██║     ██╔══╝   ║
   ║    ╚██████╗╚██████╔╝   ██║  ██║╚██████╗███████╗ ║
   ║     ╚═════╝ ╚═════╝    ╚═╝  ╚═╝ ╚═════╝╚══════╝ ║
   ║                                                   ║
   ║      Automatic Context Manager                   ║
   ╚═══════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"
echo -e "${CYAN}    ⚡ Installing CC-ACM for Claude Code CLI ⚡${RESET}"
echo ""

# Create scripts directory if needed
mkdir -p "$SCRIPTS_DIR"

# Backup existing handoff script if present
if [ -f "$SCRIPTS_DIR/handoff-prompt.sh" ]; then
    echo -e "${GRAY}→${RESET} Backing up existing handoff-prompt.sh"
    cp "$SCRIPTS_DIR/handoff-prompt.sh" "$SCRIPTS_DIR/handoff-prompt.sh.bak"
fi

# Copy the handoff script
echo -e "${GRAY}→${RESET} Installing handoff-prompt.sh"
if ! cp "$SCRIPT_DIR/scripts/handoff-prompt.sh" "$SCRIPTS_DIR/"; then
    echo -e "${PINK}✗${RESET} Failed to copy script"
    exit 1
fi
chmod +x "$SCRIPTS_DIR/handoff-prompt.sh"
echo -e "${GREEN}✓${RESET} Script installed"

# Check if statusline needs patching
if [ -f "$STATUSLINE" ]; then
    if grep -q "handoff-prompt.sh" "$STATUSLINE"; then
        echo -e "${GREEN}✓${RESET} Statusline already patched"
    else
        echo -e "${GRAY}→${RESET} Backing up statusline"
        cp "$STATUSLINE" "$STATUSLINE.bak"

        echo -e "${GRAY}→${RESET} Patching statusline for 60% context trigger"
        # Add the handoff trigger after the 60% color setting
        sed -i "/ctx_color='\\\\033\[31m'/a\\
\\
        # Auto-trigger handoff at 60% (only once per session, with snooze support)\\
        session_id=\$(echo \"\$input\" | grep -o '\"session_id\":\"[^\"]*\"' | sed 's/.*:\"//;s/\"//')\\
        transcript=\$(echo \"\$input\" | grep -o '\"transcript_path\":\"[^\"]*\"' | sed 's/.*:\"//;s/\"//')\\
        flag_file=\"/tmp/handoff-triggered-\${session_id}\"\\
        snooze_file=\"/tmp/handoff-snooze-\${session_id}\"\\
\\
        should_trigger=false\\
        if [ -n \"\$session_id\" ]; then\\
            if [ -f \"\$snooze_file\" ]; then\\
                snooze_until=\$(cat \"\$snooze_file\")\\
                now=\$(date +%s)\\
                if [ \"\$now\" -ge \"\$snooze_until\" ]; then\\
                    rm -f \"\$snooze_file\"\\
                    should_trigger=true\\
                fi\\
            elif [ ! -f \"\$flag_file\" ]; then\\
                should_trigger=true\\
            fi\\
        fi\\
\\
        if [ \"\$should_trigger\" = true ]; then\\
            touch \"\$flag_file\"\\
            ~/.claude/scripts/handoff-prompt.sh \"\$transcript\" \"\$session_id\" \&\\
        fi" "$STATUSLINE"

        echo -e "${GREEN}✓${RESET} Statusline patched"
    fi
else
    echo -e "${PINK}⚠${RESET} No statusline found at $STATUSLINE"
    echo -e "${GRAY}  You'll need to manually add the trigger to your statusline${RESET}"
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Installation complete!${RESET}"
echo ""
echo -e "${CYAN}The handoff dialog will appear when context reaches 60%.${RESET}"
echo -e "${GRAY}To test manually: ${RESET}~/.claude/scripts/handoff-prompt.sh"
echo ""
echo -e "${ORANGE}⚡ Happy coding! ⚡${RESET}"
