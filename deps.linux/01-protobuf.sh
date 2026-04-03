#!/usr/bin/env bash

# Dependency information
NAME='protobuf'
VERSION='3.21.12'
URI='https://github.com/protocolbuffers/protobuf.git'
HASH="f0dc78d7e6e331b8c6bb2d5283e06aa26883ca7c"
TARGETS=('x86_64' 'aarch64')

# protoc-gen-doc settings
PROTOC_GEN_DOC_VERSION='1.5.1'
PROTOC_GEN_DOC_URI_X86_64='https://github.com/pseudomuto/protoc-gen-doc/releases/download/v1.5.1/protoc-gen-doc_1.5.1_linux_amd64.tar.gz'
PROTOC_GEN_DOC_URI_AARCH64='https://github.com/pseudomuto/protoc-gen-doc/releases/download/v1.5.1/protoc-gen-doc_1.5.1_linux_arm64.tar.gz'
PROTOC_GEN_DOC_HASH_X86_64="${SCRIPT_DIR}/deps.linux/checksums/protoc-gen-doc_1.5.1_linux_amd64.tar.gz.sha256"
PROTOC_GEN_DOC_HASH_AARCH64="${SCRIPT_DIR}/deps.linux/checksums/protoc-gen-doc_1.5.1_linux_arm64.tar.gz.sha256"

setup() {
    log_info "Setup ${NAME} (${TARGET})"
    setup_dependency "${URI}" "${HASH}" "${WORK_ROOT}"
    cd "${WORK_ROOT}/protobuf"
}

clean() {
    cd "${WORK_ROOT}/protobuf"
    
    if [[ -d "build_${TARGET}" ]]; then
        log_info "Clean build directory (${TARGET})"
        rm -rf "build_${TARGET}"
    fi
}

patch() {
    log_info "Patch ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/protobuf"
}

configure() {
    log_info "Configure ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/protobuf"
    
    local shared_libs="OFF"
    if [[ "${SHARED}" == "true" ]]; then
        shared_libs="ON"
    fi
    
    local options=(
        "${CMAKE_OPTIONS[@]}"
        "-Dprotobuf_BUILD_SHARED_LIBS:BOOL=${shared_libs}"
        "-Dprotobuf_BUILD_TESTS:BOOL=OFF"
        "-Dprotobuf_BUILD_PROTOC_BINARIES:BOOL=ON"
    )
    
    cmake -S . -B "build_${TARGET}" "${options[@]}"
}

build() {
    log_info "Build ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/protobuf"
    
    cmake --build "build_${TARGET}" --config "${CONFIGURATION}" -j "${NUM_PROCS}"
}

install() {
    log_info "Install ${NAME} (${TARGET})"
    cd "${WORK_ROOT}/protobuf"
    
    local options=(
        --install "build_${TARGET}"
        --config "${CONFIGURATION}"
    )
    
    if [[ "${CONFIGURATION}" =~ ^(Release|MinSizeRel)$ ]]; then
        options+=(--strip)
    fi
    
    cmake "${options[@]}"
    
    # Install protoc-gen-doc
    install_protoc_gen_doc
}

install_protoc_gen_doc() {
    log_info "Install protoc-gen-doc (${TARGET})"
    
    local download_dir="${WORK_ROOT}/protoc-gen-doc-download"
    mkdir -p "${download_dir}"
    cd "${download_dir}"
    
    # Select correct URI and hash based on target architecture
    local uri hash filename
    if [[ "${TARGET}" == "x86_64" ]]; then
        uri="${PROTOC_GEN_DOC_URI_X86_64}"
        hash="${PROTOC_GEN_DOC_HASH_X86_64}"
        filename="protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz"
    else
        uri="${PROTOC_GEN_DOC_URI_AARCH64}"
        hash="${PROTOC_GEN_DOC_HASH_AARCH64}"
        filename="protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_arm64.tar.gz"
    fi
    
    # Download if not exists
    if [[ ! -f "${filename}" ]]; then
        log_info "Downloading ${filename}..."
        curl -L -o "${filename}" "${uri}"
    fi
    
    # Verify checksum if hash file exists
    if [[ -f "${hash}" ]]; then
        log_info "Verifying checksum..."
        sha256sum -c "${hash}"
    else
        log_warning "Checksum file not found for protoc-gen-doc, skipping verification"
    fi
    
    # Extract
    log_info "Extracting ${filename}..."
    tar -xzf "${filename}"
    
    # Install binary
    local bin_dir="${OUTPUT_PATH}/bin"
    mkdir -p "${bin_dir}"
    cp -f protoc-gen-doc "${bin_dir}/"
    chmod +x "${bin_dir}/protoc-gen-doc"
    log_info "Installed protoc-gen-doc to ${bin_dir}"
}

fixup() {
    log_info "Fixup ${NAME} (${TARGET})"
}
