#!/bin/sh

# Assume VERSION="v2.1.0" is sourced from main config file

show_banner()
{
    # Use a specific, wider character for tree structure to keep alignment
    _t="${GRAY}│${RESET}"

    # Line 1: DAYPASS (with Version on Right)
    printf "${CYAN}%-22s${RESET} ${_t} ${BOLD}DayPass Package Deployer${RESET} ( ${YELLOW}%s${RESET} )\n" \
        "    ____              " "${VERSION:-v?.?.?}"

    # Line 2: DAYPASS (with Memorial on Right)
    printf "${CYAN}%-22s${RESET} ${_t} ${RED}🕊️  Remembering IRAN massacre (Jan 8-9)$RESET\n" \
        "   |  _ \  __ _ _   _"

    # Line 3: DAYPASS (with Github on Right)
    printf "${CYAN}%-22s${RESET} ${_t} ${GRAY}🐱 github.com/Chamroosh98${RESET}\n" \
        "   | | | |/ _\` | | |"

    # Line 4: DAYPASS
    printf "${CYAN}%-22s${RESET} ${_t}\n" \
        "   | |_| | (_| | |_| |"

    # Line 5: DAYPASS
    printf "${CYAN}%-22s${RESET} ${_t}\n" \
        "   |____/ \__,_|\__, |"

    # Line 6: DAYPASS
    printf "${CYAN}%-22s${RESET} ${_t}\n" \
        "                |___/"
    
    # Optional: A clean divider after the whole banner
    printf "${GRAY} ────────────────────────────────────────────────────────────────────────── ${RESET}\n"
}