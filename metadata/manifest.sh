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
        local arch_dir="$output_dir/$arch"
        
        echo "   ⚙️ Generating manifest for $arch ..."

        local pkg_json_tmp
        pkg_json_tmp=$(mktemp)
        echo "[]" > "$pkg_json_tmp"

        if [ -d "$arch_dir" ]; then
            while IFS= read -r file_path; do
                [ -z "$file_path" ] && continue
                
                local file_name
                file_name=$(basename "$file_path")
                local pkg_name="${file_name%.apk}"
                
                local file_size
                file_size=$(stat -c "%s" "$file_path" 2>/dev/null || echo "0")
                
                local file_sha
                file_sha=$(sha256sum "$file_path" | cut -d' ' -f1)

                jq \
                    --arg pkg "$pkg_name" \
                    --arg file "$file_name" \
                    --arg sha "$file_sha" \
                    --argjson size "$file_size" \
                    '. += [{package: $pkg, file: $file, sha256: $sha, size: $size}]' \
                    "$pkg_json_tmp" > "${pkg_json_tmp}.tmp" && mv "${pkg_json_tmp}.tmp" "$pkg_json_tmp"

            done < <(find "$arch_dir" -type f -name "*.apk" 2>/dev/null)
        else
            echo "⚠️ Directory not found : $arch_dir (Skipping ...)"
        fi

        jq \
            --arg arch "$arch" \
            --argjson packages "$(cat "$pkg_json_tmp")" \
            '.architectures += [{name: $arch, packages: $packages}]' \
            "$main_manifest" > "${main_manifest}.tmp"

        mv "${main_manifest}.tmp" "$main_manifest"
        rm -f "$pkg_json_tmp"
    done

    echo "🎉 manifest.json successfully updated!"
}