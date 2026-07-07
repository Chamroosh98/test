#!/bin/sh

initialize_installer() {

    detect_package_manager

    pkg_update

    TMP_DIR="/tmp/daypass"

    mkdir -p "$TMP_DIR"

    MANIFEST_FILE="$TMP_DIR/manifest.json"

    curl -fsSL \
        "$REPO_URL/manifest.json" \
        -o "$MANIFEST_FILE"

    ARCH="$(uname -m)"

    case "$ARCH" in

        x86_64)
            ARCH="x86_64"
            ;;

        armv7l)
            ARCH="arm_cortex-a7_neon-vfpv4"
            ;;

        aarch64)
            ARCH="aarch64_generic"
            ;;

    esac
}