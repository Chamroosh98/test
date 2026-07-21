#!/bin/sh

BOX_WIDTH=50

box_header()
{
    TITLE="$1"

    TITLE_LEN=$(echo "$TITLE" | wc -c)
    DASH_COUNT=$((BOX_WIDTH - TITLE_LEN - 4))
    [ "$DASH_COUNT" -lt 5 ] && DASH_COUNT=5

    DASHES=""
    i=0
    while [ "$i" -lt "$DASH_COUNT" ]; do
        DASHES="${DASHES}─"
        i=$((i+1))
    done

    printf "  %b╭─ %b%s%b %b%s%b\n" "$CYAN" "$BOLD" "$TITLE" "$RESET$CYAN" "$DASHES" "$RESET"
}

box_line()
{
    printf "  %b│%b %b\n" "$CYAN" "$RESET" "$1"
}

box_empty()
{
    printf "  %b│%b\n" "$CYAN" "$RESET"
}

box_subheader()
{
    TITLE="$1"
    TITLE_LEN=$(echo "$TITLE" | wc -c)
    DASH_COUNT=$((BOX_WIDTH - TITLE_LEN - 4))
    [ "$DASH_COUNT" -lt 5 ] && DASH_COUNT=5

    DASHES=""
    i=0
    while [ "$i" -lt "$DASH_COUNT" ]; do
        DASHES="${DASHES}─"
        i=$((i+1))
    done

    printf "  %b├─ %b%s%b %b%s%b\n" "$CYAN" "$BOLD" "$TITLE" "$RESET$CYAN" "$DASHES" "$RESET"
}

box_footer()
{
    DASHES=""
    i=0
    while [ "$i" -lt "$BOX_WIDTH" ]; do
        DASHES="${DASHES}─"
        i=$((i+1))
    done

    printf "  %b╰%s%b\n" "$CYAN" "$DASHES" "$RESET"
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
    while [ "$i" -lt "$FILLED" ]; do 
        BAR="${BAR}█"
        i=$((i+1))
    done
    while [ "$i" -lt "$BW" ]; do 
        BAR="${BAR}░"
        i=$((i+1))
    done

    printf "  %b%s%b" "$COLOR" "$BAR" "$RESET"
}

log_info()    { printf "  %bℹ️  %s%b\n" "$CYAN" "$1" "$RESET"; }
log_success() { printf "  %b✅  %s%b\n" "$GREEN" "$1" "$RESET"; }
log_warn()    { printf "  %b⚠️  %s%b\n" "$YELLOW" "$1" "$RESET" >&2; }
log_error()   { printf "  %b❌  %s%b\n" "$RED" "$1" "$RESET" >&2; }