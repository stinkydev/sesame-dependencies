#!/usr/bin/env bash

# Dependency information
NAME='glm'
VERSION='0.9.9.8'
URI='https://github.com/g-truc/glm.git'
HASH='bf71a834948186f4097caa076cd2663c69a10e1e'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/glm"

    mkdir -p "${OUTPUT_PATH}/include"
    cp -r glm "${OUTPUT_PATH}/include/"
    rm -f "${OUTPUT_PATH}/include/glm/CMakeLists.txt"
}
