#!/usr/bin/env bash

# Dependency information
NAME='libogg'
VERSION='1.3.5'
URI='https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.xz'
HASH="${SCRIPT_DIR}/deps.ffmpeg/checksums/libogg-1.3.5.tar.xz.sha256"
TARGETS=('x86_64' 'aarch64')
EXTRACTED_DIR='libogg-1.3.5'

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

clean() {
    if [[ -d "${WORK_ROOT}/${EXTRACTED_DIR}/build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "${WORK_ROOT}/${EXTRACTED_DIR}/build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    local shared_libs="OFF"
    if [[ "${SHARED}" == "true" ]]; then
        shared_libs="ON"
    fi
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-DBUILD_SHARED_LIBS:BOOL=${shared_libs}"
        "-DINSTALL_DOCS=OFF"
        "-DBUILD_TESTING=OFF"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${EXTRACTED_DIR}"
    
    cmake --install "build_${TARGET}" --config "${CONFIGURATION}"
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
