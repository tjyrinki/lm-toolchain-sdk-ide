if ( ${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR} )
    message( FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt." )
endif()

project(lm-sdk-ide C CXX)

# https://download.qt.io/official_releases/qt-installer-framework/3.0.2/QtInstallerFramework-linux-x64.run
# https://download.qt.io/official_releases/qt/5.9/5.9.3/qt-opensource-linux-x64-5.9.3.run

include(ExternalProject)
include(ProcessorCount)

function(ConcatStrings targetVar )
  set(loc_val ${${targetVar}})
  foreach(curr_substr ${ARGN})
      set(loc_val "${loc_val}${curr_substr}")
  endforeach()
  set(${targetVar} ${loc_val} PARENT_SCOPE)
endfunction()

ProcessorCount(JOBS)
if(NOT JOBS EQUAL 0)
  MATH(EXPR JOBS "${JOBS}*2")
  
  message("Running with ${JOBS} threads")
  set(GENERATED_MAKE_FLAGS -j${JOBS})
endif()

cmake_minimum_required(VERSION 2.8.9)
set (lm_sdk_VERSION_MAJOR 3)
set (lm_sdk_VERSION_MINOR 5)

set (EXT_SOURCE_DIR "${CMAKE_SOURCE_DIR}/dist")
set (QT_INSTALL_DIR "/usr" CACHE FILEPATH "")
set (INSTALLER_PATH "/usr" CACHE FILEPATH "")


IF(CMAKE_BUILD_TYPE MATCHES DEBUG)
    message("debug mode enabled")
    set(QMAKE_ADDITIONAL_CONF "CONFIG+=DEBUG")
    set(CMAKE_ADDITIONAL_CONF "-DCMAKE_BUILD_TYPE=Debug")
    set(CMAKE_BUILD_TYPE_STRING "Debug")
ELSE(CMAKE_BUILD_TYPE MATCHES DEBUG)
    message("Release Build enabled")
    set(CMAKE_BUILD_TYPE_STRING "RelWithDebugInfo")
    set(QMAKE_ADDITIONAL_CONF "CONFIG+=release CONFIG+=force_debug_info CONFIG+=separate_debug_info")
    set(CMAKE_ADDITIONAL_CONF "-DCMAKE_BUILD_TYPE=RelWithDebugInfo")
ENDIF(CMAKE_BUILD_TYPE MATCHES DEBUG)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/sync_submodules
                   COMMAND git submodule update --init
                   COMMAND touch ${CMAKE_BINARY_DIR}/sync_submodules
                   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/dist/ide/qtcreator-plugin-linkmotion/src/lmbaseplugin/cred_key.h
                   COMMAND CRED_FILE=${CMAKE_SOURCE_DIR}/dist/ide/qtcreator-plugin-linkmotion/src/lmbaseplugin/cred_key.h  ${CMAKE_SOURCE_DIR}/scripts/generate_cred_key.sh
                   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})  

add_custom_target(ApplyPatches
                  ${CMAKE_SOURCE_DIR}/apply-patches.sh
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  DEPENDS ${CMAKE_BINARY_DIR}/sync_submodules ${CMAKE_SOURCE_DIR}/dist/ide/qtcreator-plugin-linkmotion/src/lmbaseplugin/cred_key.h)

SET (QTCREATOR_PREFIX "${CMAKE_BINARY_DIR}/qtcreator-build")
ExternalProject_Add(qtcreator
  DEPENDS ApplyPatches
  PREFIX      "${QTCREATOR_PREFIX}"
  SOURCE_DIR  "${EXT_SOURCE_DIR}/ide"
  BINARY_DIR  "${QTCREATOR_PREFIX}/build"
  INSTALL_DIR "${CMAKE_BINARY_DIR}/lm-sdk-ide"
  DOWNLOAD_COMMAND  sh -c "exit 0"
  CONFIGURE_COMMAND sh -c "LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib ${QT_INSTALL_DIR}/bin/qmake -r ${QMAKE_ADDITIONAL_CONF} ${EXT_SOURCE_DIR}/ide/lm-sdk-ide.pro"
  BUILD_COMMAND     sh -c "QT_PRIVATE_HEADERS=${QT_INSTALL_DIR} LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib make ${GENERATED_MAKE_FLAGS}"
  INSTALL_COMMAND   sh -c "QT_PRIVATE_HEADERS=${QT_INSTALL_DIR} LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib make INSTALL_ROOT=${CMAKE_BINARY_DIR}/lm-sdk-ide -j1 docs deployqt"
)

SET (TOOLS_PREFIX "${CMAKE_BINARY_DIR}/tools-build")
ConcatStrings (LMSDK_TOOLS_DOWNLOAD_SCRIPT
  "ln -s ${EXT_SOURCE_DIR}/link-motion.com ${TOOLS_PREFIX}/build/src/link-motion.com && "
  "env GOPATH=${TOOLS_PREFIX}/build go get -d link-motion.com/lm-toolchain-sdk-tools/lmsdk-target && "
  "env GOPATH=${TOOLS_PREFIX}/build go get -d link-motion.com/lm-toolchain-sdk-tools/lmsdk-wrapper &&"
  "env GOPATH=${TOOLS_PREFIX}/build go get -d link-motion.com/lm-toolchain-sdk-tools/lmsdk-download"
)
ExternalProject_Add(lm-sdk-tools
  PREFIX      "${TOOLS_PREFIX}"
  SOURCE_DIR   "${EXT_SOURCE_DIR}/link-motion.com"
  DOWNLOAD_DIR "${TOOLS_PREFIX}/build/src"
  BINARY_DIR  "${TOOLS_PREFIX}/build"
  INSTALL_DIR "${CMAKE_BINARY_DIR}/lm-sdk-ide/bin"
  DOWNLOAD_COMMAND  sh -c "${LMSDK_TOOLS_DOWNLOAD_SCRIPT}"
  # PATCH_COMMAND     sh -c "cd ${TOOLS_PREFIX}/build/src && patch -p1 -i ${EXT_SOURCE_DIR}/link-motion.com/lm-toolchain-sdk-tools/patches/lxc.patch"
  CONFIGURE_COMMAND sh -c "exit 0"
  BUILD_COMMAND     sh -c "env GOPATH=${TOOLS_PREFIX}/build go install link-motion.com/lm-toolchain-sdk-tools/lmsdk-target && env GOPATH=${TOOLS_PREFIX}/build go install link-motion.com/lm-toolchain-sdk-tools/lmsdk-wrapper && env GOPATH=${TOOLS_PREFIX}/build go install link-motion.com/lm-toolchain-sdk-tools/lmsdk-download"
  INSTALL_COMMAND   sh -c "install -t ${CMAKE_BINARY_DIR}/lm-sdk-ide/bin ${TOOLS_PREFIX}/build/bin/lmsdk-target ${TOOLS_PREFIX}/build/bin/lmsdk-wrapper ${TOOLS_PREFIX}/build/bin/lmsdk-download ${EXT_SOURCE_DIR}/link-motion.com/lm-toolchain-sdk-tools/share/lxc-lm-download"
  DEPENDS ApplyPatches
)

if(NOT SKIP_INSTALLER)

  set (QT_STATIC_BUILD_DIR    "${CMAKE_BINARY_DIR}/qt-static-build/build")
  set (QT_STATIC_INSTALL_DIR  "${CMAKE_BINARY_DIR}/qt-static")

  SET (INSTALLER_BUILD_DIR "${CMAKE_BINARY_DIR}/installer")
  add_custom_target(installer
    COMMAND rsync -av --delete ${CMAKE_SOURCE_DIR}/installer/ ${CMAKE_BINARY_DIR}/installer
    COMMAND 7z a ${INSTALLER_BUILD_DIR}/packages/fi.linkmotion.qtcreator/data/lm-sdk-ide.7z ${CMAKE_BINARY_DIR}/lm-sdk-ide '-xr!*.debug'
    COMMAND ${INSTALLER_PATH}/bin/binarycreator --offline-only 
      -c ${INSTALLER_BUILD_DIR}/config.xml -p ${INSTALLER_BUILD_DIR}/packages
      -i fi.linkmotion.reqs,fi.linkmotion.qtcreator
      LinkMotionSDK.sh
    COMMAND ${INSTALLER_PATH}/bin/binarycreator --online-only 
      -c ${INSTALLER_BUILD_DIR}/config.xml -p ${INSTALLER_BUILD_DIR}/packages
      LinkMotionSDK-Online.sh
    COMMAND ${INSTALLER_PATH}/bin/repogen -r
      -p ${INSTALLER_BUILD_DIR}/packages
      -i fi.linkmotion.reqs,fi.linkmotion.qtcreator
      lm-repository
    DEPENDS lm-sdk-tools qtcreator
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )

  add_custom_target(deploy-installer
    COMMAND rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress --delete
            LinkMotionSDK* builder@tre-ci.build.link-motion.com:/data/build-artifacts/lm-sdk-ide/ 
    COMMAND rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress --delete
            lm-repository/ builder@tre-ci.build.link-motion.com:/data/build-artifacts/lm-sdk-ide/repository

    DEPENDS installer
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )

endif(NOT SKIP_INSTALLER)
