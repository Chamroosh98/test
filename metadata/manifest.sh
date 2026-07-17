#!/usr/bin/env bash

source "$DAYPASS_CORE_DIR/context.sh"

generate_manifest() {

    local output="$DAYPASS_OUTPUT_DIR/manifest.json"

    jq -n \
        --arg release "$(jq -r '.release' "$DAYPASS_ARCH_FILE")" \
        --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '
        {
            release: $release,
            generated_at: $generated,
            architectures: []
        }
        ' > "$output"

}