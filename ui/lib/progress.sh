#!/bin/sh

# ==============================================================================
# Progress Bar & Real-time Step Logger Module
# ==============================================================================

show_progress()
{
    title="$1"
    current="$2"
    total="$3"
    bar_width="${4:-20}"

    [ "$total" -le 0 ] && return

    # Calculate Percentage
    percent=$((current * 100 / total))
    [ "$percent" -gt 100 ] && percent=100

    # Calculate Fill width
    filled=$((percent * bar_width / 100))

    # Dynamic Color based on progress
    if [ "$percent" -eq 100 ]; then
        COLOR="${GREEN}"
    elif [ "$percent" -ge 50 ]; then
        COLOR="${CYAN}"
    else
        COLOR="${YELLOW}"
    fi

    # Build Bar String
    bar=""
    i=0
    while [ "$i" -lt "$filled" ]; do
        bar="${bar}█"
        i=$((i + 1))
    done

    while [ "$i" -lt "$bar_width" ]; do
        bar="${bar}░"
        i=$((i + 1))
    done

    # Print Real-time progress on same line (\r)
    printf "\r 📦 %-20s [${COLOR}%s${RESET}] ${BOLD}%3d%%${RESET} (%s/%s)" \
            "$title" "$bar" "$percent" "$current" "$total"

    # Print newline when task is complete
    [ "$current" -ge "$total" ] && echo
}

log_step()
{
    status="$1"
    message="$2"

    case "$status" in
        ok)   printf "   ${GREEN}✔ [  OK  ]${RESET} %s\n" "$message" ;;
        fail) printf "   ${RED}✖ [ FAIL ]${RESET} %s\n" "$message" >&2 ;;
        warn) printf "   ${YELLOW}⚠️ [ WARN ]${RESET} %s\n" "$message" ;;
        *)    printf "   ${CYAN}ℹ [ INFO ]${RESET} %s\n" "$message" ;;
    esac
}