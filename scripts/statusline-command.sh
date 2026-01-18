#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Claudikins Automatic Context Manager retro Statusline
# Colors from the pixel art palette

# True color (24-bit) - exact palette match
DARK_BG='\033[38;2;46;44;59m'       # #2e2c3b
DARK_GRAY='\033[38;2;62;65;95m'     # #3e415f
MED_GRAY='\033[38;2;85;96;125m'     # #55607d
LIGHT_GRAY='\033[38;2;116;125;136m' # #747d88
MINT='\033[38;2;65;222;149m'        # #41de95 - normal/good
TEAL='\033[38;2;42;164;170m'        # #2aa4aa - info
BLUE='\033[38;2;59;119;166m'        # #3b77a6
DARK_GREEN='\033[38;2;36;147;55m'   # #249337
BRIGHT_GREEN='\033[38;2;86;190;68m' # #56be44
LIME='\033[38;2;198;222;120m'       # #c6de78
GOLD='\033[38;2;243;194;32m'        # #f3c220 - warning
ORANGE='\033[38;2;196;101;28m'      # #c4651c - accent
RUST='\033[38;2;181;65;49m'         # #b54131 - critical
PURPLE='\033[38;2;97;64;122m'       # #61407a
MAGENTA='\033[38;2;143;61;167m'     # #8f3da7
PINK='\033[38;2;234;97;157m'        # #ea619d
ICE='\033[38;2;193;229;234m'        # #c1e5ea

BOLD='\033[1m'
RESET='\033[0m'

# Extract values using grep/sed (no jq dependency)
extract() {
    echo "$input" | grep -o "\"$1\":[^,}]*" | sed 's/.*:\s*//' | tr -d '"' | head -1
}

# Extract basic information
user=$(whoami)
host=$(hostname -s)
cwd=$(extract "current_dir")
[ -z "$cwd" ] && cwd=$(pwd)

# Shorten the path if too long
if [ ${#cwd} -gt 30 ]; then
    cwd="...${cwd: -27}"
fi

model=$(extract "display_name")
[ -z "$model" ] && model="claude"

# Check if current_usage has actual token data (not null and has input_tokens)
has_tokens=$(echo "$input" | grep -o '"current_usage":\s*{[^}]*"input_tokens"' || echo "")

if [ -n "$has_tokens" ]; then
    # API auth: Calculate current context percentage
    context_size=$(extract "context_window_size")
    context_size=${context_size:-200000}

    # Extract current_usage tokens
    current_input=$(echo "$input" | grep -o '"current_usage":\s*{[^}]*}' | grep -o '"input_tokens":[0-9]*' | sed 's/.*://')
    cache_creation=$(echo "$input" | grep -o '"current_usage":\s*{[^}]*}' | grep -o '"cache_creation_input_tokens":[0-9]*' | sed 's/.*://')
    cache_read=$(echo "$input" | grep -o '"current_usage":\s*{[^}]*}' | grep -o '"cache_read_input_tokens":[0-9]*' | sed 's/.*://')

    # Default to 0 if not found
    current_input=${current_input:-0}
    cache_creation=${cache_creation:-0}
    cache_read=${cache_read:-0}

    # Calculate current context
    current_context=$((current_input + cache_creation + cache_read))

    if [ "$context_size" -gt 0 ] && [ "$current_context" -gt 0 ]; then
        pct=$((current_context * 100 / context_size))
    else
        pct=0
    fi

    # Build progress bar (10 chars)
    filled=$((pct / 10))
    empty=$((10 - filled))
    bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    # Colour code based on percentage thresholds
    if [ "$pct" -ge 60 ]; then
        ctx_color="$RUST"
        bar_empty="$MED_GRAY"
        glow="$BOLD"

        # --- Claudikins Automatic Context Manager START ---
        session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | sed 's/.*:"//;s/"//')
        transcript=$(echo "$input" | grep -o '"transcript_path":"[^"]*"' | sed 's/.*:"//;s/"//')
        flag_file="/tmp/handoff-triggered-${session_id}"
        snooze_file="/tmp/handoff-snooze-${session_id}"

        should_trigger=false
        if [ -n "$session_id" ]; then
            if [ -f "$snooze_file" ]; then
                snooze_until=$(cat "$snooze_file")
                now=$(date +%s)
                if [ "$now" -ge "$snooze_until" ]; then
                    rm -f "$snooze_file"
                    should_trigger=true
                fi
            elif [ ! -f "$flag_file" ]; then
                should_trigger=true
            fi
        fi

        if [ "$should_trigger" = true ]; then
            # Create flag file with percentage (native hook reads this)
            echo "$pct" > "/tmp/acm-threshold-${session_id}"
        fi
        # --- Claudikins Automatic Context Manager END ---
    elif [ "$pct" -ge 40 ]; then
        ctx_color="$GOLD"
        bar_empty="$MED_GRAY"
        glow=""
    else
        ctx_color="$MINT"
        bar_empty="$DARK_GRAY"
        glow=""
    fi

    # Build colored progress bar
    bar_filled=""
    bar_unfilled=""
    for ((i=0; i<filled; i++)); do bar_filled+="█"; done
    for ((i=0; i<empty; i++)); do bar_unfilled+="░"; done

    context_info="${glow}${ctx_color}${bar_filled}${RESET}${bar_empty}${bar_unfilled}${RESET} ${ctx_color}${pct}%${RESET}"
else
    # Claude auth (Pro/Max): Show session indicator instead
    transcript=$(extract "transcript_path")
    if [ -n "$transcript" ] && [ -f "$transcript" ]; then
        msg_count=$(grep -c '"role":' "$transcript" 2>/dev/null || echo "0")
    else
        msg_count="0"
    fi
    context_info="${TEAL}◆${msg_count}${RESET}"
fi

# Format output - retro style with pixel art palette
# ░▒▓ user@host ▓ dir ▓ model ▓ ████░░░░ 45% ▓▒░
printf "${DARK_GRAY}░▒${RESET}${ORANGE}▓${RESET} ${PINK}%s${RESET} ${ORANGE}▓${RESET} ${TEAL}%s${RESET} ${ORANGE}▓${RESET} ${MINT}%s${RESET} ${ORANGE}▓${RESET} %b ${ORANGE}▓${RESET}${DARK_GRAY}▒░${RESET}" \
    "$user" "$cwd" "$model" "$context_info"
