#!/usr/bin/env bash

set -euo pipefail

DAYPASS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DAYPASS_ROOT

# Directories
DAYPASS_CONFIG_DIR="$DAYPASS_ROOT/config"
DAYPASS_CORE_DIR="$DAYPASS_ROOT/core"
DAYPASS_PROVIDER_DIR="$DAYPASS_ROOT/providers"
DAYPASS_METADATA_DIR="$DAYPASS_ROOT/metadata"
DAYPASS_INSTALLER_DIR="$DAYPASS_ROOT/installer"
DAYPASS_MODULE_DIR="$DAYPASS_ROOT/modules"
DAYPASS_UI_DIR="$DAYPASS_ROOT/ui"

DAYPASS_CACHE_DIR="$DAYPASS_ROOT/cache"
DAYPASS_TEMP_DIR="$DAYPASS_ROOT/temp"
DAYPASS_OUTPUT_DIR="$DAYPASS_ROOT/output"

# Config Files
DAYPASS_ARCH_FILE="$DAYPASS_CONFIG_DIR/architectures.json"
DAYPASS_PROVIDER_FILE="$DAYPASS_CONFIG_DIR/providers.json"
DAYPASS_SETTINGS_FILE="$DAYPASS_CONFIG_DIR/settings.json"

# Runtime
DAYPASS_LOG_FILE="$DAYPASS_TEMP_DIR/daypass.log"

# Cache
DAYPASS_INDEX_CACHE="$DAYPASS_CACHE_DIR/index"
DAYPASS_PACKAGE_CACHE="$DAYPASS_CACHE_DIR/packages"
DAYPASS_METADATA_CACHE="$DAYPASS_CACHE_DIR/metadata"
DAYPASS_CHECKSUM_CACHE="$DAYPASS_CACHE_DIR/checksums"

# Output
DAYPASS_INSTALL_SCRIPT="$DAYPASS_OUTPUT_DIR/install.sh"

# Default Provider
DAYPASS_PROVIDER="sourceforge"

# Default Branch
DAYPASS_BRANCH="stable"

# Default Release
DAYPASS_RELEASE="latest"

# Default Package Manager
DAYPASS_PACKAGE_MANAGER=""

# Architecture
DAYPASS_ARCH=""

# Repository
DAYPASS_REPOSITORY=""

###############################################################################
# Create Runtime Directories
###############################################################################

mkdir -p \
"$DAYPASS_CACHE_DIR" \
"$DAYPASS_TEMP_DIR" \
"$DAYPASS_OUTPUT_DIR" \
"$DAYPASS_INDEX_CACHE" \
"$DAYPASS_PACKAGE_CACHE" \
"$DAYPASS_METADATA_CACHE" \
"$DAYPASS_CHECKSUM_CACHE"

###############################################################################
# Export
###############################################################################

export DAYPASS_ROOT

export DAYPASS_CONFIG_DIR
export DAYPASS_CORE_DIR
export DAYPASS_PROVIDER_DIR
export DAYPASS_METADATA_DIR
export DAYPASS_INSTALLER_DIR
export DAYPASS_MODULE_DIR
export DAYPASS_UI_DIR

export DAYPASS_CACHE_DIR
export DAYPASS_TEMP_DIR
export DAYPASS_OUTPUT_DIR

export DAYPASS_ARCH_FILE
export DAYPASS_PROVIDER_FILE
export DAYPASS_SETTINGS_FILE

export DAYPASS_LOG_FILE

export DAYPASS_INDEX_CACHE
export DAYPASS_PACKAGE_CACHE
export DAYPASS_METADATA_CACHE
export DAYPASS_CHECKSUM_CACHE

export DAYPASS_INSTALL_SCRIPT

export DAYPASS_PROVIDER
export DAYPASS_BRANCH
export DAYPASS_RELEASE

export DAYPASS_PACKAGE_MANAGER
export DAYPASS_ARCH
export DAYPASS_REPOSITORY