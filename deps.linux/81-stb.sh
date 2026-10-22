#!/usr/bin/env bash

# Dependency information
NAME='stb'
# stb has no releases; the version is that of stb_image.h, the header NVD tracks.
VERSION='2.26'
CPE='nothings:stb_image.h'
URI='https://github.com/nothings/stb.git'
HASH='e140649ccf40818781b7e408f6228a486f6d254b'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/stb"

    mkdir -p "${OUTPUT_PATH}/include/stb"
    cp stb_image.h stb_image_write.h "${OUTPUT_PATH}/include/stb/"
}
