# sesame-dependencies

This repository is a collection of build scripts to build Sesame dependencies for Windows and Linux. "Inspired" by OBS...

## CEF Binaries in Releases

When creating a release tag, CEF (Chromium Embedded Framework) binaries are automatically downloaded and included in the release. The URLs for CEF binaries are configurable via the `cef-config.json` file in the repository root.

### Configuring CEF Binary URLs

Edit the `cef-config.json` file to update the URLs for Windows and Linux CEF binaries:

```json
{
  "cef_binaries": {
    "windows": {
      "url": "https://cdn-fastly.obsproject.com/downloads/cef_binary_6533_windows_x64_v2.zip",
      "filename": "cef_binary_6533_windows_x64_v2.zip"
    },
    "linux": {
      "url": "https://cdn-fastly.obsproject.com/downloads/cef_binary_6533_linux_x86_64.tar.xz",
      "filename": "cef_binary_6533_linux_x86_64.tar.xz"
    }
  }
}
```

The binaries will be automatically downloaded during the release creation process and included as release artifacts.

## Windows

Sesame dependencies for Windows can be built via the `Build-Dependencies.ps1` PowerShell script. Powershell >= 7 is required.

## Linux

Sesame dependencies for Linux can be built via the `build-dependencies.sh` Bash script.

### Prerequisites

The following tools are required:
- git
- cmake (>= 3.16)
- make or ninja
- gcc/g++ or clang
- Standard build tools (pkg-config, autoconf, automake, libtool, etc.)

### Building

```bash
./build-dependencies.sh
```

### Options

The script supports the following environment variables:
- `CONFIGURATION`: Build configuration (Debug, Release, RelWithDebInfo, MinSizeRel) - default: Release
- `TARGET`: Target architecture (x86_64, aarch64) - default: auto-detected
- `SHARED`: Build shared libraries (true/false) - default: false
- `CLEAN`: Clean build directories before building (true/false) - default: false
- `DEPENDENCIES`: Space-separated list of specific dependencies to build - default: all

Example:
```bash
CONFIGURATION=Debug SHARED=true ./build-dependencies.sh
```

## FFmpeg

### Linux

FFmpeg for Linux can be built via the `build-ffmpeg.sh` Bash script. This script uses a modular build system that builds all required dependencies from source, including video and audio codecs.

#### Prerequisites

```bash
# Required packages
sudo apt-get install -y build-essential cmake nasm yasm pkg-config git
```

**Note**: All codecs (x264, x265, libvpx, opus, vorbis, ogg, lame) are built from source using scripts in the `deps.ffmpeg/` directory.

#### Building

```bash
./build-ffmpeg.sh
```

The script will:
1. Build all FFmpeg dependencies from source (x264, x265, libvpx, opus, vorbis, ogg, lame, zlib, libpng)
2. Build FFmpeg with the following features:
   - GPL and version3 licensed codecs
   - H.264 (libx264), H.265 (libx265), VP8/VP9 (libvpx)
   - MP3 (libmp3lame), Opus (libopus), Vorbis (libvorbis)
   - Shared libraries
   - Optional: AV1 (libaom, libsvtav1) if system packages are available

### macOS and Windows

FFmpeg can also be built via the `build-ffmpeg.zsh` Zsh-script. FFmpeg can be compiled natively on macOS and Linux, and cross-compiled on Linux for Windows. In the latter case, specify a Windows-based target (e.g., `windows-x64`) to enable cross-compilation. On macOS, both Intel and Apple Silicon are supported.
