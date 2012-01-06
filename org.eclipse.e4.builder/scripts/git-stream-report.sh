#!/bin/bash
#

REPO=$(pwd)
STREAM_42=origin/master
STREAM_38=origin/R3_development
BRANCH_POINT=pre_R4_HEAD_merge
EXCLUDE_DIRS=$REPO/git_report/git_stream_exclude_dirs.txt
INCLUDE_DIRS=$REPO/git_report/git_stream_include_dirs.txt
EXCLUDE_COMMITS=$REPO/git_report/git_stream_exclude_commits.txt
MISSING_COMMITS=/tmp/missing_commits.txt

STREAM_42_DIR=$( dirname $STREAM_42 )
if [ . != $STREAM_42_DIR ]; then
	mkdir -p /tmp/${STREAM_42_DIR}
fi
STREAM_38_DIR=$( dirname $STREAM_38 )
if [ . != $STREAM_38_DIR ]; then
	mkdir -p /tmp/${STREAM_38_DIR}
fi


ORIGINAL_DIRS=$( find * -name .project | sed 's/\/.project$//g' | sort -u )

compare_proj () {
DIR="$1"
rm -f /tmp/${STREAM_42}.txt /tmp/${STREAM_38}.txt
if grep "^$DIR$" $EXCLUDE_DIRS >/dev/null; then
	return
fi

git log --format="%s" ${BRANCH_POINT}..${STREAM_42} \
  -- "$DIR" | grep -v -f  $EXCLUDE_COMMITS | sort -u >/tmp/${STREAM_42}.txt
git log --format="%s" ${BRANCH_POINT}..${STREAM_38} \
  -- "$DIR" | grep -v -f  $EXCLUDE_COMMITS | sort -u >/tmp/${STREAM_38}.txt

DIR_SED=$( echo "$DIR" | sed 's/\//\\\//g' )
diff /tmp/${STREAM_38}.txt /tmp/${STREAM_42}.txt \
  | grep ^\> | sed "s/$/: $DIR_SED/g" >>$MISSING_COMMITS

}

rm -f ${MISSING_COMMITS}

#DIR=bundles/org.eclipse.jface
for DIR in $ORIGINAL_DIRS; do
	compare_proj "$DIR"
done

while read DIR; do
	compare_proj "$DIR"
done < $INCLUDE_DIRS

sed 's/^> //g' ${MISSING_COMMITS} | sort -u


