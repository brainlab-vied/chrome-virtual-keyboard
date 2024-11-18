#!/bin/bash -e

# Create a preference file for the crx plugin file.
#
# This script assumes that it is called either from
# generate.sh in this repo, or from within Yocto.
# Meaning build tools are available from env,
# either by sourcing yocto sdk first,
# or calling this script from within a yocto build env.

# Expected defines from outside
if [ -z "${EXTENSION_ID}" ]; then
    echo "Please define EXTENSION_ID variable first!"
    exit 1
fi

if [ -z "${INSTALLATION_PATH}" ]; then
    echo "Please define INSTALLATION_PATH variable first!"
    exit 1
fi

if [ -z "${CRXFN}" ]; then
    echo "Please define CRXFN (crx filename) variable first!"
    exit 1
fi

# Build directory
BUILDDIR="build"
mkdir -p ${BUILDDIR}

PREFERENCE_FILE_NAME="${EXTENSION_ID}.json"
PREFERENCE_FILE="${BUILDDIR}/${PREFERENCE_FILE_NAME}"

# Create the preference file
echo "{" > ${PREFERENCE_FILE}
echo "    \"external_crx\": \"${INSTALLATION_PATH}/${PN}.crx\"," >> ${PREFERENCE_FILE}
echo "    \"external_version\": \"${VERSION}\"" >> ${PREFERENCE_FILE}
echo "}" >> ${PREFERENCE_FILE}
