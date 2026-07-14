#!/bin/sh

INSTALL_LOG="/tmp/daypass/install.log"
INSTALLED_PACKAGES=""

TRANSACTION_LOG="/tmp/daypass/transaction.log"

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
    (.package == $pkg)
    or
    (.package | startswith($pkg + "-"))
)
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
| select(.package | startswith($pkg))
| "\(.package) | \(.size) bytes"
' \
"$MANIFEST_FILE" | head -n1
}


download_package()
{
    package="$1"


    file=$(manifest_lookup "file" "$package")

    sha256=$(manifest_lookup "sha256" "$package")


    if [ -z "$file" ] || [ "$file" = "null" ]; 
        then
        echo "   ❌ Package not found in manifest : $package"
        return 1

    fi

    target="$TMP_DIR/$file"
    tmp="$target.part"

    mkdir -p "$(dirname "$target")"


    echo
    echo "   📦 Package : $(manifest_info "$package")"
    echo "   📁 File    : $file"
    echo "   🔗 URL     : $REPO_URL/$ARCH/$file"
    echo "   📥 Downloading $package"

    curl -fsSL \
        "$REPO_URL/$ARCH/$file" \
        -o "$tmp" || {

        rm -f "$tmp"
        return 1
    }

    if [ ! -s "$tmp" ]; 
        then
        echo "   ❌ Invalid package: empty file"
        rm -f "$tmp"
        return 1
    fi

    if ! echo "$sha256  $tmp" | sha256sum -c -
        then
        echo "   ❌ Checksum failed : $package"
        rm -f "$tmp"
        return 1
    fi

    mv "$tmp" "$target"

    echo "   ✅ Verified $package"
}

install_package()
{
    file="$1"
    pkg="$(basename "$file")"


    if [ ! -s "$file" ]; 
        then
        echo "   ❌ Package file invalid: $file"
        return 1
    fi

    echo "   📦 Installing $pkg"

    case "$PKG_MANAGER" in
        opkg)
            if opkg install "$file"
                then
                echo "$pkg" >> "$INSTALL_LOG"
                INSTALLED_PACKAGES="$INSTALLED_PACKAGES $pkg"
                echo "$pkg" >> "$TRANSACTION_LOG"
                return 0
            fi
            ;;
        apk)
            if apk add --allow-untrusted "$file"
                then
                echo "$pkg" >> "$INSTALL_LOG"
                INSTALLED_PACKAGES="$INSTALLED_PACKAGES $pkg"
                echo "$pkg" >> "$TRANSACTION_LOG"
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
    rm -f "$TRANSACTION_LOG"
    touch "$TRANSACTION_LOG"

    echo
    echo "   🏁 Starting installation ..."
    echo

    # Resource snapshot BEFORE installation

    resource_snapshot
    estimate_install_size

    INSTALL_FILES=""

    for pkg in $FINAL_PACKAGES
        do
            if ! download_package "$pkg"
                then
                echo "   ❌ Download failed : $pkg"
                rollback_failed_install
                return 1
            fi

            file=$(manifest_lookup "file" "$pkg")
            INSTALL_FILES="$INSTALL_FILES $TMP_DIR/$file"
        done

    echo
    echo "   📦 Installing packages :"
    echo "$INSTALL_FILES"
    echo

    case "$PKG_MANAGER" in

        apk)
            if apk add --allow-untrusted $INSTALL_FILES
                then
                    echo "$FINAL_PACKAGES" >> "$INSTALL_LOG"
                    resource_compare
                    return 0

            fi
            ;;

        opkg)
            if opkg install $INSTALL_FILES
                then
                    echo "$FINAL_PACKAGES" >> "$INSTALL_LOG"
                    resource_compare
                    return 0
            fi
            ;;
    esac

    echo "   ❌ Installation failed!"

    rollback_failed_install
    return 1
}

rollback_failed_install()
{

    echo
    echo "   ⚠️  Rolling back installation ..."
    echo

    [ -f "$TRANSACTION_LOG" ] || return

    case "$PKG_MANAGER" in
        opkg)
            while read -r pkg
                do
                    [ -z "$pkg" ] && continue
                    echo "   🔄 Removing ($pkg) for RollBack!"
                    opkg remove "$pkg" || true
                done < "$TRANSACTION_LOG"
            ;;
        apk)
            while read -r pkg
                do
                    [ -z "$pkg" ] && continue
                    echo "   🔄 Removing ($pkg) for RollBack!"
                    apk del "$pkg" || true
                done < "$TRANSACTION_LOG"
            ;;
    esac

    rm -f "$TRANSACTION_LOG"
    echo "   ✅ Rollback completed ;))"

}