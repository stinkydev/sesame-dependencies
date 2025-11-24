#!/usr/bin/env bash

# Dependency information
NAME='libvpx'
VERSION='1.14.1'
URI='https://github.com/webmproject/libvpx/archive/v1.14.1.tar.gz'
HASH="${SCRIPT_DIR}/deps.linux/checksums/v1.14.1-libvpx.tar.gz.sha256"
TARGETS=('x86_64' 'aarch64')
EXTRACTED_DIR='libvpx-1.14.1'

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
        "--enable-pic"
        "--disable-examples"
        "--disable-docs"
        "--disable-unit-tests"
    )
    
    # Add shared library support if requested
    if [[ "${SHARED}" == "true" ]]; then
        options+=("--enable-shared")
    else
        options+=("--disable-shared")
    fi
    
    # Set target architecture
    case "${ARCH}" in
        x86_64)
            options+=("--target=x86_64-linux-gcc")
            ;;
        aarch64)
            options+=("--target=arm64-linux-gcc")
            ;;
    esac
    
    ./configure "${options[@]}"
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
