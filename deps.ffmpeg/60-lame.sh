#!/usr/bin/env bash

# Dependency information
NAME='lame'
VERSION='3.100'
URI='https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz'
HASH="${SCRIPT_DIR}/deps.ffmpeg/checksums/lame-3.100.tar.gz.sha256"
TARGETS=('x86_64' 'aarch64')
EXTRACTED_DIR='lame-3.100'

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

clean() {
    if [[ -d "${WORK_ROOT}/${EXTRACTED_DIR}" ]]; then
        cd "${WORK_ROOT}/${EXTRACTED_DIR}"
        
        if [[ -f "Makefile" ]]; then
            log_info "Clean build directory (${TARGET})"
            make distclean 2>/dev/null || true
        fi
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    local options=(
        "--prefix=${OUTPUT_PATH}"
        "--enable-static"
        "--enable-nasm"
        "--disable-frontend"
    )
    
    # Add shared library support if requested
    if [[ "${SHARED}" == "true" ]]; then
        options+=("--enable-shared")
    else
        options+=("--disable-shared")
    fi
    
    # Build with -fPIC for compatibility with shared libraries
    CFLAGS="-fPIC ${CFLAGS:-}" ./configure "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    make -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    make install
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
