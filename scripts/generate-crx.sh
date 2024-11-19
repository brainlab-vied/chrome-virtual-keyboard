#!/bin/bash -e

# Package the chrome extension into a crx file.
# Use a disposable temp key for plugin signing.
#
# Create a preference file for the extension,
# which triggers plugin auto installation.
#
# This script assumes that it is called either from
# generate.sh in this repo, or from within Yocto.
# Meaning the build tools are available from env,
# either by sourcing SDK or from yocto build sysroot.
#
# How to create a chromium plugin crx:
# http://www.dre.vanderbilt.edu/~schmidt/android/android-4.0/external/chromium/chrome/common/extensions/docs/crx.html
# https://gromnitsky.blogspot.com/2019/04/crx3.html
# https://github.com/ahwayakchih/crx3/blob/master/lib/crx3.proto
# https://github.dev/pawliczka/CRX3-Creator/blob/6aa7d583dc28b2845cd59b14c3ac3e2041aa5379/main.py#L159

usage() {
    local script=$(basename "$0")
    echo "Usage ${script} [PN] [INSTALLATION_PATH] [BUILDDIR]"
    echo "PN: for example 'chromium-cirtual-keyboard'"
    echo "INSTALLATION_PATH: the placement of the crx file on the rootfs of the device, example: '/usr/share/chromium/extensions'"
    echo "BUILDDIR: the folder name where to build inside, folder is created at repo top level"
}

# Input parameters
if [ "$#" -ne 3 ]; then
    echo "Wrong usage!"
    usage
    exit 1
fi

PN=${1}
INSTALLATION_PATH=${2}
BUILDDIR=${3}

if [ -z "${PN}" ]; then
    echo "Missing PN variable!"
    exit 1
fi

if [ -z "${INSTALLATION_PATH}" ]; then
    echo "Missing INSTALLATION_PATH variable!"
    exit 1
fi

if [ -z "${BUILDDIR}" ]; then
    echo "Missing BUILDDIR variable!"
    exit 1
fi

# Run this script from repo top level
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd ${SCRIPT_DIR}/../

# Builddir on top level repo
mkdir -p $(basename ${BUILDDIR})

# Generated (partly intermediate) files
TARGET_ZIP="${BUILDDIR}/${PN}.zip"
TARGET_SIG="${BUILDDIR}/${PN}.sig"
TARGET_PUB="${BUILDDIR}/${PN}.pub"
TARGET_PM="${BUILDDIR}/${PN}.pm"
TARGET_PM2="${BUILDDIR}/${PN}.pm2"
TARGET_HD="${BUILDDIR}/${PN}.hd"
TARGET_SD="${BUILDDIR}/${PN}.sd"
TARGET_DD="${BUILDDIR}/${PN}.dd"
TARGET_CRX="${BUILDDIR}/${PN}.crx"

# Zip the plugin sources
zip -r -9 -X ${TARGET_ZIP} buttons icons layouts options background.js keyboard.html keyboard.png LICENSE manifest.json options.html README.md script.js style.css toggle.html toggle.js

# Generate a disposable temp private key
KEY="${BUILDDIR}/${PN}.pem"
openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out ${KEY}

# CRX metadata
VERSION="$(grep '"version"' ${SCRIPT_DIR}/../manifest.json | awk '{print $2}' | tr -d '",')"
EXTENSION_ID="$(cat ${KEY} | openssl rsa -pubout -outform DER | openssl dgst -sha256 | awk '{print $2}' | cut -c 1-32 | tr '0-9a-f' 'a-p')"

# Version string validation, must either contain "dev" or be formatted as "major.minor.patch_blxx" (see README)
REGEX_VERSION_BL='^\d+\.\d+\.\d+_bl\d{2}$'
if [[ "$VERSION" == *"dev"* ]] || [[ "$VERSION" =~ $REGEX_VERSION_BL ]]; then
    echo "Found version ${VERSION}"
else
    echo "Version ${VERSION} malformed, see README!"
    exit 1
fi

# Generate a disposable temp public key
openssl rsa -pubout -outform DER < "$KEY" > "$TARGET_PUB" 2>/dev/null

byte_swap () {
    # Take "abcdefgh" and return it as "ghefcdab"
    echo "${1:6:2}${1:4:2}${1:2:2}${1:0:2}"
}

## Create crx file
echo "Create crx file for: '$PN' with extension id '$EXTENSION_ID' in version '$VERSION'"

crx_id="$(cat ${KEY} | openssl rsa -pubout -outform DER | openssl dgst -sha256 | awk '{print $2}' | cut -c 1-32 | sed 's/../\\x&/g')"
(
    echo "crx_id: \"${crx_id}\""
) > ${TARGET_PM2}
cat ${TARGET_PM2} | protoc --proto_path ${SCRIPT_DIR} --encode=crx_file.SignedData ${SCRIPT_DIR}/crx3.proto >  "$TARGET_SD"

delimiter="00"
signed_header_size=$(byte_swap $(printf '%08x\n' $(ls -l "$TARGET_SD" | awk '{print $5}')))

# signature
    #context
    #delimiter
    #len of SignedData
    #SignedData as string
    #ZIP
(
    echo -n "CRX3 SignedData"
    echo -n "$delimiter $signed_header_size" | xxd -r -p
    cat "${TARGET_SD}" #SignedData as string
    cat "${TARGET_ZIP}"
) > ${TARGET_DD}
openssl sha256 -sha256 -binary -sign "$KEY" < ${TARGET_DD} > "$TARGET_SIG"

(
    echo "sha256_with_rsa: {"
    echo "public_key: \"$(xxd -p ${TARGET_PUB} | tr -d '\n' | sed 's/../\\x&/g')\""
    echo "signature: \"$(xxd -p ${TARGET_SIG} | tr -d '\n' | sed 's/../\\x&/g')\""
    echo "}"
    echo "signed_header_data:  \"$(xxd -p ${TARGET_SD} | tr -d '\n' | sed 's/../\\x&/g')\""
) > ${TARGET_PM}
cat ${TARGET_PM} | protoc --proto_path ${SCRIPT_DIR} --encode=crx_file.CrxFileHeader ${SCRIPT_DIR}/crx3.proto > "$TARGET_HD"

crmagic_hex="4372 3234" # Cr24
version_hex="0300 0000" # 2
hd_len_hex=$(byte_swap $(printf '%08x\n' $(ls -l "$TARGET_HD" | awk '{print $5}')))
(
    echo -n "$crmagic_hex $version_hex $hd_len_hex" | xxd -r -p
    cat "$TARGET_HD" "$TARGET_ZIP"
) > "$TARGET_CRX"
echo "Wrote $TARGET_CRX"

if [ ! -e ${TARGET_CRX} ]; then
    echo "Failed to create crx file"
    exit 1
fi

# cleanup intermediate files
rm ${TARGET_ZIP}
rm ${TARGET_SIG}
rm ${TARGET_PUB}
rm ${TARGET_DD}
rm ${TARGET_SD}
rm ${TARGET_HD}
rm ${TARGET_PM}
rm ${TARGET_PM2}

## Create preference file

PREFERENCE_FILE_NAME="${EXTENSION_ID}.json"
PREFERENCE_FILE="${BUILDDIR}/${PREFERENCE_FILE_NAME}"

# Create the preference file
echo "{" > ${PREFERENCE_FILE}
echo "    \"external_crx\": \"${INSTALLATION_PATH}/${PN}.crx\"," >> ${PREFERENCE_FILE}
echo "    \"external_version\": \"${VERSION}\"" >> ${PREFERENCE_FILE}
echo "}" >> ${PREFERENCE_FILE}

popd
