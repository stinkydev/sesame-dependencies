#!/usr/bin/env bash

# Dependency information
NAME='nlohmann-json'
VERSION='3.11.3'
URI='https://github.com/nlohmann/json.git'
HASH='9cca280a4d0ccf0c08f47a99aa71d1b0e52f8d03'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
    cd "${WORK_ROOT}/json"
}

clean() {
    cd "${WORK_ROOT}/json"
    
    if [[ -d "build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/json"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/json"
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-DJSON_BuildTests:BOOL=OFF"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/json"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/json"
    
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
