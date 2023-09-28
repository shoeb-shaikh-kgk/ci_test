#!/bin/bash

# Constants
MANIFEST_BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases"
OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
MANIFEST_JSON_PATH="releases_${OS_NAME}.json"
MANIFEST_URL="$MANIFEST_BASE_URL/$MANIFEST_JSON_PATH"
CACHE_DIR="$RUNNER_TEMP/flutter_cache"
FLUTTER_DIR="$HOME/flutter"

# Function to check if a command is available
check_command() {
    command -v "$1" >/dev/null 2>&1
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

# Check for the required jq tool
if ! check_command jq; then
    echo "jq not found, please install it, https://stedolan.github.io/jq/download/"
    exit 1
fi

# Function to download the manifest file if it doesn't exist
download_manifest() {
    if [[ ! -f "$MANIFEST_JSON_PATH" ]]; then
        echo "Downloading Flutter releases manifest..."
        curl --connect-timeout 15 --retry 5 -o "$MANIFEST_JSON_PATH" "$MANIFEST_URL"
    fi
}

# Main function to set up Flutter
setup_flutter() {
    local channel="$1"
    local version="$2"
    local arch="$3"
    local cache="$4"
    
    # Download the manifest file if it doesn't exist
    download_manifest
    
    [[ "$channel" == "master" ]] && FLUTTER_VERSION="master" || {
        local version_manifest
        version_manifest=$(filter_manifest "$channel" "$arch" "$version")
        [[ -n "$version_manifest" ]] || { echo "Unable to determine Flutter version."; exit 1; }
        FLUTTER_VERSION="$(echo "$version_manifest" | jq -r '.version')"
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
    ' "$MANIFEST_JSON_PATH"
}

# Main script logic
[[ -z "$RUNNER_OS" ]] && { echo "This script is intended for use in GitHub Actions workflows."; exit 1; }

[[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"

# Call the setup_flutter function with appropriate parameters
setup_flutter "$1" "$2" "$3" "$4"
