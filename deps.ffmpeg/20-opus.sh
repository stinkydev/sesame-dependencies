#!/usr/bin/env bash

# Dependency information
NAME='opus'
VERSION='1.5.2'
URI='https://github.com/xiph/opus.git'
HASH='ddbe48383984d56acd9e1ab6a090c54ca6b735a6'
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
        "-DBUILD_TESTING=OFF"
        "-DOPUS_BUILD_PROGRAMS=OFF"
        "-DOPUS_STACK_PROTECTOR=ON"
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
