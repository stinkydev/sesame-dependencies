#!/usr/bin/env bash

# Dependency information
NAME='openssl'
VERSION='3.3.2'
URI='https://github.com/openssl/openssl/archive/refs/tags/openssl-3.3.2.tar.gz'
HASH="${SCRIPT_DIR}/deps.linux/checksums/openssl-3.3.2.tar.gz.sha256"
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"
    
    # Check if system OpenSSL is available and sufficient
    if pkg-config --exists openssl && pkg-config --atleast-version=1.1.1 openssl; then
        log_info "Using system OpenSSL ($(pkg-config --modversion openssl))"
        return 0
    fi
    
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

clean() {
    if [[ -d "${WORK_ROOT}/openssl-openssl-${VERSION}" ]]; then
        cd "${WORK_ROOT}/openssl-openssl-${VERSION}"
        
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
    # Skip if using system OpenSSL
    if pkg-config --exists openssl && pkg-config --atleast-version=1.1.1 openssl; then
        return 0
    fi
    
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/openssl-openssl-${VERSION}"
    
    local options=(
        "--prefix=${OUTPUT_PATH}"
        "--openssldir=${OUTPUT_PATH}/ssl"
        "no-shared"
        "no-tests"
    )
    
    ./config "${options[@]}"
}

build() {
    # Skip if using system OpenSSL
    if pkg-config --exists openssl && pkg-config --atleast-version=1.1.1 openssl; then
        return 0
    fi
    
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/openssl-openssl-${VERSION}"
    
    make -j "${NUM_PROCS}"
}

install() {
    # If using system OpenSSL, create symlinks
    if pkg-config --exists openssl && pkg-config --atleast-version=1.1.1 openssl; then
        log_info "Install ${NAME} (system) (${TARGET})"
        mkdir -p "${OUTPUT_PATH}/lib/pkgconfig"
        mkdir -p "${OUTPUT_PATH}/include"
        
        # Copy pkg-config file
        local pc_path=$(pkg-config --variable=pcfiledir openssl)
        cp "${pc_path}/openssl.pc" "${OUTPUT_PATH}/lib/pkgconfig/" 2>/dev/null || true
        cp "${pc_path}/libssl.pc" "${OUTPUT_PATH}/lib/pkgconfig/" 2>/dev/null || true
        cp "${pc_path}/libcrypto.pc" "${OUTPUT_PATH}/lib/pkgconfig/" 2>/dev/null || true
        
        return 0
    fi
    
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/openssl-openssl-${VERSION}"
    
    make install_sw
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
