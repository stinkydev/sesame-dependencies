#!/usr/bin/env bash

# Dependency information
NAME='audio-plugins'
VERSION='0.0.3'
URI='https://github.com/stinkydev/audio-plugins.git'
HASH='db0c5a25b1f44e1dfd64a001a33dff9d4166d868'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
    cd "${WORK_ROOT}/audio-plugins"
}

clean() {
    cd "${WORK_ROOT}/audio-plugins"
    
    if [[ -d "build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/audio-plugins"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/audio-plugins"
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-DBUILD_TESTS:BOOL=OFF"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/audio-plugins"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/audio-plugins"
    
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
