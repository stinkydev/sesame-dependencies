# sesame-dependencies

This repository is a collection of build scripts to build Sesame dependencies for Windows. "Inspired" by OBS...

## Windows

Sesame dependencies for Windows can be built via the `Build-Dependencies.ps1` PowerShell script. Powershell >= 7 is required.

## FFmpeg

FFmpeg can be built via the `build-ffmpeg.zsh` Zsh-script. FFmpeg can be compiled natively on macOS and Linux, and cross-compiled on Linux for Windows. In the latter case, specify a Windows-based target (e.g., `windows-x64`) to enable cross-compilation. On macOS, both Intel and Apple Silicon are supported.
