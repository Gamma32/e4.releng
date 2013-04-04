#!/bin/bash
#
# read in a list of bugs and generate a wiki page to work from

# output
# {{bug|389478}} - Need IDE.openEditors(...) that allows to inject state

for BUG in $( cat $1 ); do
	BUGT2=/tmp/buginfo_$$.txt
	curl -k https://bugs.eclipse.org/bugs/show_bug.cgi?id=${BUG}\&ctype=xml >$BUGT2 2>/dev/null
	TITLE=$( grep short_desc $BUGT2 | sed 's/^.*<short_desc.//g' | sed 's/<\/short_desc.*$//g' )
	STATUS=$( grep bug_status $BUGT2 | sed 's/^.*<bug_status.//g' | sed 's/<\/bug_status.*$//g' )
	if [ RESOLVED = "$STATUS" -o VERIFIED = "$STATUS" ]; then
        	STATUS=$( grep '<resolution>' $BUGT2 | sed 's/^.*<resolution.//g' | sed 's/<\/resolution.*$//g' )
    	fi
	TARGET=$( grep target_milestone $BUGT2 | sed 's/^.*<target_milestone.//g' | sed 's/<\/target.*$//g' )
	echo \# \{\{bug\|$BUG}} - $TARGET - $TITLE - $STATUS
done

