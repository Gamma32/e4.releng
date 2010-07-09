#!/bin/bash
#

writableBuildRoot=/shared/eclipse/e4
supportDir=$writableBuildRoot/build/e4

cd $supportDir
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update \
  -d org.eclipse.e4.builder_HEAD
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update \
  -d org.eclipse.e4.sdk
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update \
  -d org.eclipse.releng.eclipsebuilder

cp org.eclipse.e4.builder_HEAD/scripts/masterBuild.sh $writableBuildRoot

cd $writableBuildRoot
/bin/bash -l $writableBuildRoot/masterBuild.sh >$writableBuildRoot/logs/current.log 2>&1

