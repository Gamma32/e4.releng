#!/bin/bash
#

writableBuildRoot=/shared/eclipse/e4
supportDir=$writableBuildRoot/build/e4

cd $supportDir
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update -r R4_1_SDK_LONGBUILD \
  -d org.eclipse.e4.builder_R4_1_SDK_LONGBUILD
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update -r R4_1_SDK_LONGBUILD \
  -d org.eclipse.e4.sdk_R4_1_SDK_LONGBUILD
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update \
  -d org.eclipse.releng.eclipsebuilder

cp org.eclipse.e4.builder_R4_1_SDK_LONGBUILD/scripts/masterBuild.sh $writableBuildRoot

cd $writableBuildRoot
/bin/bash -l $writableBuildRoot/masterBuild.sh >$writableBuildRoot/logs/current.log 2>&1

