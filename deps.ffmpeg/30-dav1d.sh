#!/usr/bin/env bash

# Dependency information
NAME='dav1d'
VERSION='1.5.1'
URI='https://code.videolan.org/videolan/dav1d.git'
HASH='3060ebf8dd26952579373084984daf70a54f5368'
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    cd "${WORK_ROOT}"

    for tool in meson ninja nasm; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            log_error "${tool} is required to build ${NAME} but was not found"
            exit 1
        fi
    done

    if [[ ! -d "${NAME}" ]]; then
        log_info "Cloning ${NAME}..."
        git clone "${URI}" "${NAME}"
        cd "${NAME}"
        git checkout "${HASH}"
    else
        log_info "${NAME} already cloned"
        cd "${NAME}"

        git reset --hard HEAD
        git clean -fdx

        current_hash=$(git rev-parse HEAD)
        if [[ "${current_hash}" != "${HASH}" ]]; then
            log_info "Updating to correct commit ${HASH}"
            git fetch origin
            git checkout -f "${HASH}"
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
    cd "${WORK_ROOT}/${NAME}"

    meson setup "build_${TARGET}" \
        --prefix="${OUTPUT_PATH}" \
        --libdir=lib \
        --buildtype=release \
        --default-library=static \
        -Db_staticpic=true \
        -Denable_tools=false \
        -Denable_tests=false \
        -Denable_examples=false
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"

    meson compile -C "build_${TARGET}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/${NAME}"

    meson install -C "build_${TARGET}"
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
