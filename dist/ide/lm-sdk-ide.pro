####################################################################
#
# This file is part of the LinkMotion plugins.
#
# License: GNU Lesser General Public License v 2.1
# Author: Benjamin Zeller <benjamin.zeller@link-motion.com>
#
# All rights reserved.
# (C) 2017 Link Motion Oy
####################################################################

TEMPLATE = subdirs
SUBDIRS = ide \
          plugins \
#          misc

OTHER_FILES += .qmake.conf

ide.subdir = qtcreator
ide.target = ide_target

plugins.subdir = qtcreator-plugin-linkmotion
plugins.target = plugins_target

misc.file = $$PWD/misc.pro

plugins.depends = ide
misc.depends = ide plugins

docs.target = docs
docs.commands = cd $$OUT_PWD/qtcreator && make docs

deployqt.target = deployqt
deployqt.commands = cd $$OUT_PWD/qtcreator-plugin-linkmotion && make install && cd $$OUT_PWD/qtcreator && make deployqt
deployqt.depends = ide_target plugins_target


QMAKE_EXTRA_TARGETS += docs deployqt

