#!/bin/bash

# Get the operating system name in lowercase.
OS_NAME=$(echo "$RUNNER_OS" | awk '{print tolower($0)}')

# Get the Flutter release manifest.
FLUTTER_RELEASE_MANIFEST=$(curl --silent --connect-timeout 15 --retry 5 "$MANIFEST_URL")

# Get the Flutter version manifest.
FLUTTER_VERSION_MANIFEST=$(echo "$FLUTTER_RELEASE_MANIFEST" | jq -r '.version')

# Download and extract Flutter.
function download_and_extract_flutter() {
  local channel=$1
  local cache_path=$2

  if [[ ! -x "$cache_path/bin/flutter" ]]; then
    if [[ "$channel" == "master" ]]; then
      git clone -b master https://github.com/flutter/flutter.git "$cache_path"
    else
      archive_url=$(echo "$FLUTTER_VERSION_MANIFEST" | jq -r '.archive')
      download_archive "$archive_url" "$cache_path"
    fi
  fi
}

# Download and extract Flutter using the master channel.
download_and_extract_flutter master "$CACHE_PATH"

# Set environment variables and paths.
echo "FLUTTER_ROOT=$CACHE_PATH" >> "$GITHUB_ENV"
echo "PUB_CACHE=$CACHE_PATH/.pub-cache" >> "$GITHUB_ENV"
echo "$CACHE_PATH/bin" >> "$GITHUB_PATH"
echo "$CACHE_PATH/bin/cache/dart-sdk/bin" >> "$GITHUB_PATH"
echo "$CACHE_PATH/.pub-cache/bin" >> "$GITHUB_PATH"
