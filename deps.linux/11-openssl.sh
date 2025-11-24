#!/usr/bin/env bash

# Dependency information
NAME='openssl'
VERSION='1.1.1w'
URI='https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_1_1w.tar.gz'
HASH="${SCRIPT_DIR}/deps.linux/checksums/OpenSSL_1_1_1w.tar.gz.sha256"
TARGETS=('x86_64' 'aarch64')
# Note: GitHub archive extracts to 'openssl-OpenSSL_1_1_1w' (not 'openssl-1.1.1w')
EXTRACTED_DIR='openssl-OpenSSL_1_1_1w'

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
        "no-shared"
        "no-tests"
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
