#!/bin/sh

get_free_ram_mb()
{
    free | awk '
    /Mem:/ {
        printf "%.0f\n", $4 / 1024
    }'
}

get_total_ram_mb()
{
    free | awk '
    /Mem:/ {
        printf "%.0f\n", $2 / 1024
    }'
}

get_free_storage_mb()
{
    df -k / | awk '
    NR==2 {
        printf "%.0f\n", $4 / 1024
    }'
}

get_total_storage_mb()
{
    df -k / | awk '
    NR==2 {
        printf "%.0f\n", $2 / 1024
    }'
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

    RAM_USED=$((SNAPSHOT_RAM_FREE - CURRENT_RAM_FREE))
    STORAGE_USED=$((SNAPSHOT_STORAGE_FREE - CURRENT_STORAGE_FREE))

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

    for pkg in $FINAL_PACKAGES
    do
        size="$(manifest_lookup "size" "$pkg")"

        [ -z "$size" ] && continue
        [ "$size" = "null" ] && continue

        TOTAL_SIZE=$((TOTAL_SIZE + size))
    done

    TOTAL_SIZE_MB=$(( (TOTAL_SIZE + 1048575) / 1048576 ))

    echo
    log_info "Installation Estimate "
    echo " ============================================================ "
    echo "  📦 Packages : $(echo "$FINAL_PACKAGES" | wc -w)"
    echo "  📥 Download : ${TOTAL_SIZE_MB} MB"
    echo
}