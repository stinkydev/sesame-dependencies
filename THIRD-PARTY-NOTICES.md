# Third-Party Notices

Applications that ship binaries produced by **sesame-dependencies** include
the third-party software listed below. The full text of each license is
installed under `licenses/<library>/` in the build output and is also
available in the [`licenses/`](licenses/) directory of this repository.

Downstream applications must reproduce the relevant notices and license
texts in their own distribution (typically in an "About" / "Open Source
Licenses" / "Third-Party Notices" screen, or in a file shipped alongside
the binaries).

---

## FFmpeg toolchain (built by `build-ffmpeg.sh` / `Build-FFMpeg.ps1`)

| Library | Version | License | Notes |
|---|---|---|---|
| [FFmpeg](https://ffmpeg.org/) | 7.1 | LGPL v2.1+ | Built **without** `--enable-gpl` and **without** `--enable-version3`. See LGPL obligations below. |
| [LAME](https://lame.sourceforge.io/) | 3.100 | LGPL v2+ | See LGPL obligations below. |
| [libogg](https://xiph.org/ogg/) | upstream | BSD-3-Clause | Xiph.Org Foundation. |
| [libvorbis](https://xiph.org/vorbis/) | upstream | BSD-3-Clause | Xiph.Org Foundation. |
| [libvpx](https://chromium.googlesource.com/webm/libvpx) | upstream | BSD-3-Clause | Google / WebM project. Includes `PATENTS` grant. |
| [Opus](https://opus-codec.org/) | upstream | BSD-3-Clause | Xiph.Org Foundation, Microsoft, Skype, Octasic, Jean-Marc Valin et al. |
| [libpng](http://www.libpng.org/pub/png/libpng.html) | upstream | libpng (PNG Reference Library License v2) | |
| [zlib](https://www.zlib.net/) | 1.3.1 | zlib license | |

## General dependencies (built by `build-dependencies.sh` / `Build-Dependencies.ps1`)

| Library | Version | License | Notes |
|---|---|---|---|
| [Protocol Buffers](https://protobuf.dev/) | 3.21.12 | BSD-3-Clause | Google. |
| [SRT](https://github.com/Haivision/srt) | 1.5.4 | MPL 2.0 | If you modify any SRT source file, you must publish that modified file's source. |
| [moq-cpp](https://github.com/stinkydev/moq-cpp) | v0.0.12 | MIT (+ bundled Rust crates) | Stinky Computing AB. Statically links its Rust crate tree; full upstream-generated attribution (`THIRD-PARTY-NOTICES.txt` / `THIRD_PARTY_LICENSES.md`) is harvested into `licenses/moq-cpp/` at build time. |
| [Vulkan SDK](https://vulkan.lunarg.com/) | 1.3.275.0 | Apache 2.0 (loader) | The SDK bundles many components under several licenses (Apache 2.0, MIT, BSD). The bundled `LICENSE.txt` enumerates them. |
| [OpenSSL](https://www.openssl.org/) | 1.1.1w | OpenSSL License **and** original SSLeay License (dual) | Both notices must be reproduced. |
| [FreeType](https://freetype.org/) | upstream | FreeType License (BSD-style w/ credit clause) **or** GPLv2 — pick FTL | Requires the acknowledgement "Portions of this software are copyright © `<year>` The FreeType Project (www.freetype.org). All rights reserved." in product documentation. |
| [Asio](https://think-async.com/Asio/) | upstream | Boost Software License 1.0 | Header-only. |
| [nlohmann/json](https://github.com/nlohmann/json) | upstream | MIT | |
| [WebSocket++](https://github.com/zaphoyd/websocketpp) | upstream | BSD-3-Clause | |
| [audio-plugins](https://github.com/stinkydev/audio-plugins) | v0.0.6 | MIT (+ bundled CLAP SDK) | Stinky Computing. Compiles in the CLAP SDK (MIT); upstream `THIRD_PARTY_LICENSES.md` + `licenses/CLAP-LICENSE.txt` are harvested into `licenses/audio-plugins/` at build time. |
| [protoc-gen-doc](https://github.com/pseudomuto/protoc-gen-doc) | 1.5.1 | MIT | Build/tooling binary; only ship if you redistribute it. |

---

## LGPL obligations (FFmpeg, LAME)

FFmpeg and LAME are distributed under the **GNU Lesser General Public
License, version 2.1 or later**. When you ship an application that uses
them, you must:

1. **Link dynamically.** This repository builds FFmpeg shared
   (`--enable-shared --disable-static`) — keep it that way. If you ever
   statically link an LGPL library, you must additionally provide the
   object files of your application so users can re-link against a
   modified version of the library.
2. **Bundle the LGPL text** with your application (`COPYING.LGPLv2.1`).
3. **Display an attribution notice**, e.g. in an About / Credits screen:
   > This software uses libraries from the FFmpeg project under the
   > LGPLv2.1, and from the LAME project under the LGPLv2.1+.
4. **Document modifications.** Any patches you apply (see
   `deps.ffmpeg/patches/`) must be disclosed and the modified source must
   be made available on request.
5. **Do not strip symbol information** beyond what the existing `fixup`
   step does. Users must be able to re-link.

## Other non-obvious obligations

- **libpng** — include the libpng license and credit ("This software uses
  libpng, copyright © `<years>` Contributing Authors.") in product
  documentation.
- **FreeType** — the FTL acknowledgement above must appear in any printed
  or on-screen documentation.
- **libvpx** — ship the `PATENTS` file alongside the license; the patent
  grant terminates if the user initiates patent litigation against the
  project.
- **OpenSSL 1.1.x** — both the OpenSSL License *and* the original SSLeay
  License must be reproduced (the single `LICENSE` file in
  `licenses/openssl/` contains both).
- **SRT (MPL 2.0)** — file-level copyleft. You may statically link SRT
  into a closed-source product, but if you modify any SRT source file
  you must publish that file's source.

## Recommended in-app attribution string

A minimal "About" / "Open Source Licenses" entry might read:

> This product includes software developed by the FFmpeg project
> (LGPLv2.1+), the LAME project (LGPLv2+), the Xiph.Org Foundation
> (Opus, Vorbis, Ogg — BSD), Google / WebM (libvpx — BSD),
> the libpng Authors, the zlib Authors (Jean-loup Gailly, Mark Adler),
> the OpenSSL Project and Eric A. Young (OpenSSL 1.1 — dual OpenSSL /
> SSLeay license), the Protocol Buffers project (Google — BSD),
> the SRT Alliance / Haivision (SRT — MPL 2.0), Khronos / LunarG
> (Vulkan SDK — Apache 2.0), the FreeType Project (FTL), Christopher
> M. Kohlhoff (Asio — Boost 1.0), Niels Lohmann (nlohmann/json — MIT),
> Peter Thorson (WebSocket++ — BSD), and Stinky Computing AB
> (moq-cpp, audio-plugins — MIT).
>
> Full license texts are included under the application's
> `licenses/` directory.
