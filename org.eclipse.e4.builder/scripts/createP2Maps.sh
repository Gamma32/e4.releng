#!/bin/bash
#

#
# This will blindly set all plugins and fragments to be
# fetched from the 3.6 repo ... let's see how far it goes :-)
#

for f in "$@"; do
echo Working on $f
rm -f t1 t2
sed 's/plugin@\([^=]*\)=.*$/plugin@\1=p2IU,id=\1,version=,repository=http:\/\/download.eclipse.org\/eclipse\/updates\/3.6\//g' $f >t1
sed 's/fragment@\([^=]*\)=.*$/fragment@\1=p2IU,id=\1,version=,repository=http:\/\/download.eclipse.org\/eclipse\/updates\/3.6\//g' t1 >t2

mv t2 $f

done

rm -f t1 t2
