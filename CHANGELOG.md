# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2-beta] - 2026-01-20

### Fixed

- Skill descriptions CSO-optimized (now start with "Use when...")
- Standardized plugin.json metadata format

---

## [1.1.1-beta] - 2026-01-19

### Fixed

- Transcript discovery now scoped to current project only (was incorrectly finding transcripts from other projects)

---

## [1.1.0] - 2026-01-18

### Added

- Native `UserPromptSubmit` hook for handoff triggering (replaces hookify)
- Structured state capture (`handoff-state.json`) with todos, modified files, and git status
- `capture-state.sh` script for extracting session context from transcripts
- Human-readable `handoff.md` generated from structured state

### Changed

- Statusline now creates flag file instead of hookify injection
- `run-handoff.sh` uses structured state capture instead of `claude -p` prose summary
- `SessionStart` hook loads structured state for precise context restoration
- `acm-handoff` skill updated to read and present structured state

### Removed

- Hookify dependency - now uses native Claude Code hooks
- `inject-handoff-hook.sh` script
- `handoff-request-template.md` template

### Known Issues

- `session-start.sh` Python triple-quote interpolation may fail if context contains `'''` (edge case)

## [1.0.0] - 2026-01-13

### Added

- Initial release
- Statusline context percentage display
- Hookify-based handoff triggering at 60% threshold
- `AskUserQuestion` prompt with Yes/Snooze/Dismiss options
- Prose summary generation via `claude -p`
- Cross-platform terminal tab opening
- `SessionStart` hook for handoff detection
