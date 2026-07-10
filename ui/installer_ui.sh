#!/bin/sh


source "$DAYPASS_ROOT/installer/ui/state.sh"
source "$DAYPASS_ROOT/installer/ui/system_info.sh"
source "$DAYPASS_ROOT/installer/ui/menu.sh"
source "$DAYPASS_ROOT/installer/ui/package_menu.sh"
source "$DAYPASS_ROOT/installer/ui/language_menu.sh"
source "$DAYPASS_ROOT/installer/ui/geo_menu.sh"
source "$DAYPASS_ROOT/installer/ui/review.sh"
source "$DAYPASS_ROOT/installer/ui/progress.sh"

start_ui()
{

reset_state

main_menu

}