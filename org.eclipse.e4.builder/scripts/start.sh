#!/bin/bash

export PATH=/bin:/usr/bin/:/usr/local/bin
export CVS_RSH=/usr/bin/ssh
umask 002

writableBuildRoot=/shared/eclipse/e4
webRoot=/shared/eclipse/e4/

#default values
version="4.0.0"; # REQUIRED
mapfileRule="gen-false"; # can be use-false, gen-true, gen-false
mapfileTag="";
dependURL=""; # loaded from -URL
branch=HEAD
projRelengBranch="HEAD"; # default set below
commonRelengBranch="HEAD"; # default set below
basebuilderBranch="R35_M2";
antTarget=run
buildAlias=""
buildType=N
javaHome=/opt/public/common/ibm-java2-ppc-50
downloadsDir=""; # default set below
builddate=$( date +%Y%m%d )
buildtime=$( date +%H%M )
buildTimestamp=$builddate$buildtime
buildDir=""; # default set below
email=""
noclean=0; # clean up temp files when done
quietCVS=-Q; # QUIET!
quietSVN=-q; # quiet
depsFile=""; # dependencies file 
projectName2="";
projectName=eclipse
subprojectName=e4
projRelengRoot=":pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse"; # default if not specified when building
topprojectName="";
e4builder=org.eclipse.e4.builder

echo "[start] [`date +%H\:%M\:%S`] Started on `date +%Y%m%d` with the following options:"


# set environment variables
# get path to PHP interpreter
if [ -x /usr/bin/php ]; then
	PHP=/usr/bin/php
elif [ -x /usr/bin/php5 ]; then
	PHP=/usr/bin/php5
elif [ -x /usr/bin/php4 ]; then
	PHP=/usr/bin/php4
else
	PHP=php
fi

export HOME=$writableBuildRoot
export JAVA_HOME=$javaHome
export ANT_HOME=/opt/public/common/apache-ant-1.7.0
export ANT=$ANT_HOME"/bin/ant"

buildDir=$writableBuildRoot/build/$projectName/$subprojectName/downloads/drops/$version/$buildType$buildTimestamp
echo "[start] Creating build directory $buildDir"
mkdir -p $buildDir/eclipse; cd $buildDir;

echo "";
echo "Environment variables: ";
echo "  HOME      = $HOME";
echo "  JAVA_HOME = $JAVA_HOME";
echo "  ANT_HOME  = $ANT_HOME";
echo "  ANT       = $ANT";
echo "  PHP       = $PHP";
echo "";

relengCommonBuilderDir=$buildDir/org.eclipse.dash.common.releng
relengBaseBuilderDir=$buildDir/org.eclipse.releng.basebuilder

echo "";
echo "  **** Export releng projects from CVS. NOTE: if the following 2 branch values are wrong, override using a debug build. ****"
echo "";

echo "[start] [`date +%H\:%M\:%S`] Export org.eclipse.dash.common.releng using "$commonRelengBranch;
if [[ -d $writableBuildRoot/build/org.eclipse.dash.common.releng ]] || [[ -L $writableBuildRoot/build/org.eclipse.dash.common.releng ]]; then
  echo "[start] Copy from $writableBuildRoot/build/org.eclipse.dash.common.releng."
  cp -r $writableBuildRoot/build/org.eclipse.dash.common.releng $buildDir/org.eclipse.dash.common.releng 
elif [[ -d $writableBuildRoot/build/org.eclipse.dash.common.releng_${commonRelengBranch} ]]; then
  echo "[start] Copy from $writableBuildRoot/build/org.eclipse.dash.common.releng_${commonRelengBranch}."
  cp -r $writableBuildRoot/build/org.eclipse.dash.common.releng_${commonRelengBranch} $buildDir/org.eclipse.dash.common.releng 
elif [[ ! -d $buildDir/org.eclipse.dash.common.releng ]]; then 
  cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/technology $quietCVS ex -r $commonRelengBranch -d org.eclipse.dash.common.releng org.eclipse.dash/athena/org.eclipse.dash.commonbuilder/org.eclipse.dash.commonbuilder.releng";
  echo "  "$cmd; $cmd; 
  chmod 754 org.eclipse.dash.common.releng/tools/scripts/*.sh
  echo "[start] [`date +%H\:%M\:%S`] Export done."
else
  echo "[start] Export skipped (dir already exists)."
fi
echo ""

cd $buildDir;

if [[ $basebuilderBranch ]]; then
  echo "[start] [`date +%H\:%M\:%S`] Export org.eclipse.releng.basebuilder using "$basebuilderBranch;
else
  echo "[start] [`date +%H\:%M\:%S`] Export org.eclipse.releng.basebuilder using HEAD";
fi
if [[ -d $writableBuildRoot/build/org.eclipse.releng.basebuilder ]] || [[ -L $writableBuildRoot/build/org.eclipse.releng.basebuilder ]]; then
  echo "[start] Copy from $writableBuildRoot/build/org.eclipse.releng.basebuilder."
  cp -r $writableBuildRoot/build/org.eclipse.releng.basebuilder $buildDir/org.eclipse.releng.basebuilder 
elif [[ -d $writableBuildRoot/build/org.eclipse.releng.basebuilder_${basebuilderBranch} ]]; then
  echo "[start] Copy from $writableBuildRoot/build/org.eclipse.releng.basebuilder_${basebuilderBranch}."
  cp -r $writableBuildRoot/build/org.eclipse.releng.basebuilder_${basebuilderBranch} $buildDir/org.eclipse.releng.basebuilder 
elif [[ ! -d $buildDir/org.eclipse.releng.basebuilder ]]; then 
  cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS ex -r $basebuilderBranch org.eclipse.releng.basebuilder"
  echo "  "$cmd; $cmd; 
  echo "[start] [`date +%H\:%M\:%S`] Export done."
else
  echo "[start] Export skipped (dir already exists)."
fi
echo ""

cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS ex -r $projRelengBranch -d $e4builder e4/releng/$e4builder"
echo "  "$cmd; $cmd; 
echo "[start] [`date +%H\:%M\:%S`] Export done."


buildfile=$relengBaseBuilderDir/plugins/org.eclipse.pde.build_3.5.0.N20081008-2000/scripts/build.xml
cpAndMain=`find $relengBaseBuilderDir/ -name "org.eclipse.equinox.launcher_*.jar" | sort | head -1`" org.eclipse.equinox.launcher.Main";
echo "[start] [`date +%H\:%M\:%S`] Invoking Eclipse build with -enableassertions and -cp $cpAndMain ...";
echo $javaHome/bin/java -enableassertions \
  -cp $cpAndMain \
  -application org.eclipse.ant.core.antRunner
  -buildfile "$buildfile" \
  -Dbuilder=$buildDir \
  -Dbuilddate=$builddate \
  -Dbuildtime=$buildtime \
  -DbuildArea=$buildDir \
  -DbuildDirectory=$buildDirEclipse 

#/opt/local/ibm-java2-i386-50/bin/javaw \
#-Declipse.p2.data.area=@config.dir/p2 \
#-Declipse.pde.launch=true -Dfile.encoding=UTF-8 \
#-os linux -ws gtk -arch x86 -nl en_US \
#-buildfile /opt/pwebster/workspaces/e4-swt/org.eclipse.pde.build/scripts/build.xml \
#-Dbuilder=/opt/pwebster/workspaces/e4-swt/org.eclipse.e4.builder/builder/swt \
#-Dbuilddate=20081117 \
#-Dbuildtime=1500 \
#-Dflex.sdk=/opt/public/common/flex_sdk_3.2.0.3794_mpl
#-buildfile ${resource_loc:/org.eclipse.pde.build/scripts/build.xml} -Dbuilder=${resource_loc:/org.eclipse.e4.builder/builder/resources} -Dbuilddate=20081114 -Dbuildtime=${string_prompt:time}


###################################### END BUILD ######################################

echo "[start] [`date +%H\:%M\:%S`] start.sh finished."
echo ""
