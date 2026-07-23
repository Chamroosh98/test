#!/bin/sh

show_banner()
{
    echo

    L1="    ____              ____"
    L2="   |  _ \  __ _ _   _|  _ \  __ _ ___ ___"
    L3="   | |_| | (_| | |_| |  __/ (_| \__ \__ \\"
    L4="   |____/ \__,_|\__, |_|   \__,_|___/___/"
    L5="                |___/"

    printf " ${CYAN}%-43s${RESET}  ${GRAY}│${RESET}  ${BOLD}DayPass Package Deployer${RESET} (${YELLOW}%s${RESET})\n" \
        "$L1" "${VERSION:-v2.1.0}"

    printf " ${CYAN}%-43s${RESET}  ${GRAY}│${RESET}  ${GRAY}An OpenWrt Deployment Engine${RESET}\n" \
        "$L2"

    printf " ${CYAN}%-43s${RESET}  ${GRAY}│${RESET}  ${GRAY}🐱 github.com/Chamroosh98${RESET}\n" \
        "$L3"

    printf " ${CYAN}%-43s${RESET}  ${GRAY}│${RESET}\n" \
        "$L4"

    printf " ${CYAN}%-43s${RESET}  ${GRAY}│${RESET}\n" \
        "$L5"

    printf "${GRAY} ────────────────────────────────── 🕊️  Remembering of the IRAN Massacre on Jan 8-9, 2026 ──────────────────────────────────────── ${RESET}\n"
    # printf "   ${RED}🕊️  Remembering of the IRAN massacre (Jan 8-9, 2026)${RESET}\n"
    # printf "${GRAY} ────────────────────────────────────────────────────────────────────────── ${RESET}\n"
    
    echo
}