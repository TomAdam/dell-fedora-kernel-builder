#!/usr/bin/env bash

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
BUILD_DIR="${DIR}/build"

function installBaseDeps {
    message "Installing base dependencies"
    sudo dnf install -y fedora-packager
}

function cloneRepo {
    message "Cloning kernel repo"
    fedpkg clone --anonymous kernel "${BUILD_DIR}"
}

function checkoutReleaseBranch {
    message "Checking out release branch"
    RELEASE_NUM="$(lsb_release -sr)"
    git -C "${BUILD_DIR}" checkout -b local-build origin/f${RELEASE_NUM}
}

function installBuildDeps {
    message "Installing build dependencies"
    sudo dnf builddep -y "${BUILD_DIR}/kernel.spec"
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
    fedpkg --path "${BUILD_DIR}" local > /dev/null
    message "Kernel built"
}

function install {
    message "Installing built kernel (feature not implemented)"
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

#cleanup
installBaseDeps
cloneRepo
checkoutReleaseBranch
installBuildDeps
setBuildId
writeKernelOption
build
install
#cleanup
