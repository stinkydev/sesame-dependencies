#!/usr/bin/env bash

# Build FFmpeg for Linux using the modular dependency build system
# This is a convenience wrapper around build-dependencies.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "---------------------------------------------------------------------------------------------------"
echo "[SESAME-FFMPEG] Building FFmpeg for Linux"
echo "---------------------------------------------------------------------------------------------------"

# Set environment variables for FFmpeg build
export CONFIGURATION="${CONFIGURATION:-Release}"
export TARGET="${TARGET:-$(uname -m)}"
export SUB_DIR="deps.ffmpeg"
export PACKAGE_NAME="ffmpeg"

# Run the main build script
"${SCRIPT_DIR}/build-dependencies.sh"
