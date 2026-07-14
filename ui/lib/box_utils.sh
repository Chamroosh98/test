#!/bin/sh

BOX_DASHES="─────────────────────────────────────────"

# --- تابع تاخیر هوشمند برای سازگاری با BusyBox (حل مشکل sleep 0.1) ---
delay_0_1() {
    if command -v usleep >/dev/null 2>&1; then
        usleep 100000
    elif read -t 0.1 _ >/dev/null 2>&1; then
        :
    else
        sleep 1
    fi
}

box_header()
{
    TITLE="$1"
    printf "${CYAN}╭─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$BOX_DASHES"
}

box_line()
{
    printf "${CYAN}│${RESET} %s\n" "$1"
}

box_empty()
{
    printf "${CYAN}│${RESET}\n"
}

box_subheader()
{
    TITLE="$1"
    printf "${CYAN}├─ ${RESET}${BOLD}%s${RESET} ${CYAN}%s${RESET}\n" "$TITLE" "$BOX_DASHES"
}

box_footer()
{
    printf "${CYAN}╰%s${RESET}\n" "$BOX_DASHES"
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

    printf "${COLOR}%s${RESET}" "$BAR"
}

log_warn()
{
    printf "${YELLOW}⚠️  %s${RESET}\n" "$1" >&2
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
            printf "%s" "$F"
            return
        fi
        I=$((I + 1))
    done
}

# --- مثال برای نحوه استفاده صحیح از اسپینر بدون ارور ---
demo_spinner() {
    TARGET="openwrt.org"
    printf "  Ping  %s" "$TARGET"
    
    # اجرای پینگ در پس‌زمینه
    ping -c 3 "$TARGET" >/dev/null 2>&1 &
    PING_PID=$!
    
    i=0
    # تا زمانی که پینگ در حال اجراست، اسپینر می‌چرخد
    while kill -0 $PING_PID 2>/dev/null; do
        FRAME=$(spinner_frame "$i")
        # بازگشت به اول خط و چاپ فریم جدید اسپینر
        printf "\r%s Ping  %s" "$FRAME" "$TARGET"
        
        # استفاده از تابع هوشمند به جای sleep 0.1
        delay_0_1
        
        i=$((i + 1))
    done
    
    # دریافت وضعیت نهایی پینگ
    wait $PING_PID
    if [ $? -eq 0 ]; then
        printf "\r🟢 Ping  %s\n" "$TARGET"
    else
        printf "\r🔴 Ping  %s (Failed)\n" "$TARGET"
    fi
}

# اگر خواستی تستش کنی، کافیه خط زیر رو از کامنت در بیاری:
demo_spinner