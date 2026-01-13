---
name: acm-handoff
description: Context handoff from a previous Claude Code session. Contains a summary of the previous conversation when context reached the configured threshold. Use this to understand what was being worked on and continue seamlessly.
---

# No Active Handoff

This skill will be populated automatically when CC-ACM performs a context handoff.

If you're seeing this, no handoff is currently active. The skill file gets written when:
1. Your session reaches the configured context threshold (default 60%)
2. You click "YES" in the handoff dialog
3. A new session is opened with the handoff summary

To trigger a manual handoff, you can run the handoff script directly:
```bash
~/.claude/scripts/handoff-prompt.sh
```

---

*CC-ACM (Claude Code Automatic Context Manager)*
