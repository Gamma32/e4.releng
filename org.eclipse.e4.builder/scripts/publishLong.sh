#!/bin/bash
#

# /home/data/httpd/download.eclipse.org/e4/sdk/drops/ReplaceMe

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
"

FILES_TO_UPDATE="
linPlatform.php
macPlatform.php
sourceBuilds.php
testResults.php
winPlatform.php
index.php
"

#HUDSON_COMMON=/opt/users/hudsonbuild/.hudson/jobs/eclipse-e4-test/workspace/builds/transfer/files
HUDSON_COMMON=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/workspace/builds/transfer/files
#HUDSON_COMMON=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/40builds
HUDSON_DROPS=$HUDSON_COMMON/bogus/downloads/drops
HUDSON_REPO=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/targets/updates/4.1-I-builds
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

cd $HUDSON_DROPS/$buildId

cp *.htm*  $BASE_DIR/$buildId

ZIPS=$( echo $ORIG_ZIPS | sed "s/ReplaceMe/$buildId/g" )
for f in $ZIPS; do
echo $f
cp $f  $BASE_DIR/$buildId
done

cp -fr buildlogs checksum compilelogs $BASE_DIR/$buildId
cp -r $HUDSON_REPO/$buildId  $BASE_DIR/$buildId/repository

cp  $TMPL_DIR/download.php  $BASE_DIR/$buildId

for f in $( echo $FILES_TO_UPDATE ); do
cat $TMPL_DIR/$f | sed "s/ReplaceMe/$buildId/g" >$BASE_DIR/$buildId/$f
done

scp -r $BASE_DIR/$buildId pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/e4/sdk/drops

echo Done $buildId

    mailx -s "4.1 SDK Build: $buildId" e4-dev@eclipse.org <<EOF

The 4.1 SDK build:
http://download.eclipse.org/e4/sdk/drops/$buildId

EOF

}

# find the builds to process

BUILDS=$( ls -d $HUDSON_DROPS/I* | cut -d/ -f17 )

if [ -z "$BUILDS" -o  "$BUILDS" = "I*" ]; then
exit 0
fi

for f in $BUILDS; do
process_build $f
done

cd $TMPL_DIR

wget -O index.txt http://download.eclipse.org/e4/sdk/createIndex.php
scp index.txt pwebster@dev.eclipse.org:/home/data/httpd/download.eclipse.org/e4/sdk/index.html


