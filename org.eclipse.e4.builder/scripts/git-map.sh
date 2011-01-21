#!/bin/bash
#
# example usage from within the local org.eclipse.e4.deeplink repo
# USAGE: git-map.sh v20101018-1500 \
#   ../releng/org.eclipse.e4.deeplink.releng/maps/deeplink.map \
#   bundles
#
#

BUG=/tmp/bugnumbers.txt
CHPROJ=/tmp/changed_projects.txt

BUILD_TAG=$1 ; shift
MAPFILE=$1 ; shift
BASEDIR=$1; shift

PROJECTS=$( ls $BASEDIR )
LATEST_SUBMISSION=""

for proj in $PROJECTS; do
    echo Processing $proj
    PROJ_LINE=$( grep "@${proj}=" ${MAPFILE} )
    projId=$proj
    
    if [ -z "$PROJ_LINE" ]; then
    	PROJ_LINE=$( grep "path=${BASEDIR}/${proj}" ${MAPFILE} )
    	projId=$( echo $PROJ_LINE | sed -e 's:^\(plugin\|feature\|fragment\|bundle\)@\([-._A-Za-z0-9]*\)=.*$:\2:' )
    fi
    
    if [ ! -z "$PROJ_LINE" ]; then
	LAST_COMMIT=$( git rev-list HEAD -- $BASEDIR/$proj | head -1 )
	LAST_SUBMISSION=$( echo $PROJ_LINE | sed -e 's/^.*tag=//' | sed -e 's/,.*$//')
	if [ "$LATEST_SUBMISSION" \< "$LAST_SUBMISSION" ]; then
	    LATEST_SUBMISSION=$LAST_SUBMISSION
	fi
	
	LAST_COMMIT_DATE=$( git log --pretty=format:"%H %ad" --date=iso | grep $LAST_COMMIT | sed -e 's:[a-f0-9]* \(.*\)$:\1:' )
	echo Last commit was at $LAST_COMMIT_DATE
	echo Map file entry is $LAST_SUBMISSION
	
	if ! ( git tag --contains $LAST_COMMIT | grep $LAST_SUBMISSION >/dev/null ); then
	    echo Needs to move from $LAST_SUBMISSION to $BUILD_TAG
	    echo ${proj} >>$CHPROJ
	    sed "s/@${projId}=GIT,tag=$LAST_SUBMISSION/@${projId}=GIT,tag=$BUILD_TAG/g" $MAPFILE >/tmp/t1.txt
	    mv /tmp/t1.txt $MAPFILE
	fi
    fi

    echo ""
done

git log  ${LATEST_SUBMISSION}..${BUILD_TAG} "$BASEDIR" \
 | grep '[Bb]ug '  \
 | sed 's/.*[Bb]ug[^0-9]*\([0-9][0-9][0-9][0-9][0-9]*\)[^0-9].*$/\1/g' >>$BUG

