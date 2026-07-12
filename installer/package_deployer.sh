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
| select(.package==$pkg)
| .[$field]
' \
"$MANIFEST_FILE" | head -n1
}


manifest_info()
{
    package="$1"

    jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
'
.architectures[]
| select(.name==$arch)
| .packages[]
| select(.package==$pkg)
| "\(.package) | \(.size) bytes"
' \
"$MANIFEST_FILE" | head -n1
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
    echo "[INFO] Package : $(manifest_info "$package")"
    echo "[INFO] URL     : $REPO_URL/$ARCH/$file"
    echo "[INFO] Downloading $package"


    rm -f "$tmp"


    if ! curl -fsSL \
        "$REPO_URL/$ARCH/$file" \
        -o "$tmp"
    then

        echo "[ERROR] Download failed: $package"

        rm -f "$tmp"

        return 1

    fi


    #
    # Zero byte protection
    #
    if [ ! -s "$tmp" ]; then

        echo "[ERROR] Empty package: $package"

        rm -f "$tmp"

        return 1

    fi


    #
    # Checksum validation
    #
    if [ -z "$sha256" ] || [ "$sha256" = "null" ]; then

        echo "[ERROR] Missing checksum: $package"

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

    if [ ! -s "$file" ]; then

        echo "[ERROR] Invalid package file: $file"

        return 1

    fi


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


    echo "[ERROR] Install failed: $pkg"

    return 1

}


deploy_targeted_packages()
{

    mkdir -p "$(dirname "$INSTALL_LOG")"

    touch "$INSTALL_LOG"


    echo
    echo "Starting installation ..."
    echo


    INSTALL_FILES=""


    for pkg in $FINAL_PACKAGES
    do

        if ! download_package "$pkg"
        then

            echo "[ERROR] Download failed: $pkg"

            rollback_failed_install

            return 1

        fi


        file=$(manifest_lookup "file" "$pkg")


        if [ -z "$file" ] || [ "$file" = "null" ]; then

            echo "[ERROR] Manifest file missing: $pkg"

            rollback_failed_install

            return 1

        fi


        INSTALL_FILES="$INSTALL_FILES $TMP_DIR/$file"


    done


    echo
    echo "[INFO] Installing packages:"
    echo "$INSTALL_FILES"
    echo


    for file in $INSTALL_FILES
    do

        if ! install_package "$file"
        then

            rollback_failed_install

            return 1

        fi

    done


    echo "[ OK ] Installation completed"

    return 0

}