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
user=pwebster
email=pwebster@ca.ibm.com
name="E4 Build"
writableBuildRoot=/shared/eclipse/e4
supportDir=$writableBuildRoot/build/e4
GIT_CLONES=$supportDir/gitClones
buildType=I
date=$(date +%Y%m%d)
time=$(date +%H%M)
timestamp=$date$time
relengBranch=master

while [ $# -gt 0 ]
do
        case "$1" in
                "-branch")
                        relengBranch="$2"; shift;;

                "-I")
                        buildType=I;
                        tagMaps="-DtagMaps=true";
                        compareMaps="-DcompareMaps=true";;
                "-N")
                        buildType=N;
                        tagMaps="";
                        compareMaps="";
                        fetchTag="-DfetchTag=CVS=HEAD,GIT=origin/master";;

                "-root")
                        writableBuildRoot="$2"; shift;;

                "-timestamp")
                        timestamp="$2";
                        date=${timestamp:0:8}
                        time=${timestamp:8};
                        shift;;

                "-noTag")
                        noTag=true;;

                -*)
                        echo >&2 usage: $0 [-I | -N]
                        exit 1;;
                 *) break;;      # terminate while loop
        esac
        shift
done

#Pull or clone a branch from a repository
#Usage: pull repositoryURL  branch
pull() {
        pushd $GIT_CLONES
        directory=$(basename $1 .git)
        if [ ! -d $directory ]; then
                echo git clone $1
                git clone $1
                cd $directory
                git config --add user.email "$email"
                git config --add user.name "$name"
        fi
        popd
        pushd $GIT_CLONES/$directory
        echo git checkout $2
        git checkout $2
        echo git pull
        git pull
        popd
}
#Nothing to do for nightly builds, or if $noTag is specified
if [ "$buildType" == "N" -o "$noTag" ]; then
        echo Skipping build tagging for nightly build or -noTag build
        exit
fi

pushd $writableBuildRoot
relengRepo=$GIT_CLONES/org.eclipse.e4.releng
#pull the releng project to get the list of repositories to tag
pull "ssh://$user@git.eclipse.org/gitroot/e4/org.eclipse.e4.releng.git" $relengBranch

if [ ! -f git-map.sh ]; then
    cp $relengRepo/org.eclipse.e4.builder/scripts/git-map.sh .
fi
chmod 744 git-map.sh
if [ ! -f git-submission.sh ]; then
    cp $relengRepo/org.eclipse.e4.builder/scripts/git-submission.sh .
fi
chmod 744 git-submission.sh


#remove comments
rm -f repos-clean.txt clones.txt
cat "$relengRepo/tagging/repositories.txt" | grep -v "^#" > repos-clean.txt
#clone or pull each repository and checkout the appropriate branch
while read line; do
        #each line is of the form <repository> <branch>
        set -- $line
        pull $1 $2
        echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' >> clones.txt
done < repos-clean.txt

cat clones.txt| xargs /bin/bash git-map.sh $GIT_CLONES \
        $relengRepo > maps.txt

#Trim out lines that don't require execution
grep -v ^OK maps.txt | grep -v ^Executed >run.txt
/bin/bash run.txt

mkdir $writableBuildRoot/$buildType$timestamp
cp report.txt $writableBuildRoot/$buildType$timestamp

cd $relengRepo
git add $( find . -name "*.map" )
git commit -m "Releng build tagging for $buildType$timestamp"
git tag -f $buildType$timestamp   #tag the map file change

git push
git push --tags

popd
