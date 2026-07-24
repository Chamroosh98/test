#!/bin/sh

get_free_ram_mb()
{
    FREE_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    [ -z "$FREE_KB" ] && FREE_KB=$(grep MemFree /proc/meminfo | awk '{print $2}')
    echo $((FREE_KB / 1024))
}

get_total_ram_mb()
{
    TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $((TOTAL_KB / 1024))
}

get_free_storage_mb()
{
    TARGET="/"
    [ -d /overlay ] && TARGET="/overlay"
    df -k "$TARGET" | awk 'END {printf "%.0f\n", $4 / 1024}'
}

get_total_storage_mb()
{
    TARGET="/"
    [ -d /overlay ] && TARGET="/overlay"
    df -k "$TARGET" | awk 'END {printf "%.0f\n", $2 / 1024}'
}

resource_snapshot()
{
    SNAPSHOT_RAM_FREE="$(get_free_ram_mb)"
    SNAPSHOT_STORAGE_FREE="$(get_free_storage_mb)"

    export SNAPSHOT_RAM_FREE
    export SNAPSHOT_STORAGE_FREE
}

resource_compare()
{
    CURRENT_RAM_FREE="$(get_free_ram_mb)"
    CURRENT_STORAGE_FREE="$(get_free_storage_mb)"

    if [ "$SNAPSHOT_RAM_FREE" -gt "$CURRENT_RAM_FREE" ]; then
        RAM_USED=$((SNAPSHOT_RAM_FREE - CURRENT_RAM_FREE))
    else
        RAM_USED=0
    fi

    if [ "$SNAPSHOT_STORAGE_FREE" -gt "$CURRENT_STORAGE_FREE" ]; then
        STORAGE_USED=$((SNAPSHOT_STORAGE_FREE - CURRENT_STORAGE_FREE))
    else
        STORAGE_USED=0
    fi

    echo
    log_info "Resource Usage"
    echo " ============================================================ "
    echo "  🧠 RAM Used      : ${RAM_USED} MB"
    echo "  💾 Storage Used  : ${STORAGE_USED} MB"
    echo
}

estimate_install_size()
{
    TOTAL_SIZE=0

    for pkg in $FINAL_PACKAGES; do
        size="$(manifest_lookup "size" "$pkg")"

        [ -z "$size" ] || [ "$size" = "null" ] && continue
        TOTAL_SIZE=$((TOTAL_SIZE + size))
    done

    TOTAL_SIZE_MB=$(( (TOTAL_SIZE + 1048575) / 1048576 ))

    echo
    log_info "Installation Estimate "
    echo " ============================================================ "
    echo "   📦 Packages : $(echo "$FINAL_PACKAGES" | wc -w)"
    echo "   📥 Download : ${TOTAL_SIZE_MB} MB"
    echo
}