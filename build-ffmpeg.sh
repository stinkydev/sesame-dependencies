#!/usr/bin/env bash

# Build FFmpeg for Linux
# Simplified approach: use system packages for dependencies, build FFmpeg from source

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
WORK_ROOT="${PROJECT_ROOT}/linux_build_temp"
CURRENT_DATE=$(date +%Y-%m-%d)

# Configuration
CONFIGURATION="${CONFIGURATION:-Release}"
TARGET="${TARGET:-$(uname -m)}"
FFMPEG_VERSION="${FFMPEG_VERSION:-7.1}"
FFMPEG_HASH="b08d7969c550a804a59511c7b83f2dd8cc0499b8"

# Determine architecture
case "${TARGET}" in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "Unsupported target: ${TARGET}"
        exit 1
        ;;
esac

OUTPUT_PATH="${PROJECT_ROOT}/linux/sesame-ffmpeg-${TARGET}"

echo "---------------------------------------------------------------------------------------------------"
echo "[SESAME-FFMPEG] Building FFmpeg for Linux"
echo "Configuration: ${CONFIGURATION}"
echo "Target: ${TARGET}"
echo "Output: ${OUTPUT_PATH}"
echo "---------------------------------------------------------------------------------------------------"

# Create directories
mkdir -p "${WORK_ROOT}"
mkdir -p "${OUTPUT_PATH}"

# Install system dependencies
echo "[INFO] Installing FFmpeg build dependencies..."
echo "[INFO] Required system packages:"
echo "  - nasm, yasm (assemblers)"
echo "  - libx264-dev, libx265-dev, libvpx-dev (video codecs)"
echo "  - libmp3lame-dev, libopus-dev, libvorbis-dev (audio codecs)"
echo "  - libaom-dev (AV1 support, optional: libsvtav1-dev)"
echo ""
echo "[INFO] To install on Ubuntu/Debian:"
echo "  sudo apt-get install -y nasm yasm libx264-dev libx265-dev libvpx-dev \\"
echo "    libmp3lame-dev libopus-dev libvorbis-dev libaom-dev pkg-config"
echo ""
echo "[INFO] Optional: sudo apt-get install -y libsvtav1-dev"
echo ""

# Check for required tools
command -v pkg-config >/dev/null 2>&1 || { echo "[ERROR] pkg-config is required"; exit 1; }
command -v nasm >/dev/null 2>&1 || { echo "[ERROR] nasm is required (sudo apt-get install nasm)"; exit 1; }

# Clone FFmpeg
cd "${WORK_ROOT}"
if [[ ! -d "FFmpeg" ]]; then
    echo "[INFO] Cloning FFmpeg..."
    # Clone full repository to ensure we can checkout any commit
    git clone https://github.com/FFmpeg/FFmpeg.git
    cd FFmpeg
    git checkout "${FFMPEG_HASH}"
else
    echo "[INFO] FFmpeg already cloned"
    cd FFmpeg
fi

# Configure FFmpeg
echo "[INFO] Configuring FFmpeg..."

# Set up paths to find built dependencies (x264, libvpx)
DEPS_PATH="${PROJECT_ROOT}/linux/sesame-dependencies-${TARGET}-${CONFIGURATION}"
if [[ -d "${DEPS_PATH}" ]]; then
    echo "[INFO] Using built dependencies from ${DEPS_PATH}"
    export PKG_CONFIG_PATH="${DEPS_PATH}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    export LD_LIBRARY_PATH="${DEPS_PATH}/lib:${LD_LIBRARY_PATH:-}"
    export CFLAGS="-I${DEPS_PATH}/include ${CFLAGS:-}"
    export LDFLAGS="-L${DEPS_PATH}/lib ${LDFLAGS:-}"
fi

# Determine compiler
CC_CXX_FLAGS=""
if command -v clang >/dev/null 2>&1; then
    CC_CXX_FLAGS="--cc=clang --cxx=clang++"
fi

# Check for optional codec support
AOM_FLAGS=""
SVTAV1_FLAGS=""
if pkg-config --exists libaom; then
    AOM_FLAGS="--enable-libaom"
fi
if pkg-config --exists SvtAv1Enc; then
    SVTAV1_FLAGS="--enable-libsvtav1"
fi

./configure \
    --prefix="${OUTPUT_PATH}" \
    --arch="${ARCH}" \
    --enable-gpl \
    --enable-version3 \
    --enable-shared \
    --disable-static \
    --enable-pthreads \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --extra-libs="-lpthread -lm" \
    ${CC_CXX_FLAGS} \
    ${AOM_FLAGS} \
    ${SVTAV1_FLAGS}

# Build FFmpeg
echo "[INFO] Building FFmpeg (this may take a while)..."
make -j$(nproc)

# Install FFmpeg
echo "[INFO] Installing FFmpeg..."
make install

# Create version file
mkdir -p "${OUTPUT_PATH}/share/sesame-deps"
echo "${CURRENT_DATE}" > "${OUTPUT_PATH}/share/sesame-deps/VERSION"

# Package FFmpeg
cd "${OUTPUT_PATH}"
ARCHIVE_NAME="linux-ffmpeg-${CURRENT_DATE}-${TARGET}.tar.gz"
echo "[INFO] Creating archive ${ARCHIVE_NAME}..."
tar -czf "${ARCHIVE_NAME}" ./*
mv "${ARCHIVE_NAME}" "${PROJECT_ROOT}/"

echo "---------------------------------------------------------------------------------------------------"
echo "[SESAME-FFMPEG] Build complete!"
echo "Archive: ${PROJECT_ROOT}/${ARCHIVE_NAME}"
echo "---------------------------------------------------------------------------------------------------"
