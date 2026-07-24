#!/bin/sh

###############################################################################
# DayPass Installer (Auto-generated via Go Action)
###############################################################################

# Dynamic REPO_URL configuration
if [ -z "${REPO_URL:-}" ]; then
    REPO_URL="https://chamroosh98.github.io/DayPass/beta"
fi
export REPO_URL


# 📄 Source : network_checker.sh

spin_sleep() {
    if command -v usleep >/dev/null 2>&1; then
        usleep 100000
    else
        sleep 1
    fi
}

GREEN_COUNT=0
YELLOW_COUNT=0
RED_COUNT=0
TOTAL_CHECKS=0
DNS_FAILED=0

ROW_HOST=""
ROW_DNS_ICON="·"
ROW_PING_ICON="·"
ROW_HTTPS_ICON="·"
ROW_ACTIVE=""

redraw_row()
{
    spin="$1"
    d="$ROW_DNS_ICON"
    p="$ROW_PING_ICON"
    h="$ROW_HTTPS_ICON"

    case "$ROW_ACTIVE" in
        dns)   d="$spin" ;;
        ping)  p="$spin" ;;
        https) h="$spin" ;;
    esac

    printf "\r  %-16s %-6s %-7s %-6s\033[K" "$ROW_HOST" "$d" "$p" "$h"
}

run_cell()
{
    ROW_ACTIVE="$1"
    tmp="$2"
    shift 2

    "$@" >"$tmp" 2>&1 &
    pid=$!

    spin_chars='-\|/'
    i=0
    while kill -0 "$pid" 2>/dev/null; do
        c="$(printf '%s' "$spin_chars" | cut -c$(( (i % 4) + 1 )))"

        if [ -n "$CYAN" ] && [ -n "$RESET" ]; then
            redraw_row "${CYAN}${c}${RESET}"
        else
            redraw_row "$c"
        fi
        i=$((i + 1))
        spin_sleep
    done

    wait "$pid" 2>/dev/null
    CELL_EXIT=$?
    CELL_OUTPUT="$(cat "$tmp" 2>/dev/null)"
    rm -f "$tmp"
}

process_host()
{
    ROW_HOST="$1"
    ROW_DNS_ICON="·"
    ROW_PING_ICON="·"
    ROW_HTTPS_ICON="·"
    ROW_ACTIVE=""
    redraw_row "·"

    # DNS
    run_cell "dns" "/tmp/.nc_dns_$$" nslookup "$ROW_HOST" 127.0.0.1
    if [ "$CELL_EXIT" -eq 0 ]; then
        ROW_DNS_ICON="🟢"
    else
        ROW_DNS_ICON="🔴"
        DNS_FAILED=1
    fi

    # Ping
    run_cell "ping" "/tmp/.nc_ping_$$" ping -c 2 -W 2 "$ROW_HOST"
    LOSS="$(printf '%s' "$CELL_OUTPUT" | grep -o '[0-9]*% packet loss' | grep -o '^[0-9]*')"
    [ -z "$LOSS" ] && LOSS=100
    if [ "$LOSS" -eq 0 ]; then
        ROW_PING_ICON="🟢"
    elif [ "$LOSS" -lt 100 ]; then
        ROW_PING_ICON="🟡"
    else
        ROW_PING_ICON="🔴"
    fi

    # HTTPS Check (Dual-Engine: curl or wget fallback)
    if command -v curl >/dev/null 2>&1; then
        run_cell "https" "/tmp/.nc_https_$$" curl -fsS -o /dev/null -w '%{time_total}' --connect-timeout 5 "https://$ROW_HOST"
    else
        # Fallback for minimal systems using wget
        run_cell "https" "/tmp/.nc_https_$$" wget -q --spider --timeout=5 "https://$ROW_HOST"
    fi

    if [ "$CELL_EXIT" -ne 0 ]; then
        ROW_HTTPS_ICON="🔴"
    else
        if command -v curl >/dev/null 2>&1; then
            IS_FAST="$(awk -v t="$CELL_OUTPUT" 'BEGIN { print (t < 2) ? "1" : "0" }' 2>/dev/null)"
            if [ "$IS_FAST" = "1" ]; then
                ROW_HTTPS_ICON="🟢"
            else
                ROW_HTTPS_ICON="🟡"
            fi
        else
            ROW_HTTPS_ICON="🟢"
        fi
    fi

    ROW_ACTIVE=""
    redraw_row " "
    printf "\n"

    for icon in "$ROW_DNS_ICON" "$ROW_PING_ICON" "$ROW_HTTPS_ICON"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        case "$icon" in
            🟢) GREEN_COUNT=$((GREEN_COUNT + 1)) ;;
            🟡) YELLOW_COUNT=$((YELLOW_COUNT + 1)) ;;
            🔴) RED_COUNT=$((RED_COUNT + 1)) ;;
        esac
    done
}

network_check()
{
    GREEN_COUNT=0
    YELLOW_COUNT=0
    RED_COUNT=0
    TOTAL_CHECKS=0
    DNS_FAILED=0

    echo
    printf "  ${BOLD}${CYAN}🔎 DayPass Network Health Check${RESET}\n"
    
    printf "  ${GRAY}──────────────────────────────────────────${RESET}\n"

    printf "  ${BOLD}%-16s %-6s %-7s %-6s${RESET}\n" "Host" "DNS" "Ping" "HTTPS"
    printf "  ${GRAY}──────────────────────────────────────────${RESET}\n"

    process_host "Google.com"
    process_host "Github.com"
    process_host "Openwrt.org"
    process_host "Cloudflare.com"

    # printf "  ${GRAY}──────────────────────────────────────────${RESET}\n"
    # printf "  ${BOLD}Status Legend :${RESET}\n"
    # printf "    🟢 ${GREEN}Passed / Fast${RESET}  |  🟡 ${YELLOW}Degraded / Slow${RESET}  |  🔴 ${RED}Failed / Blocked${RESET}\n"
    
    printf "  ${GRAY}──────────────────────────────────────────${RESET}\n\n"

    PCT=0
    [ "$TOTAL_CHECKS" -gt 0 ] && PCT=$((GREEN_COUNT * 100 / TOTAL_CHECKS))

    printf "  ${BOLD}Overall Score :${RESET} "
    if command -v draw_bar >/dev/null 2>&1; then
        draw_bar "$PCT" 12 "score"
    fi
    printf " %s%% (🟢 %s  🟡 %s  🔴 %s)\n\n" "$PCT" "$GREEN_COUNT" "$YELLOW_COUNT" "$RED_COUNT"

    printf "  ${BOLD}Diagnostic Report :${RESET}"
    if [ "$DNS_FAILED" -eq 1 ]; then
        if command -v log_error >/dev/null 2>&1; then
            log_error "DNS resolution is failing! Router cannot translate domain names."
        else
            printf "❌${RED}DNS resolution failed! Domain name lookup is broken.${RESET}\n"
        fi
        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
            if command -v dns_fix_menu >/dev/null 2>&1; then
                dns_fix_menu
            fi
        fi
    elif [ "$RED_COUNT" -gt 0 ]; then
        if command -v log_warn >/dev/null 2>&1; then
            log_warn "HTTPS connections are blocked or filtered (Possible Censorship/DPI)."
        else
            printf "⚠️${YELLOW}HTTPS traffic is blocked or severely interfered with.${RESET}\n"
        fi
    elif [ "$YELLOW_COUNT" -gt 0 ]; then
        if command -v log_warn >/dev/null 2>&1; then
            log_warn "Network is active but experiencing high packet loss/latency (>2s)."
        else
            printf "⚠️${YELLOW}High latency or degraded response time detected.${RESET}\n"
        fi
    else
        if command -v log_success >/dev/null 2>&1; then
            log_success "Network is fully functional with clean connectivity!"
        else
            printf "✅${GREEN}Network is fully functional!${RESET}\n"
        fi
    fi

    echo
    printf "  ${GRAY}Press [Enter] to continue ...${RESET}"
    read -r _ </dev/tty
    echo
    return 0
}

case "$0" in
    *network_checker.sh) network_check ;;
esac

# 📄 Source : package_manager.sh

detect_package_manager()
{
    # 1. Identify standard package manager binary
    if command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"
        log_info "Package manager identified : [apk] (Alpine/OpenWrt NextGen)"
    elif command -v opkg >/dev/null 2>&1; then
        PKG_MANAGER="opkg"
        log_info "Package manager identified : [opkg] (Legacy OpenWrt)"
    else
        log_error "Critical Error : Neither 'apk' nor 'opkg' package manager was found!"
        exit 1
    fi

    export PKG_MANAGER
}

pkg_update()
{
    log_info "Updating package indexes using [$PKG_MANAGER] ..."

    if [ "$PKG_MANAGER" = "apk" ]; then
        # Standard update first; if IPv6/DNS issues occur, fall back to IPv4
        if ! apk update --network-timeout 5 >/dev/null 2>&1; then
            log_warn "Standard APK update failed/timed out! Attempting fallback via IPv4 ..."
            if ! apk update --force-ipv4 --network-timeout 5 >/dev/null 2>&1; then
                log_warn "APK update encountered repository warnings. Proceeding with local cache ..."
            else
                log_success "APK indexes updated successfully using IPv4 fallback."
            fi
        else
            log_success "APK package indexes updated successfully."
        fi

    elif [ "$PKG_MANAGER" = "opkg" ]; then
        if ! opkg update >/dev/null 2>&1; then
            log_warn "OPKG update encountered minor mirror warnings. Proceeding anyway ..."
        else
            log_success "OPKG package indexes updated successfully."
        fi
    fi
}

pkg_installed()
{
    PACKAGE_NAME="$1"

    # Check if target package is registered as installed in the local DB
    if [ "$PKG_MANAGER" = "apk" ]; then
        apk info -e "$PACKAGE_NAME" >/dev/null 2>&1
    elif [ "$PKG_MANAGER" = "opkg" ]; then
        opkg list-installed | grep -q "^$PACKAGE_NAME - "
    fi
}

pkg_install()
{
    PACKAGE_NAME="$1"

    log_info "Executing package installation : [$PACKAGE_NAME]"

    if [ "$PKG_MANAGER" = "apk" ]; then
        # 1. Try standard installation with untrusted keyring bypass (for local/custom builds)
        if apk add --no-cache --allow-untrusted "$PACKAGE_NAME" >/dev/null 2>&1; then
            log_success "Package [$PACKAGE_NAME] installed successfully via APK."
            return 0
        fi

        # 2. Fallback attempt using IPv4 explicit routing if network fails
        log_warn "Standard APK installation failed for [$PACKAGE_NAME]. Trying IPv4 fallback..."
        if apk add --force-ipv4 --no-cache --allow-untrusted "$PACKAGE_NAME" >/dev/null 2>&1; then
            log_success "Package [$PACKAGE_NAME] installed successfully via APK (IPv4 fallback)."
            return 0
        fi

        log_error "APK failed to install package : [$PACKAGE_NAME]"
        return 1

    elif [ "$PKG_MANAGER" = "opkg" ]; then
        # Install with opkg bypassing unverified signature warnings
        if opkg install --force-checksum "$PACKAGE_NAME" >/dev/null 2>&1; then
            log_success "Package [$PACKAGE_NAME] installed successfully via OPKG."
            return 0
        fi

        log_error "OPKG failed to install package : [$PACKAGE_NAME]"
        return 1
    fi
}

# 📄 Source : install_core.sh

initialize_installer()
{
    # 1. Detect environment and update local package index
    detect_package_manager

    log_info "Updating package database ..."
    pkg_update >/dev/null 2>&1 || log_warn "Package index update finished with warnings!"

    # 2. Setup temporary workspace
    TMP_DIR="/tmp/daypass"
    mkdir -p "$TMP_DIR"
    MANIFEST_FILE="$TMP_DIR/manifest.json"

    # 3. Validate base repository URL
    if [ -z "${REPO_URL:-}" ]; then
        log_error "REPO_URL environment variable is not defined!"
        exit 1
    fi

    log_info "Downloading architecture manifest from : [$REPO_URL/manifest.json]"
    
    # 4. Download manifest using resilient fallback mechanisms (curl -> wget -> uclient-fetch)
    DOWNLOAD_SUCCESS=0

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_URL/manifest.json" -o "$MANIFEST_FILE" && DOWNLOAD_SUCCESS=1
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$MANIFEST_FILE" "$REPO_URL/manifest.json" && DOWNLOAD_SUCCESS=1
    elif command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch -q -O "$MANIFEST_FILE" "$REPO_URL/manifest.json" && DOWNLOAD_SUCCESS=1
    else
        log_error "No network download utility found (curl, wget, or uclient-fetch)!"
        exit 1
    fi

    # 5. Verify downloaded file presence and size
    if [ "$DOWNLOAD_SUCCESS" -ne 1 ] || [ ! -s "$MANIFEST_FILE" ]; then
        log_error "Failed to download or received empty manifest from [$REPO_URL/manifest.json]"
        exit 1
    fi

    # Log downloaded file size for telemetry
    MANIFEST_SIZE=$(wc -c < "$MANIFEST_FILE" | awk '{print $1}')
    log_info "Manifest downloaded successfully ($MANIFEST_SIZE bytes)."

    # 6. Detect host system target architecture
    if [ -f /etc/openwrt_release ]; then
        ARCH=$(grep "DISTRIB_ARCH" /etc/openwrt_release | cut -d"'" -f2)
    else
        ARCH="$(uname -m)"
    fi

    if [ -z "$ARCH" ]; then
        log_error "Unable to detect host system architecture!"
        exit 1
    fi

    log_info "Target System Architecture detected : [$ARCH]"

    # 7. Validate JSON syntax integrity
    if ! jq empty "$MANIFEST_FILE" >/dev/null 2>&1; then
        log_error "Manifest file is corrupted or invalid JSON!"
        log_warn "JSON Parser Output Error:"
        jq empty "$MANIFEST_FILE" 2>&1 | head -n 3 | sed 's/^/   └─ /'
        exit 1
    fi

    # 8. Extract release metadata for diagnostic logs
    MANIFEST_REL=$(jq -r '.release // "unknown"' "$MANIFEST_FILE" 2>/dev/null)
    MANIFEST_GEN=$(jq -r '.generated_at // "unknown"' "$MANIFEST_FILE" 2>/dev/null)
    log_info "Manifest Metadata -> Release: [$MANIFEST_REL] | Generated At: [$MANIFEST_GEN]"

    # 9. Query architecture support in manifest
    FOUND_ARCH=$(jq -r --arg arch "$ARCH" '.architectures[]? | select(.name == $arch) | .name' "$MANIFEST_FILE" 2>/dev/null | head -n1)

    if [ -z "$FOUND_ARCH" ] || [ "$FOUND_ARCH" = "null" ]; then
        log_error "Architecture [$ARCH] is NOT supported in this build manifest!"
        log_warn "Available architectures in current manifest:"
        
        jq -r '.architectures[].name' "$MANIFEST_FILE" 2>/dev/null | sed 's/^/   • /'
        
        exit 1
    fi

    # 10. Success confirmation & environment export
    log_success "Manifest loaded & verified for architecture : [$ARCH]"

    export ARCH
    export TMP_DIR
    export MANIFEST_FILE
}

# 📄 Source : package_deployer.sh


INSTALL_LOG="/tmp/daypass/install.log"
TRANSACTION_LOG="/tmp/daypass/transaction.log"

# Queries manifest metadata for a given package and field

manifest_lookup()
{
    field="$1"
    package="$2"

    jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
        --arg field "$field" \
'
.architectures[]?
| select(.name == $arch)
| .packages[]?
| select(
    (.package == $pkg)
    or
    (.package | startswith($pkg + "-"))
)
| .[$field] // empty
' \
"$MANIFEST_FILE" 2>/dev/null | head -n1
}


# Formats package size into human-readable units (KB / MB)

format_size()
{
    bytes="$1"
    if [ -z "$bytes" ] || [ "$bytes" = "null" ]; then
        echo "0 B"
        return
    fi

    if [ "$bytes" -ge 1048576 ]; then
        mb=$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}")
        echo "${mb} MB"
    elif [ "$bytes" -ge 1024 ]; then
        kb=$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")
        echo "${kb} KB"
    else
        echo "${bytes} Bytes"
    fi
}


# Fetches package details for UI display

manifest_info()
{
    package="$1"

    raw_size=$(manifest_lookup "size" "$package")
    formatted_size=$(format_size "$raw_size")
    file_name=$(manifest_lookup "file" "$package")

    echo "[$package] -> $file_name ($formatted_size)"
}


# Downloads and verifies package integrity against SHA256 checksum

download_package()
{
    package="$1"

    file=$(manifest_lookup "file" "$package")
    sha256=$(manifest_lookup "sha256" "$package")

    if [ -z "$file" ] || [ "$file" = "null" ]; then
        log_error "Package [$package] not found in manifest for architecture [$ARCH]!"
        return 1
    fi

    # download_base from manifest
    base_url=$(jq -r '.download_base // empty' "$MANIFEST_FILE" 2>/dev/null)
    
    if [ -n "$base_url" ]; then
        target_url="${base_url}/${file}"
    else
        target_url="${REPO_URL}/${file}"
    fi

    file_basename=$(basename "$file")
    target="$TMP_DIR/$file_basename"
    tmp="$target.part"

    mkdir -p "$(dirname "$target")"

    log_info "Processing Package : $(manifest_info "$package")"
    log_info "Target URL         : $target_url"
    log_info "Downloading [$package] ..."

    # Resilient download logic with fallback
    DOWNLOAD_SUCCESS=0
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$target_url" -o "$tmp" && DOWNLOAD_SUCCESS=1
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$tmp" "$target_url" && DOWNLOAD_SUCCESS=1
    elif command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch -q -O "$tmp" "$target_url" && DOWNLOAD_SUCCESS=1
    fi

    if [ "$DOWNLOAD_SUCCESS" -ne 1 ] || [ ! -s "$tmp" ]; then
        log_error "Download failed or produced empty file for : [$package]!"
        rm -f "$tmp"
        return 1
    fi

    # SHA256 Checksum Verification
    log_info "Verifying SHA256 checksum for : [$file_basename]!"
    if ! echo "$sha256  $tmp" | sha256sum -c - >/dev/null 2>&1; then
        log_error "Checksum verification FAILED for : [$package]!"
        log_warn "Expected Hash : [$sha256]"
        rm -f "$tmp"
        return 1
    fi

    mv "$tmp" "$target"
    log_success "Package [$package] verified successfully!"
}


# Orchestrates download, dependency resolution, and batch installation

deploy_targeted_packages()
{
    mkdir -p "$(dirname "$INSTALL_LOG")"
    touch "$INSTALL_LOG"
    
    # Initialize transaction log for rollback tracking
    rm -f "$TRANSACTION_LOG"
    touch "$TRANSACTION_LOG"

    if command -v pkg_update >/dev/null 2>&1; then
        pkg_update
    fi

    echo
    log_info "=================================================="
    log_info "Starting Package Deployment Pipeline"
    log_info "=================================================="
    echo

    # Resource check integration (if available)
    if command -v resource_snapshot >/dev/null 2>&1; then
        resource_snapshot
    fi

    if command -v estimate_install_size >/dev/null 2>&1; then
        estimate_install_size
    fi

    INSTALL_FILES=""

    # 1. Download and verify all target packages
    for pkg in $FINAL_PACKAGES; do
        if ! download_package "$pkg"; then
            log_error "Failed during download phase : [$pkg]"
            rollback_failed_install
            return 1
        fi

        file=$(manifest_lookup "file" "$pkg")
        file_basename=$(basename "$file")
        INSTALL_FILES="$INSTALL_FILES $TMP_DIR/$file_basename"
        
        # Record package in transaction log BEFORE installation
        echo "[$pkg]" >> "$TRANSACTION_LOG"
    done

    echo
    log_info "Batch installing resolved package files ..."
    log_info "Package List : [$FINAL_PACKAGES]"
    echo

    # 2. Perform installation via native package manager
    INSTALL_SUCCESS=0

    case "$PKG_MANAGER" in
        apk)
            log_info "Installing packages into system via APK..."
            APK_LOG=$(mktemp)
            
            if apk add --allow-untrusted --no-progress $INSTALL_FILES >"$APK_LOG" 2>&1; then
                INSTALL_SUCCESS=1
            else
                log_error "APK installation failed! Output:"
                cat "$APK_LOG"
            fi
            rm -f "$APK_LOG"
            ;;
        opkg)
            log_info "Installing packages into system via OPKG..."
            OPKG_LOG=$(mktemp)
            
            if opkg install $INSTALL_FILES >"$OPKG_LOG" 2>&1; then
                INSTALL_SUCCESS=1
            else
                log_error "OPKG installation failed! Output:"
                cat "$OPKG_LOG"
            fi
            rm -f "$OPKG_LOG"
            ;;
    esac

    # 3. Post-installation check and state commit
    if [ "$INSTALL_SUCCESS" -eq 1 ]; then
        echo "$FINAL_PACKAGES" >> "$INSTALL_LOG"
        
        if command -v resource_compare >/dev/null 2>&1; then
            resource_compare
        fi

        # Clear transaction log on successful deployment
        rm -f "$TRANSACTION_LOG"
        log_success "All targeted packages deployed successfully!"
        return 0
    fi

    log_error "Batch installation failed during package manager execution!"
    rollback_failed_install
    return 1
}


# Rolls back changes if installation fails mid-way

rollback_failed_install()
{
    echo
    log_warn "=================================================="
    log_warn "Initiating Automatic Rollback Procedures ..."
    log_warn "=================================================="
    echo

    if [ ! -s "$TRANSACTION_LOG" ]; then
        log_warn "Transaction log is empty! No installed packages to Rollback!"
        return 0
    fi

    case "$PKG_MANAGER" in
        opkg)
            while read -r pkg; do
                [ -z "$pkg" ] && continue
                log_info "Rollback : Removing package [$pkg] ..."
                opkg remove "$pkg" >/dev/null 2>&1 || log_warn "Could not remove : [$pkg]"
            done < "$TRANSACTION_LOG"
            ;;
        apk)
            while read -r pkg; do
                [ -z "$pkg" ] && continue
                log_info "Rollback : Removing package [$pkg] ..."
                apk del "$pkg" >/dev/null 2>&1 || log_warn "Could not remove : [$pkg]"
            done < "$TRANSACTION_LOG"
            ;;
    esac

    rm -f "$TRANSACTION_LOG"
    log_success "Rollback process completed!"
}

# 📄 Source : package_resolver.sh

resolve_packages()
{
    log_info "Resolving targeted packages and dependencies..."

    FINAL_PACKAGES=""

    add_final()
    {
        pkg="$1"
        [ -z "$pkg" ] && return

        case " $FINAL_PACKAGES " in
            *" $pkg "*) 
                # Already exists! skip
                ;;
            *) 
                if [ -z "$FINAL_PACKAGES" ]; then
                    FINAL_PACKAGES="$pkg"
                else
                    FINAL_PACKAGES="$FINAL_PACKAGES $pkg"
                fi
                log_info "  ├─ Resolved dependency : [$pkg]"
                ;;
        esac
    }

    # 1. Prerequisites / Low-level tools
    add_final "tcping"
    add_final "geoview"

    # 2. Famous DBs
    if [ "${SELECTED_GEO:-}" = "official" ]; then
        add_final "v2ray-geoip"
        add_final "v2ray-geosite"
    fi

    # 3. Engine Core
    case "${SELECTED_ENGINE:-auto}" in
        xray)     
            add_final "xray-core" 
            ;;
        sing-box) 
            add_final "sing-box" 
            ;;
        auto|*)     
            add_final "xray-core" 
            ;;
    esac

    # 4. User-selected custom packages (excluding main app and i18n to maintain strict hierarchy)
    if [ -n "${SELECTED_PACKAGES:-}" ]; then
        for pkg in $SELECTED_PACKAGES; do
            case "$pkg" in
                luci-app-passwall|luci-app-passwall2|luci-i18n-*) 
                    ;; # Skip here, will be added in controlled order below
                *) 
                    add_final "$pkg" 
                    ;;
            esac
        done
    fi

    # 5. Main Application Interface (MUST BE INSTALLED BEFORE TRANSLATION)
    case "${SELECTED_PROFILE:-}" in
        passwall2) add_final "luci-app-passwall2" ;;
        passwall)  add_final "luci-app-passwall" ;;
    esac

    # 6. Language and Translations (MUST BE INSTALLED AFTER MAIN APP)
    case "${SELECTED_LANGUAGE:-}" in
        fa)    add_final "luci-i18n-passwall2-fa" ;;
        zh-cn) add_final "luci-i18n-passwall2-zh-cn" ;;
        ru)    add_final "luci-i18n-passwall2-ru" ;;
    esac

    if [ -z "$FINAL_PACKAGES" ]; then
        log_error "Package resolution finished with an empty package list!"
        return 1
    fi

    log_success "Package resolution complete."
    log_info "Final target list : [$FINAL_PACKAGES]"

    export FINAL_PACKAGES
}

# 📄 Source : styles.sh

ESC="$(printf '\033')"

RESET="${ESC}[0m"
BOLD="${ESC}[1m"
DIM="${ESC}[2m"

BLACK="${ESC}[30m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
ORANGE="${ESC}[33m"
YELLOW="${ESC}[1;33m"
BLUE="${ESC}[34m"
PURPLE="${ESC}[35m"
PINK="${ESC}[1;35m"
CYAN="${ESC}[36m"
WHITE="${ESC}[37m"
GRAY="${ESC}[90m"

export RESET BOLD DIM CYAN GREEN YELLOW RED BLUE BLACK WHITE GRAY PURPLE ORANGE PINK


# 📄 Source : box_utils.sh

draw_bar()
{
    PCT="$1"
    BW="${2:-20}"
    MODE="${3:-usage}"
    
    [ "$PCT" -gt 100 ] && PCT=100
    [ "$PCT" -lt 0 ] && PCT=0

    FILLED=$(( PCT * BW / 100 ))

    if [ "$MODE" = "score" ]; then
        if [ "$PCT" -ge 80 ]; then COLOR="$GREEN"
        elif [ "$PCT" -ge 50 ]; then COLOR="$YELLOW"
        else COLOR="$RED"
        fi
    else
        if [ "$PCT" -ge 85 ]; then COLOR="$RED"
        elif [ "$PCT" -ge 60 ]; then COLOR="$YELLOW"
        else COLOR="$GREEN"
        fi
    fi

    BAR=""
    i=0
    while [ "$i" -lt "$FILLED" ]; do 
        BAR="${BAR}█"
        i=$((i+1))
    done
    while [ "$i" -lt "$BW" ]; do 
        BAR="${BAR}░"
        i=$((i+1))
    done

    printf "${COLOR}%s${RESET}" "$BAR"
}

log_warn()    { printf "   ${YELLOW}⚠️  %s${RESET}\n" "$1" >&2; }
log_info()    { printf "   ${CYAN}ℹ️  %s${RESET}\n" "$1"; }
log_success() { printf "   ${GREEN}✅  %s${RESET}\n" "$1"; }
log_error()   { printf "   ${RED}❌  %s${RESET}\n" "$1" >&2; }

SPINNER_FRAMES="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"

spinner_frame()
{
    IDX="$1"
    set -- $SPINNER_FRAMES
    COUNT=$#
    N=$(( IDX % COUNT + 1 ))
    I=1
    for F in "$@"; do
        if [ "$I" -eq "$N" ]; then
            printf "   %s" "$F"
            return
        fi
        I=$((I + 1))
    done
}

# 📄 Source : header.sh

render_persistent_header()
{
    clear
    show_banner
    # show_system_info
    # get_network_info
    echo
}

# 📄 Source : progress.sh

show_progress()
{
    title="$1"
    current="$2"
    total="$3"
    bar_width="${4:-20}"

    [ "$total" -le 0 ] && return

    # Calculate Percentage
    percent=$((current * 100 / total))
    [ "$percent" -gt 100 ] && percent=100

    # Calculate Fill width
    filled=$((percent * bar_width / 100))

    # Dynamic Color based on progress
    if [ "$percent" -eq 100 ]; then
        COLOR="${GREEN}"
    elif [ "$percent" -ge 50 ]; then
        COLOR="${CYAN}"
    else
        COLOR="${YELLOW}"
    fi

    # Build Bar String
    bar=""
    i=0
    while [ "$i" -lt "$filled" ]; do
        bar="${bar}█"
        i=$((i + 1))
    done

    while [ "$i" -lt "$bar_width" ]; do
        bar="${bar}░"
        i=$((i + 1))
    done

    # Print Real-time progress on same line (\r)
    printf "\r 📦 %-20s [${COLOR}%s${RESET}] ${BOLD}%3d%%${RESET} (%s/%s)" \
            "$title" "$bar" "$percent" "$current" "$total"

    # Print newline when task is complete
    [ "$current" -ge "$total" ] && echo
}

log_step()
{
    status="$1"
    message="$2"

    case "$status" in
        ok)   printf "   ${GREEN}✔ [  OK  ]${RESET} %s\n" "$message" ;;
        fail) printf "   ${RED}✖ [ FAIL ]${RESET} %s\n" "$message" >&2 ;;
        warn) printf "   ${YELLOW}⚠️ [ WARN ]${RESET} %s\n" "$message" ;;
        *)    printf "   ${CYAN}ℹ [ INFO ]${RESET} %s\n" "$message" ;;
    esac
}

# 📄 Source : zero_deps.sh

deploy_system_dependencies()
{
    echo "  🔎 Checking system dependencies ..."

    detect_package_manager
    pkg_update

    # 1st ca-bundle, ca-certificates that HTTPS working whell!
    REQUIRED_PACKAGES="ca-bundle ca-certificates curl jq"

    for pkg in $REQUIRED_PACKAGES; do
        if pkg_installed "$pkg"; then
            continue
        fi
        echo "  📦 Installing [$pkg] ..."
        pkg_install "$pkg"
    done

    if ! command -v curl >/dev/null 2>&1; then
        echo "  ⚠️ Warning : curl installation via [$PKG_MANAGER] failed. Falling back to wget ..."
    fi

    if [ -f /etc/openwrt_release ]; then
        echo
        echo "  🔎 Checking dnsmasq ..."

        if ! pkg_installed "dnsmasq-full"; then
            echo "  🔼 Upgrading dnsmasq to dnsmasq-full ..."
            case "$PKG_MANAGER" in
                opkg)
                    opkg install dnsmasq-full --replace-files >/dev/null 2>&1 || true
                    ;;
                apk)
                    apk add dnsmasq-full >/dev/null 2>&1 || true
                    ;;
            esac
        else
            echo "  💣 dnsmasq-full is already installed!"
        fi
    fi
}

# 📄 Source : version_check.sh

check_version() {
    if ! command -v opkg >/dev/null 2>&1 && ! command -v apk >/dev/null 2>&1; then
        log_error "No supported package manager found!"
        return 1
    fi

    OPENWRT_VERSION="$(
        . /etc/openwrt_release 2>/dev/null
        echo "$DISTRIB_RELEASE"
    )"

    if [ -z "$OPENWRT_VERSION" ]; then
        log_warn "Unable to detect OpenWrt version!"
    else
        log_info "OpenWrt Version : ${OPENWRT_VERSION}"
    fi
}

# 📄 Source : system_info.sh

detect_arch()
{
    if [ -f /etc/openwrt_release ]; then
        ARCH=$(grep "DISTRIB_ARCH" /etc/openwrt_release | cut -d"'" -f2)
    else
        case "$(uname -m)" in
            armv7l)  ARCH="arm_cortex-a7_neon-vfpv4" ;;
            aarch64) ARCH="aarch64_generic" ;;
            x86_64)  ARCH="x86_64" ;;
            *)       ARCH="$(uname -m)" ;;
        esac
    fi
    export ARCH
}

show_system_info_content()
{
    detect_arch
    
    OW_VER="Unknown"
    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        OW_VER="${DISTRIB_RELEASE:-Unknown}"
    fi

    TOTAL_RAM_MB=$(get_total_ram_mb)
    FREE_RAM_MB=$(get_free_ram_mb)
    USED_RAM_MB=$((TOTAL_RAM_MB - FREE_RAM_MB))
    
    MEM_PCT=0
    [ "$TOTAL_RAM_MB" -gt 0 ] && MEM_PCT=$((USED_RAM_MB * 100 / TOTAL_RAM_MB))

    TOTAL_STO_MB=$(get_total_storage_mb)
    FREE_STO_MB=$(get_free_storage_mb)
    USED_STO_MB=$((TOTAL_STO_MB - FREE_STO_MB))
    
    STO_PCT=0
    [ "$TOTAL_STO_MB" -gt 0 ] && STO_PCT=$((USED_STO_MB * 100 / TOTAL_STO_MB))

    # Tree-Style Clean Rendering
    printf " 🖥️  ${BOLD}System Overview${RESET}\n"
    printf " ├── 🩻 Architecture : ${CYAN}%s${RESET}\n" "$ARCH"
    printf " ├── 💡 OpenWrt      : ${CYAN}%s${RESET}\n" "$OW_VER"
    
    printf " ├── 🧠 Memory       : "
    draw_bar "$MEM_PCT" 16 "usage"
    printf " ${BOLD}%3d%%${RESET} (%s/%s MB)\n" "$MEM_PCT" "$USED_RAM_MB" "$TOTAL_RAM_MB"

    printf " └── 💾 Storage      : "
    draw_bar "$STO_PCT" 16 "usage"
    printf " ${BOLD}%3d%%${RESET} (%s/%s MB)\n" "$STO_PCT" "$USED_STO_MB" "$TOTAL_STO_MB"
    echo
}

show_system_info()
{
    echo
    show_system_info_content
}

case "$0" in
    *system_info.sh) show_system_info ;;
esac

# 📄 Source : network_info.sh

country_flag()
{
    case "$1" in
        IR) echo "🦁☀️" ;;
        AZ) echo "🇦🇿" ;;
        DE) echo "🇩🇪" ;;
        US) echo "🇺🇸" ;;
        NL) echo "🇳🇱" ;;
        RU) echo "🇷🇺" ;;
        CN) echo "🇨🇳" ;;
        JP) echo "🇯🇵" ;;
        SG) echo "🇸🇬" ;;
        TR) echo "🇹🇷" ;;
        GB) echo "🇬🇧" ;;
        FR) echo "🇫🇷" ;;
        FI) echo "🇫🇮" ;;
        SE) echo "🇸🇪" ;;
        PL) echo "🇵🇱" ;;
        *)  echo "🌐" ;;
    esac
}

fetch_ip_data()
{
    # Main
    NETWORK_JSON="$($FETCH_CMD https://ipwho.is/ 2>/dev/null || true)"
    if [ -n "$NETWORK_JSON" ] && echo "$NETWORK_JSON" | grep -q '"success":true'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.ip // "")|\(.country // "")|\(.country_code // "")|\(.flag.emoji // "")|\(.city // "")|\(.connection.isp // "")|\(.connection.asn // "")"' 2>/dev/null || echo "false|||||||"
        return 0
    fi

    # FallBack 1
    NETWORK_JSON="$($FETCH_CMD https://ipapi.co/json/ 2>/dev/null || true)"
    if [ -n "$NETWORK_JSON" ] && echo "$NETWORK_JSON" | grep -q '"ip"'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.ip // "")|\(.country_name // "")|\(.country_code // "")||\(.city // "")|\(.org // "")|\(.asn // "")"' 2>/dev/null || echo "false|||||||"
        return 0
    fi
    
    # FallBack 2
    NETWORK_JSON="$($FETCH_CMD https://ifconfig.co/json 2>/dev/null || true)"
    if [ -n "$NETWORK_JSON" ] && echo "$NETWORK_JSON" | grep -q '"ip"'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.ip // "")|\(.country // "")|\(.country_iso // "")||\(.city // "")|\(.asn_org // "")|\(.asn // "")"' 2>/dev/null || echo "false|||||||"
        return 0
    fi

    echo "false|||||||"
}

show_full_network_info()
{
    clear
    printf "\n   ${CYAN}🌐 Network Diagnostics & Information${RESET}\n"
    printf "   ${GRAY}─────────────────────────────────────────${RESET}\n"

    if command -v curl >/dev/null 2>&1; then
        FETCH_CMD="curl -fsS --connect-timeout 2 --max-time 4"
    elif command -v uclient-fetch >/dev/null 2>&1; then
        FETCH_CMD="uclient-fetch -q -T 4 -O-"
    else
        printf "   ${YELLOW}⚠️  curl / uclient-fetch unavailable!${RESET}\n\n"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        printf "   ${YELLOW}⚠️  jq is missing!${RESET}\n\n"
        return 0
    fi

    printf "   ${GRAY}Fetching network details ...${RESET}\r"
    PARSED_DATA="$(fetch_ip_data 2>/dev/null || echo "false|||||||")"

    IFS='|' read -r SUCCESS PUBLIC_IP COUNTRY COUNTRY_CODE FLAG CITY ISP ASN <<EOF
$PARSED_DATA
EOF

    if [ "${SUCCESS:-false}" != "true" ] || [ -z "$PUBLIC_IP" ]; then
        printf "   ${GRAY}IP      :${RESET} ${RED}Offline / Disconnected${RESET}\n"
        printf "   ${GRAY}Status  :${RESET} ${YELLOW}No Internet Access${RESET}\n"
    else
        if [ "$COUNTRY_CODE" = "IR" ]; then
            FLAG="🦁☀️"
        elif [ -z "$FLAG" ]; then
            FLAG="$(country_flag "$COUNTRY_CODE")"
        fi

        CITY_STR=""
        [ -n "$CITY" ] && CITY_STR=" ${GRAY}($CITY)${RESET}"

        printf "   Public IP   : $PUBLIC_IP\n"
        printf "   Country     : $FLAG $COUNTRY ${GRAY}$CITY_STR${RESET}\n"
        [ -n "$ISP" ] && printf "   ISP         : $ISP\n"
        [ -n "$ASN" ] && printf "   ASN         : ${GRAY}$ASN${RESET}\n"
    fi

    printf "   ${GRAY}─────────────────────────────────────────${RESET}\n\n"
}


network_menu()
{
    while true; do
        show_full_network_info
        
        printf "   📊 ${CYAN}1${RESET}) Live Speed Monitor\n"
        printf "   🔄 ${CYAN}2${RESET}) Refresh Information\n"
        printf "   ⬅️ ${CYAN}0${RESET}) Back to Main Menu\n\n"
        
        printf "   ⁉️ ${YELLOW}Select${RESET} ${GRAY}:${RESET} "
        read -r net_choice </dev/tty

        case "$net_choice" in
            1) show_live_speed ;;
            2) continue ;;
            0) break ;;
            *) log_warn "Invalid choice!" ;;
        esac
    done
}

show_live_speed() {
    IFACE=$(uci get network.wan.device 2>/dev/null || echo "wan")
    [ ! -d "/sys/class/net/$IFACE" ] && IFACE="eth0"

    echo
    MSG="Monitoring live speed on [${CYAN}$IFACE${RESET}] ${GRAY}(Press Ctrl+C to stop)...${RESET}"
    if command -v log_info >/dev/null 2>&1; then
        log_info "$MSG"
    else
        echo "$MSG"
    fi
    echo

    RX_PREV=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
    TX_PREV=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)

    trap 'echo ""; return 0' INT

    while true; do
        sleep 1
        RX_NOW=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        TX_NOW=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)

        RX_SPEED=$(( (RX_NOW - RX_PREV) / 1024 ))
        TX_SPEED=$(( (TX_NOW - TX_PREV) / 1024 ))

        if [ "$RX_SPEED" -gt 1024 ]; then
            RX_FMT="$(awk "BEGIN {printf \"%.2f MB/s\", $RX_SPEED/1024}")"
        else
            RX_FMT="${RX_SPEED} KB/s"
        fi

        if [ "$TX_SPEED" -gt 1024 ]; then
            TX_FMT="$(awk "BEGIN {printf \"%.2f MB/s\", $TX_SPEED/1024}")"
        else
            TX_FMT="${TX_SPEED} KB/s"
        fi

        printf "\r   📥 ${GREEN}Down:${RESET} %s%-10s%s ${GRAY}|${RESET}    📤 ${YELLOW}Up:${RESET} %s%-10s%s\033[K" \
            "$GREEN" "$RX_FMT" "$RESET" \
            "$YELLOW" "$TX_FMT" "$RESET"

        RX_PREV=$RX_NOW
        TX_PREV=$TX_NOW
    done
}

case "$0" in
    *network_checker.sh|*network_info.sh) network_menu ;;
esac

# 📄 Source : resource_monitor.sh

get_free_ram_mb()
{
    FREE_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    [ -z "$FREE_KB" ] && FREE_KB=$(grep MemFree /proc/meminfo | awk '{print $2}')
    echo $((FREE_KB / 1024))
}

get_total_ram_mb()
{
    TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $((TOTAL_KB / 1024))
}

get_free_storage_mb()
{
    TARGET="/"
    [ -d /overlay ] && TARGET="/overlay"
    df -k "$TARGET" | awk 'END {printf "%.0f\n", $4 / 1024}'
}

get_total_storage_mb()
{
    TARGET="/"
    [ -d /overlay ] && TARGET="/overlay"
    df -k "$TARGET" | awk 'END {printf "%.0f\n", $2 / 1024}'
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

    if [ "$SNAPSHOT_RAM_FREE" -gt "$CURRENT_RAM_FREE" ]; then
        RAM_USED=$((SNAPSHOT_RAM_FREE - CURRENT_RAM_FREE))
    else
        RAM_USED=0
    fi

    if [ "$SNAPSHOT_STORAGE_FREE" -gt "$CURRENT_STORAGE_FREE" ]; then
        STORAGE_USED=$((SNAPSHOT_STORAGE_FREE - CURRENT_STORAGE_FREE))
    else
        STORAGE_USED=0
    fi

    RAM_STR="${RAM_USED} MB"
    STORAGE_STR="${STORAGE_USED} MB"

    echo
    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │ 📊 System Resource Impact                                 │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    printf "  │ 🧠 RAM Consumed     : %-35s │\n" "$RAM_STR"
    printf "  │ 💾 Storage Consumed : %-35s │\n" "$STORAGE_STR"
    echo "  └───────────────────────────────────────────────────────────┘"
    echo
}

estimate_install_size()
{
    TOTAL_SIZE=0

    for pkg in $FINAL_PACKAGES; do
        size="$(manifest_lookup "size" "$pkg")"

        [ -z "$size" ] || [ "$size" = "null" ] && continue
        TOTAL_SIZE=$((TOTAL_SIZE + size))
    done

    if [ "$TOTAL_SIZE" -lt 1048576 ]; then
        SIZE_DISPLAY="$((TOTAL_SIZE / 1024)) KB"
    else
        SIZE_DISPLAY="$(( (TOTAL_SIZE + 1048575) / 1048576 )) MB"
    fi

    PKG_COUNT=$(echo "$FINAL_PACKAGES" | wc -w | tr -d ' ')

    echo
    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │ 📥 Download & Deployment Estimate                         │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    printf "  │ 📦 Packages Count   : %-35s │\n" "${PKG_COUNT:-0}"
    printf "  │ 💾 Total Download   : %-35s │\n" "$SIZE_DISPLAY"
    echo "  └───────────────────────────────────────────────────────────┘"
    echo
}

# 📄 Source : dns_fix.sh

BACKUP_DNS_FILE="/etc/resolv.conf.daypass.bak"

apply_dns()
{
    NEW_DNS="${1:-1.1.1.1}"
    log_info "Setting temporary DNS to : [$NEW_DNS]"

    if [ -f /etc/resolv.conf ]; then

        if [ ! -f "$BACKUP_DNS_FILE" ]; then
            cp /etc/resolv.conf "$BACKUP_DNS_FILE" 2>/dev/null
            log_success "Original DNS backed up to : [$BACKUP_DNS_FILE]"
        fi

        echo "nameserver $NEW_DNS" > /etc/resolv.conf
        log_success "DNS changed to : [$NEW_DNS]"
    fi
}

restore_dns()
{
    if [ -f "$BACKUP_DNS_FILE" ]; then
        cp "$BACKUP_DNS_FILE" /etc/resolv.conf 2>/dev/null
        rm -f "$BACKUP_DNS_FILE" 2>/dev/null
        log_success "Original DNS restored successfully!"
    else
        log_warn "No DNS backup found to restore!"
    fi
}

dns_fix_menu()
{
    render_persistent_header

    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │ 📡 DNS Resolution Recovery                                │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    echo "  │  1) ☁️  Cloudflare DNS (1.1.1.1)                           │"
    echo "  │  2) 🔍 Google DNS     (8.8.8.8)                           │"
    echo "  │  3) 🛡️ Quad9 DNS      (9.9.9.9)                           │"
    
    if [ -f "$BACKUP_DNS_FILE" ]; then
        echo "  │  4) 🔄 Restore Original DNS                               │"
        echo "  │  5) 🚫 Skip                                               │"
        MAX_OPT="5"
    else
        echo "  │  4) 🚫 Skip                                               │"
        MAX_OPT="4"
    fi
    echo "  └───────────────────────────────────────────────────────────┘"
    echo

    printf "  ⁉️  Select option [1-%s] (Default: 1) : " "$MAX_OPT"
    read -r dns_choice </dev/tty

    case "$dns_choice" in
        1|"")
            apply_dns "1.1.1.1"
            ;;
        2)
            apply_dns "8.8.8.8"
            ;;
        3)
            apply_dns "9.9.9.9"
            ;;
        4) 
            if [ -f "$BACKUP_DNS_FILE" ]; then
                restore_dns
            else
                log_info "Skipping DNS fix."
            fi
            ;;
        *)
            log_info "Skipping DNS fix."
            ;;
    esac
}

# 📄 Source : banner.sh

show_banner()
{
    detect_arch
    
    OW_VER="Unknown"
    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        OW_VER="${DISTRIB_RELEASE:-Unknown}"
    fi

    TOTAL_RAM_MB=$(get_total_ram_mb 2>/dev/null || echo 0)
    FREE_RAM_MB=$(get_free_ram_mb 2>/dev/null || echo 0)
    USED_RAM_MB=$((TOTAL_RAM_MB - FREE_RAM_MB))

    TOTAL_STO_MB=$(get_total_storage_mb 2>/dev/null || echo 0)
    FREE_STO_MB=$(get_free_storage_mb 2>/dev/null || echo 0)
    USED_STO_MB=$((TOTAL_STO_MB - FREE_STO_MB))

    echo

    L1="    ____              ____"
    L2="   |  _ \  __ _ _   _|  _ \  __ _ ___ ___"
    L3="   | | | |/ _\` | | | | |_) / _\` / __/ __|"
    L4="   | |_| | (_| | |_| |  __/ (_| \__ \__ \\\\"
    L5="   |____/ \__,_|\__, |_|   \__,_|___/___/"
    L6="                |___/"

    printf " ${CYAN}%-43s${RESET}\n" "$L1"
    printf " ${CYAN}%-43s${RESET}       🐱 ${WHITE}github.com/Chamroosh98${RESET}\n" "$L2"
    printf " ${CYAN}%-43s${RESET}       🩻 ${WHITE}Architecture : %s${RESET}\n" "$L3" "$ARCH"
    printf " ${CYAN}%-43s${RESET}       💡 ${WHITE}OpenWrt      : %s${RESET}\n" "$L4" "$OW_VER"
    printf " ${CYAN}%-43s${RESET}       🧠 ${WHITE}Memory       : %s/%s MB${RESET}\n" "$L5" "$USED_RAM_MB" "$TOTAL_RAM_MB"
    printf " ${CYAN}%-43s${RESET}       💾 ${WHITE}Storage      : %s/%s MB${RESET}\n" "$L6" "$USED_STO_MB" "$TOTAL_STO_MB"
    
    # printf "                ${GRAY}%s${RESET}\n" "${VERSION:-v2.1.0}"

    echo
    printf " ${GRAY}───────────────────── 🕊️  Remembering the IRAN Massacre on Jan 8-9, 2026 ─────────────────────${RESET}\n"
    echo
}

# 📄 Source : state.sh

SELECTED_PROFILE=""
SELECTED_ENGINE="auto"
SELECTED_LANGUAGE="none"
SELECTED_GEO="none"
SELECTED_PACKAGES=""
GEOIP_URL=""
GEOSITE_URL=""

add_selected_package()
{
    pkg="$1"
    [ -z "$pkg" ] && return

    case " $SELECTED_PACKAGES " in
        *" $pkg "*) ;;
        *) SELECTED_PACKAGES="$SELECTED_PACKAGES $pkg" ;;
    esac
}

reset_state()
{
    SELECTED_PROFILE=""
    SELECTED_ENGINE="auto"
    SELECTED_LANGUAGE="none"
    SELECTED_GEO="none"
    SELECTED_PACKAGES=""
    GEOIP_URL=""
    GEOSITE_URL=""
}

# 📄 Source : menu_recommended.sh

handle_recommended_profile()
{
    # Clear manually selected packages so resolver handles strict ordering
    SELECTED_PACKAGES=""
    export SELECTED_PACKAGES
}

# 📄 Source : menu_custom.sh

handle_custom_profile()
{
    ALL_AVAILABLE_PKGS="$(jq -r --arg arch "$ARCH" '.architectures[] | select(.name==$arch) | .packages[].package' "$MANIFEST_FILE" 2>/dev/null)"

    if [ -z "$ALL_AVAILABLE_PKGS" ]; then
        log_error "No packages found in manifest for architecture: $ARCH"
        return 1
    fi

    PAGE_SIZE=5
    CURRENT_PAGE=1
    TOTAL_PKGS=$(echo "$ALL_AVAILABLE_PKGS" | wc -w)
    TOTAL_PAGES=$(( (TOTAL_PKGS + PAGE_SIZE - 1) / PAGE_SIZE ))
    
    FIRST_RENDER=1

    while true; do
        render_persistent_header

        SEL_COUNT=0
        for _p in $SELECTED_PACKAGES; do
            SEL_COUNT=$((SEL_COUNT + 1))
        done

        echo "  🛠️  ${BOLD}Custom Package Selection${RESET} ${GRAY}(Page ${YELLOW}$CURRENT_PAGE${RESET}${GRAY}/$TOTAL_PAGES | Selected: ${GREEN}$SEL_COUNT${RESET}${GRAY})${RESET}"
        echo "  ${GRAY}──────────────────────────────────────────────────────────${RESET}"

        START_IDX=$(( (CURRENT_PAGE - 1) * PAGE_SIZE + 1 ))
        END_IDX=$(( CURRENT_PAGE * PAGE_SIZE ))

        i=1
        item_no=1
        eval set -- "$ALL_AVAILABLE_PKGS"
        
        for pkg in "$@"; do
            if [ "$i" -ge "$START_IDX" ] && [ "$i" -le "$END_IDX" ]; then
                
                is_selected="${GRAY}[ ]${RESET}"
                case " $SELECTED_PACKAGES " in
                    *" $pkg "*) is_selected="${GREEN}[✔]${RESET}" ;;
                esac
                
                printf "   ${CYAN}%d${RESET}) %b %s\n" "$item_no" "$is_selected" "$pkg"
                
                if [ "$FIRST_RENDER" -eq 1 ]; then
                    command -v usleep >/dev/null 2>&1 && usleep 12000
                fi

                item_no=$((item_no + 1))
            fi
            i=$((i + 1))
        done

        FIRST_RENDER=0

        echo "  ${GRAY}──────────────────────────────────────────────────────────${RESET}"
        echo "   ${GRAY}[${CYAN}n${RESET}${GRAY}] Next Page  |  [${CYAN}p${RESET}${GRAY}] Prev Page  |  [${GREEN}d${RESET}${GRAY}] Done Selection${RESET}"
        echo

        printf "   ⁉️  ${YELLOW}Toggle Item${RESET} ${GRAY}(1-$((item_no - 1))) or Action (${CYAN}n${RESET}${GRAY}/${CYAN}p${RESET}${GRAY}/${GREEN}d${RESET}${GRAY}) :${RESET} "
        read -r cmd </dev/tty

        case "$cmd" in
            n|N)
                [ "$CURRENT_PAGE" -lt "$TOTAL_PAGES" ] && CURRENT_PAGE=$((CURRENT_PAGE + 1))
                ;;
            p|P)
                [ "$CURRENT_PAGE" -gt 1 ] && CURRENT_PAGE=$((CURRENT_PAGE - 1))
                ;;
            d|D)
                log_info "Custom package selection saved."
                break
                ;;
            [1-9])
                TARGET_INDEX=$(( START_IDX + cmd - 1 ))
                idx=1
                for pkg in "$@"; do
                    if [ "$idx" -eq "$TARGET_INDEX" ]; then
                        add_selected_package "$pkg"
                        break
                    fi
                    idx=$((idx + 1))
                done
                ;;
            *)
                log_warn "Invalid command!"
                sleep 1
                ;;
        esac
    done
}

# 📄 Source : menu_mode.sh

menu_mode()
{
    render_persistent_header

    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │  🕵️‍♀️ Select Installation Mode                              │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    echo "  │  1) ⚡ Recommended (Quick & Pre-configured for users)     │"
    echo "  │  2) 🛠️ Custom      (Advanced package selection)           │"
    echo "  └───────────────────────────────────────────────────────────┘"
    echo

    printf "  ⁉️ Select option [1-2] (Default: 1) : "
    read -r choice </dev/tty

    case "$choice" in
        1|"")
            handle_recommended_profile
            ;;
        2)
            handle_custom_profile
            ;;
        *)
            log_warn "Invalid choice! Defaulting to Recommended mode!"
            handle_recommended_profile
            ;;
    esac
}

# 📄 Source : engine_menu.sh

engine_menu()
{
    render_persistent_header

    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │  🕵️‍♀️  Select Proxy Engine                                  │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    echo "  │  1) ⚡ Auto      (Recommended)                            │"
    echo "  │  2) ✖️ Xray      (Xray-core proxy engine)                 │"
    echo "  │  3) 📦 Sing-box  (Sing-box proxy engine)                  │"
    echo "  └───────────────────────────────────────────────────────────┘"
    echo

    printf "  ⁉️ Select option [1-3] (Default: 1) : "
    read -r choice </dev/tty

    case "$choice" in
        1|"")
            SELECTED_ENGINE="auto"
            ;;
        2)
            SELECTED_ENGINE="xray"
            add_selected_package "xray-core"
            ;;
        3)
            SELECTED_ENGINE="sing-box"
            echo
            log_warn "Sing-box may consume higher RAM on low-end hardware!"
            echo
            printf "  ⁉️  Are you sure you want to proceed with Sing-box? [y/N] : "
            read -r confirm </dev/tty

            case "$confirm" in
                y|Y)
                    add_selected_package "sing-box"
                    ;;
                *)
                    log_info "Reverting Proxy Engine selection to Auto."
                    SELECTED_ENGINE="auto"
                    ;;
            esac
            ;;
        *)
            log_warn "Invalid choice! Defaulting to Auto engine."
            SELECTED_ENGINE="auto"
            ;;
    esac

    export SELECTED_ENGINE
}

# 📄 Source : menu_language.sh

language_menu()
{
    if [ "$SELECTED_PROFILE" != "passwall2" ]; then
        SELECTED_LANGUAGE="en"
        export SELECTED_LANGUAGE
        return 0
    fi

    render_persistent_header

    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │  🕵️‍♀️ Select Language (Passwall 2)                          │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    echo "  │  1) 🦁☀️ Persian  (fa)                                    │"
    echo "  │  2) 🇬🇧   English  (en)                                    │"
    echo "  │  3) 🇨🇳   Chinese  (zh-cn)                                 │"
    echo "  │  4) 🇷🇺   Russian  (ru)                                    │"
    echo "  └───────────────────────────────────────────────────────────┘"
    echo

    printf "  ⁉️ Select option [1-4] (Default: 1) : "
    read -r choice </dev/tty

    case "$choice" in
        1|"")
            SELECTED_LANGUAGE="fa"
            add_selected_package "luci-i18n-passwall2-fa"
            ;;
        2)
            SELECTED_LANGUAGE="en"
            ;;
        3)
            SELECTED_LANGUAGE="zh-cn"
            add_selected_package "luci-i18n-passwall2-zh-cn"
            ;;
        4)
            SELECTED_LANGUAGE="ru"
            add_selected_package "luci-i18n-passwall2-ru"
            ;;
        *)
            log_warn "Invalid choice! Defaulting to English."
            SELECTED_LANGUAGE="en"
            ;;
    esac

    export SELECTED_LANGUAGE
}

# 📄 Source : menu_geo.sh

geo_menu()
{
    render_persistent_header

    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │  🕵️‍♀️ Select Geo Database                                    │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    echo "  │  1) Skip       (Do not install Geo databases)             │"
    echo "  │  2) Official   (Standard official release packages)       │"
    echo "  │  3) Iran Full  (Custom ruleset - Full database)           │"
    echo "  │  4) Iran Lite  (Custom ruleset - Compact database)        │"
    echo "  └───────────────────────────────────────────────────────────┘"
    echo

    printf "  ⁉️ Select option [1-4] (Default: 1) : "
    read -r choice </dev/tty

    GEOIP_URL=""
    GEOSITE_URL=""

    case "$choice" in
        1|"")
            SELECTED_GEO="none"
            ;;
        2)
            SELECTED_GEO="official"
            add_selected_package "v2ray-geoip"
            add_selected_package "v2ray-geosite"
            ;;
        3)
            SELECTED_GEO="iran-full"
            GEOIP_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geoip.dat"
            GEOSITE_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geosite.dat"
            ;;
        4)
            SELECTED_GEO="iran-lite"
            GEOIP_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geoip-lite.dat"
            GEOSITE_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geosite-lite.dat"
            ;;
        *)
            log_warn "Invalid choice! Defaulting to Skip."
            SELECTED_GEO="none"
            ;;
    esac

    export SELECTED_GEO
    export GEOIP_URL
    export GEOSITE_URL
}

# 📄 Source : review.sh

review_install()
{
    resolve_packages

    clear
    
    [ -n "$(command -v render_persistent_header)" ] && render_persistent_header

    echo "  📊 Installation Plan Summary"
    echo "  ─────────────────────────────────────────────────────────────"
    printf "  %-18s : %s\n" "👤 Selected Profile" "${SELECTED_PROFILE:-N/A}"
    printf "  %-18s : %s\n" "⚙️ Selected Engine"  "${SELECTED_ENGINE:-auto}"
    printf "  %-18s : %s\n" "🗣️ Language"         "${SELECTED_LANGUAGE:-none}"
    printf "  %-18s : %s\n" "🌐 Geo Database"     "${SELECTED_GEO:-none}"
    echo "  ─────────────────────────────────────────────────────────────"
    
    PKG_COUNT=$(echo $FINAL_PACKAGES | wc -w | tr -d ' ')
    echo "  📦 Targeted Packages (${PKG_COUNT:-0}) :"

    i=0
    for pkg in $FINAL_PACKAGES; do
        i=$((i + 1))
        if [ "$i" -eq "$PKG_COUNT" ]; then
            echo "     └─ 🔹 $pkg"
        else
            echo "     ├─ 🔹 $pkg"
        fi
    done
    echo "  ─────────────────────────────────────────────────────────────"
    echo

    while true; do
        printf "  ⁉️  Continue with installation? [y/N] : "
        read -r confirm </dev/tty

        case "$confirm" in
            y|Y)
                return 0
                ;;
            n|N|"")
                log_warn "Installation cancelled by user."
                return 1
                ;;
            *)
                log_error "Invalid input! Please enter Y or N!"
                ;;
        esac
    done
}

# 📄 Source : menu_package.sh

package_menu()
{
    render_persistent_header

    echo "  ┌───────────────────────────────────────────────────────────┐"
    echo "  │  🕵️‍♀️ Select Package Type                                   │"
    echo "  ├───────────────────────────────────────────────────────────┤"
    echo "  │  🔒 1) Passwall-1  (Legacy Stable Release)                │"
    echo "  │  🔒 2) Passwall-2  (Modern Release - Recommended)         │"
    echo "  └───────────────────────────────────────────────────────────┘"
    echo

    printf "  ⁉️ Select option [1-2] : "
    read -r choice </dev/tty

    # Reset manual selections to let resolver handle exact dependency hierarchy
    SELECTED_PACKAGES=""

    case "$choice" in
        1)
            SELECTED_PROFILE="passwall"
            ;;
        2)
            SELECTED_PROFILE="passwall2"
            ;;
        *)
            log_error "Invalid choice! Returning to menu ..."
            sleep 1
            return 1
            ;;
    esac

    export SELECTED_PROFILE

    # 1. Select Mode (Recommended / Custom) via modular menu
    menu_mode

    # 2. Select Engine, Language and Geo if Custom mode requires
    if [ "${SELECTED_MODE:-}" = "custom" ]; then
        engine_menu || return 1
        language_menu || return 1
        geo_menu || return 1
    else
        SELECTED_ENGINE="xray"
        SELECTED_LANGUAGE="fa"
        SELECTED_GEO="official"
        export SELECTED_ENGINE SELECTED_LANGUAGE SELECTED_GEO
    fi

    # 3. Review Summary Screen
    review_install || return 1

    # 4. Deployment Pipeline
    render_persistent_header
    if deploy_targeted_packages; then
        echo
        log_success "All targeted components deployed successfully!"
        echo
        printf "  ${GRAY}Press [ENTER] to return to main menu ...${NC}"
        read -r _ </dev/tty
        render_persistent_header
    else
        echo
        log_error "Installation process failed!"
        echo
        printf "  ${GRAY}Press [ENTER] to return to main menu ...${NC}"
        read -r _ </dev/tty
        render_persistent_header
        return 1
    fi

    return 0
}

# 📄 Source : main_menu.sh

main_menu()
{
    while true; 
        do
            show_banner
            # show_system_info
            echo

            printf "   📦 1) Install Package\n"
            printf "   🖥️ 2) Network Info & Speed Monitor\n"
            printf "   🚪 0) Exit\n\n"

            printf "   ⁉️ Select option [0-2] : "
            read -r choice </dev/tty

            case "$choice" in
                1)
                    if command -v package_menu >/dev/null 2>&1; then
                        package_menu || true
                    fi
                    ;;
                2)
                    if command -v network_menu >/dev/null 2>&1; then
                        network_menu || true
                    fi
                    ;;
                0)
                    log_info "Exiting DayPass ..."
                    exit 0
                    ;;
                *)
                    log_warn "Invalid choice!"
                    sleep 3
                    clear
                    ;;
            esac
        done
}

###############################################################################
# Runtime Execution Pipeline
###############################################################################
DEPLOYMENT_FAILED=0

# 🔴🔴🔴🔴🔴🔴🔴 The execution order of the modules is important! 🔴🔴🔴🔴🔴🔴🔴
# ============= Checking network connection =============
network_check || exit 1

# ============= Installing requirements =================
deploy_system_dependencies

# Continue initialization
check_version
detect_arch
initialize_installer

# ============= Pre-TUI Smooth Transition =============
for i in 3 2 1; do
    printf "\r🚀 Launching DayPass Interactive UI in \033[1;33m%d\033[0m seconds... (Press \033[1;36m[Enter]\033[0m to skip) " "$i"
    if read -t 1 -r; then
        break
    fi
done

# Launching TUI Interface
clear
reset_state
main_menu

# Execution
deploy_targeted_packages

echo
echo "🎉 DayPass installation completed successfully! ;))"
exit 0
