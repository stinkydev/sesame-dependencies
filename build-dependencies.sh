#!/usr/bin/env bash

set -euo pipefail

# Default configuration
CONFIGURATION="${CONFIGURATION:-Release}"
PACKAGE_NAME="${PACKAGE_NAME:-dependencies}"
TARGET="${TARGET:-$(uname -m)}"
CLEAN="${CLEAN:-false}"
QUIET="${QUIET:-false}"
SHARED="${SHARED:-false}"
SKIP_ALL="${SKIP_ALL:-false}"
SKIP_BUILD="${SKIP_BUILD:-false}"
SKIP_DEPS="${SKIP_DEPS:-false}"
SKIP_UNPACK="${SKIP_UNPACK:-false}"
DEPENDENCIES="${DEPENDENCIES:-}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
WORK_ROOT="${PROJECT_ROOT}/linux_build_temp"
CURRENT_DATE=$(date +%Y-%m-%d)

# Determine architecture
case "${TARGET}" in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "Unsupported target: ${TARGET}"
        exit 1
        ;;
esac

# Output directory
OUTPUT_PATH="${PROJECT_ROOT}/linux/sesame-${PACKAGE_NAME}-${TARGET}-${CONFIGURATION}"

# Helper functions
log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    if [[ "${QUIET}" != "true" ]]; then
        echo "[DEBUG] $*"
    fi
}

# Display configuration
echo "---------------------------------------------------------------------------------------------------"
echo -n "[SESAME-DEPENDENCIES] - configuration "
echo -n "${CONFIGURATION}"
echo -n ", target "
echo -n "${TARGET}"
echo -n ", shared libraries "
if [[ "${SHARED}" == "true" ]]; then
    echo "Yes"
else
    echo "No"
fi
echo "Dependencies: ${DEPENDENCIES:-All}"
echo "---------------------------------------------------------------------------------------------------"

# Setup host
log_info "Setting up build environment"

# Check for required tools
command -v git >/dev/null 2>&1 || { log_error "git is required but not installed."; exit 1; }
command -v cmake >/dev/null 2>&1 || { log_error "cmake is required but not installed."; exit 1; }
command -v make >/dev/null 2>&1 || { log_error "make is required but not installed."; exit 1; }

# Get number of processors
NUM_PROCS=$(nproc)

# CMake options
CMAKE_OPTIONS=(
    "-DCMAKE_INSTALL_PREFIX=${OUTPUT_PATH}"
    "-DCMAKE_PREFIX_PATH=${OUTPUT_PATH}"
    "-DCMAKE_BUILD_TYPE=${CONFIGURATION}"
    "-DCMAKE_CXX_STANDARD=20"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
)

if [[ "${QUIET}" == "true" ]]; then
    CMAKE_OPTIONS+=(
        "-Wno-deprecated"
        "-Wno-dev"
        "--log-level=ERROR"
    )
fi

log_debug "Architecture: ${ARCH}"
log_debug "Target: ${TARGET}"
log_debug "Output dir: ${OUTPUT_PATH}"
log_debug "Working dir: ${WORK_ROOT}"
log_debug "Project dir: ${PROJECT_ROOT}"
log_debug "Multi-process: ${NUM_PROCS}"

# Create work directory
mkdir -p "${WORK_ROOT}"
mkdir -p "${OUTPUT_PATH}"

# Dependency setup function
setup_dependency() {
    local uri="$1"
    local hash="$2"
    local dest_path="$3"
    
    if [[ "${uri}" == *.git ]]; then
        # Git repository
        local repo_name=$(basename "${uri}" .git)
        if [[ ! -d "${dest_path}/${repo_name}" ]] || [[ "${SKIP_UNPACK}" != "true" ]]; then
            log_info "Cloning ${repo_name}..."
            if [[ -d "${dest_path}/${repo_name}" ]]; then
                rm -rf "${dest_path}/${repo_name}"
            fi
            git clone "${uri}" "${dest_path}/${repo_name}"
            cd "${dest_path}/${repo_name}"
            git checkout "${hash}"
        fi
    else
        # Archive download
        local filename=$(basename "${uri}")
        local checksum_file="${hash}"
        
        if [[ ! -f "${filename}" ]]; then
            log_info "Downloading ${filename}..."
            curl -L -o "${filename}" "${uri}"
        fi
        
        if [[ -f "${checksum_file}" ]]; then
            log_info "Verifying checksum..."
            sha256sum -c "${checksum_file}"
        fi
        
        if [[ "${SKIP_UNPACK}" != "true" ]]; then
            log_info "Extracting ${filename}..."
            case "${filename}" in
                *.tar.gz|*.tgz)
                    tar -xzf "${filename}" -C "${dest_path}"
                    ;;
                *.tar.bz2|*.tbz2)
                    tar -xjf "${filename}" -C "${dest_path}"
                    ;;
                *.tar.xz|*.txz)
                    tar -xJf "${filename}" -C "${dest_path}"
                    ;;
                *.zip)
                    unzip -q "${filename}" -d "${dest_path}"
                    ;;
                *)
                    log_error "Unsupported archive format: ${filename}"
                    return 1
                    ;;
            esac
        fi
    fi
}

# Export functions and variables for dependency scripts
export SCRIPT_DIR PROJECT_ROOT WORK_ROOT OUTPUT_PATH CONFIGURATION TARGET ARCH
export CMAKE_OPTIONS NUM_PROCS SHARED CLEAN SKIP_BUILD SKIP_UNPACK
export -f log_info log_error log_debug setup_dependency

# Determine which dependencies to build
SUB_DIR="deps.linux"

if [[ -z "${DEPENDENCIES}" ]]; then
    # Build all dependencies
    DEPENDENCY_FILES=($(find "${SCRIPT_DIR}/${SUB_DIR}" -name "*.sh" -type f 2>/dev/null | sort))
else
    # Build specific dependencies
    DEPENDENCY_FILES=()
    for dep in ${DEPENDENCIES}; do
        dep_file=$(find "${SCRIPT_DIR}/${SUB_DIR}" -name "*${dep}.sh" -type f 2>/dev/null | head -1)
        if [[ -n "${dep_file}" ]]; then
            DEPENDENCY_FILES+=("${dep_file}")
        else
            log_error "Script for requested dependency ${dep} not found"
            exit 1
        fi
    done
fi

log_debug "Using dependency scripts: ${DEPENDENCY_FILES[*]}"

# Process each dependency
for dep_file in "${DEPENDENCY_FILES[@]}"; do
    log_info "Processing $(basename "${dep_file}")"
    
    # Change to work directory
    cd "${WORK_ROOT}"
    
    # Source the dependency script
    # shellcheck disable=SC1090
    source "${dep_file}"
    
    # Run stages
    STAGES=("setup")
    
    if [[ "${SKIP_ALL}" == "true" ]] || [[ "${SKIP_BUILD}" == "true" ]]; then
        STAGES+=("install" "fixup")
    else
        if [[ "${CLEAN}" == "true" ]]; then
            STAGES+=("clean")
        fi
        STAGES+=("patch" "configure" "build" "install" "fixup")
    fi
    
    for stage in "${STAGES[@]}"; do
        if type -t "${stage}" >/dev/null 2>&1; then
            log_debug "Running stage: ${stage}"
            "${stage}" || log_error "Stage ${stage} failed for $(basename "${dep_file}")"
        fi
    done
    
    # Copy license files
    dep_name=$(basename "${dep_file}" .sh)
    dep_name="${dep_name#[0-9][0-9]-}"
    if [[ -d "${SCRIPT_DIR}/licenses/${dep_name}" ]]; then
        log_info "Installing license files for ${dep_name}"
        mkdir -p "${OUTPUT_PATH}/licenses"
        cp -r "${SCRIPT_DIR}/licenses/${dep_name}" "${OUTPUT_PATH}/licenses/"
    fi
    
    # Clean up functions
    for stage in "${STAGES[@]}"; do
        unset -f "${stage}" 2>/dev/null || true
    done
done

# Package dependencies
if [[ -z "${DEPENDENCIES}" ]] && [[ -d "${OUTPUT_PATH}" ]]; then
    log_info "Packaging dependencies"
    
    cd "${OUTPUT_PATH}"
    
    # Cleanup unnecessary files
    case "${PACKAGE_NAME}" in
        dependencies)
            if [[ "${TARGET}" != "x86" ]]; then
                rm -rf lib/pkgconfig 2>/dev/null || true
            fi
            ARCHIVE_NAME="linux-deps-${CURRENT_DATE}-${TARGET}-${CONFIGURATION}.tar.gz"
            ;;
        *)
            ARCHIVE_NAME="linux-${PACKAGE_NAME}-${CURRENT_DATE}-${TARGET}.tar.gz"
            ;;
    esac
    
    # Create version file
    mkdir -p share/sesame-deps
    echo "${CURRENT_DATE}" > share/sesame-deps/VERSION
    
    # Create archive
    log_info "Creating archive ${ARCHIVE_NAME}"
    tar -czf "${ARCHIVE_NAME}" ./*
    
    # Move archive to parent directory
    mv "${ARCHIVE_NAME}" "${PROJECT_ROOT}/"
    
    log_info "Archive created: ${PROJECT_ROOT}/${ARCHIVE_NAME}"
fi

echo "---------------------------------------------------------------------------------------------------"
echo "[SESAME-DEPENDENCIES] All done"
echo "Built Dependencies: ${DEPENDENCIES:-All}"
echo "---------------------------------------------------------------------------------------------------"
