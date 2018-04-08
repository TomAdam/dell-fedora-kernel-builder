#!/usr/bin/env bash

set -e

function usage {
    cat <<-EOF
Usage: build.sh build_id
    build_id: an identifier for your kernel build
EOF
}

if [ -z "${1}" ]
then
    usage
    exit 1
fi

BUILD_ID="${1}"
DIR="$(dirname ${0})"
BUILD_DIR="${DIR}/kernel-build"

function installBaseDeps {
    message "Installing base dependencies (sudo required)"
    sudo dnf install -y fedora-packager > /dev/null
}

function cloneRepo {
    message "Cloning kernel repo"
    fedpkg clone --anonymous kernel "${BUILD_DIR}" > /dev/null
}

function checkoutReleaseBranch {
    message "Checking out release branch"
    RELEASE_NUM="$(lsb_release -sr)"
    git -C "${BUILD_DIR}" checkout -b local-build origin/f${RELEASE_NUM} > /dev/null
}

function installBuildDeps {
    message "Installing build dependencies (sudo required)"
    sudo dnf builddep -y "${BUILD_DIR}/kernel.spec" > /dev/null
}

function setBuildId {
    message "Setting build ID"
    sed -i -e "s/# define buildid \.local/%define buildid \.${BUILD_ID}/g" "${BUILD_DIR}/kernel.spec"
}

function writeKernelOption {
    message "Setting kernel config"
    echo "CONFIG_ACPI_REV_OVERRIDE_POSSIBLE=y" > "${BUILD_DIR}/kernel-local"
}

function build {
    message "Building kernel, this will take over an hour"
    fedpkg --path "${BUILD_DIR}" local  > /dev/null 2>&1
    # TODO: check for build failure here
    message "Kernel built"
}

function movePackages {
    ARCH="$(uname -p)"
    BUILD_PACKAGE_DIR="${BUILD_DIR}/${ARCH}"
    KERNEL_VERSION=$(ls ${BUILD_PACKAGE_DIR}/kernel-* | tail -n 1 | sed -r "s/.*(([0-9]+[\.|-]){4}\w+\.\w+).*/\1/")
    PACKAGE_DIR="${DIR}/packages/${KERNEL_VERSION}"
    message "Moving built kernel to `realpath ${PACKAGE_DIR}`"
    mkdir -p ${PACKAGE_DIR}
    mv ${BUILD_PACKAGE_DIR}/* ${PACKAGE_DIR}
    mv ${DIR}/.build-${KERNEL_VERSION}.log ${PACKAGE_DIR}
}

function cleanup {
    message "Cleaning up"
    rm -rf "${BUILD_DIR}"
}

function message {
    tput setaf 2
    echo "${1}"
    tput sgr0
}

cleanup
installBaseDeps
cloneRepo
checkoutReleaseBranch
installBuildDeps
setBuildId
writeKernelOption
build
movePackages
cleanup
