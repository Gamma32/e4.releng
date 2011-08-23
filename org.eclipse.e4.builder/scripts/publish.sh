#!/bin/bash
#

# /home/data/httpd/download.eclipse.org/eclipse/downloads/drops4/ReplaceMe

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

#HUDSON_COMMON=/opt/users/hudsonbuild/.hudson/jobs/eclipse-e4-test/workspace/builds/transfer/files
#HUDSON_COMMON=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/workspace/builds/transfer/files
HUDSON_COMMON=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/40builds
HUDSON_DROPS=$HUDSON_COMMON
HUDSON_REPO=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/targets/updates/4.2-I-builds
#HUDSON_REPO=$HUDSON_COMMON/testUpdates-I

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
	
	scp -r $BASE_DIR/$buildId pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/downloads/drops4
	

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
echo "Subject: 4.2 SDK Build: $buildId $failed"
echo ""
echo "<html><head><title>4.2 SDK Build $buildId</title></head>" 
echo "<body>Check here for the build results: <a href="http://download.eclipse.org/eclipse/downloads/drops4/$buildId">$buildId</a><br>" 
echo "$testsMsg</body></html>" 
) | /usr/lib/sendmail -t
   
}

# find the builds to process

BUILDS=$( ls -d $HUDSON_DROPS/I* | cut -d/ -f11 )

if [ -z "$BUILDS" -o  "$BUILDS" = "I*" ]; then
exit 0
fi

for f in $BUILDS; do
process_build $f
done

cd $TMPL_DIR

wget -O index.txt http://download.eclipse.org/eclipse/downloads/create4xIndex.php
scp index.txt pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/downloads/index.html


