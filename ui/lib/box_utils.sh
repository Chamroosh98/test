#!/bin/sh

BOX_DASHES="─────────────────────────────────────────"

box_header()
{
    # $1 = آیکون + عنوان (مثلا "🖥️  System Information")
    TITLE="$1"
    printf "${CYAN}╭─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$BOX_DASHES"
}

box_line()
{
    # $1 = متن خط داخل باکس
    printf "${CYAN}│${RESET} %s\n" "$1"
}

box_empty()
{
    printf "${CYAN}│${RESET}\n"
}

box_footer()
{
    printf "${CYAN}╰%s${RESET}\n" "$BOX_DASHES"
}

# --- progress bar رنگی بر اساس درصد ---
draw_bar()
{
    # $1=percent  $2=bar_width(پیش‌فرض 20)  -> مستقیم چاپ می‌کنه، echo نداره
    PCT="$1"
    BW="${2:-20}"
    FILLED=$(( PCT * BW / 100 ))
    [ "$FILLED" -gt "$BW" ] && FILLED="$BW"

    if [ "$PCT" -ge 85 ]; then COLOR="$RED"
    elif [ "$PCT" -ge 60 ]; then COLOR="$YELLOW"
    else COLOR="$GREEN"
    fi

    BAR=""
    i=0
    while [ "$i" -lt "$FILLED" ]; do BAR="${BAR}█"; i=$((i+1)); done
    while [ "$i" -lt "$BW" ]; do BAR="${BAR}░"; i=$((i+1)); done

    printf "${COLOR}%s${RESET}" "$BAR"
}

# --- لاگ هشدار ساده (استفاده مشترک توسط ماژول‌ها) ---
log_warn()
{
    printf "${YELLOW}⚠️  %s${RESET}\n" "$1" >&2
}