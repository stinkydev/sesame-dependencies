#!/usr/bin/env bash

# Dependency information
NAME='websocketpp'
VERSION='0.8.2'
URI='https://github.com/zaphoyd/websocketpp.git'
HASH='56123c87598f8b1dd471be83ca841ceae07f95ba'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
    cd "${WORK_ROOT}/websocketpp"
}

clean() {
    cd "${WORK_ROOT}/websocketpp"
    
    if [[ -d "build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/websocketpp"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/websocketpp"
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-DENABLE_CPP11:BOOL=ON"
        "-DBUILD_EXAMPLES:BOOL=OFF"
        "-DBUILD_TESTS:BOOL=OFF"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/websocketpp"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/websocketpp"
    
    local options=(
        --install "build_${TARGET}"
        --config "${CONFIGURATION}"
    )
    
    if [[ "${CONFIGURATION}" =~ ^(Release|MinSizeRel)$ ]]; then
        options+=(--strip)
    fi
    
    cmake "${options[@]}"
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
