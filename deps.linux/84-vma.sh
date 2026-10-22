#!/usr/bin/env bash

# Dependency information
NAME='vma'
VERSION='3.1.0-dev+a53702cb'
URI='https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git'
HASH='a53702cbe2289b3c37f0904290ad2b03f703d0df'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/VulkanMemoryAllocator"

    mkdir -p "${OUTPUT_PATH}/include/vma"
    cp include/vk_mem_alloc.h "${OUTPUT_PATH}/include/vma/"
}
