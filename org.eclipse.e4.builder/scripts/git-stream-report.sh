#!/bin/bash
#

REPO=$(pwd)
STREAM_42=origin/master
STREAM_42_FROM=pre_R4_HEAD_merge
STREAM_38=origin/R3_development
STREAM_38_FROM=pre_R4_HEAD_merge
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

git log --format="%s::%H::" ${STREAM_42_FROM}..${STREAM_42} \
  -- "$DIR" | grep -v -f  $EXCLUDE_COMMITS  >$TMP_DIR/${STREAM_42}.txt
git log --format="%s::%H::" ${STREAM_38_FROM}..${STREAM_38} \
  -- "$DIR" | grep -v -f  $EXCLUDE_COMMITS  >$TMP_DIR/${STREAM_38}.txt

list_delta "$TMP_DIR/${STREAM_42}.txt" \
  "$TMP_DIR/${STREAM_38}.txt" >>${MISSING_COMMITS}.1


list_delta  "$TMP_DIR/${STREAM_38}.txt" \
   "$TMP_DIR/${STREAM_42}.txt" >>${MISSING_COMMITS}.2

}

list_delta () {
IN="$1" ; shift
FROM="$1" ; shift



OLD_IFS="$IFS"
IFS=$'\n'

for line in $( cat "$IN" ); do
	SUBJECT=$( echo "$line" | sed 's/::[a-z0-9]*::$//g' | tr "\[\]" ".." )
	COMMIT=$( echo "$line" | sed 's/^.*::\([a-z0-9]*\)::$/\1/g' )
	if ! grep "^${SUBJECT}::" "$FROM" >/dev/null; then
		echo "${line}${DIR}" 
	fi
done

IFS="$OLD_IFS"

}


rm -f ${MISSING_COMMITS} ${MISSING_COMMITS}.1 ${MISSING_COMMITS}.2


#DIR=bundles/org.eclipse.ui.ide
for DIR in $ORIGINAL_DIRS; do
	compare_proj "$DIR"
done

while read DIR; do
	compare_proj "$DIR"
done < $INCLUDE_DIRS

#touch ${MISSING_COMMITS}

echo "Commits in $STREAM_42 missing from $STREAM_38" >>${MISSING_COMMITS}
echo >>${MISSING_COMMITS}
cat ${MISSING_COMMITS}.1 >>${MISSING_COMMITS}
echo >>${MISSING_COMMITS}
echo "Commits in $STREAM_38 missing from $STREAM_42" >>${MISSING_COMMITS}
echo >>${MISSING_COMMITS}
cat ${MISSING_COMMITS}.2 >>${MISSING_COMMITS}

cat ${MISSING_COMMITS}



