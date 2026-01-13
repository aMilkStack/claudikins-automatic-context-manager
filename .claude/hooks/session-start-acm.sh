#!/bin/bash
# CC-ACM SessionStart Hook
# Detects if a handoff is available and prompts Claude to use it

# Read hook input from stdin
INPUT=$(cat)

# Extract session info
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | sed 's/.*:"//' | sed 's/"//')
SOURCE=$(echo "$INPUT" | grep -o '"source":"[^"]*"' | sed 's/.*:"//' | sed 's/"//')

# Only check for handoff on new sessions (not resume/clear/compact)
if [ "$SOURCE" != "startup" ]; then
    exit 0
fi

# Check if handoff skill exists and has content
HANDOFF_SKILL="$HOME/.claude/skills/acm-handoff/SKILL.md"

if [ ! -f "$HANDOFF_SKILL" ]; then
    # Skill doesn't exist, no handoff available
    exit 0
fi

# Check if skill contains actual handoff (not placeholder)
if grep -q "No Active Handoff" "$HANDOFF_SKILL"; then
    # Placeholder content, no real handoff
    exit 0
fi

# Handoff exists! Tell Claude to use it
CONTEXT="A context handoff from your previous session is available. Use the /acm:handoff skill to load the summary and continue where you left off."

# Return as JSON with additionalContext
python3 -c "import json; print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': '''$CONTEXT'''
    }
}))"

exit 0
