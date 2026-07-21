#!/bin/sh

# ساخت کاراکتر واقعی Escape برای پشتیبانی کامل در BusyBox ash / POSIX shell
ESC="$(printf '\033')"

RESET="${ESC}[0m"
BOLD="${ESC}[1m"
DIM="${ESC}[2m"

BLACK="${ESC}[30m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
ORANGE="${ESC}[33m"
YELLOW="${ESC}[1;33m"
BLUE="${ESC}[34m"
PURPLE="${ESC}[35m"
PINK="${ESC}[1;35m"
CYAN="${ESC}[36m"
WHITE="${ESC}[37m"
GRAY="${ESC}[90m"

export RESET BOLD DIM CYAN GREEN YELLOW RED BLUE BLACK WHITE GRAY PURPLE ORANGE PINK

# #!/bin/sh

# RESET="\033[0m"
# BOLD="\033[1m"
# DIM="\033[2m"

# BLACK="\033[30m"
# RED="\033[31m"
# GREEN="\033[32m"
# ORANGE="\033[33m"
# YELLOW="\033[33m"
# BLUE="\033[34m"
# PURPLE="\033[35m"
# PINK="\033[35m"
# CYAN="\033[36m"
# WHITE="\033[37m"
# GRAY="\033[90m"

# export RESET BOLD DIM CYAN GREEN YELLOW RED BLUE BLACK WHITE GRAY PURPLE ORANGE PINK
