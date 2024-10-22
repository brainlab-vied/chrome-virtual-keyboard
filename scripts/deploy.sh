
script=$(basename "$0")
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [ "$#" -lt 1 ]; then
    if [[ -z "${BV_IP}" ]]; then
        echo "BV_IP not defined. Usage $script [TARGET_IP]"
        exit 1
    else
        MY_BV_IP=${BV_IP}
    fi
else
    MY_BV_IP=${1}
fi

pushd  $DIR/..

VERSION="$(grep '"version"' manifest.json | awk '{print $2}' | tr -d '",')"
BUILD_DIR="release/${VERSION}"


echo "Copy deploy directory to XU9 tmp"

SSH_BASE_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
SCP_BASE_COMMAND="scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Copy deploy/ folder structure to XU9 as intermediate step
${SCP_BASE_COMMAND} -r $BUILD_DIR root@${MY_BV_IP}:/tmp

echo "Deploy to K26"

K26_IP="k26"

echo "Remounting the target file system to rw..."
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SSH_BASE_COMMAND} root@${K26_IP} \"mount -o remount,rw / \""

echo "Stopping services..."
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SSH_BASE_COMMAND} root@${K26_IP} \"systemctl stop chromium\""
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SSH_BASE_COMMAND} root@${K26_IP} \"rm -rf /data/settings/chromium\""
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SSH_BASE_COMMAND} root@${K26_IP} \"mkdir -p /data/settings/chromium\""

echo "Copying extension..."
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SCP_BASE_COMMAND} -r /tmp/${VERSION}/* root@${K26_IP}:/usr/share/chromium/extensions"

echo "Enabling systemd services..."
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SSH_BASE_COMMAND} root@${K26_IP} \"sync\""
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SSH_BASE_COMMAND} root@${K26_IP} \"mount -o remount,ro / \""
${SSH_BASE_COMMAND} root@${MY_BV_IP} "${SSH_BASE_COMMAND} root@${K26_IP} \"systemctl start chromium\""

popd
