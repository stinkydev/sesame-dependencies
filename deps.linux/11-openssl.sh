#!/usr/bin/env bash

# Dependency information
NAME='openssl'
VERSION='1.1.1w'
URI='https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_1_1w.tar.gz'
HASH="${SCRIPT_DIR}/deps.linux/checksums/OpenSSL_1_1_1w.tar.gz.sha256"
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

clean() {
    if [[ -d "${WORK_ROOT}/openssl-OpenSSL_1_1_1w" ]]; then
        cd "${WORK_ROOT}/openssl-OpenSSL_1_1_1w"
        
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
    cd "${WORK_ROOT}/openssl-OpenSSL_1_1_1w"
    
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
    cd "${WORK_ROOT}/openssl-OpenSSL_1_1_1w"
    
    make -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/openssl-OpenSSL_1_1_1w"
    
    make install_sw
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
