#!/bin/bash

export PATH=/bin:/usr/bin/:/usr/local/bin
export CVS_RSH=/usr/bin/ssh
umask 002

writableBuildRoot=/shared/eclipse/e4
webRoot=/shared/eclipse/e4/

#default values
version=""; # REQUIRED
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
javaHome=""
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
projRelengRoot=":pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse"; # default if not specified when building
topprojectName="";
e4builder=org.eclipse.e4.builder

function usage()
{
	echo "usage: start.sh"
	echo "-top            <REQUIRED: name of the top-level project, eg. modeling, tools>"
	echo "-proj           <REQUIRED: name of the project to be build, eg. mdt, gef>"
	echo "-sub            <REQUIRED: shortname of the project to be build, eg. uml2tools, gef>"
	echo "-version        <REQUIRED: version to use, eg., 1.0.0>"
	echo "-mapfileRule    <Use static mapfile? (use-false) Generate mapfile? Tag files during build (gen-true, gen-false)? default gen-false>"
	echo "-mapfileTag     <Tag to use when generating mapfile; default to either build_timestamp (gen-true) or cvsbranch (gen-false)>"  
	echo "-URL            <The URLs of the Eclipse driver, EMF driver, and any other zips that need to be unpacked into"
	echo "                 the eclipse install to resolve all dependencies. Enter one -URL [...] per required URL.>"     
	echo "-branch         <REQUIRED: CVS branch of the files to be built (eg., build_200409171617); default HEAD)>"
	echo "-projRelengRoot     <optional: CVSROOT of org.eclipse(.emf).\$subprojectName.releng; default: $projRelengRoot>"
	echo "-projRelengPath     <optional: module/path/to/org.eclipse(.emf).\$subprojectName.releng; default: org.eclipse.\$projectName/org.eclipse(.emf).\$subprojectName.releng>"
	echo "-projRelengBranch   <CVS branch of org.eclipse.\$subprojectName.releng or org.eclipse.emf.\$subprojectName.releng>"
	echo "-commonRelengBranch <CVS branch of org.eclipse.dash.common.releng>"
	echo "-basebuilderBranch <CVS branch of org.eclipse.releng.basebuilder>"
	echo "-antTarget      <The Ant target of the build script: run, runWithoutTest; default: run>"
	echo "-buildAlias     <The Alias of the build (for named S and R builds), eg. 2.0.2RC1; default: none>"
	echo "-buildType      <The type of the build: N, I, M, S, R; default: N>"
	echo "-javaHome       <The JAVA_HOME directory; default: $JAVA_HOME or value in ../../server.properties>"
	echo "-downloadsDir   <The directory where dependent zips are downloaded; default: \$writableBuildRoot/build/downloads>"
	echo "-buildTimestamp <optional: YYYYmmddhhMM timestamp to be used to label the build; default will be generated>"
	echo "-writableBuildRoot <OPTIONAL: dir where builds will occur, eg., /opt/public/modeling or /home/www-data>"
	echo "-buildDir       <The directory of this build; default: \$downloadsDir/drops/\$version/\$buildType\$buildTimestamp>"
	echo "-email          <The email address(es) to be contacted when the tests complete. Separate multiple w/ commas>"
	echo "-noclean        <DON'T clean up temp files after build>"
	echo "-addSDK         <optional: if used, add the resulting SDK zip to the specified dependencies file for use with other builds>"
	echo "-localSourceCheckoutDir <optional: if you have a CVS dump of the whole project tree already checked out, you can use that dir>"
	echo ""
	echo "example: "
	echo "./start.sh -projectid tools.gef -version 3.4.0 \\"
	echo "  -basebuilderBranch R35_M2 \\"
	echo "  -URL http://download.eclipse.org/eclipse/downloads/drops/S-3.3M3-200611021715/eclipse-SDK-3.3M3-linux-gtk.tar.gz \\"
	echo "  -URL http://download.eclipse.org/modeling/emf/emf/downloads/drops/2.3.0/S200611091546/emf-sdo-xsd-SDK-2.3.0M3.zip \\"
	echo "  -URL http://download.eclipse.org/modeling/mdt/uml2/downloads/drops/2.1.0/S200611161552/uml2-SDK-2.1M3.zip \\"
	echo "  -URL http://download.eclipse.org/modeling/mdt/ocl/downloads/drops/1.1.0/S200612211659/emft-ocl-SDK-1.1M4.zip \\"
	echo "  -URL http://download.eclipse.org/modeling/emf/query/downloads/drops/1.1.0/S200612211745/emft-query-SDK-1.1M4.zip \\"
	echo "  -URL http://download.eclipse.org/modeling/emf/transaction/downloads/drops/1.1.0/S200612220820/emft-transaction-SDK-1.1M4.zip \\"
	echo "  -URL http://download.eclipse.org/modeling/emf/validation/downloads/drops/1.1.0/S200612211746/emft-validation-SDK-1.1M4.zip \\"
	echo "  -URL http://download.eclipse.org/tools/gef/downloads/drops/S-3.3M4-200612191422/GEF-ALL-3.3M4.zip \\"
	echo "  -URL http://download.eclipse.org/modeling/gmf/downloads/drops/S-2.0M3-200611201300/GMF-sdk-2.0M3.zip \\"
	echo "  -email nickboldt@gmail.com 2>&1 | tee /tmp/buildlog_\`date +%H%M%S\`.txt"
	echo
	echo "example #2: "
	echo "./start.sh -projectid tools.gef -version 3.4.0 \\"
	echo "  -projRelengRoot ':pserver:anonymous@dev.eclipse.org:/cvsroot/technology' \\"
	echo "  -projRelengPath 'org.eclipse.dash/athena/org.eclipse.dash.commonbuilder/org.eclipse.gef.releng' \\"
	echo "  -basebuilderBranch RC2_34 -javaHome /opt/public/common/ibm-java2-142 \\"
	echo "  -URL http://download.eclipse.org/eclipse/downloads/drops/R-3.4-200806172000/eclipse-SDK-3.4-linux-gtk.tar.gz \\"
	echo "  2>&1 | tee /tmp/buildlog_\`date +%H%M%S\`.txt"
	echo 
	echo "example #3 (build with local GEF checkout):"
	echo "./start.sh -projectid tools.gef -version 3.4.0 \\"
	echo "  -projRelengRoot ':pserver:anonymous@dev.eclipse.org:/cvsroot/technology' \\"
	echo "  -projRelengPath 'org.eclipse.dash/athena/org.eclipse.dash.commonbuilder/org.eclipse.gef.releng' \\"
	echo "  -basebuilderBranch RC2_34 -javaHome /opt/public/common/ibm-java2-142 \\"
	echo "  -URL http://download.eclipse.org/eclipse/downloads/drops/R-3.4-200806172000/eclipse-SDK-3.4-linux-gtk.tar.gz \\"
	echo "  -localSourceCheckoutDir /tmp/gefCheckout \\"
	echo "  2>&1 | tee /tmp/buildlog_\`date +%H%M%S\`.txt"
	exit 1
}

if [[ $# -eq 0 ]]; then
	usage;
fi

echo "[start] [`date +%H\:%M\:%S`] Started on `date +%Y%m%d` with the following options:"
# Create local variable based on the input
tmpfile=`mktemp`;
echo "#Build options (all but -URL)" >> $tmpfile;
while [ "$#" -gt 0 ]; do
	case $1 in
		'-writableBuildRoot') 	
			writableBuildRoot=$2; 
			echo "   $1 $2"; 
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-projectid')
			projectid=$2;
			# if x.y -> top.proj, proj=sub
			if [[ ${projectid%.*} == ${projectid%%.*} ]]; then # two-part projectid; single-match trim .* and greedy-match trim .* are the same
				topprojectName=${projectid%%.*}; # get first chunk
				projectName=${projectid##*.}; # get last chunk
				subprojectName=${projectName}; # proj == sub
			else # assume x.y.z -> top.proj.sub 
				topprojectName=${projectid%%.*}; # get first chunk
				subprojectName=${projectid##*.}; # get last chunk
				projectName=${projectid#${topprojectName}.}; # trim first chunk
				projectName=${projectName%.${subprojectName}}; # trim last chunk
			fi				
			#echo "Got: $topprojectName / $projectName / $subprojectName";
			echo "   $1 $2";
			
			echo "topprojectName=$topprojectName" >> $tmpfile
			echo "projectName=$projectName" >> $tmpfile
			echo "subprojectName=$subprojectName" >> $tmpfile
			shift 1
			;;
		'-top')
			topprojectName=$2;
			echo "   $1 $2";
			echo "topprojectName=$2" >> $tmpfile
			shift 1
			;;
		'-proj')
			projectName=$2;
			echo "   $1 $2";
			echo "projectName=$2" >> $tmpfile
			shift 1
			;;
		'-sub')
			subprojectName=$2;
			echo "   $1 $2";
			echo "subprojectName=$2" >> $tmpfile
			shift 1
			;;
		'-version')
			version=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			echo "buildVer=$2" >> $tmpfile
			shift 1
			;;
		'-branch')
			branch=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-URL')
			if [ "x$dependURL" != "x" ]; then
			  dependURL="$dependURL "
			fi
			dependURL=$dependURL"$2";
			echo "   $1 $2";
			shift 1
			;;
		'-javaHome')
			javaHome=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-antTarget')
			antTarget=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-buildAlias')
			buildAlias=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-buildType')
			buildType=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-buildDir')
			buildDir=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-downloadsDir')
			downloadsDir=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-buildTimestamp')
			buildTimestamp=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-mapfileRule')
			mapfileRule=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-mapfileTag')
			mapfileTag=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-email')
			email=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-basebuilderBranch')
			basebuilderBranch=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-projRelengRoot')
			projRelengRoot=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-projRelengPath')
			projRelengPath=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-projRelengBranch')
			projRelengBranch=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-commonRelengBranch')
			commonRelengBranch=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-noclean')
			noclean=1;
			echo "   $1";
			echo "${1:1}=1" >> $tmpfile
			shift 0
			;;
		'-localSourceCheckoutDir')
			localSourceCheckoutDir=$2;
			echo "   $1 $2";
			echo "${1:1}=$2" >> $tmpfile
			shift 1
			;;
		'-addSDK')
			depsFile="$2";
			echo "   $1 $2";
			echo "${1:1}=1" >> $tmpfile
			shift 0
			;;
	esac
	shift 1
done	

# TODO: similar hack for m2t.common and m2t.shared?
if [[ $projectName = "e4" ]]; then
  subprojectName2="e4."$subprojectName; # exception case for org.eclipse.emf.foo
else
  subprojectName2=$subprojectName; # everyone else, org.eclipse.foo
fi


lockfile=$writableBuildRoot"/tmp/${projectName}-${subprojectName}_${version}.lock.txt";
if [[ -f $lockfile ]]; then # eg., mdt-eodm_2.0.0.lock.txt
  echo "[start] Removing lockfile: $lockfile ..."
  rm -f $lockfile;
fi

hostname="`hostname -f`";

commonScriptsDir=$writableBuildRoot/build/org.eclipse.dash.common.releng/tools/scripts
mkdir -p $commonScriptsDir
cd $commonScriptsDir
configfile=$commonScriptsDir/../../server.properties 

# set environment variables
export HOME=$writableBuildRoot
if [ "x$javaHome" != "x" ]; then
	export JAVA_HOME=$javaHome;
else # use default
	export JAVA_HOME=$($commonScriptsDir/readProperty.sh $configfile JAVA_HOME)
	javaHome="$JAVA_HOME"
fi
export ANT_HOME=$($commonScriptsDir/readProperty.sh $configfile ANT_HOME);
ANT_BIN=$($commonScriptsDir/readProperty.sh $configfile ANT_BIN);
if [ "x$ANT_BIN" != "x" ]; then
	export ANT=$ANT_BIN
else
	export ANT=$ANT_HOME"/bin/ant";
fi

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

projectPath=modeling/$projectName/$subprojectName;

hasProblem="";
hasFailed="";
# should set noclean=1, hasProblem/hasFailed & cc: default email address
# if there's a problem in the build 
# TODO: make checkBuildStatus.php work on build.eclipse.org
checkBuildStatus()
{
	projectNameActual=$projectName;
	checkBuildStatusURL="http://$hostname/modeling/build/checkBuildStatus.php?parent=$topprojectName&top=$projectName&project=$subprojectName&version=$version";
	checkBuildStatusURL=$checkBuildStatusURL"&buildID=$buildType$buildTimestamp";
	echo "[start] Checking build status from $checkBuildStatusURL ..."; 
	result=$(wget "$checkBuildStatusURL" -O - 2>/dev/null);
	hasProblem=$(echo $result | egrep "FAIL|ERROR| F| E"); 
	hasFailed=$(echo $result | egrep "FAIL| F"); 
	isUnknown=$(echo $result | egrep "UNKNOWN"); 
	if [[ $hasFailed ]]; then noclean=1; fi
	
	# special case for emf/emft
	if [[ $isUnknown ]] && [[ $projectName == "emf" ]]; then 
		projectName2="emft";
		checkBuildStatusURL="http://$hostname/modeling/build/checkBuildStatus.php?parent=$topprojectName&top=$projectName2&project=$subprojectName&version=$version";
		checkBuildStatusURL=$checkBuildStatusURL"&buildID=$buildType$buildTimestamp"; 
		echo "[start] Checking build status from $checkBuildStatusURL ..."; 
		result=$(wget "$checkBuildStatusURL" -O - 2>/dev/null);
		hasProblem=$(echo $result | egrep "FAIL|ERROR| F| E"); 
		hasFailed=$(echo $result | egrep "FAIL| F"); 
		isUnknown=$(echo $result | egrep "UNKNOWN"); 
		if [[ ! $isUnknown ]]; then
			projectNameActual=$projectName2;
		fi
		if [[ $hasFailed ]]; then noclean=1; fi
	fi
	if [[ $hasProblem ]]; then
		emailDefault=$($commonScriptsDir/readProperty.sh $relengBuilderDir/build.properties emailDefault); 
		emailDefault=${emailDefault#*=> \"}; 
		emailDefault=${emailDefault%%\"*};
		 if [[ ! $email ]]; then 
			email=$emailDefault;
		elif [[ $email ]] && [[ $emailDefault ]]; then
			email=$email","$emailDefault;
		fi
	fi
}	

# must call checkBuildStatus before sendEmail to ensure we have all the right email addresses listed (user-defined + default/backup)
sendEmail () 
{
	if [[ $email ]]; then
		$commonScriptsDir/executeCommand.sh "$PHP -q $commonScriptsDir/sendEmail.php \
		  -email $email -proj $projectNameActual -sub $subprojectName \
		  -branch $branch -version $version -buildID $buildType$buildTimestamp \
		  -hostname $hostname -parent $topprojectName";
	fi
}

# collect values from input / set defaults from input values

if [ "x$projectName" = "x" ] || [ "x$version" = "x" ]; then
	usage;
fi

if [ "x$downloadsDir" = "x" ]; then
	downloadsDir=$writableBuildRoot/build/downloads
fi

if [ "x$buildDir" = "x" ]; then
	buildDir=$writableBuildRoot/build/$projectName/$subprojectName/downloads/drops/$version/$buildType$buildTimestamp
fi

# org.eclipse.*releng* directories
relengBuilderDir=$buildDir/org.eclipse.$subprojectName2.releng
relengCommonBuilderDir=$buildDir/org.eclipse.dash.common.releng
relengBaseBuilderDir=$buildDir/org.eclipse.releng.basebuilder

echo "";
echo "Environment variables: ";
echo "  HOME      = $HOME";
echo "  JAVA_HOME = $JAVA_HOME";
echo "  ANT_HOME  = $ANT_HOME";
echo "  ANT       = $ANT";
echo "  PHP       = $PHP";
echo "";

echo "" >> $tmpfile;
echo "# Environment variables"  >> $tmpfile;
echo "HOME=$HOME" >> $tmpfile;
echo "JAVA_HOME=$JAVA_HOME" >> $tmpfile;
echo "ANT_HOME=$ANT_HOME" >> $tmpfile;
echo "ANT=$ANT" >> $tmpfile;
echo "PHP=$PHP" >> $tmpfile;

if [[ "$branch" != "HEAD" ]] && [[ !$projRelengBranch ]]; then
	echo "  **** Defaulting -projRelengBranch to $branch. If that's not good, override using a -debug build. ****"
	projRelengBranch="$branch"; # by default, if build from R1_0_maintenance, use same tag for o.e.*.releng
fi

echo "[start] Check if dependent drivers exist or can be downloaded:"

checkZipExists ()
{
	theURL=$1;
	theFile=`echo $theURL | sed -e 's/^.*\///'`
        mkdir -p $downloadsDir;
	$ANT -f checkZipExists.xml -DdownloadsDir=$downloadsDir -DtheFile=$theFile -DtheURL=$theURL
	#echo "[start] Ant returned: $#"
}

for dep in $dependURL; do
	outfile=`mktemp`;
	checkZipExists $dep 2>&1 | tee $outfile;
	result=`cat $outfile | grep -c FAILED`
	rm -fr $outfile
	#echo $result
	if [ "$result" != "0" ]; then
		echo "[start] An error occurred finding or downloading $dep."
		# TODO: make checkBuildStatus.php work on build.eclipse.org
		# checkBuildStatus; 
		sendEmail;
		echo "[start] This script will now exit."
		exit 99;
	fi
done

echo "[start] Creating build directory $buildDir"
mkdir -p $buildDir/eclipse; cd $buildDir;

# add some properties to build.cfg
buildcfg="$buildDir/build.cfg";
echo "Storing build properties in $buildcfg";
#echo -n "" > $buildcfg; # truncate file if exists; create if not
cp $relengBuilderDir/$e4builder/$subprojectName/* $buildDir
cp $buildDir/build.properties $buildcfg

cat $tmpfile >> $buildcfg;
echo "" >> $buildcfg;
rm -fr $tmpfile

if [ "x$localSourceCheckoutDir" != "x" ]; then
	echo "skipFetch=true" >> $buildcfg;
	echo "localSourceCheckoutDir=$localSourceCheckoutDir" >> $buildcfg
fi

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

echo "[start] [`date +%H\:%M\:%S`] Export org.eclipse.$subprojectName2.releng using "$projRelengBranch;
if [[ -d $writableBuildRoot/build/org.eclipse.$subprojectName2.releng ]] || [[ -L $writableBuildRoot/build/org.eclipse.$subprojectName2.releng ]]; then
  echo "[start] Copy from $writableBuildRoot/build/org.eclipse.$subprojectName2.releng."
  cp -r $writableBuildRoot/build/org.eclipse.$subprojectName2.releng $buildDir/org.eclipse.$subprojectName2.releng 
elif [[ -d $writableBuildRoot/build/org.eclipse.$subprojectName2.releng_${projRelengBranch} ]]; then
  echo "[start] Copy from $writableBuildRoot/build/org.eclipse.$subprojectName2.releng_${projRelengBranch}."
  cp -r $writableBuildRoot/build/org.eclipse.$subprojectName2.releng_${projRelengBranch} $buildDir/org.eclipse.$subprojectName2.releng 
elif [[ ! -d $buildDir/org.eclipse.$subprojectName2.releng ]]; then 
  if [[ ! ${projRelengRoot##*svn*} ]]; then # checkout from svn
  	# svn -q export -r HEAD http://dev.eclipse.org/svnroot/technology/org.eclipse.linuxtools/releng/trunk/org.eclipse.linuxtools.releng org.eclipse.linuxtools.releng
	cmd="svn $quietSVN export -r $projRelengBranch ${projRelengRoot//\'/}/$projRelengPath org.eclipse.$subprojectName2.releng";
  else
  	cmd="cvs -d ${projRelengRoot//\'/} $quietCVS ex -r $projRelengBranch -d org.eclipse.$subprojectName2.releng $projRelengPath";
  fi
  echo "  "$cmd; $cmd; 
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

cd $buildDir/org.eclipse.dash.common.releng/tools/scripts
#echo [start] Now in $PWD

###################################### BEGIN RUN ######################################


echo "relengBuilderDir=$relengBuilderDir" >> $buildcfg;
echo "relengCommonBuilderDir=$relengCommonBuilderDir" >> $buildcfg;
echo "relengBaseBuilderDir=$relengBaseBuilderDir" >> $buildcfg;

echo "java.home=$JAVA_HOME" >> $buildcfg;

#cat $relengBuilderDir/$e4builder/$subprojectName/build.properties >> $buildcfg;
cat $relengCommonBuilderDir/build.properties >> $buildcfg;
cat $configfile >> $buildcfg;
cp $buildcfg $buildDir/build.properties


buildfile=$relengBaseBuilderDir/plugins/org.eclipse.pde.build_3.5.0.N20081008-2000/scripts/build.xml
cpAndMain=`find $relengBaseBuilderDir/ -name "org.eclipse.equinox.launcher_*.jar" | sort | head -1`" org.eclipse.equinox.launcher.Main";
echo "[start] [`date +%H\:%M\:%S`] Invoking Eclipse build with -enableassertions and -cp $cpAndMain ...";
$javaHome/bin/java -enableassertions \
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

# generate a log of any compiler problems, warnings, errors, or failures
echo -n "[start] [`date +%H\:%M\:%S`] Generating compilelogs summary... ";
if [ -d $buildDir/compilelogs ]; then
  summary=$($relengCommonBuilderDir/tools/scripts/getCompilerResults.sh $buildDir/compilelogs);
  echo $summary > $buildDir/compilelogs/summary.txt
  if [ "x$summary" != "x" ]; then 
  	echo $summmary": ";
  fi
  echo "done.";
else
  echo "skipped.";
fi 

# add build to dependencies file?
if [[ $depsFile != "" ]]; then
	if [[ -f $depsFile ]]; then
		depNum=$(cat $depsFile | grep "$subprojectName=" | tail -1); depNum=${depNum%%$subprojectName=*};
		SDKURL=$(find $buildDir -maxdepth 1 -name "$projectName-$subprojectName-*SDK*.zip" | tail -1);
		# TODO: support non-standard SDK names (eg., GEF-SDK*.zip)
		if [[ $SDKURL != "" ]]; then 
			SDKURL=${SDKURL##$buildDir}; SDKURL=${SDKURL##*/}; 
			SDKURL=http://$hostname/$projectPath/downloads/drops/$version/$buildType$buildTimestamp/$SDKURL; 
			if [[ -w $depsFile ]]; then 
				echo "$depNum$subprojectName=$SDKURL" >> $depsFile;
				echo "[promote] $SDKURL ($depNum$subprojectName) appended to $depsFile.";
			else
				echo "[promote] *** WARNING: File $depsFile is not writable. Add this manually:";
				echo "$depNum$subprojectName=$SDKURL"
				echo "[promote] ***";
			fi
		else
			echo "[start] *** WARNING: no SDK zip found in $buildDir. ***"; 
		fi
	else
		echo "[start] *** WARNING: cannot store SDK. File $depsFile does not exist. ***";
	fi
fi

###################################### END RUN ######################################

cd $buildDir;

# in addition to the commandline flag, check for a file called "noclean" which could have a value of "1"
if [[ -e "$buildDir/noclean" ]]; then
	noclean=`cat $buildDir/noclean`;
fi

# should set noclean & cc: default email address if there's a problem in the build 
# TODO: make checkBuildStatus.php work on build.eclipse.org
#checkBuildStatus; 

if [[ $hasProblem ]] || [[ $email ]]; then
	sendEmail;
fi

if [[ $noclean -eq 0 ]]; then
	echo "[start] Cleaning up & removing temporary directories in $buildDir"
	rm -fr $buildDir/org.eclipse.dash.common.releng
	rm -fr $buildDir/org.eclipse.$subprojectName2.releng
	rm -fr $buildDir/org.eclipse.releng.basebuilder
	rm -fr $buildDir/eclipse
	rm -fr $buildDir/testing
else
	echo "[start] Cleaning up & removing temporary directories in $buildDir ... OMITTED." 
	echo "[start] Please scrub the following folders manually:"
	echo "[start]   $buildDir/org.eclipse.dash.common.releng"
	echo "[start]   $buildDir/org.eclipse.$subprojectName2.releng"
	echo "[start]   $buildDir/org.eclipse.releng.basebuilder"
	echo "[start]   $buildDir/eclipse"
	echo "[start]   $buildDir/testing"
fi

echo "[start] [`date +%H\:%M\:%S`] start.sh finished."
echo ""
