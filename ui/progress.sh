#!/bin/sh


show_progress()
{

title="$1"
current="$2"
total="$3"


[ "$total" -eq 0 ] && return


percent=$((current * 100 / total))


printf "\r%s [%s%%] (%s/%s)" \
"$title" \
"$percent" \
"$current" \
"$total"


[ "$current" -eq "$total" ] && echo

}



log_step()
{

status="$1"
message="$2"


case "$status" in

ok)

printf "[ OK ] %s\n" "$message"

;;

fail)

printf "[FAIL] %s\n" "$message"

;;

warn)

printf "[WARN] %s\n" "$message"

;;

*)

printf "[INFO] %s\n" "$message"

;;

esac

}