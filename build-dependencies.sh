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

log_warning() {
    echo "[WARNING] $*" >&2
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
command -v jq >/dev/null 2>&1 || { log_error "jq is required but not installed."; exit 1; }

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

# Applies a patch in the current directory and records it for the component record. A patch that is
# already applied counts as applied; any other failure returns non-zero.
apply_patch() {
    local patch_file="$1"

    if /usr/bin/patch -p1 -N -f -r /dev/null < "${patch_file}" > /dev/null 2>&1 \
        || /usr/bin/patch -p1 -R -f --dry-run < "${patch_file}" > /dev/null 2>&1; then
        APPLIED_PATCHES+=("${patch_file}")
        return 0
    fi
    return 1
}

# Writes a CycloneDX component record for the dependency just processed into
# share/sesame-deps/components, the inventory consumed by downstream SBOM
# generation and vulnerability scanning. SCOPE=excluded marks a build-time tool
# that is packaged but not part of the product at run time.
write_component() {
    local version="${VERSION#v}"
    local github_re='^https://github\.com/([^/]+)/([^/]+)'
    local purl sha256="" purl_version="${version}" patch_urls="[]" metadata

    # License, description and website live in licenses/components.json, shared with Write-Component.ps1.
    metadata=$(jq -e --arg n "${NAME,,}" '.[$n]' "${SCRIPT_DIR}/licenses/components.json") || {
        log_error "No entry for ${NAME,,} in licenses/components.json"
        return 1
    }

    # A git source is identified by its pinned commit; the display version can name something else (stb).
    if [[ "${HASH}" =~ ^[0-9a-f]{40}$ ]]; then
        purl_version="${HASH}"
    fi

    if [[ "${URI}" =~ ${github_re} ]]; then
        local repo="${BASH_REMATCH[2]%.git}"
        purl="pkg:github/${BASH_REMATCH[1],,}/${repo,,}@${purl_version}"
    else
        purl="pkg:generic/${NAME,,}@${version}?download_url=$(jq -rn --arg u "${URI}" '$u | @uri')"
    fi

    if [[ ! "${HASH}" =~ ^[0-9a-f]{40}$ ]] && [[ -f "${HASH}" ]]; then
        sha256=$(cut -d ' ' -f 1 "${HASH}")
    fi

    if [[ ${#APPLIED_PATCHES[@]} -gt 0 ]]; then
        local commit
        commit=$(git -C "${SCRIPT_DIR}" rev-parse HEAD 2>/dev/null || echo main)
        patch_urls=$(printf '%s\n' "${APPLIED_PATCHES[@]#"${SCRIPT_DIR}/"}" \
            | jq -R --arg c "${commit}" '"https://github.com/stinkydev/sesame-dependencies/blob/\($c)/\(.)"' \
            | jq -s 'unique')
    fi

    mkdir -p "${OUTPUT_PATH}/share/sesame-deps/components"
    jq -n \
        --arg name "${NAME}" --arg version "${version}" --arg purl "${purl}" --arg cpe "${CPE}" \
        --arg uri "${URI}" --arg hash "${HASH}" --arg sha256 "${sha256}" --arg platform "linux-${TARGET}" \
        --arg scope "${SCOPE}" --argjson patches "${patch_urls}" --argjson meta "${metadata}" '
        ($hash | test("^[0-9a-f]{40}$")) as $git
        | { type: "library", name: $name, version: $version, description: $meta.description }
        + (if $scope != "" then { scope: $scope } else {} end)
        + { licenses: [{ license: { id: $meta.license } }] }
        + { purl: $purl }
        + (if $cpe != "" then { cpe: "cpe:2.3:a:\($cpe):\($version):*:*:*:*:*:*:*" } else {} end)
        + (if $sha256 != "" then { hashes: [{ alg: "SHA-256", content: $sha256 }] } else {} end)
        + { externalReferences: [{ type: (if $git then "vcs" else "distribution" end), url: $uri },
                                 { type: "website", url: $meta.website }] }
        + (if ($patches | length) > 0
           then { pedigree: { patches: [$patches[] | { type: "unofficial", diff: { url: . } }] } }
           else {} end)
        + { properties: ([{ name: "sesame-deps:platform", value: $platform }]
              + (if $git then [{ name: "sesame-deps:git-commit", value: $hash }] else [] end)) }' \
        > "${OUTPUT_PATH}/share/sesame-deps/components/${NAME,,}.json"
}

# Export functions and variables for dependency scripts
export SCRIPT_DIR PROJECT_ROOT WORK_ROOT OUTPUT_PATH CONFIGURATION TARGET ARCH
export CMAKE_OPTIONS NUM_PROCS SHARED CLEAN SKIP_BUILD SKIP_UNPACK
export -f log_info log_error log_debug log_warning setup_dependency

# Determine which dependencies to build
SUB_DIR="${SUB_DIR:-deps.linux}"

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
    
    # Reset the declared fields so a script that omits one can't inherit the
    # previous script's value.
    NAME=""
    VERSION=""
    URI=""
    HASH=""
    CPE=""
    SCOPE=""
    APPLIED_PATCHES=()

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
        # Only run stages the script defines; 'patch' and 'install' are also system commands.
        if [[ "$(type -t "${stage}")" == "function" ]]; then
            log_debug "Running stage: ${stage}"
            # Called directly so errexit applies inside the stage and a failure stops the build.
            "${stage}"
        fi
    done
    
    # Copy license files. Resolve the folder from the dependency's declared
    # NAME (e.g. 'FFmpeg', 'vulkansdk'), falling back to the script filename,
    # and match case-insensitively so casing differences don't matter on
    # case-sensitive filesystems.
    dep_name=$(basename "${dep_file}" .sh)
    dep_name="${dep_name#[0-9][0-9]-}"
    license_dir=$(find "${SCRIPT_DIR}/licenses" -mindepth 1 -maxdepth 1 -type d -iname "${NAME:-${dep_name}}" 2>/dev/null | head -1)
    if [[ -n "${license_dir}" ]]; then
        log_info "Installing license files for $(basename "${license_dir}")"
        mkdir -p "${OUTPUT_PATH}/licenses"
        cp -r "${license_dir}" "${OUTPUT_PATH}/licenses/"
    fi

    if [[ -n "${URI}" ]]; then
        write_component
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
            rm -rf lib/pkgconfig 2>/dev/null || true
            ARCHIVE_NAME="linux-deps-${CURRENT_DATE}-${TARGET}-${CONFIGURATION}.tar.gz"
            ;;
        *)
            ARCHIVE_NAME="linux-${PACKAGE_NAME}-${CURRENT_DATE}-${TARGET}.tar.gz"
            ;;
    esac
    
    # Create version file
    mkdir -p share/sesame-deps
    echo "${CURRENT_DATE}" > share/sesame-deps/VERSION

    # Release packaging regenerates this once the FFmpeg and dependency packages are merged.
    pwsh -NoProfile -Command ". '${SCRIPT_DIR}/utils.pwsh/Write-Notices.ps1'; Write-Notices -PackagePath '${OUTPUT_PATH}'"

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
