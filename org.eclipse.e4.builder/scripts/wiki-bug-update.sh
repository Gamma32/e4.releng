#!/bin/bash
#
# read in a list of bugs and generate a wiki page to work from

# input form:
# {{bug|389478}} ... whatever

# output
# {{bug|389478}} - Need IDE.openEditors(...) that allows to inject state

INFILE=$1; shift
SFILE=/tmp/t1_$$.txt

sed 's/^.*bug|\([0-9]*\).*$/\1/g' $INFILE >$SFILE

for BUG in $( cat $SFILE ); do
	PRE=""
	POST=""
	BUGT2=/tmp/buginfo_$$.txt
	curl -k https://bugs.eclipse.org/bugs/show_bug.cgi?id=${BUG}\&ctype=xml >$BUGT2 2>/dev/null
	TITLE=$( grep short_desc $BUGT2 | sed 's/^.*<short_desc.//g' | sed 's/<\/short_desc.*$//g' )
	STATUS=$( grep bug_status $BUGT2 | sed 's/^.*<bug_status.//g' | sed 's/<\/bug_status.*$//g' )
	if [ RESOLVED = "$STATUS" -o VERIFIED = "$STATUS" ]; then
        	STATUS=$( grep '<resolution>' $BUGT2 | sed 's/^.*<resolution.//g' | sed 's/<\/resolution.*$//g' )
		PRE="<strike>"
		POST="</strike>"
    	fi
	echo "# $PRE{{bug|$BUG}} - $TITLE ($STATUS)$POST"
done

