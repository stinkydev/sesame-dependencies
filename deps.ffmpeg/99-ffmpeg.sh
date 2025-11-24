#!/usr/bin/env bash

# Dependency information
NAME='FFmpeg'
VERSION='7.1'
URI='https://github.com/FFmpeg/FFmpeg.git'
HASH='b08d7969c550a804a59511c7b83f2dd8cc0499b8'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"
    
    if [[ ! -d "${NAME}" ]]; then
        log_info "Cloning ${NAME}..."
        git clone "${URI}" "${NAME}"
        cd "${NAME}"
        git checkout "${HASH}"
    else
        log_info "${NAME} already cloned"
        cd "${NAME}"
        
        # Clean any uncommitted changes or untracked files
        git reset --hard HEAD
        git clean -fdx
        
        # Verify we're at the correct commit
        current_hash=$(git rev-parse HEAD)
        if [[ "${current_hash}" != "${HASH}" ]]; then
            log_info "Updating to correct commit ${HASH}"
            git fetch origin
            git checkout -f "${HASH}"
        fi
    fi
}

clean() {
    if [[ -d "${WORK_ROOT}/${NAME}/build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "${WORK_ROOT}/${NAME}/build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"
    
    # Apply patches if they exist
    local patch_dir="${SCRIPT_DIR}/deps.ffmpeg/patches/FFmpeg"
    if [[ -d "${patch_dir}" ]]; then
        for patch_file in "${patch_dir}"/*.patch; do
            if [[ -f "${patch_file}" ]]; then
                local patch_name=$(basename "${patch_file}")
                
                # Skip Windows-specific patches on non-Windows platforms
                if [[ "${patch_name}" == *"-Windows.patch" ]]; then
                    log_debug "Skipping Windows-specific patch: ${patch_name}"
                    continue
                fi
                
                # Apply patch, -N skips if already applied, -f forces no prompts, -r /dev/null rejects to /dev/null
                log_info "Applying patch: ${patch_name}"
                /usr/bin/patch -p1 -N -f -r /dev/null < "${patch_file}" >/dev/null 2>&1 || log_debug "Patch ${patch_name} skipped (already applied or failed)"
            fi
        done
    fi
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"
    
    mkdir -p "build_${TARGET}"
    cd "build_${TARGET}"
    
    local cc_flags="-I${OUTPUT_PATH}/include"
    local ld_flags="-L${OUTPUT_PATH}/lib"
    
    local options=(
        "--prefix=${OUTPUT_PATH}"
        "--arch=${ARCH}"
        "--extra-cflags=${cc_flags}"
        "--extra-ldflags=${ld_flags}"
        "--extra-libs=-lpthread -lm"
        "--pkg-config-flags=--static"
        "--enable-version3"
        "--enable-gpl"
        "--enable-libx264"
        "--enable-libx265"
        "--enable-libopus"
        "--enable-libvorbis"
        "--enable-libvpx"
        "--enable-libmp3lame"
        "--enable-pthreads"
        "--enable-shared"
        "--disable-static"
        "--disable-doc"
        "--disable-postproc"
    )
    
    # Check for optional codec support
    if pkg-config --exists libaom 2>/dev/null; then
        options+=("--enable-libaom")
    fi
    
    if pkg-config --exists SvtAv1Enc 2>/dev/null; then
        options+=("--enable-libsvtav1")
    fi
    
    # Use clang if available
    if command -v clang >/dev/null 2>&1; then
        options+=(
            "--cc=clang"
            "--cxx=clang++"
            "--host-cc=clang"
        )
    fi
    
    PKG_CONFIG_PATH="${OUTPUT_PATH}/lib/pkgconfig:${PKG_CONFIG_PATH:-}" \
    LD_LIBRARY_PATH="${OUTPUT_PATH}/lib:${LD_LIBRARY_PATH:-}" \
    ../configure "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}/build_${TARGET}"
    
    make -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}/build_${TARGET}"
    
    make install
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
    
    # Strip symbols from shared libraries in Release mode
    if [[ "${CONFIGURATION}" == "Release" || "${CONFIGURATION}" == "MinSizeRel" ]]; then
        local so_files=("${OUTPUT_PATH}"/lib/lib{sw,av,postproc}*.so.*)
        if [[ -n "${so_files}" ]]; then
            strip -x "${so_files[@]}" 2>/dev/null || true
        fi
    fi
}
