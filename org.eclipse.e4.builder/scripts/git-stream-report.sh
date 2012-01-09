#!/bin/bash
#

REPO=$(pwd)
STREAM_42=origin/master
STREAM_38=origin/R3_development
BRANCH_POINT=pre_R4_HEAD_merge
EXCLUDE_DIRS=$REPO/git_report/git_stream_exclude_dirs.txt
INCLUDE_DIRS=$REPO/git_report/git_stream_include_dirs.txt
EXCLUDE_COMMITS=$REPO/git_report/git_stream_exclude_commits.txt
TMP_DIR=/tmp/report_$$
MISSING_COMMITS=$TMP_DIR/missing_commits.txt

STREAM_42_DIR=$( dirname $STREAM_42 )
if [ . != $STREAM_42_DIR ]; then
	mkdir -p $TMP_DIR/${STREAM_42_DIR}
fi
STREAM_38_DIR=$( dirname $STREAM_38 )
if [ . != $STREAM_38_DIR ]; then
	mkdir -p $TMP_DIR/${STREAM_38_DIR}
fi


ORIGINAL_DIRS=$( find * -name .project | sed 's/\/.project$//g' | sort -u )

compare_proj () {
DIR="$1"
rm -f $TMP_DIR/${STREAM_42}.txt $TMP_DIR/${STREAM_38}.txt
if grep "^$DIR$" $EXCLUDE_DIRS >/dev/null; then
	return
fi

git log --format="%s::%H::" ${BRANCH_POINT}..${STREAM_42} \
  -- "$DIR" | grep -v -f  $EXCLUDE_COMMITS  >$TMP_DIR/${STREAM_42}.txt
git log --format="%s::%H::" ${BRANCH_POINT}..${STREAM_38} \
  -- "$DIR" | grep -v -f  $EXCLUDE_COMMITS  >$TMP_DIR/${STREAM_38}.txt


OLD_IFS="$IFS"
IFS=$'\n'

for line in $( cat $TMP_DIR/${STREAM_42}.txt ); do
	SUBJECT=$( echo "$line" | sed 's/::[a-z0-9]*::$//g' | tr "\[\]" ".." )
	COMMIT=$( echo "$line" | sed 's/^.*::\([a-z0-9]*\)::$/\1/g' )
	if ! grep "^${SUBJECT}::" $TMP_DIR/${STREAM_38}.txt >/dev/null; then
		echo "${line}${DIR}" >>${MISSING_COMMITS}
	fi
done

IFS="$OLD_IFS"

}

rm -f ${MISSING_COMMITS}
echo "Cherry-pick: $STREAM_42 commits missing from $STREAM_38" >>${MISSING_COMMITS}
echo >>${MISSING_COMMITS}


#DIR=bundles/org.eclipse.ui.ide
for DIR in $ORIGINAL_DIRS; do
	compare_proj "$DIR"
done

while read DIR; do
	compare_proj "$DIR"
done < $INCLUDE_DIRS

#touch ${MISSING_COMMITS}
cat ${MISSING_COMMITS}



