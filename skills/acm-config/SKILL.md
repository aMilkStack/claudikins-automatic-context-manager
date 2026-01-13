---
name: acm-config
description: Interactively configures CC-ACM (Claude Code Automatic Context Manager) settings by asking the user questions about trigger threshold, snooze duration, summary length, and other preferences. Use when the user wants to customize CC-ACM behavior or runs '/acm:config'.
---

# CC-ACM Interactive Configuration

You are helping the user configure CC-ACM (Claude Code Automatic Context Manager). This skill guides you through an interactive configuration process where you ask the user questions and save their preferences to `~/.claude/cc-acm.conf`.

## Configuration Flow

Follow this conversational flow to configure CC-ACM:

### 1. Welcome & Current Settings

First, check if a config file exists and show current settings:

```bash
# Check for existing config
if [ -f ~/.claude/cc-acm.conf ]; then
    echo "Current CC-ACM Configuration:"
    cat ~/.claude/cc-acm.conf
else
    echo "No configuration found. Let's set up CC-ACM!"
fi
```

### 2. Ask Configuration Questions

Ask the user about each setting in a friendly, conversational way:

**Context Trigger Threshold:**
- Question: "At what context percentage should the handoff dialog appear?"
- Default: 60
- Valid range: 50-90
- Explain: "This controls when CC-ACM alerts you. Lower = more frequent alerts, higher = fewer alerts but less context headroom."

**Snooze Duration:**
- Question: "How long should the snooze duration be (in minutes)?"
- Default: 5
- Valid range: 1-60
- Explain: "When you click 'IN 5 MIN', how long should CC-ACM wait before asking again?"

**Summary Token Length:**
- Question: "How detailed should handoff summaries be (in tokens)?"
- Default: 500
- Valid range: 200-2000
- Explain: "Larger = more detailed summaries but takes longer to generate. 500 is usually perfect."

**Dialog Style:**
- Question: "Which dialog style do you prefer?"
- Options: "vibrant" (colorful, current default) or "minimal" (subtle colors)
- Default: vibrant
- Explain: "Vibrant uses bright orange/pink colors. Minimal uses muted tones."

### 3. Validate Input

For each answer:
- Ensure values are within valid ranges
- If invalid, explain why and ask again
- Provide examples of good values

### 4. Save Configuration

After all questions are answered, create the config file:

```bash
cat > ~/.claude/cc-acm.conf << EOF
# CC-ACM Configuration
# Generated on $(date)

# Context trigger threshold (50-90)
THRESHOLD=${threshold_value}

# Snooze duration in seconds
SNOOZE_DURATION=$((snooze_minutes * 60))

# Summary token length (200-2000)
SUMMARY_TOKENS=${summary_tokens}

# Dialog style (vibrant|minimal)
DIALOG_STYLE="${dialog_style}"
EOF
```

### 5. Apply Changes

After saving, offer to reload the configuration:

```bash
# Source the new config
source ~/.claude/cc-acm.conf
echo "Configuration saved to ~/.claude/cc-acm.conf"
echo ""
echo "Note: Changes will take effect in new sessions or after running:"
echo "  source ~/.claude/cc-acm.conf"
```

### 6. Show Summary

Display a friendly summary of what was configured:

```
╔═══════════════════════════════════════╗
║     CC-ACM Configuration Saved!       ║
╚═══════════════════════════════════════╝

✓ Trigger threshold: 60%
✓ Snooze duration: 5 minutes
✓ Summary length: 500 tokens
✓ Dialog style: vibrant

Your changes will take effect in new sessions.
Want to test it? Run: ~/.claude/scripts/handoff-prompt.sh
```

## Tone & Style

- Be conversational and friendly
- Explain technical terms in simple language
- Show enthusiasm about customization
- Use the CC-ACM branding colors (orange, pink, cyan) in output
- No emoji (matches CC-ACM's clean aesthetic)

## Example Interaction

```
USER: /acm:config

ASSISTANT: Let's configure CC-ACM! I'll ask you a few questions about your preferences.

Current settings not found. Let's set up fresh!

First question: At what context percentage should the handoff dialog appear?

The default is 60%, which means you'll get alerted when your session is 60% full.
This gives you plenty of headroom. You can set it anywhere from 50% to 90%.

What would you like? (Press enter for 60%)
```

## Additional Commands

If the user wants to:
- **View current config**: Show the contents of `~/.claude/cc-acm.conf`
- **Reset to defaults**: Delete the config file and recreate with defaults
- **Edit manually**: Open the config file in their editor

## Error Handling

- If config file cannot be written, check permissions on `~/.claude/`
- If values are out of range, explain valid ranges and ask again
- If user cancels (Ctrl+C), save partial configuration if any values were set

## Integration Notes

The config file will be sourced by:
- `install.sh` during installation (if exists)
- `handoff-prompt.sh` at runtime
- `statusline-command.sh` for threshold value

Format is simple bash variables that can be sourced directly.