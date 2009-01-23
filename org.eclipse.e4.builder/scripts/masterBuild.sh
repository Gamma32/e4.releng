#!/bin/bash +x

quietCVS=-Q
writableBuildRoot=/shared/eclipse/e4
supportDir=$writableBuildRoot/build/e4
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
    basebuilderBranch=v20090122a
    eclipseIBuild=3.5M4

}


#
# test Build
#
testBuildProperties () {
#builddate=20081215
#buildtime=1845
    builddate=$( date +%Y%m%d )
    buildtime=$( date +%H%M )

    projRoot=':pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse'
    basebuilderBranch=v20090122a
    eclipseIBuild=3.5M4

}

commonProperties () {
    javaHome=/opt/public/common/ibm-java2-ppc-50
    buildTimestamp=${builddate}-${buildtime}
    buildDir=${supportDir}/downloads/drops/4.0.0
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

# now update the variables that depend on this
    pdeDir=$( find $relengBaseBuilderDir/ -name "org.eclipse.pde.build_*" | sort | head -1 )
    buildfile=$pdeDir/scripts/build.xml
    cpAndMain=$( find $relengBaseBuilderDir/ -name "org.eclipse.equinox.launcher_*.jar" | sort | head -1 )" org.eclipse.equinox.launcher.Main";
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

    cd $supportDir/org.eclipse.e4.builder/scripts
}

copyCompileLogs () {
    cat >$buildResults/compilelogs.html <<EOF
<html><head><title>compile logs</title></head>
<body>
<table border="1">
EOF

    for f in $buildResults/compilelogs/plugins/*/*; do
        FN=$( basename $f )
        FN_DIR=$( dirname $f )
        PA_FN=$( basename $FN_DIR )
        cat >>$buildResults/compilelogs.html <<EOF
<tr><td><a href="compilelogs/plugins/$PA_FN/$FN">$PA_FN - $FN</a></td></tr>
EOF

    done
    cat >>$buildResults/compilelogs.html <<EOF
</table>
</body>
</html>

EOF
}


runTheTests () {
    mkdir -p $testDir

    cd $testDir
    unzip $buildDirectory/../eclipse-Automated-Tests-${eclipseIBuild}.zip
    cd eclipse-testing

    cp $buildDirectory/../eclipse-SDK-${eclipseIBuild}-linux-gtk${archProp}.tar.gz  .
    # can't re-run automated tests against an milestone build that has been renamed
    mv eclipse-SDK-${eclipseIBuild}-linux-gtk${archProp}.tar.gz \
      eclipse-SDK-I20081211-1908-linux-gtk${archProp}.tar.gz
    cp $buildDirectory/../emf-runtime-2.5.0M4.zip .
    cp $buildDirectory/../xsd-runtime-2.5.0M4.zip .
    cp $buildDirectory/../GEF-SDK-3.5.0M4.zip .
    cp $buildDirectory/../wtp-wst-S-3.1M4-20081219210304.zip .

    cat $buildDirectory/test.properties \
        | grep -v org.eclipse.core.tests.resources.prerequisite.testplugins \
        | sed 's/org.eclipse.e4.ui.tests.css.swt.prerequisite.testplugins=/org.eclipse.e4.ui.tests.css.swt.prerequisite.testplugins=**\/${org.eclipse.core.tests.harness}**/g' \
        | sed 's/org.eclipse.e4.xwt.tests.prerequisite.testplugins=/org.eclipse.e4.xwt.tests.prerequisite.testplugins=**\/${org.eclipse.core.tests.harness}**/g' >> test.properties
    cat $buildDirectory/label.properties >> label.properties

    for f in $buildResults/*.zip; do
        FN=$( basename $f )
        echo Copying $FN
        cp $f .
    done

    cp $supportDir/org.eclipse.e4.builder/builder/general/tests/* .

    ./runtests -os linux -ws gtk \
        -arch ${arch} e4

    mkdir -p $buildResults/results
    cp -r results/* $buildResults/results

    cp $supportDir/org.eclipse.e4.builder/templates/build.testResults.html \
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
      -Dbuilder=$supportDir/org.eclipse.e4.builder/builder/general \
      -Dbuilddate=$builddate \
      -Dbuildtime=$buildtime \
      -DeclipseBuildId=$eclipseIBuild \
      ${archJavaProp} \
      -DbuildArea=$buildDir \
      -DbuildDirectory=$buildDirectory \
      -DmapsRepo=$projRoot \
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


#realBuildProperties
testBuildProperties
commonProperties
updateBaseBuilder
updateE4Builder

echo "[start] [`date +%H\:%M\:%S`] setting eclipse $eclipseIBuild"

buildMasterFeature

# copy some other logs
copyCompileLogs

# try some tests
runTheTests

cp /shared/eclipse/e4/logs/buildlog_${builddate}${buildtime}.txt \
    $buildResults/buildlog.txt


if [ ! -z "$publishDir" ]; then
    echo Publishing  $buildResults to "$publishDir"  2>&1 | tee -a /shared/eclipse/e4/logs/buildlog_${builddate}${buildtime}.txt
    scp -r $buildResults "$publishDir"  2>&1 | tee -a /shared/eclipse/e4/logs/buildlog_${builddate}${buildtime}.txt
    sendMail  2>&1 | tee -a /shared/eclipse/e4/logs/buildlog_${builddate}${buildtime}.txt
fi
