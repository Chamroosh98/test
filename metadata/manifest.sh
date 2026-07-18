#!/usr/bin/env bash

source "$DAYPASS_CORE_DIR/context.sh"

generate_manifest() {
    local target_subfolder=""
    if [ "${GITHUB_REF_NAME:-}" = "dev" ]; then
        target_subfolder="/dev"
        echo "⚠️ Target branch is 'dev'. Outputting to subfolder /dev"
    fi

    local output_dir="$DAYPASS_OUTPUT_DIR$target_subfolder"
    local main_manifest="$output_dir/manifest.json"

    mkdir -p "$output_dir"

    echo "  🧠 Generating manifests in : $output_dir"

    local release
    release=$(jq -r '.release' "$DAYPASS_ARCH_FILE")

    local architectures='[]'

    while read -r arch; 
    do
        local arch_dir="$DAYPASS_OUTPUT_DIR/$arch"
        
        if [ ! -d "$arch_dir" ]; then
            echo "   ⚠️ Warning : Directory not found for $arch -> $arch_dir (Skipping ...)"
            continue
        fi

        echo " 🔬 Processing packages for $arch ..."
        local packages='[]'

        while IFS= read -r file; do
            [ -f "$file" ] || continue

            local filename
            filename=$(basename "$file")
            
            local sha256
            sha256=$(sha256sum "$file" | awk '{print $1}')
            
            local size
            size=$(stat -c%s "$file")

            local pkg_name
            pkg_name=$(echo "$filename" | sed -E 's/_[0-9].*\.(apk|ipk)$//' | sed -E 's/\.(apk|ipk)$//')

            packages=$(jq \
                --arg pkg "$pkg_name" \
                --arg file "$filename" \
                --arg sha "$sha256" \
                --argjson size "$size" \
                '. + [{
                    package: $pkg,
                    file: $file,
                    sha256: $sha,
                    size: $size
                }]' <<< "$packages")

        done < <(find "$arch_dir" -type f \( -name "*.apk" -o -name "*.ipk" \))

        architectures=$(jq \
            --arg arch "$arch" \
            --argjson pkgs "$packages" \
            '. + [{
                name: $arch,
                packages: $pkgs
            }]' <<< "$architectures")

        jq -n \
            --arg arch "$arch" \
            --argjson pkgs "$packages" \
            '{
                name: $arch,
                packages: $pkgs
            }' > "$output_dir/manifest.$arch.json"

    done < <(jq -r '.architectures[].name' "$DAYPASS_ARCH_FILE")

    jq -n \
        --arg release "$release" \
        --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson architectures "$architectures" \
        '{
            release: $release,
            generated_at: $generated,
            architectures: $architectures
        }' \
        > "$main_manifest"

    echo "  🎉 Manifests generated successfully in $output_dir!"
}