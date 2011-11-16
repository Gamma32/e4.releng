#!/bin/bash
#

writableBuildRoot=/shared/eclipse/e4
supportDir=$writableBuildRoot/build/e4
relengBranch=HEAD
while [ $# -gt 0 ]
do
        case "$1" in
                "-branch")
                        relengBranch="$2"; shift;;
                 *) break;;      # terminate while loop
        esac
        shift
done


cd $supportDir
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update \
  -d org.eclipse.e4.builder_$relengBranch
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update \
  -d org.eclipse.e4.sdk_$relengBranch
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse update \
  -d org.eclipse.releng.eclipsebuilder_$relengBranch

cp org.eclipse.e4.builder_$relengBranch/scripts/masterBuild.sh $writableBuildRoot

cd $writableBuildRoot
/bin/bash -l $writableBuildRoot/masterBuild.sh >$writableBuildRoot/logs/current.log 2>&1

