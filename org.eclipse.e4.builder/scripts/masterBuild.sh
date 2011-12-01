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


# first, let's check out all of those pesky projects
updateBaseBuilder () {
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

}

updateBaseBuilderInfo() {
# now update the variables that depend on this
    pdeDir=$( find $relengBaseBuilderDir/ -name "org.eclipse.pde.build_*" | sort | head -1 )
    buildfile=$pdeDir/scripts/build.xml
    cpLaunch=$( find $relengBaseBuilderDir/ -name "org.eclipse.equinox.launcher_*.jar" | sort | head -1 )
    cpAndMain="$cpLaunch org.eclipse.equinox.launcher.Main"
}

updateE4Builder () {
    echo "[updateE4Builder]" cd ${gitCache}/${relengProject}
    echo "[updateE4Builder]" git checkout ${relengBranch}
    cd ${gitCache}/${relengProject}
    git checkout ${relengBranch}
    git pull
    
    cd $supportDir

    echo "[start] [`date +%H\:%M\:%S`] setting org.eclipse.e4.builder_${relengBranch}"
    rm org.eclipse.e4.builder
    ln -s ${gitCache}/${relengProject}/org.eclipse.e4.builder org.eclipse.e4.builder

    echo "[start] [`date +%H\:%M\:%S`] setting org.eclipse.e4.sdk_${relengBranch}"
    rm org.eclipse.e4.sdk 
    ln -s ${gitCache}/${relengProject}/org.eclipse.e4.sdk org.eclipse.e4.sdk  
}


updateEclipseBuilder() {
	cd $supportDir
	echo "[`date +%H\:%M\:%S`] get org.eclipse.releng.eclipsebuilder"
    if [[ ! -d org.eclipse.releng.eclipsebuilder_${eclipsebuilderBranch} ]]; then
        cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS co -r $eclipsebuilderBranch -d org.eclipse.releng.eclipsebuilder_${eclipsebuilderBranch} org.eclipse.releng.eclipsebuilder"
        echo $cmd
        $cmd
    else
        cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS update -C -d org.eclipse.releng.eclipsebuilder_${eclipsebuilderBranch} "
        echo $cmd
        $cmd
    fi
    
    echo "[`date +%H\:%M\:%S`] setting org.eclipse.e4.builder_${eclipsebuilderBranch}"
    rm org.eclipse.releng.eclipsebuilder
    ln -s ${supportDir}/org.eclipse.releng.eclipsebuilder_${eclipsebuilderBranch} org.eclipse.releng.eclipsebuilder
}

sync_sdk_updates () {
	fromDir=$targetDir/updates/${eclipseStream}-I-builds
	toDir="pwebster@build.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/updates"

	rsync --recursive --delete "${fromDir}" "${toDir}"
}

runSDKBuild () {
	cd $supportDir

    cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS update -C -d org.eclipse.releng.eclipsebuilder "
    echo $cmd
    $cmd
    
    cd $buildDir/40builds
    
    cmd="$javaHome/bin/java -Xmx500m -enableassertions \
      -cp $cpAndMain \
      -application org.eclipse.ant.core.antRunner  \
      -buildfile $buildfile \
	  -Dbuilder=$gitCache/${relengProject}/org.eclipse.e4.sdk/builder \
	  -Dorg.eclipse.e4.builder=$gitCache/${relengProject}/org.eclipse.e4.builder \
	  -Declipse.build.configs=$supportDir/org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs \
	  -DbuildType=$buildType \
	  -Dbuilddate=$date \
	  -Dbuildtime=$time \
	  -Dbase=$buildDir/40builds \
	  -DupdateSite=$targetDir/updates/${eclipseStream}-I-builds
	"   
    echo $cmd
    $cmd  
    
   #stop now if the build failed
	failure=$(sed -n '/BUILD FAILED/,/Total time/p' $writableBuildRoot/logs/current.log)
	if [[ ! -z $failure ]]; then
		compileMsg=""
		prereqMsg=""
		pushd $sdkBuildDirectory/plugins
		compileProblems=$( find . -name compilation.problem | cut -d/ -f2 )
		popd
		
		if [[ ! -z $compileProblems ]]; then
			compileMsg="Compile errors occurred in the following bundles:"
		fi
		if [[ -e $buildDirectory/prereqErrors.log ]]; then
			prereqMsg=`cat $buildDirectory/prereqErrors.log` 
		fi
		
		mailx -s "$eclipseStream SDK Build: $buildTag failed" e4-dev@eclipse.org <<EOF
$compileMsg
$compileProblems

$prereqMsg

$failure
EOF
		exit
	fi 
      
	sync_sdk_updates
}

process_build () {
	buildId=$1 ; shift
	echo Processing $BASE_DIR/$buildId/$buildId
	
	if [ -e $BASE_DIR/$buildId ]; then
	return;
	fi
	
	mkdir -p $BASE_DIR/$buildId
	
	cd $TMPL_DIR
	cp *.php *.htm*  *.gif *.jpg  $BASE_DIR/$buildId
	
	cd $HUDSON_DROPS/$buildId/$buildId
	
	cp *.htm*  $BASE_DIR/$buildId
	cp -r results $BASE_DIR/$buildId
	
	ZIPS=$( echo $ORIG_ZIPS | sed "s/ReplaceMe/$buildId/g" )
	for f in $ZIPS; do
	echo $f
	cp $f  $BASE_DIR/$buildId
	done
	
	cp -fr *repository.zip buildlogs checksum compilelogs $BASE_DIR/$buildId
	#cp -r $HUDSON_REPO/$buildId  $BASE_DIR/$buildId/repository
	
	cp  $TMPL_DIR/download.php  $BASE_DIR/$buildId
	
	for f in $( echo $FILES_TO_UPDATE ); do
	cat $TMPL_DIR/$f | sed "s/ReplaceMe/$buildId/g" >$BASE_DIR/$buildId/$f
	done
	
	scp -r $BASE_DIR/$buildId pwebster@build.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/downloads/drops4
	

	echo Done $buildId

	failed=""
	testsMsg=$(sed -n '/<!--START-TESTS-->/,/<!--END-TESTS-->/p' $HUDSON_DROPS/$buildId/$buildId/results/testResults.html > mail.txt)
	testsMsg=$(cat mail.txt | sed s_href=\"_href=\"http://download.eclipse.org/eclipse/downloads/drops4/$buildId/results/_)
	rm mail.txt
	
	red=$(echo $testsMsg | grep "color:red")
    if [[ ! -z $red ]]; then
		failed="tests failed"
    fi
 
(
echo "From: e4Build@build.eclipse.org "
echo "To: e4-dev@eclipse.org "
echo "MIME-Version: 1.0 "
echo "Content-Type: text/html; charset=us-ascii"
echo "Subject: $eclipseStream SDK Build: $buildId $failed"
echo ""
echo "<html><head><title>$eclipseStream SDK Build $buildId</title></head>" 
echo "<body>Check here for the build results: <a href="http://download.eclipse.org/eclipse/downloads/drops4/$buildId">$buildId</a><br>" 
echo "$testsMsg</body></html>" 
) | /usr/lib/sendmail -t
   
}

publish_sdk () {

BASE_DIR=/shared/eclipse/e4/sdk
TMPL_DIR=$BASE_DIR/template

ORIG_ZIPS="
eclipse-SDK-ReplaceMe-linux-gtk-ppc64.tar.gz
eclipse-SDK-ReplaceMe-linux-gtk.tar.gz
eclipse-SDK-ReplaceMe-linux-gtk-x86_64.tar.gz
eclipse-SDK-ReplaceMe-macosx-cocoa.tar.gz
eclipse-SDK-ReplaceMe-macosx-cocoa-x86_64.tar.gz
eclipse-SDK-ReplaceMe-win32-x86_64.zip
eclipse-SDK-ReplaceMe-win32.zip
eclipse-SDK-ReplaceMe-aix-gtk-ppc.zip
eclipse-SDK-ReplaceMe-aix-gtk-ppc64.zip
eclipse-SDK-ReplaceMe-hpux-gtk-ia64_32.zip
eclipse-SDK-ReplaceMe-solaris-gtk.zip
eclipse-SDK-ReplaceMe-solaris-gtk-x86.zip
"

FILES_TO_UPDATE="
linPlatform.php
macPlatform.php
sourceBuilds.php
winPlatform.php
index.php
"

HUDSON_COMMON=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/40builds
HUDSON_DROPS=$HUDSON_COMMON
HUDSON_REPO=$targetDir/updates/${eclipseStream}-I-builds



# find the builds to process

BUILDS=$( ls -d $HUDSON_DROPS/I* | cut -d/ -f11 )

if [ -z "$BUILDS" -o  "$BUILDS" = "I*" ]; then
	return
fi

for f in $BUILDS; do
process_build $f
done

cd $TMPL_DIR

wget -O index.txt http://download.eclipse.org/eclipse/downloads/createIndex4x.php
scp index.txt pwebster@build.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/downloads/index.html
}

runSDKTests() {
    mkdir -p $sdkTestDir
    cd $sdkTestDir

	echo "Copying eclipse SDK archive to tests." 
    cp $sdkResults/eclipse-SDK-*-linux-gtk${archProp}.tar.gz  .

    cat $sdkBuildDirectory/test.properties >> test.properties
    cat $sdkBuildDirectory/label.properties >> label.properties

	echo "sdkResults=$sdkResults" >> label.properties
	echo "e4Results=$buildResults" >> label.properties
	echo "buildType=$buildType" >> label.properties
	echo "sdkRepositoryRoot=$targetDir/updates/${eclipseStream}-I-builds" >> label.properties
	echo "e4RepositoryRoot=$targetDir/updates/${e4Stream}-I-builds" >> label.properties

	echo "Copying test framework."
    cp -r ${builderDir}/builder/general/tests/* .

    ./runtests -os linux -ws gtk -arch ${arch} sdk

    mkdir -p $sdkResults/results
    cp -r results/* $sdkResults/results

	cd $sdkBuildDirectory
	mv $sdkTestDir $sdkBuildDirectory/eclipse-testing
    
    publish_sdk
}

copyCompileLogs () {
    pushd $buildResults
    cat >$buildResults/compilelogs.html <<EOF
<html><head><title>compile logs</title></head>
<body>
<h1>compile logs</h1>
<table border="1">
EOF

    for f in $( find compilelogs -name "*.html" ); do
        FN=$( basename $f )
        FN_DIR=$( dirname $f )
        PA_FN=$( basename $FN_DIR )
        cat >>$buildResults/compilelogs.html <<EOF
<tr><td><a href="$f">$PA_FN - $FN</a></td></tr>
EOF

    done
    cat >>$buildResults/compilelogs.html <<EOF
</table>
</body>
</html>

EOF
popd
}

generateRepoHtml () {
    pushd $buildResults/repository

    cat >$buildResults/repository/index.html <<EOF
<html><head><title>E4 p2 repo</title></head>
<body>
<h1>E4 p2 repo</h1>
<table border="1">
<tr><th>Feature</th><th>Version</th></tr>

EOF

    for f in features/*.jar; do
        FN=$( basename $f .jar )
        FID=$( echo $FN | cut -f1 -d_ )
        FVER=$( echo $FN | cut -f2 -d_ )
        echo "<tr><td>$FID</td><td>$FVER</td></tr>" >> $buildResults/repository/index.html
    done

    cat >>$buildResults/repository/index.html <<EOF
</table>
</body>
</html>

EOF

    popd

}



runTheTests () {
    mkdir -p $e4TestDir
    cd $e4TestDir

	echo "Copying eclipse SDK archive to tests." 
    cp $sdkResults/eclipse-SDK-*-linux-gtk${archProp}.tar.gz  .

    cat $buildDirectory/test.properties >> test.properties
    cat $buildDirectory/label.properties >> label.properties

	echo "sdkResults=$sdkResults" >> label.properties
	echo "e4Results=$buildResults" >> label.properties
	echo "buildType=$buildType" >> label.properties
	echo "sdkRepositoryRoot=$targetDir/updates/${eclipseStream}-I-builds" >> label.properties
	echo "e4RepositoryRoot=$targetDir/updates/${e4Stream}-I-builds" >> label.properties

	echo "Copying test framework."
    cp -r ${builderDir}/builder/general/tests/* .

    ./runtests -os linux -ws gtk \
        -arch ${arch}  $1

    mkdir -p $buildResults/results
    cp -r results/* $buildResults/results

	cd $buildDirectory
	mv $e4TestDir $buildDirectory/eclipse-testing
	
    cp ${builderDir}/templates/build.testResults.html \
        $buildResults/testResults.html

}

sendMail () {
	failed=""
	testsMsg=$(sed -n '/<!--START-TESTS-->/,/<!--END-TESTS-->/p' $buildResults/results/testResults.html > mail.txt)
	testsMsg=$(cat mail.txt | sed s_href=\"_href=\"http://download.eclipse.org/e4/downloads/drops/$buildTag/results/_)
	rm mail.txt
	
	red=$(echo $testsMsg | grep "color:red")
    if [[ ! -z $red ]]; then
		failed="tests failed"
    fi
 
(
echo "From: e4Build@build.eclipse.org "
echo "To: e4-dev@eclipse.org "
echo "MIME-Version: 1.0 "
echo "Content-Type: text/html; charset=us-ascii"
echo "Subject: $e4Stream Build: $buildTag $failed"
echo ""
echo "<html><head><title>$e4Stream Build: $buildTag $failed</title></head>" 
echo "<body>Check here for the build results: <a href="http://download.eclipse.org/e4/downloads/drops/$buildTag">$buildTag</a><br><br>" 
echo "$testsMsg</body></html>" 
) | /usr/lib/sendmail -t

}

buildMasterFeature () {
    mkdir -p $buildDirectory/eclipse; cd $buildDirectory

    echo "[start] [`date +%H\:%M\:%S`] Invoking Eclipse build with -enableassertions and -cp $cpAndMain ...";
    cmd="$javaHome/bin/java -Xmx500m -enableassertions \
      -cp $cpAndMain \
      -application org.eclipse.ant.core.antRunner  \
      -buildfile $buildfile \
      -Dbuilder=${builderDir}/builder/general \
      -Dbuilddate=$date \
      -Dbuildtime=$time \
      -Dtransformed.dir=${transformedRepo} \
      ${archJavaProp} \
      -DbuildArea=$buildDir \
      -DbuildDirectory=$buildDirectory \
      -Dbase.builder=$relengBaseBuilderDir \
      -Dbase.builder.launcher=$cpLaunch \
      -DlogExtension=.xml \
      -Djava15-home=$javaHome \
      -DrunPackager=true -Dgenerate.p2.metadata=true -Dp2.publish.artifacts=true \
      -DtopLevelElementId=org.eclipse.e4.master \
      -Dflex.sdk=$writableBuildRoot/flex_sdk_3.2.0.3794_mpl "
  
    echo $cmd
    $cmd

}

swtExport () {
    swtMap=$buildDirectory/maps/e4/releng/org.eclipse.e4.swt.releng/maps/swt.map
    swtName=$1
    swtVer=$( grep ${swtName}= $swtMap | cut -f1 -d, | cut -f2 -d= )
    swtPlugin=$( grep ${swtName}= $swtMap | cut -f4 -d, )
    if [ -z "$swtPlugin" ]; then
        swtPlugin=$swtName
    fi

    cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS ex -r $swtVer -d $swtName $swtPlugin"
    echo $cmd
    $cmd
}

generateSwtZip () {
    mkdir -p $buildDirectory/swt
    cd $buildDirectory/swt
    swtExport org.eclipse.swt
    ls -d org.eclipse.swt/Ecli*/* | grep -v common | grep -v emulate | while read line; do rm -rf "$line" ; done
    cp org.eclipse.swt/.classpath_flex org.eclipse.swt/.classpath
    rm -rf org.eclipse.swt/build
    swtExport org.eclipse.swt.e4
    cp -r org.eclipse.swt.e4/* org.eclipse.swt
    awk ' /<linkedResources/,/<\/linkedResource/ {next } { print $0 } ' org.eclipse.swt/.project >tmp.txt
    cp tmp.txt org.eclipse.swt/.project
    grep -v org.eclipse.swt.awt org.eclipse.swt/META-INF/MANIFEST.MF >tmp.txt
    cp tmp.txt org.eclipse.swt/META-INF/MANIFEST.MF
    swtExport org.eclipse.swt.e4.jcl
    cp org.eclipse.swt.e4.jcl/.classpath_flex org.eclipse.swt.e4.jcl/.classpath
    zip -r ../$buildTag/org.eclipse.swt.e4.flex-incubation-$buildTag.zip org.eclipse.swt org.eclipse.swt.e4.jcl
}

tagRepo () {
	pushd $writableBuildRoot
	/bin/bash git-release.sh -branch "$relengBranch" \
   -relengProject "$relengProject" \
   -buildType "$buildType" -gitCache "$gitCache" -root "$writableBuildRoot" \
   -committerId "$committerId" -gitEmail "$gitEmail" -gitName "$gitName" \
   -timestamp "$timestamp" -oldBuildTag $oldBuildTag -buildTag $buildTag \
   -tag $tag
	popd
	mailx -s "$eclipseStream SDK Build: $buildTag submission" e4-dev@eclipse.org <$writableBuildRoot/$buildTag/report.txt
}

updateBaseBuilder
updateBaseBuilderInfo
updateE4Builder
updateEclipseBuilder

tagRepo

cd ${builderDir}/scripts


echo "[start] [`date +%H\:%M\:%S`] setting eclipse $eclipseIBuild"

runSDKBuild

buildMasterFeature

# copy some other logs
copyCompileLogs
generateRepoHtml

# generate the SWT zip file
#generateSwtZip

# try some tests
runSDKTests
runTheTests e4less

cp $writableBuildRoot/logs/current.log \
	$writableBuildRoot/$buildTag/report.txt \
    $buildResults/buildlog.txt


if $publish && [ ! -z "$publishDir"  ]; then
    echo Publishing  $buildResults to "$publishDir"
    scp -r $buildResults "$publishDir"
    rsync --recursive --delete ${targetDir}/updates/${e4Stream}-I-builds \
      "${publishUpdates}"
    sendMail
    sleep 60
    wget -O index.txt http://download.eclipse.org/e4/downloads/createIndex.php
    scp index.txt "$publishIndex"/index.html
fi

