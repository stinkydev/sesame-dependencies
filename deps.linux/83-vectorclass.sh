#!/usr/bin/env bash

# Dependency information
NAME='vectorclass'
VERSION='2.02.01'
URI='https://github.com/vectorclass/version2.git'
HASH='fe6c4506c6e8301d2edd884284d69663ec2b68a1'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/version2"

    # instrset_detect.cpp is compiled into the consumer alongside the headers.
    mkdir -p "${OUTPUT_PATH}/include/vectorclass"
    cp ./*.h instrset_detect.cpp "${OUTPUT_PATH}/include/vectorclass/"
}
