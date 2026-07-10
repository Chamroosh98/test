#!/bin/sh


language_menu()
{

echo

echo "Language"

echo "1) Persian"
echo "2) English"
echo "3) Chinese"
echo "4) Russian"

printf "Choice: "
read choice


case "$choice" in

1)

SELECTED_LANGUAGE="fa"

add_selected_package \
"luci-i18n-passwall2-fa"

;;

2)

SELECTED_LANGUAGE="en"

;;

3)

SELECTED_LANGUAGE="zh-cn"

add_selected_package \
"luci-i18n-passwall2-zh-cn"

;;

4)

SELECTED_LANGUAGE="ru"

add_selected_package \
"luci-i18n-passwall2-ru"

;;

*)

SELECTED_LANGUAGE="en"

;;

esac


export SELECTED_LANGUAGE

}