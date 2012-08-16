#!/bin/bash

#*******************************************************************************
# Copyright (c) 2011 IBM Corporation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     IBM Corporation - initial API and implementation
#*******************************************************************************

#default values, overridden by command line
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
tag=true
noTag=false

ARGS="$@"

while [ $# -gt 0 ]
do
        case "$1" in
                "-branch")
                        relengBranch="$2"; shift;;
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
                "-oldBuildTag")
                        oldBuildTag="$2"; shift;;
                "-buildTag")
                        buildTag="$2"; shift;;
                "-basebuilderBranch")
                        basebuilderBranch="$2"; shift;;
                "-eclipsebuilderBranch")
                        eclipsebuilderBranch="$2"; shift;;
                "-tag")
                        tag="$2"; shift;;
                "-timestamp")
                        timestamp="$2";
                        date=${timestamp:0:8}
                        time=${timestamp:8};
                        shift;;
                 *) break;;      # terminate while loop
        esac
        shift
done

if [ -z "$oldBuildTag"  ]; then
  echo You must provide -oldBuildTag
  echo args: "$ARGS"
  exit
fi

if ! $tag; then
	noTag=true
fi

supportDir=$writableBuildRoot/build/e4
if [ -z "$gitCache" ]; then
	gitCache=$supportDir/gitClones
fi

if [ -z "$buildTag" ]; then
	buildTag=$buildType${date}-${time}
fi

#Pull or clone a branch from a repository
#Usage: pull repositoryURL  branch
pull() {
        pushd $gitCache
        directory=$(basename $1 .git)
        if [ ! -d $directory ]; then
                echo git clone $1
                git clone $1
                cd $directory
                git config --add user.email "$gitEmail"
                git config --add user.name "$gitName"
        fi
        popd
        pushd $gitCache/$directory
        # git fetch first, to be sure new branches can be "seen" to be checked out
        echo "git fetch"
        git fetch
        echo git checkout $2
        git checkout $2
        echo git pull
        git pull
        popd
}

#Nothing to do for nightly builds, or if $noTag is specified
if $noTag || [ "$buildType" == "N" ]; then
        echo Skipping build tagging for nightly build or -tag false build
        exit
fi

pushd $writableBuildRoot
relengRepo=$gitCache/${relengProject}
# pull the releng project to get the list of repositories to tag
pull "ssh://$committerId@git.eclipse.org/gitroot/e4/org.eclipse.e4.releng.git" $relengBranch

wget -O git-map.sh http://git.eclipse.org/c/e4/org.eclipse.e4.releng.git/plain/org.eclipse.e4.builder/scripts/git-map.sh
wget -O git-submission.sh http://git.eclipse.org/c/e4/org.eclipse.e4.releng.git/plain/org.eclipse.e4.builder/scripts/git-submission.sh
#cp /opt/pwebster/git/R42/org.eclipse.e4.releng/org.eclipse.e4.builder/scripts/git-map.sh .
#cp /opt/pwebster/git/R42/org.eclipse.e4.releng/org.eclipse.e4.builder/scripts/git-submission.sh .


#remove comments
rm -f repos-clean.txt clones.txt repos-report.txt

cat "$relengRepo/tagging/repositories.txt" | grep -v "^#" > repos-clean.txt
# clone or pull each repository and checkout the appropriate branch
while read line; do
        #each line is of the form <repository> <branch>
        set -- $line
        pull $1 $2
        echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' >> clones.txt
done < repos-clean.txt

cat repos-clean.txt | sed "s/ / $oldBuildTag /" >repos-report.txt

# generate the change report
mkdir $writableBuildRoot/$buildTag
echo "[git-release]" git-submission.sh $gitCache $( cat repos-report.txt )
/bin/bash git-submission.sh $gitCache $( cat repos-report.txt ) > $writableBuildRoot/$buildTag/report.txt


cat clones.txt| xargs /bin/bash git-map.sh $gitCache $buildTag \
        $relengRepo > maps.txt

#Trim out lines that don't require execution
grep -v ^OK maps.txt | grep -v ^Executed >run.txt
/bin/bash run.txt


cd $relengRepo
git add $( find . -name "*.map" )
git commit -m "Releng build tagging for $buildTag"
git tag -f $buildTag   #tag the map file change

git push
git push --tags

popd
