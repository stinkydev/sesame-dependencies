# sesame-dependencies

This repository is a collection of build scripts to build Sesame dependencies for Windows and Linux. "Inspired" by OBS...

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

FFmpeg for Linux can be built via the `build-ffmpeg.sh` Bash script. This script builds FFmpeg with common codec support using system libraries.

#### Prerequisites

```bash
sudo apt-get install -y nasm yasm libx264-dev libx265-dev libvpx-dev \
  libmp3lame-dev libopus-dev libvorbis-dev libaom-dev pkg-config
```

#### Building

```bash
./build-ffmpeg.sh
```

The script will build FFmpeg with the following features:
- GPL and version3 licensed codecs
- H.264 (libx264), H.265 (libx265), VP8/VP9 (libvpx), AV1 (libaom)
- MP3 (libmp3lame), Opus (libopus), Vorbis (libvorbis)
- Shared libraries

### macOS and Windows

FFmpeg can also be built via the `build-ffmpeg.zsh` Zsh-script. FFmpeg can be compiled natively on macOS and Linux, and cross-compiled on Linux for Windows. In the latter case, specify a Windows-based target (e.g., `windows-x64`) to enable cross-compilation. On macOS, both Intel and Apple Silicon are supported.
