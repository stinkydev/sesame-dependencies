#!/usr/bin/env bash

# Dependency information
NAME='x265'
VERSION='3.6'
URI='https://bitbucket.org/multicoreware/x265_git.git'
HASH='aa7f58723bc2ba48fdcf80779d4547b1a9a0b00d'
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
    cd "${WORK_ROOT}/${NAME}/source"
    
    local shared_libs="OFF"
    if [[ "${SHARED}" == "true" ]]; then
        shared_libs="ON"
    fi
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-DENABLE_SHARED:BOOL=${shared_libs}"
        "-DENABLE_CLI:BOOL=OFF"
    )
    
    cmake -S . -B "../build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}/build_${TARGET}"
    
    cmake --build . --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}/build_${TARGET}"
    
    cmake --install . --config "${CONFIGURATION}"
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
