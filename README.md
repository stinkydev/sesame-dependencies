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

This project builds FFmpeg under the **LGPL v2.1+ only**. GPL-licensed components
(e.g. libx264, libx265, libpostproc) are intentionally excluded so that the
resulting binaries can be distributed under the LGPL. Do not add
`--enable-gpl`, `--enable-version3`, or any GPL-only external library to the
configure flags.

### Linux

FFmpeg for Linux can be built via the `build-ffmpeg.sh` Bash script. This script uses a modular build system that builds all required dependencies from source.

#### Prerequisites

```bash
# Required packages
sudo apt-get install -y build-essential cmake nasm yasm pkg-config git
```

**Note**: All codecs (libvpx, opus, vorbis, ogg, lame) are built from source using scripts in the `deps.ffmpeg/` directory.

#### Building

```bash
./build-ffmpeg.sh
```

The script will:
1. Build all FFmpeg dependencies from source (libvpx, opus, vorbis, ogg, lame, zlib, libpng)
2. Build FFmpeg with the following features (LGPL v2.1+ only):
   - VP8/VP9 (libvpx, BSD)
   - MP3 (libmp3lame, LGPL v2+)
   - Opus (libopus, BSD)
   - Vorbis (libvorbis, BSD)
   - Shared libraries
   - `libpostproc` is disabled (GPL-only)

### Windows

FFmpeg for Windows can be built via the `Build-FFMpeg.ps1` PowerShell script (PowerShell >= 7, MSYS2 with the MSVC toolchain). It builds the same dependencies from the `deps.ffmpeg/` `*.ps1` scripts and produces shared libraries under the same LGPL v2.1+ configuration.

```powershell
./Build-FFMpeg.ps1
```

## Licensing

FFmpeg as built by this repository is licensed under the GNU Lesser General
Public License, version 2.1 or later. The full license text and FFmpeg's own
licensing notice are installed alongside the binaries under
`licenses/FFmpeg/`. License texts for the bundled external libraries are
installed under `licenses/<library>/`.

If you need to add a new codec or external library, verify its license is
compatible with LGPL v2.1+ before enabling it. GPL-only options must not be
re-introduced.
