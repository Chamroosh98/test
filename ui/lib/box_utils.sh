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

box_subheader()
{
    # $1 = آیکون + عنوان بخش داخلی (بدون بستن/بازکردن باکس بیرونی)
    TITLE="$1"
    printf "${CYAN}├─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$BOX_DASHES"
}

box_footer()
{
    printf "${CYAN}╰%s${RESET}\n" "$BOX_DASHES"
}

# --- progress bar رنگی بر اساس درصد ---
draw_bar()
{
    # $1=percent  $2=bar_width(پیش‌فرض 20)  $3=mode ("usage" پیش‌فرض | "score")
    # usage : درصد بالا = بد (قرمز)   -> برای رم/استوریج
    # score : درصد بالا = خوب (سبز)   -> برای نتیجه‌ی تست/چک‌لیست
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
    while [ "$i" -lt "$FILLED" ]; do BAR="${BAR}█"; i=$((i+1)); done
    while [ "$i" -lt "$BW" ]; do BAR="${BAR}░"; i=$((i+1)); done

    printf "${COLOR}%s${RESET}" "$BAR"
}

# --- لاگ هشدار ساده (استفاده مشترک توسط ماژول‌ها) ---
log_warn()
{
    printf "${YELLOW}⚠️  %s${RESET}\n" "$1" >&2
}

# --- گرفتن فریم اسپینر بر اساس اندیس (بدون نیاز به آرایه‌ی bash) ---
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
            printf "%s" "$F"
            return
        fi
        I=$((I + 1))
    done
}