#!/bin/bash

set -e

WORK_DIR=${PWD}/sdkbuild
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_DIR=${SCRIPT_DIR}

QT_URL="https://download.qt.io/official_releases/qt/5.9/5.9.3/qt-opensource-linux-x64-5.9.3.run"
FW_URL="https://download.qt.io/official_releases/qt-installer-framework/3.0.2/QtInstallerFramework-linux-x64.run"
GO_URL="https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz"

function downloadIfNotExist {
    if [ -f $2 ]; then
    echo "File $2 exists, skipping"
    else
    echo "File $2 does not exist. Downloading from $1"
    wget -q $1 -O $2
    fi
}

mkdir -p ${WORK_DIR}

downloadIfNotExist "${GO_URL}" "/tmp/go.tgz"
downloadIfNotExist "${FW_URL}" "/tmp/installer.run"
downloadIfNotExist "${QT_URL}" "/tmp/qt.run"

chmod a+x /tmp/installer.run
chmod a+x /tmp/qt.run

#install Qt 
export LM_SDK_BUILD_DIR=${WORK_DIR}

if [ ! -d ${WORK_DIR}/qt ]; then
    echo "Running Qt install."
    /tmp/qt.run -platform minimal -v --script ${SRC_DIR}/scripts/qt-install-script.js
else
    echo "Skipping Qt install, as its there already."
fi

if [ ! -d ${WORK_DIR}/installerfw ]; then
    echo "Running Installer framework install."
    /tmp/installer.run -platform minimal -v --script ${SRC_DIR}/scripts/qt-installer-installscript.js
else
    echo "Skipping Installer framework install, as its there already."
fi

if [ ! -d ${WORK_DIR}/go ]; then
    echo "Running Go install."
    tar -C ${WORK_DIR} -xf /tmp/go.tgz
else
    echo "Skipping Go install, as its there already."
fi

export GOROOT=${WORK_DIR}/go
export PATH=$GOROOT/bin:$PATH

cd ${WORK_DIR}
cmake -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DQT_INSTALL_DIR="${WORK_DIR}/qt/5.9.3/gcc_64" -DINSTALLER_PATH="${WORK_DIR}/installerfw/"  ${SRC_DIR}
make installer

