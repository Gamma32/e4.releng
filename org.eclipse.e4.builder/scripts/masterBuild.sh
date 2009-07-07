#!/bin/bash +x

quietCVS=-Q
writableBuildRoot=/shared/eclipse/e4
projRelengBranch="HEAD"; # default set below
arch="x86"
archProp=""
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
    publishDir="pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/e4/downloads/drops "

# available builds
    #basebuilderBranch=$( grep v2009 /cvsroot/eclipse/org.eclipse.releng.basebuilder/about.html,v | head -1 | cut -f1 -d: | tr -d "[:blank:]" )
    #eclipseIBuild=$( ls -d /home/data/httpd/download.eclipse.org/eclipse/downloads/drops/I*/eclipse-SDK-I*-linux-gtk${archProp}.tar.gz | tail -1 | cut -d/ -f9 )
    basebuilderBranch=v20090610
    eclipseIBuild=I20090611-1540

}


#
# test Build
#
testBuildProperties () {
#	supportDir=$writableBuildRoot/build/e4
#	builderDir=${supportDir}/org.eclipse.e4.builder

	supportDir=/opt/pwebster/workspaces/e4
	builderDir=${supportDir}/releng/org.eclipse.e4.builder
#builddate=20090624
#buildtime=1012
    builddate=$( date +%Y%m%d )
    buildtime=$( date +%H%M )

    projRoot=':pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse'
    basebuilderBranch=v20090610
    eclipseIBuild=I20090611-1540

}

commonProperties () {
    javaHome=/opt/public/common/ibm-java2-ppc-50
    buildTimestamp=${builddate}-${buildtime}
    buildDir=$writableBuildRoot/build/e4/downloads/drops/4.0.0
    targetDir=${buildDir}/targets
    targetZips=$targetDir/downloads
    untransformedRepo=${targetDir}/galileo
    buildDirectory=$buildDir/I$buildTimestamp
    testDir=$buildDirectory/tests
    buildResults=$buildDirectory/I$buildTimestamp
    relengBaseBuilderDir=$supportDir/org.eclipse.releng.basebuilder
    buildDirEclipse="$buildDir/eclipse"
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
    mkdir -p $testDir/eclipse-testing

    cd $testDir/eclipse-testing

    cp $buildResults/eclipse-e4-SDK-incubation-I${buildTimestamp}-linux-gtk${archProp}.tar.gz  .

    cat $buildDirectory/test.properties >> test.properties
    cat $buildDirectory/label.properties >> label.properties


    cp -r ${builderDir}/builder/general/tests/* .

    ./runtests -os linux -ws gtk \
        -arch ${arch}  e4

    mkdir -p $buildResults/results
    cp -r results/* $buildResults/results

    cp ${builderDir}/templates/build.testResults.html \
        $buildResults/testResults.html

}

sendMail () {
    mailx -s "Integration Build: I$buildTimestamp" e4-dev@eclipse.org <<EOF

Check here for test results and update site: 
http://download.eclipse.org/e4/downloads/drops/I$buildTimestamp

EOF

}

buildMasterFeature () {
    mkdir -p $buildDirectory/eclipse; cd $buildDirectory

    echo "[start] [`date +%H\:%M\:%S`] Invoking Eclipse build with -enableassertions and -cp $cpAndMain ...";
    cmd="$javaHome/bin/java -enableassertions \
      -cp $cpAndMain \
      -application org.eclipse.ant.core.antRunner \
      -buildfile $buildfile \
      -Dbuilder=${builderDir}/builder/general \
      -Dbuilddate=$builddate \
      -Dbuildtime=$buildtime \
      -DeclipseBuildId=$eclipseIBuild \
      -Duntransformed.dir=${untransformedRepo} \
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



#realBuildProperties
testBuildProperties
commonProperties
#updateBaseBuilder
#updateE4Builder

updateBaseBuilderInfo


cd ${builderDir}/scripts


echo "[start] [`date +%H\:%M\:%S`] setting eclipse $eclipseIBuild"

buildMasterFeature

# copy some other logs
copyCompileLogs
generateRepoHtml

# generate the SWT zip file
#generateSwtZip

# try some tests
runTheTests

cp /shared/eclipse/e4/logs/current.log \
    $buildResults/buildlog.txt


if [ ! -z "$publishDir" ]; then
    echo Publishing  $buildResults to "$publishDir"
    scp -r $buildResults "$publishDir" 
    sendMail 
fi
