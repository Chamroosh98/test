#!/usr/bin/env bash

###############################################################################
# DayPass Catalog & Manifest Generator
###############################################################################

source "$DAYPASS_CORE_DIR/context.sh"

generate_catalog() {

    local manifest="$DAYPASS_OUTPUT_DIR/manifest.json"

    local release
    release=$(jq -r '.release' "$DAYPASS_ARCH_FILE")

    local generated
    generated=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq -n \
        --arg release "$release" \
        --arg generated "$generated" \
        '
        {
            release:$release,
            generated_at:$generated,
            architectures:[]
        }
        ' > "$manifest"

    local arch_count
    arch_count=$(jq '.architectures | length' "$DAYPASS_ARCH_FILE")

    for ((i=0;i<arch_count;i++)); do

        local arch
        arch=$(jq -r ".architectures[$i].name" "$DAYPASS_ARCH_FILE")

        local arch_json
        arch_json=$(mktemp)

        jq -n \
            --arg arch "$arch" \
            '
            {
                name:$arch,
                packages:[]
            }
            ' > "$arch_json"

        while IFS= read -r pkg; do

            [[ -z "$pkg" ]] && continue

            local feed
            feed=$(dirname "$pkg")

            local filename
            filename=$(basename "$pkg")

            local package
            package="${filename%.apk}"

            local sha256
            sha256=$(sha256sum "$DAYPASS_TEMP_DIR/$arch/$pkg" | awk '{print $1}')

            local size
            size=$(stat -c%s "$DAYPASS_TEMP_DIR/$arch/$pkg")

            jq \
                --arg feed "$feed" \
                --arg package "$package" \
                --arg file "$pkg" \
                --arg sha "$sha256" \
                --argjson size "$size" \
                '
                .packages += [{
                    feed:$feed,
                    package:$package,
                    file:$file,
                    sha256:$sha,
                    size:$size
                }]
                ' \
                "$arch_json" > "$arch_json.tmp"

            mv "$arch_json.tmp" "$arch_json"

        done < <(

            cd "$DAYPASS_TEMP_DIR/$arch" || exit

            find . \
                -type f \
                -name "*.apk" \
                | sed 's#^\./##' \
                | sort

        )

        jq \
            --slurpfile arch "$arch_json" \
            '.architectures += $arch' \
            "$manifest" > "$manifest.tmp"

        mv "$manifest.tmp" "$manifest"

        rm -f "$arch_json"

    done

}