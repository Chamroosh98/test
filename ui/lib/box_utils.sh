#!/bin/sh

BOX_WIDTH=50

box_header()
{
    TITLE="$1"
    TITLE_LEN=$(printf "%s" "$TITLE" | wc -c)
    DASH_COUNT=$((BOX_WIDTH - TITLE_LEN - 4))
    [ "$DASH_COUNT" -lt 5 ] && DASH_COUNT=5

    DASHES=""
    i=0
    while [ "$i" -lt "$DASH_COUNT" ]; do
        DASHES="${DASHES}─"
        i=$((i+1))
    done

    printf "╭─ %s%s%s %s%s%s\n" "$BOLD" "$TITLE" "$RESET" "$CYAN" "$DASHES" "$RESET"
}

box_line()
{
    printf "%s│%s %s\n" "$CYAN" "$RESET" "$1"
}

box_empty()
{
    printf "%s│%s\n" "$CYAN" "$RESET"
}

box_subheader()
{
    TITLE="$1"
    TITLE_LEN=$(printf "%s" "$TITLE" | wc -c)
    DASH_COUNT=$((BOX_WIDTH - TITLE_LEN - 4))
    [ "$DASH_COUNT" -lt 5 ] && DASH_COUNT=5

    DASHES=""
    i=0
    while [ "$i" -lt "$DASH_COUNT" ]; do
        DASHES="${DASHES}─"
        i=$((i+1))
    done

    printf "%s├─ %s%s%s %s%s%s\n" "$CYAN" "$BOLD" "$TITLE" "$RESET" "$CYAN" "$DASHES" "$RESET"
}

box_footer()
{
    DASHES=""
    i=0
    while [ "$i" -lt "$BOX_WIDTH" ]; do
        DASHES="${DASHES}─"
        i=$((i+1))
    done

    printf "%s╰%s%s\n" "$CYAN" "$DASHES" "$RESET"
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

    printf "%s%s%s" "$COLOR" "$BAR" "$RESET"
}

log_info()    { printf "%sℹ️  %s%s\n" "$CYAN" "$1" "$RESET"; }
log_success() { printf "%s✅  %s%s\n" "$GREEN" "$1" "$RESET"; }
log_warn()    { printf "%s⚠️  %s%s\n" "$YELLOW" "$1" "$RESET" >&2; }
log_error()   { printf "%s❌  %s%s\n" "$RED" "$1" "$RESET" >&2; }