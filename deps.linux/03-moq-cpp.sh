#!/usr/bin/env bash

# Dependency information
NAME='moq-cpp'
VERSION='v0.0.12'
URI='https://github.com/stinkydev/moq-cpp.git'
HASH="406ae7dd8fd150d361c13122eb341ca5a431ed1c"
TARGETS=('x86_64' 'aarch64')

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
    cd "${WORK_ROOT}/moq-cpp"
}

clean() {
    cd "${WORK_ROOT}/moq-cpp"
    
    if [[ -d "build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/moq-cpp"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/moq-cpp"
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/moq-cpp"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/moq-cpp"
    
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
    cd "${WORK_ROOT}/moq-cpp"

    # moq-cpp statically links its full Rust crate tree; the aggregated
    # attribution is generated upstream (cargo-about). Harvest those notices
    # into the package instead of maintaining a copy in this repo.
    local license_dir="${OUTPUT_PATH}/licenses/${NAME}"
    mkdir -p "${license_dir}"

    local found=0
    for f in LICENSE THIRD-PARTY-NOTICES.txt THIRD_PARTY_LICENSES.md; do
        if [[ -f "${f}" ]]; then
            cp -f "${f}" "${license_dir}/"
            found=1
        fi
    done

    if [[ "${found}" -eq 0 ]]; then
        log_warning "${NAME}: no upstream license/notice files found - attribution may be incomplete"
    fi
}
