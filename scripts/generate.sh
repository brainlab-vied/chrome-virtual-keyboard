#!/bin/bash -e

# Generate a crx file and preference file for the chromium plugin.
#
# This is a wrapper script for local usage on a developer PC,
# it calls the nested generate-*.sh scripts.
# Required tools are sourced from the Yocto SDK.
#
# This script is also a reference for Yocto builds on the environment
# they have to setup before calling the nested scripts.

# Source the Yocto SDK
# TODO do it like other repos
source /home/martin/workspace/master-builds/k26-product/image/sdk/environment-setup-cortexa72-cortexa53-brainlab-linux

# Reference plugin scripts relative to the location of this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Create the crx file using a nested script
# Use source command so that internal variables are avaible.
# TODO: this will break in yocto.
export PN="chrome-virtual-keyboard"
source ${SCRIPT_DIR}/generate-crx.sh

# Validate expected script output
CRXFN="${PN}.crx"
if [ ! -e ./build/${CRXFN} ]; then
    echo "${CRXFN} file not generated"
    exit 1
fi

if [ -z "${EXTENSION_ID}" ]; then
    echo "EXTENSION_ID was not defined"
    exit 1
fi

# Creeate the extension preference file
export EXTENSION_ID
export INSTALLATION_PATH="/usr/share/chromium/extensions"
export CRXFN
${SCRIPT_DIR}/generate-preference-file.sh

# Validate expected script output
PREFERENCEFN="${EXTENSION_ID}.json"
if [ ! -e ./build/${PREFERENCEFN} ]; then
    echo "${PREFERENCEFN} file not generated"
    exit 1
fi

exit 0
