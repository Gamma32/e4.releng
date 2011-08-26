#!/bin/bash
#
# Invoke this script from the root of an up to date clone of
# git://git.eclipse.org/gitroot/platform/org.eclipse.platform.ui.git
#
# This script will output the git commands to cherry pick commits
# from R4_development to R3_development
# 
# Example:  
#  git-cherry.sh > cherry.txt  #examine resulting file
#  /bin/bash cherry.txt  


#This is the list of projects that should not be cherrypicked over to the R3_development branch
EXCLUDED="bundles/org.eclipse.ui.workbench bundles/org.eclipse.ui bundles/org.eclipse.e4*"

EXCLUDED_COMMITS=$(git rev-list cherry_marker..R4_development -- $EXCLUDED)

COMMIT_LIST=$(git rev-list --cherry --reverse R3_development...R4_development ^cherry_marker --not $EXCLUDED_COMMITS)


echo git checkout R3_development
for COMMIT in $COMMIT_LIST; do
		commit_id=${COMMIT:1}
		echo git cherry-pick -x $commit_id
done