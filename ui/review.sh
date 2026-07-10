#!/bin/sh


review_install()
{

echo

echo "Selected Profile"
echo "----------------"

echo "$SELECTED_PROFILE"


echo

echo "Selected Engine"
echo "---------------"

echo "${SELECTED_ENGINE:-auto}"


echo

echo "Language"
echo "--------"

echo "${SELECTED_LANGUAGE:-none}"


echo

echo "Geo Database"
echo "------------"

echo "${SELECTED_GEO:-none}"


echo

echo "Selected Packages"
echo "-----------------"


for pkg in $SELECTED_PACKAGES
do

echo "[+] $pkg"

done


echo

printf "Continue? [y/N]: "
read confirm


case "$confirm" in

y|Y)
    return 0
    ;;

*)

    exit 0

    ;;

esac

}