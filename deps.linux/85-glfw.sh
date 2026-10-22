#!/usr/bin/env bash

# Dependency information
NAME='glfw'
VERSION='3.3.2'
URI='https://github.com/glfw/glfw.git'
HASH='0a49ef0a00baa3ab520ddc452f0e3b1e099c5589'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

clean() {
    cd "${WORK_ROOT}/glfw"

    if [[ -d "build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "build_${TARGET}"
    fi
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/glfw"

    local shared_libs="OFF"
    if [[ "${SHARED}" == "true" ]]; then
        shared_libs="ON"
    fi

    local options=(
        "${CMAKE_OPTIONS[@]}"
        # fixup() edits lib/cmake/glfw3; keep GNUInstallDirs from choosing lib64.
        "-DCMAKE_INSTALL_LIBDIR=lib"
        "-DBUILD_SHARED_LIBS:BOOL=${shared_libs}"
        "-DGLFW_BUILD_DOCS:BOOL=OFF"
        "-DGLFW_BUILD_EXAMPLES:BOOL=OFF"
        "-DGLFW_BUILD_TESTS:BOOL=OFF"
        # glfw 3.3.2 declares cmake_minimum_required(VERSION 3.0), which CMake 4 rejects.
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    )

    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/glfw"

    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/glfw"

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

    # The exported target names system libraries by their absolute path on the build machine; use plain
    # names so consumers link against their own copies.
    sed -i -E 's#/usr/lib/[^;"]*/lib([A-Za-z0-9_]+)\.(a|so)#\1#g' \
        "${OUTPUT_PATH}/lib/cmake/glfw3/glfw3Targets.cmake"
}
