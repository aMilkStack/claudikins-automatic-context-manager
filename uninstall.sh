#!/bin/bash
# CC-ACM Uninstaller

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
STATUSLINE="$CLAUDE_DIR/statusline-command.sh"
CONFIG_FILE="$CLAUDE_DIR/cc-acm.conf"

# Colors for output
ORANGE='\033[38;5;208m'
PINK='\033[38;5;205m'
GREEN='\033[38;5;120m'
CYAN='\033[38;5;51m'
GRAY='\033[38;5;240m'
RESET='\033[0m'
BOLD='\033[1m'

# ASCII art banner
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
   ║           Uninstaller                            ║
   ╚═══════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"
echo -e "${CYAN}    Removing CC-ACM from Claude Code CLI${RESET}"
echo ""

# Confirm uninstall
echo -e "${PINK}This will remove:${RESET}"
echo -e "${GRAY}  • Handoff script from ~/.claude/scripts/${RESET}"
echo -e "${GRAY}  • SessionStart hook and handoff skill${RESET}"
echo -e "${GRAY}  • Warp launch configuration${RESET}"
echo -e "${GRAY}  • Statusline patches${RESET}"
echo -e "${GRAY}  • Configuration file${RESET}"
echo -e "${GRAY}  • Temporary flag files${RESET}"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GRAY}Uninstall cancelled.${RESET}"
    exit 0
fi

echo ""

# Remove handoff script
if [ -f "$SCRIPTS_DIR/handoff-prompt.sh" ]; then
    echo -e "${GRAY}→${RESET} Removing handoff-prompt.sh"
    rm -f "$SCRIPTS_DIR/handoff-prompt.sh"
    echo -e "${GREEN}✓${RESET} Script removed"
else
    echo -e "${GRAY}→${RESET} Handoff script not found (already removed?)"
fi

# Remove SessionStart hook
if [ -f "$CLAUDE_DIR/hooks/session-start-acm.sh" ]; then
    echo -e "${GRAY}→${RESET} Removing SessionStart hook"
    rm -f "$CLAUDE_DIR/hooks/session-start-acm.sh"
    echo -e "${GREEN}✓${RESET} Hook removed"
else
    echo -e "${GRAY}→${RESET} Hook not found"
fi

# Remove handoff skill
if [ -d "$CLAUDE_DIR/skills/acm-handoff" ]; then
    echo -e "${GRAY}→${RESET} Removing handoff skill"
    rm -rf "$CLAUDE_DIR/skills/acm-handoff"
    echo -e "${GREEN}✓${RESET} Skill removed"
else
    echo -e "${GRAY}→${RESET} Skill not found"
fi

# Remove Warp launch configuration
if [ -f "$HOME/.warp/launch_configurations/cc-acm-handoff.yaml" ]; then
    echo -e "${GRAY}→${RESET} Removing Warp launch configuration"
    rm -f "$HOME/.warp/launch_configurations/cc-acm-handoff.yaml"
    echo -e "${GREEN}✓${RESET} Warp config removed"
else
    echo -e "${GRAY}→${RESET} Warp config not found"
fi

# Note about hooks.json
if [ -f "$CLAUDE_DIR/hooks.json" ] && grep -q "session-start-acm.sh" "$CLAUDE_DIR/hooks.json"; then
    echo -e "${PINK}⚠${RESET} Please manually remove session-start-acm.sh from ~/.claude/hooks.json"
fi

# Restore statusline from backup
if [ -f "$STATUSLINE.bak" ]; then
    echo -e "${GRAY}→${RESET} Restoring statusline from backup"
    mv "$STATUSLINE.bak" "$STATUSLINE"
    echo -e "${GREEN}✓${RESET} Statusline restored"
elif [ -f "$STATUSLINE" ]; then
    # No backup, try to remove the patch manually
    if grep -q "handoff-prompt.sh" "$STATUSLINE"; then
        echo -e "${GRAY}→${RESET} Removing statusline patch"
        # Create backup before modifying
        cp "$STATUSLINE" "$STATUSLINE.bak.uninstall"
        # Remove the injected lines (everything from the comment to the script call)
        sed -i '/# --- CC-ACM START ---/,/# --- CC-ACM END ---/d' "$STATUSLINE"
        echo -e "${GREEN}✓${RESET} Statusline patch removed"
        echo -e "${GRAY}  Backup saved to: $STATUSLINE.bak.uninstall${RESET}"
    else
        echo -e "${GRAY}→${RESET} Statusline not patched (already clean?)"
    fi
else
    echo -e "${GRAY}→${RESET} Statusline not found"
fi

# Remove config file
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GRAY}→${RESET} Removing configuration file"
    rm -f "$CONFIG_FILE"
    echo -e "${GREEN}✓${RESET} Config removed"
else
    echo -e "${GRAY}→${RESET} Config file not found"
fi

# Clean up temp files
echo -e "${GRAY}→${RESET} Cleaning up temporary files"
rm -f /tmp/handoff-triggered-* 2>/dev/null || true
rm -f /tmp/handoff-snooze-* 2>/dev/null || true
rm -f /tmp/claude-handoff.txt 2>/dev/null || true
echo -e "${GREEN}✓${RESET} Temp files cleaned"

echo ""
echo -e "${GREEN}${BOLD}✓ CC-ACM uninstalled successfully!${RESET}"
echo ""
echo -e "${GRAY}Thanks for using CC-ACM. To reinstall, run: ./install.sh${RESET}"
echo ""
