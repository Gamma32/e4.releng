#!/bin/bash +x

mavenVerbose=-X
mavenSign=-Peclipse-sign
mavenBREE=-Pbree-libs

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

eclipseStream=4.3
e4Stream=0.14
basebuilderBranch=R3_7
eclipsebuilderBranch=R4_HEAD

quietCVS=-Q
arch="x86_64"
archProp="-x86_64"
processor=$( uname -p )
if [ $processor = ppc -o $processor = ppc64 ]; then
    archProp="-ppc"
    archJavaProp="-DarchProp=-ppc"
    arch="ppc"
fi

#
#  control various aspects of the build
#

publish=true
tag=true



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

if [ "$buildType" = N ]; then
	tag=false
fi

#publish
publishIndex="${committerId}@build.eclipse.org:/home/data/httpd/download.eclipse.org/e4/downloads"
publishUpdates="${committerId}@build.eclipse.org:/home/data/httpd/download.eclipse.org/e4/updates"
publishDir="${publishIndex}/drops"






# common properties

javaHome=/opt/public/common/sun-jdk1.6.0_21_x64
buildTimestamp=${date}-${time}
buildTag=$buildType$buildTimestamp

oldBuildTag=$( cat $writableBuildRoot/${buildType}build.properties )
echo "Last build: $oldBuildTag"
echo $buildTag >$writableBuildRoot/${buildType}build.properties

buildDir=$writableBuildRoot/build/e4/downloads/drops/4.0.0
targetDir=${buildDir}/targets
targetZips=$targetDir/downloads
transformedRepo=${targetDir}/helios-p2
buildDirectory=$buildDir/$buildTag
updateSite=${targetDir}/updates/${e4Stream}-I-builds
    
e4TestDir=/opt/buildhomes/e4Build/e4Tests/$buildTag
sdkTestDir=/opt/buildhomes/e4Build/sdkTests/$buildTag
    
buildResults=$buildDirectory/$buildTag
    
sdkResults=$buildDir/40builds/$buildTag/$buildTag
sdkBuildDirectory=$buildDir/40builds/$buildTag

buildDirEclipse="$buildDir/eclipse"
WORKSPACE="$buildDir/workspace"
export WORKSPACE

TMP_DIR=$buildDirectory/tmp
export MAVEN_PATH=/opt/public/common/apache-maven-3.0.4/bin
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=256M -Djava.io.tmpdir=${TMP_DIR}"
export JAVA_HOME=/opt/public/common/jdk1.7.0_11
export PATH=$JAVA_HOME/bin:${MAVEN_PATH}:$PATH


mkdir -p $TMP_DIR

cd $buildDirectory

gunzip -dc /home/data/httpd/download.eclipse.org/eclipse/downloads/drops4/R-4.2.2-201302041200/eclipse-SDK-4.2.2-linux-gtk-x86_64.tar.gz  | \
tar xf -

ECLIPSE=$(pwd)/eclipse/eclipse

localMavenRepo=$buildDirectory/localRepo

e4_releng=file:///gitroot/e4/org.eclipse.e4.releng.git
e4_tools=file:///gitroot/e4/org.eclipse.e4.tools.git
e4_search=file:///gitroot/e4/org.eclipse.e4.search.git
e4_lang=file:///gitroot/e4/org.eclipse.e4.languages.git
e4_resources=file:///gitroot/e4/org.eclipse.e4.resources.git
e4_databinding=file:///gitroot/e4/org.eclipse.e4.databinding.git

#git clone file:///gitroot/cbi/org.eclipse.cbi.maven.plugins.git
git clone $e4_releng
git clone $e4_tools
git clone $e4_search
git clone $e4_lang
git clone $e4_resources
git clone $e4_databinding

# tag first


pushd org.eclipse.e4.releng
git tag $buildTag
git push origin $buildTag
popd

pushd org.eclipse.e4.tools
git tag $buildTag
git push origin $buildTag
popd

pushd org.eclipse.e4.search
git tag $buildTag
git push origin $buildTag
popd

pushd org.eclipse.e4.languages
git tag $buildTag
git push origin $buildTag
popd

pushd org.eclipse.e4.resources
git tag $buildTag
git push origin $buildTag
popd

pushd org.eclipse.e4.databinding
git tag $buildTag
git push origin $buildTag
popd

/bin/bash \
org.eclipse.e4.releng/org.eclipse.e4.builder/scripts/git-submission.sh \
$(pwd) \
$( echo $e4_tools | sed 's!file:///!git://git.eclipse.org/!g' ) \
$oldBuildTag $buildTag \
$( echo $e4_search | sed 's!file:///!git://git.eclipse.org/!g' ) \
$oldBuildTag $buildTag \
$( echo $e4_lang | sed 's!file:///!git://git.eclipse.org/!g' ) \
$oldBuildTag $buildTag \
$( echo $e4_resources | sed 's!file:///!git://git.eclipse.org/!g' ) \
$oldBuildTag $buildTag \
$( echo $e4_databinding | sed 's!file:///!git://git.eclipse.org/!g' ) \
$oldBuildTag $buildTag >submission_report.txt 2>&1

mailx -s "$e4Stream Build: $buildTag submission" e4-dev@eclipse.org <submission_report.txt


# build everything


# In theory, this comes from repo.eclipse.org
#pushd org.eclipse.cbi.maven.plugins
#mvn -X \
#clean install \
#-Dmaven.repo.local=$localMavenRepo
#popd


pushd org.eclipse.e4.releng/cbi
mvn -f eclipse-parent/pom.xml \
clean install \
-Dmaven.repo.local=$localMavenRepo
popd

pushd org.eclipse.e4.tools
mvn $mavenVerbose \
clean install \
$mavenSign \
$mavenBREE \
-Dmaven.test.skip=true \
-Dmaven.repo.local=$localMavenRepo
popd

pushd org.eclipse.e4.search
mvn $mavenVerbose \
clean install \
$mavenSign \
$mavenBREE \
-Dmaven.test.skip=true \
-Dmaven.repo.local=$localMavenRepo
popd

pushd org.eclipse.e4.languages
mvn $mavenVerbose \
clean install \
$mavenSign \
$mavenBREE \
-Dmaven.test.skip=true \
-Dmaven.repo.local=$localMavenRepo
popd

pushd org.eclipse.e4.resources
mvn $mavenVerbose \
clean install \
$mavenSign \
$mavenBREE \
-Dmaven.test.skip=true \
-Dmaven.repo.local=$localMavenRepo
popd

pushd org.eclipse.e4.databinding
mvn $mavenVerbose \
clean install \
$mavenSign \
$mavenBREE \
-Dmaven.test.skip=true \
-Dmaven.repo.local=$localMavenRepo
popd

pushd org.eclipse.e4.releng/cbi
mvn -f org.eclipse.e4.releng.update/pom.xml \
clean verify \
-DbuildDirectory=$buildDirectory \
-Dmaven.repo.local=$localMavenRepo
popd

if [ ! -e repository ]; then
	mailx -s "$e4Stream Build: $buildTag Failed" e4-dev@eclipse.org <<EOF
Build log: http://build.eclipse.org/eclipse/e4/cbi/log.txt

EOF
exit 0
fi

# update the common repo

$ECLIPSE \
-noSplash \
-application org.eclipse.equinox.p2.artifact.repository.mirrorApplication \
-source file://$(pwd)/repository \
-destination file://$updateSite \
-destinationName $e4Stream-I-builds


$ECLIPSE \
-noSplash \
-application org.eclipse.equinox.p2.metadata.repository.mirrorApplication \
-source file://$(pwd)/repository \
-destination file://$updateSite \
-destinationName $e4Stream-I-builds

# get ready to publish

mkdir -p $buildResults
cp -r repository $buildResults
cp submission_report.txt $buildResults

pushd repository
zip -r $buildResults/eclipse-e4-repo-incubation-${buildTag}.zip *
popd


cp org.eclipse.e4.releng/org.eclipse.e4.builder/templates/build.index.html t1
sed "s/@repbuildid@/$buildTag/g" t1 >t2
sed "s/@repmaindate@/$timestamp/g" t2 >t1
sed "s/@repbuilddate@/$buildTag/g" t1 >t2
repoSize=$( ls -l $buildResults/eclipse-e4-repo-incubation-${buildTag}.zip | awk ' {print $5 }' )
sed "s/@repobuildsize@/${repoSize}/g" t2 >$buildResults/index.html
rm -f t1 t2

cp /shared/eclipse/e4/cbi/log.txt $buildResults/buildlog.txt


echo Publishing  $buildResults to "$publishDir"
scp -r $buildResults "$publishDir"
rsync --recursive --delete ${updateSite} \
"${publishUpdates}"
#sendMail
sleep 60
wget -O index.txt http://download.eclipse.org/e4/downloads/createIndex.php
scp index.txt "$publishIndex"/index.html



