#!/bin/bash
#
# this is a much better script for converting CVS maps to git maps.
# you need to have org.eclipse.releng checked out in $WS
# and you need to list the repos you want to convert to.  For each
# repo, git://git.eclipse.org/gitroot/platform/eclipse.platform.ui.git,
# the clone must exist at $ROOT/eclipse.platform.ui


ROOT=/opt/pwebster/git/eclipse
WS=/opt/pwebster/workspaces/gitMigration

REPOS='
git://git.eclipse.org/gitroot/platform/eclipse.platform.runtime.git 
git://git.eclipse.org/gitroot/platform/eclipse.platform.ui.git 
git://git.eclipse.org/gitroot/e4/org.eclipse.e4.tools.git 
git://git.eclipse.org/gitroot/e4/org.eclipse.e4.ui.git
'

cd $ROOT

update_map () {
	REPO=$1
	REPO_DIR=$( basename $REPO .git )
	M=$2
	ID=$3
	MAP=$4
	if [ ! -z "$5" ]; then
		echo Extra map $5
	fi
	
	REPO_PATH=$( echo $REPO | sed 's/\//\\\//g' )
	M_PATH=$( echo $M | sed 's/^[^/]*\///g' | sed 's/\//\\\//g' )
	echo sed "'s/@${ID}=\([^,]*\),.*$/@${ID}=GIT,tag=\1,repo=${REPO_PATH},path=${M_PATH}/g' $MAP >t1.txt ; mv t1.txt $MAP "
}


# find the map files
for REPO in $REPOS; do
	REPO_DIR=$( basename $REPO .git )
	MODULES=$( ls -d $REPO_DIR/*/* )
	for M in $MODULES; do
		ID=$( basename $M )
		MAP=$( find $WS/org.eclipse.releng/maps -name "*.map" -exec grep -l "@${ID}=" {} \; )
		if [ ! -z "$MAP" ]; then
			update_map $REPO $M $ID $MAP
		fi
		#MAP=$( find $WS/releng -name "*.map" -exec grep -l "@${ID}=" {} \; )
		#if [ ! -z "$MAP" ]; then
		#	update_map $REPO $M $ID $MAP
		#fi
	done
done
