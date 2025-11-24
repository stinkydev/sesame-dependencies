#!/usr/bin/env bash

# Dependency information
NAME='x264'
VERSION='r3106'
URI='https://github.com/mirror/x264.git'
HASH='eaa68fad9e5d201d42fde51665f2d137ae96baf0'
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
        # Verify we're at the correct commit
        current_hash=$(git rev-parse HEAD)
        if [[ "${current_hash}" != "${HASH}" ]]; then
            log_info "Updating to correct commit ${HASH}"
            git fetch origin
            git checkout "${HASH}"
        fi
    fi
}

clean() {
    if [[ -d "${WORK_ROOT}/${NAME}" ]]; then
        cd "${WORK_ROOT}/${NAME}"
        
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
    cd "${WORK_ROOT}/${NAME}"
    
    local options=(
        "--prefix=${OUTPUT_PATH}"
        "--enable-static"
        "--enable-pic"
    )
    
    # Add shared library support if requested
    if [[ "${SHARED}" == "true" ]]; then
        options+=("--enable-shared")
    else
        options+=("--disable-shared")
    fi
    
    ./configure "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"
    
    make -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"
    
    make install
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
