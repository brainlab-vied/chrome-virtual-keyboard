#/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#TODO source SDK
source ~/toolchain/k26/environment-setup-cortexa72-cortexa53-brainlab-linux
#export PATH=$PATH:~/.local/go/bin
#export PATH=$PATH:~/.local/protoc/bin
#export PATH="$PATH:$(go env GOPATH)/bin"

script=$(basename "$0")
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

PN="chrome-virtual-keyboard"
INSTALLATION_PATH="/usr/share/chromium/extensions"
#pushd  $DIR/../..

#Generate private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out ${SCRIPT_DIR}/${PN}.pem

KEY="${SCRIPT_DIR}/${PN}.pem"
VERSION="$(grep '"version"' ${SCRIPT_DIR}/../manifest.json | awk '{print $2}' | tr -d '",')"
EXTENSION_ID="$(cat ${KEY} | openssl rsa -pubout -outform DER | openssl dgst -sha256 | awk '{print $2}' | cut -c 1-32 | tr '0-9a-f' 'a-p')"
echo "release '$PN' with id '$EXTENSION_ID' in version '$VERSION'"

TARGET_DIR="release/${VERSION}"
mkdir -p ${TARGET_DIR}

TARGET_ZIP="${TARGET_DIR}/${PN}.zip"
TARGET_SIG="${TARGET_DIR}/${PN}.sig"
TARGET_PUB="${TARGET_DIR}/${PN}.pub"
TARGET_PM="${TARGET_DIR}/${PN}.pm"
TARGET_PM2="${TARGET_DIR}/${PN}.pm2"
TARGET_HD="${TARGET_DIR}/${PN}.hd"
TARGET_SD="${TARGET_DIR}/${PN}.sd"
TARGET_DD="${TARGET_DIR}/${PN}.dd"
TARGET_CRX="${TARGET_DIR}/${PN}.crx"

#http://www.dre.vanderbilt.edu/~schmidt/android/android-4.0/external/chromium/chrome/common/extensions/docs/crx.html
#https://gromnitsky.blogspot.com/2019/04/crx3.html
#https://github.com/ahwayakchih/crx3/blob/master/lib/crx3.proto
#https://github.dev/pawliczka/CRX3-Creator/blob/6aa7d583dc28b2845cd59b14c3ac3e2041aa5379/main.py#L159

zip -q -r -9 -X ${TARGET_ZIP} buttons icons layouts options _config.yaml background.js keyboard.html keyboard.png LICENSE manifest.json options.html README.md script.js style.css toggle.html toggle.js

# public key
openssl rsa -pubout -outform DER < "$KEY" > "$TARGET_PUB" 2>/dev/null

byte_swap () {
  # Take "abcdefgh" and return it as "ghefcdab"
  echo "${1:6:2}${1:4:2}${1:2:2}${1:0:2}"
}

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

rm -f ${TARGET_ZIP}
rm -f ${TARGET_SIG}
rm -f ${TARGET_PUB}
rm -f ${TARGET_DD}
rm -f ${TARGET_SD}
rm -f ${TARGET_HD}
rm -f ${TARGET_PM}
rm -f ${TARGET_PM2}

PREFERENCE_FILE_NAME="${EXTENSION_ID}.json"

# Extension preference file path on build host
PREFERENCE_FILE="${TARGET_DIR}/${PREFERENCE_FILE_NAME}"
echo "{" > ${PREFERENCE_FILE}
echo "    \"external_crx\": \"${INSTALLATION_PATH}/${PN}.crx\"," >> ${PREFERENCE_FILE}
echo "    \"external_version\": \"${VERSION}\"" >> ${PREFERENCE_FILE}
echo "}" >> ${PREFERENCE_FILE}
#popd