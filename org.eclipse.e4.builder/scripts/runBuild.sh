#!/bin/bash

quietCVS=-Q
supportDir=/shared/eclipse/e4/build/e4
projRelengBranch="HEAD"; # default set below
arch="x86"
archProp=""
processor=$( uname -p )
if [ $processor = ppc -o $processor = ppc64 ]; then
  archProp="-ppc"
  arch="ppc"
fi

#
# Real Build on build.eclipse.org
#
builddate=$( date +%Y%m%d )
buildtime=$( date +%H%M )

#tag maps
#projRoot='pwebster@dev.eclipse.org:/cvsroot/eclipse'
#tagMaps=-tagMaps

#publish
#publishDir="pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/e4/downloads/drops "

# available builds
#basebuilderBranch=$( grep v2008 /cvsroot/eclipse/org.eclipse.releng.basebuilder/about.html,v | head -1 | cut -f1 -d: | tr -d "[:blank:]" )
#eclipseIBuild=$( ls -d /home/data/httpd/download.eclipse.org/eclipse/downloads/drops/I*/eclipse-SDK-I*-linux-gtk${archProp}.tar.gz | tail -1 | cut -d/ -f9 )


#
# test Build
#
#builddate=20081215
#buildtime=1845
projRoot=':pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse'
basebuilderBranch=v20081210a
eclipseIBuild=I20090106-1323


# first, let's check out all of those pesky projects
cd $supportDir


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
  cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS update -d org.eclipse.e4.builder_${projRelengBranch} "
  echo $cmd
  $cmd
fi

echo "[start] [`date +%H\:%M\:%S`] setting org.eclipse.e4.builder_${projRelengBranch}"
rm org.eclipse.e4.builder
ln -s ${supportDir}/org.eclipse.e4.builder_${projRelengBranch} org.eclipse.e4.builder

cd $supportDir/org.eclipse.e4.builder/scripts


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
  2>&1 | tee -a /shared/eclipse/e4/logs/buildlog_${builddate}${buildtime}.txt


}

buildFeature repo org.eclipse.e4.resources.feature
buildFeature repo org.eclipse.e4.swt.as.feature
buildFeature repo org.eclipse.e4.ui.feature
buildFeature repo org.eclipse.e4.ui.css.feature
buildFeature repo org.eclipse.e4.xwt.feature

buildFeature org.eclipse.e4.resources.tests.feature
buildFeature org.eclipse.e4.swt.as.tests.feature
buildFeature org.eclipse.e4.ui.examples.feature
buildFeature org.eclipse.e4.ui.tests.feature
buildFeature org.eclipse.e4.xwt.tests.feature

buildTimestamp=${builddate}-${buildtime}
buildDir=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0
buildDirectory=$buildDir/I$buildTimestamp

# copy some other logs

cat >$buildDirectory/I$buildTimestamp/compilelogs.html <<EOF
<html><head><title>compile logs</title></head>
<body>
<table border="1">
EOF
for f in $buildDirectory/I$buildTimestamp/compilelogs/plugins/*/*; do
  
  FN=$( basename $f )
  FN_DIR=$( dirname $f )
  PA_FN=$( basename $FN_DIR )
  cat >>$buildDirectory/I$buildTimestamp/compilelogs.html <<EOF
<tr><td><a href="compilelogs/plugins/$PA_FN/$FN">$PA_FN - $FN</a></td></tr>
EOF
done
cat >>$buildDirectory/I$buildTimestamp/compilelogs.html <<EOF
</table>
</body>
</html>

EOF


# try some tests
testDir=$buildDirectory/tests
mkdir -p $testDir

cd $testDir
unzip $buildDirectory/../eclipse-Automated-Tests-${eclipseIBuild}.zip
cd eclipse-testing

cp $buildDirectory/../eclipse-SDK-${eclipseIBuild}-linux-gtk${archProp}.tar.gz  .
cp $buildDirectory/../emf-runtime-2.4.1.zip .
cat $buildDirectory/test.properties \
  | grep -v org.eclipse.core.tests.resources.prerequisite.testplugins \
  | sed 's/org.eclipse.e4.ui.tests.css.swt.prerequisite.testplugins=/org.eclipse.e4.ui.tests.css.swt.prerequisite.testplugins=**\/${org.eclipse.core.tests.harness}**/g' \
  | sed 's/org.eclipse.e4.xwt.tests.prerequisite.testplugins=/org.eclipse.e4.xwt.tests.prerequisite.testplugins=**\/${org.eclipse.core.tests.harness}**/g' >> test.properties
cat $buildDirectory/label.properties >> label.properties

for f in $buildDirectory/I$buildTimestamp/*.zip; do
  FN=$( basename $f )
  echo Copying $FN
  cp $f .
done

cp $supportDir/org.eclipse.e4.builder/builder/general/tests/* .

./runtests -os linux -ws gtk \
  -arch ${arch} e4 \
  2>&1 | tee -a /shared/eclipse/e4/logs/buildlog_${builddate}${buildtime}.txt

cp /shared/eclipse/e4/logs/buildlog_${builddate}${buildtime}.txt \
  $buildDirectory/I$buildTimestamp/buildlog.txt

mkdir -p $buildDirectory/I$buildTimestamp/results
cp -r results/* $buildDirectory/I$buildTimestamp/results

cp $supportDir/org.eclipse.e4.builder/templates/build.testResults.html \
  $buildDirectory/I$buildTimestamp/testResults.html

if [ ! -z "$publishDir" ]; then
  echo Publishing  $buildDirectory/I$buildTimestamp to "$publishDir"
  scp -r $buildDirectory/I$buildTimestamp "$publishDir"
  mailx -s "Integration Build: I$buildTimestamp" e4-dev@eclipse.org <<EOF

Check here for test results and update site: 
http://download.eclipse.org/e4/downloads/drops/I$buildTimestamp

EOF
fi
