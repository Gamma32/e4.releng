#!/bin/bash
#

writableBuildRoot=/shared/eclipse/e4
supportDir=$writableBuildRoot/build/e4
GIT_CLONES=$supportDir/gitClones
relengBranch=master

while [ $# -gt 0 ]
do
        case "$1" in
                "-branch")
                        relengBranch="$2"; shift;;
                 *) break;;      # terminate while loop
        esac
        shift
done


cd $GIT_CLONES/org.eclipse.e4.releng
git checkout $relengBranch
git pull


cp $GIT_CLONES/org.eclipse.e4.releng/org.eclipse.e4.builder/scripts/masterBuild.sh \
  $GIT_CLONES/org.eclipse.e4.releng/org.eclipse.e4.builder/scripts/git-release.sh \
  $writableBuildRoot

cd $writableBuildRoot
/bin/bash -l $writableBuildRoot/masterBuild.sh -branch $relengBranch >$writableBuildRoot/logs/current.log 2>&1

