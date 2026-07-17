#!/bin/sh

initialize_installer()
{
    detect_package_manager
    pkg_update

    TMP_DIR="/tmp/daypass"

    mkdir -p "$TMP_DIR"

    MANIFEST_FILE="$TMP_DIR/manifest.json"


    curl -fsSL \
        "$REPO_URL/manifest.json" \
        -o "$MANIFEST_FILE"


    [ -s "$MANIFEST_FILE" ] || {
        echo "❌ Failed downloading manifest!"
        exit 1
    }


    if [ -f /etc/openwrt_release ]; then

        ARCH=$(grep "DISTRIB_ARCH" /etc/openwrt_release | cut -d"'" -f2)

    else

        ARCH="$(uname -m)"

    fi


    if [ -z "$ARCH" ]; then
        echo "❌ Critical : Unable to detect system architecture!"
        exit 1
    fi


    if ! jq -e \
        --arg arch "$ARCH" \
        '.architectures[] | select(.name==$arch)' \
        "$MANIFEST_FILE" >/dev/null
    then
        echo "❌ Unsupported architecture in DayPass repository : $ARCH"
        exit 1
    fi


    export ARCH
}