#!/bin/bash +x

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

eclipseStream=4.2
e4Stream=0.12
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


builderDir=${gitCache}/${relengProject}/org.eclipse.e4.builder

if [ "$buildType" = N ]; then
	tag=false
fi

#publish
publishIndex="${committerId}@build.eclipse.org:/home/data/httpd/download.eclipse.org/e4/downloads"
publishSDKIndex="${committerId}@build.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/downloads"
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
    
e4TestDir=/opt/buildhomes/e4Build/e4Tests/$buildTag
sdkTestDir=/opt/buildhomes/e4Build/sdkTests/$buildTag
    
buildResults=$buildDirectory/$buildTag
    
sdkResults=$buildDir/40builds/$buildTag/$buildTag
sdkBuildDirectory=$buildDir/40builds/$buildTag
		
relengBaseBuilderDir=$supportDir/org.eclipse.releng.basebuilder
buildDirEclipse="$buildDir/eclipse"
WORKSPACE="$buildDir/workspace"
export WORKSPACE

export PATH=/opt/public/common/apache-maven-3.0.4/bin:$PATH
export MAVEN_OPTS=-Xmx1024m
export JAVA_HOME=/opt/public/common/jdk-1.6.x86_64/jre

mkdir -p $buildDirectory

cd $buildDirectory
