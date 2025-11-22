#!/usr/bin/env bash

# Dependency information
NAME='srt'
VERSION='1.5.4'
URI='https://github.com/Haivision/srt/archive/refs/tags/v1.5.4.zip'
HASH="${SCRIPT_DIR}/deps.linux/checksums/v1.5.4.zip.sha256"
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

clean() {
    cd "${WORK_ROOT}/${NAME}-${VERSION}"
    
    if [[ -d "build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}-${VERSION}"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}-${VERSION}"
    
    local shared_libs="ON"
    if [[ "${SHARED}" == "true" ]]; then
        shared_libs="ON"
    fi
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-DBUILD_SHARED_LIBS:BOOL=${shared_libs}"
        "-DENABLE_APPS:BOOL=OFF"
        "-DENABLE_LOGGING:BOOL=OFF"
        "-DENABLE_SHARED:BOOL=${shared_libs}"
        "-DENABLE_STATIC:BOOL=ON"
        "-DENABLE_STDCXX_SYNC:BOOL=ON"
        "-DENABLE_ENCRYPTION:BOOL=ON"
        "-DOPENSSL_USE_STATIC_LIBS:BOOL=ON"
        "-DUSE_OPENSSL_PC:BOOL=OFF"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}-${VERSION}"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}-${VERSION}"
    
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
