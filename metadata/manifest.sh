#!/usr/bin/env bash

source "$DAYPASS_CORE_DIR/context.sh"

generate_manifest()
{
    local output_dir="$DAYPASS_OUTPUT_DIR"
    local main_manifest="$output_dir/manifest.json"

    echo "   🧠 Generating main manifest ..."

    jq -n \
        --arg release "$(jq -r '.release' "$DAYPASS_ARCH_FILE")" \
        --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson architectures "$(jq -c '
            .architectures |
            map({
                name: .name,
                packages: []
            })
        ' "$DAYPASS_ARCH_FILE")" \
        '
        {
            release: $release,
            generated_at: $generated,
            architectures: $architectures
        }
        ' \
        > "$main_manifest"


    while read -r arch
    do
        [ -z "$arch" ] && continue

        echo "   ⚙️ Generating package list for $arch ..."

        local packages="[]"

        if [ -d "$DAYPASS_TEMP_DIR/$arch" ]; then

            packages=$(find "$DAYPASS_TEMP_DIR/$arch" \
                -type f \
                -name "*.apk" \
                -printf "%f\n" |
            jq -R -s '
                split("\n")
                | map(select(length>0))
            ')

        fi


        jq \
            --arg arch "$arch" \
            --argjson packages "$packages" \
            '
            .architectures |=
            map(
                if .name == $arch
                then .packages = $packages
                else .
                end
            )
            ' \
            "$main_manifest" \
            > "${main_manifest}.tmp"


        mv "${main_manifest}.tmp" "$main_manifest"


    done < <(jq -r '.architectures[].name' "$DAYPASS_ARCH_FILE")


    echo "   ✅ Manifest generated!"
}