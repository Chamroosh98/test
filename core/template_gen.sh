#!/usr/bin/env bash

set -euo pipefail

generate_install_script() {

    mkdir -p "$DAYPASS_OUTPUT_DIR"

    cat > "$DAYPASS_INSTALL_SCRIPT" <<'EOF'
#!/bin/sh

echo "=================================================="
echo " DayPass"
echo "=================================================="

echo
echo "This is a temporary installer."
echo "Build completed successfully."
echo

exit 0

EOF

    chmod +x "$DAYPASS_INSTALL_SCRIPT"

    log_success "install.sh generated."

}