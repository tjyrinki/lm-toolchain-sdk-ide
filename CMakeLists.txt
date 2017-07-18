if ( ${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR} )
    message( FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt." )
endif()

project(lm-sdk-ide C CXX)

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
  set(GENERATED_MAKE_FLAGS -j${JOBS})
endif()

cmake_minimum_required(VERSION 2.8.9)
set (lm_sdk_VERSION_MAJOR 3)
set (lm_sdk_VERSION_MINOR 5)

set (QT_VERSION      "qt-5.9.0")
set (EXT_SOURCE_DIR  "${CMAKE_SOURCE_DIR}/dist")
set (QT_SOURCE_DIR   "${EXT_SOURCE_DIR}/qt5")
set (QT_BUILD_DIR    "${CMAKE_BINARY_DIR}/qt-build/build")
set (QT_INSTALL_DIR  "${CMAKE_BINARY_DIR}/qt")

IF(CMAKE_BUILD_TYPE MATCHES DEBUG)
    message("debug mode enabled")
    set(QT_ADDITIONAL_CONF "-debug")
    set(QMAKE_ADDITIONAL_CONF "CONFIG+=DEBUG")
    set(CMAKE_ADDITIONAL_CONF "-DCMAKE_BUILD_TYPE=Debug")
    set(CMAKE_BUILD_TYPE_STRING "Debug")
ELSE(CMAKE_BUILD_TYPE MATCHES DEBUG)
    message("Release Build enabled")
    set(CMAKE_BUILD_TYPE_STRING "RelWithDebugInfo")
    #set(QT_ADDITIONAL_CONF "-force-debug-info")
    set(QMAKE_ADDITIONAL_CONF "CONFIG+=release CONFIG+=force_debug_info CONFIG+=separate_debug_info")
    set(CMAKE_ADDITIONAL_CONF "-DCMAKE_BUILD_TYPE=RelWithDebugInfo")
ENDIF(CMAKE_BUILD_TYPE MATCHES DEBUG)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/sync_submodules
                   COMMAND git submodule update --checkout
                   COMMAND touch ${CMAKE_BINARY_DIR}/sync_submodules
                   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

add_custom_target(InitQt
                  ${QT_SOURCE_DIR}/init-repository -q
                  WORKING_DIRECTORY ${QT_SOURCE_DIR}
		  DEPENDS ${CMAKE_BINARY_DIR}/sync_submodules)

add_custom_target(ApplyPatches
                  ${CMAKE_SOURCE_DIR}/apply-patches.sh
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		  DEPENDS InitQt)


ExternalProject_Add(${QT_VERSION}
  PREFIX      "qt-build"
  SOURCE_DIR  "${QT_SOURCE_DIR}"
  BINARY_DIR  "${QT_BUILD_DIR}"
  INSTALL_DIR "${QT_INSTALL_DIR}"
  DOWNLOAD_COMMAND  sh -c "exit 0"
  CONFIGURE_COMMAND sh -c "${QT_SOURCE_DIR}/configure -prefix ${QT_INSTALL_DIR} ${QT_ADDITIONAL_CONF} `cat ${CMAKE_SOURCE_DIR}/qt5config`"
  BUILD_COMMAND     sh -c "make ${GENERATED_MAKE_FLAGS}"
  INSTALL_COMMAND   sh -c "make install"
  DEPENDS     ApplyPatches
)

SET (FCITX_PREFIX "${CMAKE_BINARY_DIR}/fcitx-qt-build")
ConcatStrings (FCITX_BUILD_SCRIPT
  "${CMAKE_COMMAND} "
  "-DCMAKE_INSTALL_PREFIX=${QT_INSTALL_DIR} "
  "-DCMAKE_PREFIX_PATH=${QT_INSTALL_DIR} "
  "-DUSE_QT5=true "
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE_STRING} "
  "-DCMAKE_INSTALL_LIBDIR=lib ${EXT_SOURCE_DIR}/fcitx-qt"
)
ExternalProject_Add(fcitx-qt5
  DEPENDS ${QT_VERSION}
  PREFIX      "${FCITX_PREFIX}"
  SOURCE_DIR  "${EXT_SOURCE_DIR}/fcitx-qt"
  BINARY_DIR  "${FCITX_PREFIX}/build"
  INSTALL_DIR "${QT_INSTALL_DIR}"
  DOWNLOAD_COMMAND  sh -c "exit 0"
  CONFIGURE_COMMAND sh -c "${FCITX_BUILD_SCRIPT}"
  BUILD_COMMAND     sh -c "LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib VERBOSE=1 make ${GENERATED_MAKE_FLAGS}"
  INSTALL_COMMAND   sh -c "LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib VERBOSE=1 make install"
)

SET (QTCREATOR_PREFIX "${CMAKE_BINARY_DIR}/qtcreator-build")
ExternalProject_Add(qtcreator
  DEPENDS fcitx-qt5
  PREFIX      "${QTCREATOR_PREFIX}"
  SOURCE_DIR  "${EXT_SOURCE_DIR}/ide"
  BINARY_DIR  "${QTCREATOR_PREFIX}/build"
  INSTALL_DIR "${CMAKE_BINARY_DIR}/lm-sdk-ide"
  DOWNLOAD_COMMAND  sh -c "exit 0"
  CONFIGURE_COMMAND sh -c "${QT_INSTALL_DIR}/bin/qmake -r ${QMAKE_ADDITIONAL_CONF} ${EXT_SOURCE_DIR}/ide/lm-sdk-ide.pro"
  BUILD_COMMAND     sh -c "QT_PRIVATE_HEADERS=${QT_INSTALL_DIR} LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib make ${GENERATED_MAKE_FLAGS}"
  INSTALL_COMMAND   sh -c "QT_PRIVATE_HEADERS=${QT_INSTALL_DIR} LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib make INSTALL_ROOT=${CMAKE_BINARY_DIR}/lm-sdk-ide -j1 docs deployqt"
)

SET (TOOLS_PREFIX "${CMAKE_BINARY_DIR}/tools-build")
ConcatStrings (LMSDK_TOOLS_DOWNLOAD_SCRIPT
  "ln -s ${EXT_SOURCE_DIR}/link-motion.com ${TOOLS_PREFIX}/build/src/link-motion.com && "
  "env GOPATH=${TOOLS_PREFIX}/build go get -d link-motion.com/lm-sdk-tools/lmsdk-target && "
  "env GOPATH=${TOOLS_PREFIX}/build go get -d link-motion.com/lm-sdk-tools/lmsdk-wrapper"
)
ExternalProject_Add(lm-sdk-tools
  PREFIX      "${TOOLS_PREFIX}"
  SOURCE_DIR   "${EXT_SOURCE_DIR}/link-motion.com"
  DOWNLOAD_DIR "${TOOLS_PREFIX}/build/src"
  BINARY_DIR  "${TOOLS_PREFIX}/build"
  INSTALL_DIR "${CMAKE_BINARY_DIR}/lm-sdk-ide/bin"
  DOWNLOAD_COMMAND  sh -c "${LMSDK_TOOLS_DOWNLOAD_SCRIPT}"
  PATCH_COMMAND     sh -c "cd ${TOOLS_PREFIX}/build/src && patch -p1 -i ${EXT_SOURCE_DIR}/link-motion.com/lm-sdk-tools/patches/lxc.patch"
  CONFIGURE_COMMAND sh -c "exit 0"
  BUILD_COMMAND     sh -c "env GOPATH=${TOOLS_PREFIX}/build go install link-motion.com/lm-sdk-tools/lmsdk-target && env GOPATH=${TOOLS_PREFIX}/build go install link-motion.com/lm-sdk-tools/lmsdk-wrapper"
  INSTALL_COMMAND   sh -c "install -t ${CMAKE_BINARY_DIR}/lm-sdk-ide/bin ${TOOLS_PREFIX}/build/bin/lmsdk-target ${TOOLS_PREFIX}/build/bin/lmsdk-wrapper ${EXT_SOURCE_DIR}/link-motion.com/lm-sdk-tools/share/lxc-lm-download"
  DEPENDS ApplyPatches
)

if(NOT SKIP_INSTALLER)

  set (QT_STATIC_BUILD_DIR    "${CMAKE_BINARY_DIR}/qt-static-build/build")
  set (QT_STATIC_INSTALL_DIR  "${CMAKE_BINARY_DIR}/qt-static")

  ExternalProject_Add(${QT_VERSION}-static
    PREFIX      "qt-static-build"
    SOURCE_DIR  "${QT_SOURCE_DIR}"
    BINARY_DIR  "${QT_STATIC_BUILD_DIR}"
    INSTALL_DIR "${QT_STATIC_INSTALL_DIR}"
    DOWNLOAD_COMMAND  sh -c "exit 0"
    CONFIGURE_COMMAND sh -c "${QT_SOURCE_DIR}/configure -prefix ${QT_STATIC_INSTALL_DIR} `cat ${CMAKE_SOURCE_DIR}/qt5config-static`"
    BUILD_COMMAND     sh -c "make ${GENERATED_MAKE_FLAGS}"
    INSTALL_COMMAND   sh -c "make install"
    DEPENDS     ApplyPatches
  )

  SET (INSTALLER_FW_PREFIX "${CMAKE_BINARY_DIR}/installer-fw-build")
  SET (INSTALLER_PATH "${INSTALLER_FW_PREFIX}/build")
  ExternalProject_Add(installer-framework
  DEPENDS ${QT_VERSION}-static
  PREFIX      "${INSTALLER_FW_PREFIX}"
  SOURCE_DIR  "${EXT_SOURCE_DIR}/installer-framework"
  BINARY_DIR  "${INSTALLER_PATH}"
  DOWNLOAD_COMMAND  sh -c "exit 0"
  CONFIGURE_COMMAND sh -c "${QT_STATIC_INSTALL_DIR}/bin/qmake ${EXT_SOURCE_DIR}/installer-framework"
  BUILD_COMMAND     sh -c "VERBOSE=1 make ${GENERATED_MAKE_FLAGS}"
  INSTALL_COMMAND   sh -c "exit 0"
  )

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
    DEPENDS ${QT_VERSION}-static installer-framework
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


#add_custom_target(package
#                  ${CMAKE_SOURCE_DIR}/apply-patches.sh
#                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		  #DEPENDS qtcreator lm-sdk-tools)

#set(QTC_BUILD  "${CMAKE_BINARY_DIR}/ubuntu-sdk-ide")
#set(QTC_SOURCE "${QTCREATOR_PREFIX}/qtcreator")

#SET (QTCREATOR_GO_PREFIX "${CMAKE_BINARY_DIR}/qtcreator-plugin-go-build")
#ExternalProject_Add(qtcreator_plugin_go
#  DEPENDS qtcreator_3.5.0
#  PREFIX      "${QTCREATOR_GO_PREFIX}"
#  SOURCE_DIR  "${QTCREATOR_GO_PREFIX}/qtcreator-plugin-go"
#  BINARY_DIR  "${QTCREATOR_GO_PREFIX}/build"
#  INSTALL_DIR "${QTCREATOR_GO_PREFIX}/ubuntu-sdk-ide"
#  DOWNLOAD_COMMAND  sh -c "bzr branch lp:qtcreator-plugin-go ${QTCREATOR_GO_PREFIX}/qtcreator-plugin-go -Ossl.cert_reqs=none --use-existing-dir"
#  CONFIGURE_COMMAND sh -c "env QTC_BUILD=\"${QTC_BUILD}\" QTC_SOURCE=\"${QTC_SOURCE}\" ${QT_INSTALL_DIR}/bin/qmake -r ${QTCREATOR_GO_PREFIX}/qtcreator-plugin-go"
#  BUILD_COMMAND     sh -c "env QTC_BUILD=\"${QTC_BUILD}\" QTC_SOURCE=\"${QTC_SOURCE}\" QT_PRIVATE_HEADERS=${QT_INSTALL_DIR} LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib make ${GENERATED_MAKE_FLAGS}"
#  #there is no install step required, the plugin is built directly into the installed plugins dir
#  INSTALL_COMMAND   sh -c "exit 0"
#)

# Disable the AP plugin for now
#
#SET (QTCREATOR_AP_PREFIX "${CMAKE_BINARY_DIR}/qtcreator-plugin-autopilot-build")
#ExternalProject_Add(qtcreator_plugin_autopilot
#  DEPENDS qtcreator_3.5.0
#  PREFIX      "${QTCREATOR_AP_PREFIX}"
#  SOURCE_DIR  "${QTCREATOR_AP_PREFIX}/qtcreator-plugin-autopilot"
#  BINARY_DIR  "${QTCREATOR_AP_PREFIX}/build"
#  INSTALL_DIR "${QTCREATOR_AP_PREFIX}/ubuntu-sdk-ide"
#  DOWNLOAD_COMMAND  sh -c "bzr branch lp:qtcreator-plugin-autopilot ${QTCREATOR_AP_PREFIX}/qtcreator-plugin-autopilot  -Ossl.cert_reqs=none --use-existing-dir"
#  CONFIGURE_COMMAND sh -c "env QTC_BUILD=\"${QTC_BUILD}\" QTC_SOURCE=\"${QTC_SOURCE}\" ${QT_INSTALL_DIR}/bin/qmake -r ${QTCREATOR_AP_PREFIX}/qtcreator-plugin-autopilot"
#  BUILD_COMMAND     sh -c "env QTC_BUILD=\"${QTC_BUILD}\" QTC_SOURCE=\"${QTC_SOURCE}\" QT_PRIVATE_HEADERS=${QT_INSTALL_DIR}  LD_LIBRARY_PATH=${QT_INSTALL_DIR}/lib make ${GENERATED_MAKE_FLAGS}"
#  #there is no install step required, the plugin is built directly into the installed plugins dir
#  INSTALL_COMMAND   sh -c "exit 0"
#)
