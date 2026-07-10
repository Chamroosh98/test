#!/bin/sh


show_system_info()
{

echo
echo "System Information"
echo "------------------"


ARCH="$(uname -m)"

echo "Architecture : $ARCH"


if [ -f /etc/openwrt_release ]; then

    . /etc/openwrt_release

    echo "OpenWrt      : ${DISTRIB_RELEASE:-Unknown}"

fi


echo


if command -v free >/dev/null 2>&1; then

    FREE_RAM="$(free | awk '/Mem:/ {print $4}')"
    TOTAL_RAM="$(free | awk '/Mem:/ {print $2}')"

    echo "Memory"
    echo "  Total : ${TOTAL_RAM:-0} KB"
    echo "  Free  : ${FREE_RAM:-0} KB"

fi


echo


df -h / | awk '
NR==2 {
    print "Storage"
    print "  Total : "$2
    print "  Used  : "$3
    print "  Free  : "$4
}
'


echo

}