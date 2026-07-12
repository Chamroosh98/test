#!/bin/sh

INSTALL_LOG="/tmp/daypass/install.log"
INSTALLED_PACKAGES=""


manifest_lookup()
{
    field="$1"
    package="$2"

    jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
        --arg field "$field" \
'
.architectures[]
| select(.name==$arch)
| .packages[]
| select(
    .package==$pkg
    or (.package | startswith($pkg + "-"))
)
| .[$field]
' \
"$MANIFEST_FILE"
}


download_package()
{

    package="$1"


    file=$(manifest_lookup "file" "$package")

    sha256=$(manifest_lookup "sha256" "$package")


    if [ -z "$file" ] || [ "$file" = "null" ]; then

        echo "[ERROR] Package not found in manifest: $package"

        return 1

    fi


    target="$TMP_DIR/$file"
    tmp="$target.part"


    mkdir -p "$(dirname "$target")"


    echo
    echo "[INFO] Package : $package"
    echo "[INFO] File    : $file"
    echo "[INFO] URL     : $REPO_URL/$ARCH/$file"


    if ! curl -fsSL \
        "$REPO_URL/$ARCH/$file" \
        -o "$tmp"
    then

        echo "[ERROR] Download failed"

        rm -f "$tmp"

        return 1

    fi


    if [ ! -s "$tmp" ]; then

        echo "[ERROR] Empty package downloaded"

        rm -f "$tmp"

        return 1

    fi


    if ! echo "$sha256  $tmp" | sha256sum -c -
    then

        echo "[ERROR] Checksum failed: $package"

        rm -f "$tmp"

        return 1

    fi


    mv "$tmp" "$target"


    echo "[ OK ] Verified $package"

}



install_package()
{

    file="$1"

    pkg="$(basename "$file")"


    echo "[INFO] Installing $pkg"


    case "$PKG_MANAGER" in

    opkg)

        if opkg install "$file"
        then

            echo "$pkg" >> "$INSTALL_LOG"
            INSTALLED_PACKAGES="$INSTALLED_PACKAGES $pkg"

            return 0
        fi

        ;;


    apk)

        if apk add --allow-untrusted "$file"
        then

            echo "$pkg" >> "$INSTALL_LOG"
            INSTALLED_PACKAGES="$INSTALLED_PACKAGES $pkg"

            return 0
        fi

        ;;

    esac


    return 1

}



deploy_targeted_packages()
{

    mkdir -p "$(dirname "$INSTALL_LOG")"

    touch "$INSTALL_LOG"


    echo
    echo "Starting installation..."
    echo


    for pkg in $FINAL_PACKAGES
    do

        if ! download_package "$pkg"
        then

            echo "[ERROR] Download failed: $pkg"

            rollback_failed_install

            return 1

        fi


        file=$(manifest_lookup "file" "$pkg")


        if ! install_package "$TMP_DIR/$file"
        then

            echo "[ERROR] Install failed: $pkg"

            rollback_failed_install

            return 1

        fi


        echo "[ OK ] Installed $pkg"


    done


    return 0

}



rollback_failed_install()
{

    echo
    echo "Rolling back..."
    echo


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