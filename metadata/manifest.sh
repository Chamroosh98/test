#!/usr/bin/env bash

source "$DAYPASS_CORE_DIR/context.sh"

generate_manifest() {

    local output_dir="$DAYPASS_OUTPUT_DIR"
    local main_manifest="$output_dir/manifest.json"

    echo "   ⚙️ Generating global manifest ..."

    local release
    release=$(jq -r '.release' "$DAYPASS_ARCH_FILE")

    local architectures='[]'

    while read -r arch; do

        local arch_dir="$output_dir/$arch"
        [ -d "$arch_dir" ] || continue

        echo "   📦 Processing $arch ..."

        local packages='[]'

        while IFS= read -r file; do

            [ -f "$file" ] || continue

            filename=$(basename "$file")

            sha256=$(sha256sum "$file" | awk '{print $1}')
            size=$(stat -c%s "$file")

            pkg_name=$(echo "$filename" | sed -E 's/_[0-9].*\.apk$//' | sed 's/\.apk$//')

            packages=$(jq \
                --arg pkg "$pkg_name" \
                --arg file "$filename" \
                --arg sha "$sha256" \
                --argjson size "$size" \
                '. + [{
                    package:$pkg,
                    file:$file,
                    sha256:$sha,
                    size:$size
                }]' <<< "$packages")

        done < <(find "$arch_dir" -type f -name "*.apk")


        architectures=$(jq \
            --arg arch "$arch" \
            --argjson pkgs "$packages" \
            '. + [{
                name:$arch,
                packages:$pkgs
            }]' <<< "$architectures")

    done < <(jq -r '.architectures[].name' "$DAYPASS_ARCH_FILE")


    jq -n \
        --arg release "$release" \
        --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson architectures "$architectures" \
        '{
            release:$release,
            generated_at:$generated,
            architectures:$architectures
        }' \
        > "$main_manifest"


    echo "   ✅ Manifest generated!"
}