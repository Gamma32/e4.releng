#!/bin/bash
#
# USAGE: /bin/bash git-gen-map.sh REPO-URL TAG <relative-directory-path-with-plugins>+
# ex: /bin/bash /opt/pwebster/workspaces/e4-search/releng/org.eclipse.e4.builder/scripts/git-gen-map.sh git://git.eclipse.org/gitroot/e4/org.eclipse.e4.search.git v20101124-0800 bundles tests features
#

REPO=$1
shift
TAG=$1
shift

gen_line () {
DIR=$1
PLUGIN=$2
START=plugin
if [ "$DIR" = "features" ]; then
	START=feature
fi
echo "${START}@${PLUGIN}=GIT,tag=${TAG},repo=${REPO},path=${DIR}/${PLUGIN}"
}


for DIR in "$@"; do
	for f in ${DIR}/*; do
		FN=$( basename $f )
		gen_line $DIR $FN
	done
	echo ""
	echo ""
done
