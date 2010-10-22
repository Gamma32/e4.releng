#!/bin/bash
#
# When the map file has been updated, this can be used to generate
# the releng build submission report
# USAGE: git-submission.sh >report.txt
#

BUG=/tmp/bugnumbers.txt
CHPROJ=/tmp/changed_projects.txt

SFX=_$( date "+%Y%m%d%H%M%S" ).txt
BUGREJ=/tmp/bugrej$SFX
BUGT1=/tmp/bug1$SFX


if [ ! -r $BUG ]; then
    echo No bug numbers to process 1>&2
    exit 0
fi

grep '[^0-9 ]' $BUG >$BUGREJ
if [ -s $BUGREJ ]; then
    echo Unprocessed lines:  1>&2
    cat $BUGREJ  1>&2
fi

grep -v '[^0-9 ]' $BUG | grep '[0-9]' | sort -nu  >$BUGT1

if [ ! -s $BUGT1 ]; then
    echo Nothing to process  1>&2
    exit 0
fi

echo The map file has been updated for the following Bug changes:

while read LINE; do
    echo Working on $LINE 1>&2
    BUGT2=/tmp/buginfo_${LINE}.txt
    
    # commented out so we can pick up the real status
    #if [ ! -s $BUGT2 ]; then
    curl -k https://bugs.eclipse.org/bugs/show_bug.cgi?id=${LINE}\&ctype=xml >$BUGT2 2>/dev/null
    #fi
    
    TITLE=$( grep short_desc $BUGT2 | sed 's/^.*<short_desc.//g' | sed 's/<\/short_desc.*$//g' )
    STATUS=$( grep bug_status $BUGT2 | sed 's/^.*<bug_status.//g' | sed 's/<\/bug_status.*$//g' )
    if [ RESOLVED = "$STATUS" -o VERIFIED = "$STATUS" ]; then
        STATUS=$( grep '<resolution>' $BUGT2 | sed 's/^.*<resolution.//g' | sed 's/<\/resolution.*$//g' )
    fi
    echo + Bug $LINE - $TITLE \(${STATUS}\)
done <$BUGT1

echo ""

if [ -s $CHPROJ ]; then
    echo The following projects have changed:
    cat $CHPROJ
fi

rm -f $BUG $CHPROJ
