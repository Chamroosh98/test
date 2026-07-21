#!/bin/sh

BOX_DASHES="─────────────────────────────────────────"

box_header()
{
    TITLE="$1"
    
    CLEAN_TITLE=$(printf "%s" "$TITLE" | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\033\[[0-9;]*m//g')
    TITLE_LEN=$(printf "%s" "$CLEAN_TITLE" | wc -m 2>/dev/null || echo 15)
    
    DASH_COUNT=$((41 - TITLE_LEN - 3))
    [ "$DASH_COUNT" -lt 2 ] && DASH_COUNT=2

    DYNAMIC_DASHES=""
    i=0
    while [ "$i" -lt "$DASH_COUNT" ]; do
        DYNAMIC_DASHES="${DYNAMIC_DASHES}─"
        i=$((i+1))
    done

    printf "   ${CYAN}╭─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$DYNAMIC_DASHES"
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
    CLEAN_TITLE=$(printf "%s" "$TITLE" | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\033\[[0-9;]*m//g')
    TITLE_LEN=$(printf "%s" "$CLEAN_TITLE" | wc -m 2>/dev/null || echo 15)
    
    DASH_COUNT=$((41 - TITLE_LEN - 3))
    [ "$DASH_COUNT" -lt 2 ] && DASH_COUNT=2

    DYNAMIC_DASHES=""
    i=0
    while [ "$i" -lt "$DASH_COUNT" ]; do
        DYNAMIC_DASHES="${DYNAMIC_DASHES}─"
        i=$((i+1))
    done

    printf "   ${CYAN}├─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$DYNAMIC_DASHES"
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
    
    [ "$PCT" -gt 100 ] && PCT=100
    [ "$PCT" -lt 0 ] && PCT=0

    FILLED=$(( PCT * BW / 100 ))

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
    while [ "$i" -lt "$FILLED" ]; do 
        BAR="${BAR}█"
        i=$((i+1))
    done
    while [ "$i" -lt "$BW" ]; do 
        BAR="${BAR}░"
        i=$((i+1))
    done

    printf "   ${COLOR}%s${RESET}" "$BAR"
}

log_warn()
{
    printf "   ${YELLOW}⚠️  %s${RESET}\n" "$1" >&2
}

log_info()    { printf "   ${CYAN}ℹ️  %s${RESET}\n" "$1"; }
log_success() { printf "   ${GREEN}✅  %s${RESET}\n" "$1"; }
log_error()   { printf "   ${RED}❌  %s${RESET}\n" "$1" >&2; }

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