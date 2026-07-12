#!/bin/sh

INSTALL_LOG="/tmp/daypass/install.log"
INSTALLED_PACKAGES=""

SELECTED_PACKAGES=""

add_package() {

    [ -z "$1" ] && return

    case " $SELECTED_PACKAGES " in
        *" $1 "*) ;;
        *)
            SELECTED_PACKAGES="$SELECTED_PACKAGES $1"
            ;;
    esac
}


download_package() {

    package="$1"

    file=$(jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
        '
        .architectures[]
        | select(.name==$arch)
        | .packages[]
        | select(.package==$pkg)
        | .file
        ' \
        "$MANIFEST_FILE")


    sha256=$(jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
        '
        .architectures[]
        | select(.name==$arch)
        | .packages[]
        | select(.package==$pkg)
        | .sha256
        ' \
        "$MANIFEST_FILE")


    [ -z "$file" ] && return 1
    [ "$file" = "null" ] && return 1


    target="$TMP_DIR/$file"
    tmp="$target.part"


    mkdir -p "$(dirname "$target")"


    echo "Downloading $package ..."


    curl -fsSL \
        "$REPO_URL/$ARCH/$file" \
        -o "$tmp" || return 1


    echo "$sha256  $tmp" | sha256sum -c - || {

        echo "Checksum failed: $package"

        rm -f "$tmp"

        return 1
    }


    mv "$tmp" "$target"


    echo "Verified: $package"

}


install_package() {

    file="$1"
    pkg="$(basename "$file")"

    case "$PKG_MANAGER" in

        opkg)

            if opkg install "$file"; then
                echo "$pkg" >> "$INSTALL_LOG"
                INSTALLED_PACKAGES="$INSTALLED_PACKAGES $pkg"
                return 0
            fi
            ;;

        apk)

            if apk add --allow-untrusted "$file"; then
                echo "$pkg" >> "$INSTALL_LOG"
                INSTALLED_PACKAGES="$INSTALLED_PACKAGES $pkg"
                return 0
            fi
            ;;

    esac


    return 1
}


deploy_targeted_packages() {

    mkdir -p "$(dirname "$INSTALL_LOG")"
    touch "$INSTALL_LOG"

    echo
    echo "Starting installation..."
    echo

    for pkg in $SELECTED_PACKAGES
    do

        echo "[INFO] Installing $pkg"


        if ! download_package "$pkg"
        then

            echo "[ERROR] Download failed: $pkg"

            DEPLOYMENT_FAILED=1
            rollback_failed_install
            break

            continue

        fi


        file=$(jq -r \
            --arg pkg "$pkg" \
            --arg arch "$ARCH" \
            '
            .architectures[]
            | select(.name==$arch)
            | .packages[]
            | select(.package==$pkg)
            | .file
            ' \
            "$MANIFEST_FILE")

        echo "[ OK ] Installed $pkg"
        
        if ! install_package "$TMP_DIR/$file"
        then

            echo "[ERROR] Install failed: $pkg"

            DEPLOYMENT_FAILED=1

        fi

    done

}

rollback_failed_install() {

    echo "Rolling back..."

    case "$PKG_MANAGER" in

        opkg)

            for pkg in $INSTALLED_PACKAGES
            do
                opkg remove "$pkg" || true
            done

            ;;

        apk)

            for pkg in $INSTALLED_PACKAGES
            do
                apk del "$pkg" || true
            done

            ;;

    esac

}