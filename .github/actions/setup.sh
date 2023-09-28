#!/bin/bash

set -eo pipefail

# Check for the required jq tool
command -v jq &>/dev/null || { echo "Please install 'jq'. See https://stedolan.github.io/jq/download/"; exit 1; }

# Constants
OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
MANIFEST_JSON_PATH="releases_${OS_NAME}.json"
MANIFEST_URL="https://storage.googleapis.com/flutter_infra_release/releases/${MANIFEST_JSON_PATH}"
FLUTTER_DIR="$HOME/flutter"
CACHE_DIR="$RUNNER_TEMP/flutter_cache"

# Local manifest path
LOCAL_MANIFEST_PATH="$RUNNER_TEMP/$MANIFEST_JSON_PATH"

# Function to download the releases file if it doesn't exist locally
download_manifest_if_not_exists() {
    if [[ ! -f "$LOCAL_MANIFEST_PATH" ]]; then
        echo "Downloading Flutter releases manifest..."
        mkdir -p "$(dirname "$LOCAL_MANIFEST_PATH")"
        curl --connect-timeout 15 --retry 5 -o "$LOCAL_MANIFEST_PATH" "$MANIFEST_URL"
    else
        echo "Using existing Flutter releases manifest at $LOCAL_MANIFEST_PATH"
    fi
}

# Function to download and extract an archive
download_and_extract_archive() {
    local archive_url="$1"
    local target_dir="$2"
    
    mkdir -p "$CACHE_DIR"
    local archive_name=$(basename "$archive_url")
    local archive_local="$CACHE_DIR/$archive_name"
    
    curl --connect-timeout 15 --retry 5 -o "$archive_local" "$archive_url"
    
    if [[ "$archive_name" == *.zip ]]; then
        unzip -q -o "$archive_local" -d "$target_dir"
    else
        tar xf "$archive_local" -C "$target_dir" --strip-components=1
    fi
    
    rm -f "$archive_local"
}

# Function to filter JSON data by channel, architecture, and version
filter_manifest() {
    local channel="$1"
    local arch="$2"
    local version="$3"
    
    jq --arg channel "$channel" --arg arch "$arch" --arg version "$version" '
        .releases[] | select(
            ($channel == "any" or .channel == $channel) and
            ($arch == "x64" or .dart_sdk_arch == $arch or (.dart_sdk_arch | not)) and
            ($version == "any" or .version == $version or
                (.version | startswith(($version | sub("\\.x$"; "")) + ".")) and
                .version != $version))
    ' "$LOCAL_MANIFEST_PATH"
}

# Function to set up Flutter
setup_flutter() {
    local channel="$1"
    local version="$2"
    local arch="$3"
    local cache="$4"

    download_manifest_if_not_exists  # Download releases file if not exists locally

    # Use the local manifest file
    MANIFEST_JSON_PATH="$LOCAL_MANIFEST_PATH"

    [[ "$channel" == "master" ]] && FLUTTER_VERSION="master" || {
        local version_manifest=$(filter_manifest "$channel" "$arch" "$version")
        [[ -n "$version_manifest" ]] || { echo "Unable to determine Flutter version."; exit 1; }
        FLUTTER_VERSION=$(echo "$version_manifest" | jq -r '.version')
    }
    
    local archive_url="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_VERSION}/flutter_${OS_NAME}_${arch}.tar.xz"
    
    # Download and extract the Flutter archive
    download_and_extract_archive "$archive_url" "$FLUTTER_DIR"
    
    # Add Flutter to the PATH
    export PATH="$FLUTTER_DIR/bin:$PATH"
    
    # Output Flutter version
    echo "installed-version=${FLUTTER_VERSION}"
    
    # Output cache path if caching is enabled
    [[ "$cache" == "true" ]] && echo "sdk-cache-path=${CACHE_DIR}"
}

# Main script logic
[[ -z "$RUNNER_OS" ]] && { echo "This script is intended for use in GitHub Actions workflows."; exit 1; }

[[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"

setup_flutter "$1" "$2" "$3" "$4"
