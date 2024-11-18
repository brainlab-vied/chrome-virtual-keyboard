#!/bin/bash -e

# Wrapper for generate-crx.sh to be used on local developer PC
# Use the yocto sdk to setup an env, thenn build the crx file.

# Source the Yocto SDK
script=$(basename "$0")
if [ "$#" -ne 1 ]; then
    if [[ -z "${YOCTO_SDK_BASE}" ]]; then
        echo "YOCTO_SDK_BASE not defined. Usage $script <yocto sdk base>"
        exit 1
    else
        MY_YOCTO_SDK_BASE=$(realpath ${YOCTO_SDK_BASE})
    fi
else
    MY_YOCTO_SDK_BASE=$(realpath ${1})
fi

if [ -f "$MY_YOCTO_SDK_BASE/environment-setup-cortexa72-cortexa53-brainlab-linux" ]; then
    YOCTO_SDK="$MY_YOCTO_SDK_BASE/environment-setup-cortexa72-cortexa53-brainlab-linux"
elif [ -f "$MY_YOCTO_SDK_BASE/environment-setup-aarch64-brainlab-linux" ]; then
    YOCTO_SDK="$MY_YOCTO_SDK_BASE/environment-setup-aarch64-brainlab-linux"
else
    echo "YOCTO_SDK_BASE no environment-setup available."
    exit 1
fi
source $YOCTO_SDK

# Setup build parameter
PACKAGE_NAME="chromium-cirtual-keyboard"
INSTALLATION_PATH="/usr/share/chromium/extensions"

# Create the crx and extension files
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
${SCRIPT_DIR}/generate-crx.sh ${PACKAGE_NAME} ${INSTALLATION_PATH}

# Sanity check generated files

# TODO: EXTENSION_ID return
if [ -z ${EXTENSION_ID} ]; then
    echo "EXTENSION_ID not defined!"
    exit 1
else
    echo "Generated EXTENSION_ID: ${EXTENSION_ID}"
fi

echo "Generated files:"
CRX_FILE="./build/${PACKAGE_NAME}.crx"
if [ ! -e ${CRX_FILE} ]; then
    echo "crx file not generated"
    exit 1
else
    echo "${CRX_FILE}"
fi

PREFERENCE_FILE="./build/${EXTENSION_ID}.json"
if [ ! -e ${PREFERENCE_FILE} ]; then
    echo "Preference file not generated"
    exit 1
else
    echo "${PREFERENCE_FILE}"
fi
