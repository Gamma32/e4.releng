#!/bin/bash

quietCVS=-Q
supportDir=/shared/eclipse/e4/build/e4
projRelengBranch="HEAD"; # default set below
builddate=$( date +%Y%m%d )
buildtime=$( date +%H%M )


projRoot=':pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse'
#
#tag maps
#projRoot='pwebster@dev.eclipse.org:/cvsroot/eclipse'
#tagMaps=-tagMaps
#publish
#publishDir="pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/e4/downloads/drops "


# first, let's check out all of those pesky projects
cd $supportDir

#basebuilderBranch=$( grep v2008 /cvsroot/eclipse/org.eclipse.releng.basebuilder/about.html,v | head -1 | cut -f1 -d: | tr -d "[:blank:]" )
basebuilderBranch=v20081210a

if [[ ! -d org.eclipse.releng.basebuilder_${basebuilderBranch} ]]; then
  echo "[start] [`date +%H\:%M\:%S`] get org.eclipse.releng.basebuilder_${basebuilderBranch}"
  cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS ex -r $basebuilderBranch -d org.eclipse.releng.basebuilder_${basebuilderBranch} org.eclipse.releng.basebuilder"
  echo $cmd
  $cmd
fi

echo "[start] [`date +%H\:%M\:%S`] setting org.eclipse.releng.basebuilder_${basebuilderBranch}"
rm org.eclipse.releng.basebuilder
ln -s ${supportDir}/org.eclipse.releng.basebuilder_${basebuilderBranch} org.eclipse.releng.basebuilder

if [[ ! -d org.eclipse.e4.builder_${projRelengBranch} ]]; then
  echo "[start] [`date +%H\:%M\:%S`] get org.eclipse.e4.builder_${projRelengBranch}"
  cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS co -r $projRelengBranch -d org.eclipse.e4.builder_${projRelengBranch} e4/releng/org.eclipse.e4.builder"
  echo $cmd
  $cmd
else
  cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS update org.eclipse.e4.builder_${projRelengBranch} "
  echo $cmd
  $cmd
fi

echo "[start] [`date +%H\:%M\:%S`] setting org.eclipse.e4.builder_${projRelengBranch}"
rm org.eclipse.e4.builder
ln -s ${supportDir}/org.eclipse.e4.builder_${projRelengBranch} org.eclipse.e4.builder

cd $supportDir/org.eclipse.e4.builder/scripts

#eclipseIBuild=$( ls -d /home/data/httpd/download.eclipse.org/eclipse/downloads/drops/I*/eclipse-SDK-I*-linux-gtk.tar.gz | tail -1 | cut -d/ -f9 )
eclipseIBuild=I20081211-1908

echo "[start] [`date +%H\:%M\:%S`] setting eclipse $eclipseIBuild"


buildFeature() {
if [ "$1" = "repo" ]; then
  repo="-genRepo"
  shift
else
  repo=""
fi

./start.sh \
  -writableBuildRoot /shared/eclipse/e4 \
  -version 4.0.0 \
  -buildDate $builddate \
  -buildTime $buildtime \
  -projRelengRoot "$projRoot" \
  -projRelengPath 'e4/releng' \
  -projRelengBranch $projRelengBranch \
  -basebuilderBranch ${basebuilderBranch}  \
  -eclipseIBuild $eclipseIBuild \
  -javaHome /opt/public/common/ibm-java2-ppc-50 \
  -featureId "$1" \
  $repo \
  $tagMaps \
  $publ \
  2>&1 | tee /shared/eclipse/e4/logs/buildlog_`date +%Y%m%d%H%M%S`.txt


}

buildFeature repo org.eclipse.e4.resources.feature
buildFeature repo org.eclipse.e4.swt.as.feature
buildFeature repo org.eclipse.e4.ui.feature

buildFeature org.eclipse.e4.resources.tests.feature
buildFeature org.eclipse.e4.swt.as.tests.feature
buildFeature org.eclipse.e4.ui.examples.feature

buildTimestamp=${builddate}-${buildtime}
buildDir=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0
buildDirectory=$buildDir/I$buildTimestamp

if [ ! -z "$publishDir" ]; then
  echo Publishing  $buildDirectory/I$buildTimestamp to "$publishDir"
  scp -r $buildDirectory/I$buildTimestamp "$publishDir"
fi


# try some tests
#testDir=$buildDirectory/tests

#cd $testDir
#unzip $buildDirectory/../eclipse-Automated-Tests-${eclipseBuildId}.zip
#cp $buildDirectory/../eclipse-SDK-${eclipseBuildId}-linux-gtk.tar.gz  eclipse-testing
#cp $buildDirectory/../emf-runtime-2.4.1.zip eclipse-testing/eclipse-SDK-Iemf-runtime-2.4.1.zip
#for f in $buildDirectory/I$buildTimestamp/*tests.feature.*.zip; do
# cp $f eclipse-testing/eclipse-junit-tests-$f
#done

#cd eclipse-testing

