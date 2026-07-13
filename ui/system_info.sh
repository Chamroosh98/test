#!/bin/sh

detect_arch()
{

    case "$(uname -m)" in

    armv7l)

        ARCH="arm_cortex-a7_neon-vfpv4"

        ;;


    aarch64)

        ARCH="aarch64_generic"

        ;;


    x86_64)

        ARCH="x86_64"

        ;;


    *)

        ARCH="$(uname -m)"

        ;;

    esac


    export ARCH

}

show_system_info()
{

    echo
    echo "  System Information"
    echo "---------------------------------------------------------------"

    detect_arch

    echo "  🩻 Architecture : $ARCH"


    if [ -f /etc/openwrt_release ]; then

        . /etc/openwrt_release

        echo "  💡 OpenWrt version      : ${DISTRIB_RELEASE:-Unknown}"

    fi


    echo


    if command -v free >/dev/null 2>&1; then

        FREE_RAM_KB="$(free | awk '/Mem:/ {print $4}')"
        TOTAL_RAM_KB="$(free | awk '/Mem:/ {print $2}')"

        FREE_RAM_MB=$((FREE_RAM_KB / 1024))
        TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))

        echo "  🧠 Memory"
        echo "          Total : ${TOTAL_RAM_MB:-0} MB"
        echo "          Free  : ${FREE_RAM_MB:-0} MB"

    fi

    echo


    df -m / | awk '
        NR==2 {
            print "  💾 Storage"
            print "          Total : "$2" MB"
            print "          Used  : "$3" MB"
            print "          Free  : "$4" MB"
        }
        '

    echo

}