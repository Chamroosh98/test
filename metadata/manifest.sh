#!/usr/bin/env bash

source "$DAYPASS_CORE_DIR/context.sh"

generate_manifest() {

    local output_dir="$DAYPASS_OUTPUT_DIR"
    local main_manifest="$output_dir/manifest.json"

    local archs
    archs=$(jq -r '.architectures[].name' "$DAYPASS_ARCH_FILE")


    jq -n \
        --arg release "$(jq -r '.release' "$DAYPASS_ARCH_FILE")" \
        --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            release: $release,
            generated_at: $generated,
            architectures: []
        }' > "$main_manifest"


    for arch in $archs; do

        local arch_dir="$DAYPASS_TEMP_DIR/$arch"
        local packages="[]"

        echo "   ⚙️ Generating manifest for $arch..."


        if [ -d "$arch_dir" ]; then

            packages=$(find "$arch_dir" -type f -name "*.apk" \
            -exec sh -c '
                for file do
                    name=$(basename "$file")
                    size=$(stat -c%s "$file" 2>/dev/null || echo 0)
                    sha=$(sha256sum "$file" | awk "{print \$1}")

                    jq -n \
                    --arg pkg "${name%.apk}" \
                    --arg file "$name" \
                    --arg sha256 "$sha" \
                    --argjson size "$size" \
                    "{
                        package: \$pkg,
                        file: \$file,
                        sha256: \$sha256,
                        size: \$size
                    }"
                done
            ' sh {} + | jq -s '.')
        fi


        jq \
            --arg arch "$arch" \
            --argjson packages "$packages" \
            '
            .architectures += [
                {
                    name: $arch,
                    packages: $packages
                }
            ]
            ' \
            "$main_manifest" > "${main_manifest}.tmp"

        mv "${main_manifest}.tmp" "$main_manifest"

    done
}