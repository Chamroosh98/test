#!/bin/sh

BOX_DASHES="   ─────────────────────────────────────────"

box_header()
{
    TITLE="$1"
    printf "   ${CYAN}╭─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$BOX_DASHES"
}

box_line()
{
    printf "   ${CYAN}│${RESET} %s\n" "$1"
}

box_empty()
{
    printf "   ${CYAN}│${RESET}\n"
}

box_subheader()
{
    TITLE="$1"
    printf "   ${CYAN}├─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$BOX_DASHES"
}

box_footer()
{
    printf "   ${CYAN}╰%s${RESET}\n" "$BOX_DASHES"
}

draw_bar()
{
    PCT="$1"
    BW="${2:-20}"
    MODE="${3:-usage}"
    FILLED=$(( PCT * BW / 100 ))
    [ "$FILLED" -gt "$BW" ] && FILLED="$BW"

    if [ "$MODE" = "score" ]; then
        if [ "$PCT" -ge 80 ]; then COLOR="$GREEN"
        elif [ "$PCT" -ge 50 ]; then COLOR="$YELLOW"
        else COLOR="$RED"
        fi
    else
        if [ "$PCT" -ge 85 ]; then COLOR="$RED"
        elif [ "$PCT" -ge 60 ]; then COLOR="$YELLOW"
        else COLOR="$GREEN"
        fi
    fi

    BAR=""
    i=0
    while [ "$i" -lt "$FILLED" ]; 
        do 
            BAR="${BAR}█"; i=$((i+1)); 
        done
    while [ "$i" -lt "$BW" ]; 
        do 
            BAR="${BAR}░"; i=$((i+1)); 
        done

    printf "   ${COLOR}%s${RESET}" "$BAR"
}

log_warn()
{
    printf "   ${YELLOW}⚠️  %s${RESET}\n" "$1" >&2
}

SPINNER_FRAMES="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"

spinner_frame()
{
    IDX="$1"
    set -- $SPINNER_FRAMES
    COUNT=$#
    N=$(( IDX % COUNT + 1 ))
    I=1
    for F in "$@"; do
        if [ "$I" -eq "$N" ]; then
            printf "   %s" "$F"
            return
        fi
        I=$((I + 1))
    done
}