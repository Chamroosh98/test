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

    for arch in $archs; 
    do
        local arch_dir="$output_dir/$arch"
        local packages="[]"

        echo " 🧠 Generating manifest for $arch ..."

        if [ -d "$arch_dir" ]; 
        then
            packages=$(find "$arch_dir" -type f -name "*.apk" -exec stat -c "%s %n" {} + 2>/dev/null | \
            awk '
            {
                size = $1
                split($2, path, "/")
                file = path[length(path)]
                
                pkg = file
                sub(/\.apk$/, "", pkg)
                
                cmd = "sha256sum \"" $2 "\" | cut -d\" \" -f1"
                cmd | getline sha
                close(cmd)
                
                printf "%s\t%s\t%s\t%s\n", pkg, file, sha, size
            }' | jq -R -s '
                split("\n") | map(select(length > 0) | split("\t")) | map({
                    package: .[0],
                    file: .[1],
                    sha256: .[2],
                    size: (.[3] | tonumber)
                })
            ')
        else
            echo " ⚠️ Directory not found : $arch_dir (Skipping packages ...)"
        fi

        jq \
            --arg arch "$arch" \
            --argjson packages "${packages:-[]}" \
            '.architectures += [{name: $arch, packages: $packages}]' \
            "$main_manifest" > "${main_manifest}.tmp"

        mv "${main_manifest}.tmp" "$main_manifest"
    done

    echo " 🚀 manifest.json successfully updated!"
}