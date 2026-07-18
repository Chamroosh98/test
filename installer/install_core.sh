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


    if [ ! -s "$MANIFEST_FILE" ]; then
        echo "❌ Failed to download manifest!"
        exit 1
    fi


    if [ -f /etc/openwrt_release ]; then

        ARCH=$(grep "DISTRIB_ARCH" /etc/openwrt_release | cut -d"'" -f2)

    else

        ARCH="$(uname -m)"

    fi


    if [ -z "$ARCH" ]; then
        echo "❌ Unable to detect architecture!"
        exit 1
    fi


    if ! jq -e \
        --arg arch "$ARCH" \
        '.architectures[] | select(.name == $arch)' \
        "$MANIFEST_FILE" >/dev/null
    then
        echo "❌ Architecture not supported : $ARCH"
        exit 1
    fi


    export ARCH
}