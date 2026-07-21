#!/bin/sh

# خط افقی ثابت برای بالاو پایین باکس
BOX_LINE="──────────────────────────────────────────────────"

box_header()
{
    TITLE="$1"
    printf "╭─  %s%s%s ──────────\n" "$BOLD" "$TITLE" "$RESET$CYAN"
}

box_line()
{
    printf "│ %s\n" "$1"
}

box_empty()
{
    printf "│\n"
}

box_subheader()
{
    TITLE="$1"
    printf "├─  %s%s%s ──────────\n" "$BOLD" "$TITLE" "$RESET$CYAN"
}

box_footer()
{
    printf "╰%s\n" "$BOX_LINE"
}

draw_bar()
{
    PCT="$1"
    BW="${2:-20}"
    MODE="${3:-usage}"
    
    # اطمینان از عدد بودن و محدود بودن درصد
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

    printf "%s%s%s" "$COLOR" "$BAR" "$RESET"
}

log_info()    { printf "%sℹ️  %s%s\n" "$CYAN" "$1" "$RESET"; }
log_success() { printf "%s✅  %s%s\n" "$GREEN" "$1" "$RESET"; }
log_warn()    { printf "%s⚠️  %s%s\n" "$YELLOW" "$1" "$RESET" >&2; }
log_error()   { printf "%s❌  %s%s\n" "$RED" "$1" "$RESET" >&2; }