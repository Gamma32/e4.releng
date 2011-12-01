#!/bin/bash
#
# must be invoked /bin/bash -l bootstrap.sh ARGS
#


writableBuildRoot=/shared/eclipse/e4
relengProject=org.eclipse.e4.releng
relengBranch=master
buildType=I
date=$(date +%Y%m%d)
time=$(date +%H%M)
timestamp=$date$time
committerId=pwebster
gitEmail=pwebster@ca.ibm.com
gitName="E4 Build"
basebuilderBranch=R3_7
eclipsebuilderBranch=R4_HEAD
eclipseStream=4.2
e4Stream=0.12


while [ $# -gt 0 ]
do
        case "$1" in
                "-branch")
                        relengBranch="$2"; shift;;
                "-eclipseStream")
                        eclipseStream="$2"; shift;;
                "-e4Stream")
                        e4Stream="$2"; shift;;
                "-buildType")
                        buildType="$2"; shift;;
                "-gitCache")
                        gitCache="$2"; shift;;
                "-relengProject")
                        relengProject="$2"; shift;;
                "-root")
                        writableBuildRoot="$2"; shift;;
                "-committerId")
                        committerId="$2"; shift;;
                "-gitEmail")
                        gitEmail="$2"; shift;;
                "-gitName")
                        gitName="$2"; shift;;
                "-basebuilderBranch")
                        basebuilderBranch="$2"; shift;;
                "-eclipsebuilderBranch")
                        eclipsebuilderBranch="$2"; shift;;
                "-timestamp")
                        timestamp="$2";
                        date=${timestamp:0:8}
                        time=${timestamp:8};
                        shift;;
                 *) break;;      # terminate while loop
        esac
        shift
done

supportDir=$writableBuildRoot/build/e4
if [ -z "$gitCache" ]; then
	gitCache=$supportDir/gitClones
fi


cd $writableBuildRoot

wget -O masterBuild.sh http://git.eclipse.org/c/e4/org.eclipse.e4.releng.git/plain/org.eclipse.e4.builder/scripts/masterBuild.sh
wget -O git-release.sh http://git.eclipse.org/c/e4/org.eclipse.e4.releng.git/plain/org.eclipse.e4.builder/scripts/git-release.sh

/bin/bash "$writableBuildRoot/masterBuild.sh" -branch "$relengBranch" \
  -relengProject "$relengProject" \
  -eclipseStream $eclipseStream \
  -e4Stream $e4Stream \
  -buildType "$buildType" \
  -gitCache "$gitCache" \
  -root "$writableBuildRoot" \
  -committerId "$committerId" \
  -gitEmail "$gitEmail" \
  -gitName "$gitName" \
  -basebuilderBranch $basebuilderBranch \
  -eclipsebuilderBranch $eclipsebuilderBranch \
  -timestamp "$timestamp" >$writableBuildRoot/logs/current.log 2>&1

