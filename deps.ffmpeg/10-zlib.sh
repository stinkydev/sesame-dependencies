#!/usr/bin/env bash

# Dependency information
NAME='zlib'
VERSION='1.3.1'
URI='https://github.com/madler/zlib.git'
HASH='51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

clean() {
    if [[ -d "${WORK_ROOT}/${NAME}/build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "${WORK_ROOT}/${NAME}/build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"
    
    local shared_libs="OFF"
    if [[ "${SHARED}" == "true" ]]; then
        shared_libs="ON"
    fi
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-DBUILD_SHARED_LIBS:BOOL=${shared_libs}"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"
    
    cmake --install "build_${TARGET}" --config "${CONFIGURATION}"
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
