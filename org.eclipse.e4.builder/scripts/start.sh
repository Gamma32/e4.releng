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
basebuilderBranch="vI20081118-0800";
antTarget=run
buildAlias=""
buildType=I
javaHome=/opt/public/common/ibm-java2-ppc-50
downloadsDir=""; # default set below
builddate=$( date +%Y%m%d )
buildtime=$( date +%H%M )

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
topprojectName="eclipse";
e4builder=org.eclipse.e4.builder
featureId=org.eclipse.e4.master

echo "[start] [`date +%H\:%M\:%S`] Started on `date +%Y%m%d` with the following options:"
while [ "$#" -gt 0 ]; do
	case $1 in
		'-branch')
			branch=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-javaHome')
			javaHome=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-buildType')
			buildType=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-buildDate')
			builddate=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-buildTime')
			buildtime=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-mapfileTag')
			mapfileTag=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-email')
			email=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-eclipseIBuild')
			eclipseIBuild=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-eclipseIBuild')
			eclipseIBuild=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-basebuilderBranch')
			basebuilderBranch=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-projRelengPath')
			projRelengPath=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-projRelengBranch')
			projRelengBranch=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-tagMaps')
			tagMaps=true;
			echo "   $1 true";
#			echo "${1:1}=$2" >> $tmpfile
			;;
		'-genRepo')
			genRepo=true;
			echo "   $1 true";
#			echo "${1:1}=$2" >> $tmpfile
			;;
		'-featureId')
			featureId=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-publishDir')
			publishDir=$2;
			echo "   $1 $2";
#			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
	esac
	shift 1
done	

buildTimestamp=${builddate}-${buildtime}

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

supportDir=$writableBuildRoot/build/$subprojectName
buildDir=$writableBuildRoot/build/$subprojectName/downloads/drops/$version
buildDirectory=$buildDir/$buildType$buildTimestamp
echo "[start] Creating build directory $buildDir"
mkdir -p $buildDirectory/eclipse; cd $buildDirectory;

echo "";
echo "Environment variables: ";
echo "  HOME      = $HOME";
echo "  JAVA_HOME = $JAVA_HOME";
echo "  ANT_HOME  = $ANT_HOME";
echo "  ANT       = $ANT";
echo "  PHP       = $PHP";
echo "";


relengBaseBuilderDir=$supportDir/org.eclipse.releng.basebuilder
buildDirEclipse="$buildDir/eclipse"
pdeDir=`find $relengBaseBuilderDir/ -name "org.eclipse.pde.build_*" | sort | head -1`

buildfile=$pdeDir/scripts/build.xml
cpAndMain=`find $relengBaseBuilderDir/ -name "org.eclipse.equinox.launcher_*.jar" | sort | head -1`" org.eclipse.equinox.launcher.Main";

runFeatureBuild () {
echo "[start] [`date +%H\:%M\:%S`] Invoking Eclipse build with -enableassertions and -cp $cpAndMain ...";
cmd="$javaHome/bin/java -enableassertions \
  -cp $cpAndMain \
  -application org.eclipse.ant.core.antRunner \
  -buildfile $buildfile \
  -Dbuilder=$supportDir/org.eclipse.e4.builder/builder/general \
  -Dbuilddate=$builddate \
  -Dbuildtime=$buildtime \
  -DeclipseBuildId=$eclipseIBuild \
  -DbuildArea=$buildDir \
  -DbuildDirectory=$buildDirectory \
  -DmapsRepo=$projRelengRoot \
  -DtopLevelElementId=$1 \
  -Dflex.sdk=$writableBuildRoot/flex_sdk_3.2.0.3794_mpl "
  
if [ ! -z "$tagMaps" ]; then
  cmd="$cmd -DtagMaps=true "
fi
if [ ! -z "$genRepo" ]; then
  cmd="$cmd -Dgenerate.p2.metadata=true -Dp2.publish.artifacts=true "
fi

echo $cmd
$cmd
}

runFeatureBuild $featureId

mergeRepo () {
echo "[start] [`date +%H\:%M\:%S`] Run the repo builder"
cmd="$javaHome/bin/java -enableassertions \
  -cp $cpAndMain \
  -application org.eclipse.equinox.p2.metadata.repository.mirrorApplication \
  -append \
  -source file:$buildDir/$1/repository \
  -destination file:$buildDir/repository "
echo $cmd
$cmd

cmd="$javaHome/bin/java -enableassertions \
  -cp $cpAndMain \
  -application org.eclipse.equinox.p2.artifact.repository.mirrorApplication \
  -append \
  -source file:$buildDir/$1/repository \
  -destination file:$buildDir/repository "
echo $cmd
$cmd
}



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

if [ ! -z "$publishDir" ]; then
  echo Publishing  $buildDirectory/$buildType$buildTimestamp to "$publishDir"
  scp -r $buildDirectory/$buildType$buildTimestamp "$publishDir"
fi

echo "[start] [`date +%H\:%M\:%S`] start.sh finished."
echo ""
