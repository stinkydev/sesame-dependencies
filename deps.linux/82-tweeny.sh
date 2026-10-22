#!/usr/bin/env bash

# Dependency information
NAME='tweeny'
VERSION='3.2.0'
URI='https://github.com/mobius3/tweeny/releases/download/v3.2.0/tweeny-3.2.0.h'
HASH="${SCRIPT_DIR}/deps.linux/checksums/tweeny-3.2.0.h.sha256"
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"

    if [[ ! -f tweeny-3.2.0.h ]]; then
        curl -fL -o tweeny-3.2.0.h "${URI}"
    fi
    sha256sum -c "${HASH}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"

    mkdir -p "${OUTPUT_PATH}/include/tweeny"
    cp tweeny-3.2.0.h "${OUTPUT_PATH}/include/tweeny/tweeny.h"
}
