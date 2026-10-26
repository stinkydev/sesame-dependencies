#!/usr/bin/env bash

# Dependency information
NAME='openssl'
VERSION='3.5.9'
CPE='openssl:openssl'
URI='https://github.com/openssl/openssl/releases/download/openssl-3.5.9/openssl-3.5.9.tar.gz'
HASH="${SCRIPT_DIR}/deps.linux/checksums/openssl-3.5.9.tar.gz.sha256"
TARGETS=('x86_64' 'aarch64')
EXTRACTED_DIR='openssl-3.5.9'

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
            make clean 2>/dev/null || true
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
        "--openssldir=${OUTPUT_PATH}/ssl"
        "--libdir=lib"
        "no-shared"
        "no-tests"
        "no-docs"
    )
    
    ./config "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    make -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    make install_sw
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
