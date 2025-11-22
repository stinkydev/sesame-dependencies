#!/usr/bin/env bash

# Dependency information
NAME='asio'
VERSION='1.31.0'
URI='https://github.com/chriskohlhoff/asio.git'
HASH="1f534288b4be0be2dd664aab43882a0aa3106a1d"
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
    cd "${WORK_ROOT}/asio"
}

clean() {
    log_info "Clean ${NAME} (${TARGET})"
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/asio/asio"
    
    mkdir -p "${OUTPUT_PATH}/include"
    
    # Copy header files
    cp -r include/asio.hpp "${OUTPUT_PATH}/include/"
    cp -r include/asio "${OUTPUT_PATH}/include/"
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
