#!/bin/bash +x

quietCVS=-Q
writableBuildRoot=/shared/eclipse/e4
projRelengBranch="R4_1_maintenance"; # default set below
arch="x86_64"
archProp="-x86_64"
processor=$( uname -p )
if [ $processor = ppc -o $processor = ppc64 ]; then
    archProp="-ppc"
    archJavaProp="-DarchProp=-ppc"
    arch="ppc"
fi

#
# Real Build on build.eclipse.org
#
realBuildProperties () {
	supportDir=$writableBuildRoot/build/e4
	builderDir=${supportDir}/org.eclipse.e4.builder
    builddate=$( date +%Y%m%d )
    buildtime=$( date +%H%M )

#tag maps
    projRoot='pwebster@dev.eclipse.org:/cvsroot/eclipse'
    tagMaps=-tagMaps

#publish
    publishIndex="pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/e4/downloads"
    publishSDKIndex="pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/downloads"
    publishUpdates="pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/e4/updates"
    publishDir="${publishIndex}/drops"

# available builds
    #basebuilderBranch=$( grep v2009 /cvsroot/eclipse/org.eclipse.releng.basebuilder/about.html,v | head -1 | cut -f1 -d: | tr -d "[:blank:]" )
    #eclipseIBuild=$( ls -d /home/data/httpd/download.eclipse.org/eclipse/downloads/drops/M*/eclipse-SDK-M*-linux-gtk${archProp}.tar.gz | tail -1 | cut -d/ -f9 )
    basebuilderBranch=R3_7
}


#
# test Build
#
testBuildProperties () {
	supportDir=$writableBuildRoot/build/e4
	builderDir=${supportDir}/org.eclipse.e4.builder

#	builderDir=/opt/pwebster/workspaces/e4/releng/org.eclipse.e4.builder
#builddate=20090624
#buildtime=1012
    builddate=$( date +%Y%m%d )
    buildtime=$( date +%H%M )

    projRoot=':pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse'
    basebuilderBranch=R3_7
}

commonProperties () {
    javaHome=/opt/public/common/sun-jdk1.6.0_21_x64
    buildTimestamp=${builddate}-${buildtime}
    buildDir=$writableBuildRoot/build/e4/downloads/drops/4.0.0
    targetDir=${buildDir}/targets
    targetZips=$targetDir/downloads
    transformedRepo=${targetDir}/helios-p2
    buildDirectory=$buildDir/M$buildTimestamp
    
    e4TestDir=/opt/buildhomes/e4Build/e4Tests/M$buildTimestamp
    sdkTestDir=/opt/buildhomes/e4Build/sdkTests/M$buildTimestamp
    
    buildResults=$buildDirectory/M$buildTimestamp
    
    sdkResults=$buildDir/40builds/M$buildTimestamp/M$buildTimestamp
    sdkBuildDirectory=$buildDir/40builds/M$buildTimestamp
		
    relengBaseBuilderDir=$supportDir/org.eclipse.releng.basebuilder
    buildDirEclipse="$buildDir/eclipse"
    WORKSPACE="$buildDir/workspace"
    export WORKSPACE
}

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
    cd $supportDir
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

}

updateSDKBuilder () {
    cd $supportDir
    echo "[start] [`date +%H\:%M\:%S`] get org.eclipse.e4.sdk_${projRelengBranch}"
    if [[ ! -d org.eclipse.e4.sdk_${projRelengBranch} ]]; then
        cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS co -r $projRelengBranch -d org.eclipse.e4.sdk_${projRelengBranch} e4/releng/org.eclipse.e4.sdk"
        echo $cmd
        $cmd
    else
        cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS update -C -d org.eclipse.e4.sdk_${projRelengBranch} "
        echo $cmd
        $cmd
    fi
    
    rm org.eclipse.e4.sdk 
    ln -s ${supportDir}/org.eclipse.e4.sdk_${projRelengBranch} org.eclipse.e4.sdk  
}

updateEclipseBuilder() {
	echo "[`date +%H\:%M\:%S`] get org.eclipse.releng.eclipsebuilder"
    if [[ ! -d org.eclipse.releng.eclipsebuilder_R4_1_maintenance ]]; then
        cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS co -r R4_1_maintenance -d org.eclipse.releng.eclipsebuilder_R4_1_maintenance org.eclipse.releng.eclipsebuilder"
        echo $cmd
        $cmd
    else
        cmd="cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse $quietCVS update -C -d org.eclipse.releng.eclipsebuilder_R4_1_maintenance "
        echo $cmd
        $cmd
    fi
    
    echo "[`date +%H\:%M\:%S`] setting org.eclipse.e4.builder_R4_1_maintenance"
    rm org.eclipse.releng.eclipsebuilder
    ln -s ${supportDir}/org.eclipse.releng.eclipsebuilder_R4_1_maintenance org.eclipse.releng.eclipsebuilder
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
	  -Dbuilder=$supportDir/org.eclipse.e4.sdk/builder \
	  -Dorg.eclipse.e4.builder=$supportDir/org.eclipse.e4.builder \
	  -Declipse.build.configs=$supportDir/org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs \
	  -DbuildType=M \
	  -Dbuilddate=$builddate \
	  -Dbuildtime=$buildtime \
	  -Dbase=$buildDir/40builds \
	  -DupdateSite=$targetDir/updates/4.1-I-builds
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
			prereqMsg=`cat $sdkBuildDirectory/prereqErrors.log` 
		fi
		
		mailx -s "4.1 SDK Maintenance Build: $buildId failed" e4-dev@eclipse.org <<EOF
$compileMsg
$compileProblems

$prereqMsg

$failure
EOF
		exit
	fi 
      
	/bin/bash ${builderDir}/scripts/sync.sh
	
	#Done at the end of runSDKTests()
	#/bin/bash ${builderDir}/scripts/publish.sh
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

	echo "Copying test framework."
    cp -r ${builderDir}/builder/general/tests/* .

    ./runtests -os linux -ws gtk -arch ${arch} sdk

    mkdir -p $sdkResults/results
    cp -r results/* $sdkResults/results

	cd $sdkBuildDirectory
	mv $sdkTestDir $sdkBuildDirectory/eclipse-testing
    
    /bin/bash ${builderDir}/scripts/publish.sh
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
	testsMsg=$(cat mail.txt | sed s_href=\"_href=\"http://download.eclipse.org/e4/downloads/drops/M$buildTimestamp/results/_)
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
echo "Subject: 0.11 Maintenance Build: M$buildTimestamp $failed"
echo ""
echo "<html><head><title>0.11 Maintenance Build: M$buildTimestamp $failed</title></head>" 
echo "<body>Check here for the build results: <a href="http://download.eclipse.org/e4/downloads/drops/M$buildTimestamp">M$buildTimestamp</a><br><br>" 
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
      -Dbuilddate=$builddate \
      -Dbuildtime=$buildtime \
      -Dtransformed.dir=${transformedRepo} \
      ${archJavaProp} \
      -DbuildArea=$buildDir \
      -DbuildDirectory=$buildDirectory \
      -Dbase.builder=$relengBaseBuilderDir \
      -Dbase.builder.launcher=$cpLaunch \
      -DmapsRepo=$projRoot \
      -DlogExtension=.xml \
      -Djava15-home=$javaHome \
      -DrunPackager=true -Dgenerate.p2.metadata=true -Dp2.publish.artifacts=true \
      -DtopLevelElementId=org.eclipse.e4.master \
      -Dflex.sdk=$writableBuildRoot/flex_sdk_3.2.0.3794_mpl "
  
    if [ ! -z "$tagMaps" ]; then
        cmd="$cmd -DtagMaps=true "
    fi
    #if [ ! -z "$genRepo" ]; then
    #    cmd="$cmd -DrunPackager=true -Dgenerate.p2.metadata=true -Dp2.publish.artifacts=true "
    #fi

    echo $cmd
    $cmd

   #stop now if the build failed
	failure=$(sed -n '/BUILD FAILED/,/Total time/p' $writableBuildRoot/logs/current.log)
	if [[ ! -z $failure ]]; then
		compileMsg=""
		prereqMsg=""
		pushd $buildDirectory/plugins
		compileProblems=$( find . -name compilation.problem | cut -d/ -f2 )
		popd
		
		if [[ ! -z $compileProblems ]]; then
			compileMsg="Compile errors occurred in the following bundles:"
		fi
		if [[ -e $buildDirectory/prereqErrors.log ]]; then
			prereqMsg=`cat $buildDirectory/prereqErrors.log` 
		fi
		
		mailx -s "0.11 Maintenance Build: $buildId failed" e4-dev@eclipse.org <<EOF
$compileMsg
$compileProblems

$prereqMsg

$failure
EOF
		exit
	fi 
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
    zip -r ../I$buildTimestamp/org.eclipse.swt.e4.flex-incubation-I$buildTimestamp.zip org.eclipse.swt org.eclipse.swt.e4.jcl
}



realBuildProperties
#testBuildProperties
commonProperties
updateBaseBuilder
updateBaseBuilderInfo
updateSDKBuilder
updateE4Builder
updateEclipseBuilder

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

cp /shared/eclipse/e4/logs/current.log \
    $buildResults/buildlog.txt


if [ ! -z "$publishDir" ]; then
    echo Publishing  $buildResults to "$publishDir"
    scp -r $buildResults "$publishDir"
    rsync --recursive --delete ${targetDir}/updates/0.11-I-builds \
      "${publishUpdates}"
    sendMail
    sleep 60
    wget -O index.txt http://download.eclipse.org/e4/downloads/createIndex.php
    scp index.txt "$publishIndex"/index.html
fi

