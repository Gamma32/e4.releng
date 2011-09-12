#!/bin/bash
#

fromDir=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/targets/updates/4.2-I-builds
toDir="pwebster@build.eclipse.org:/home/data/httpd/download.eclipse.org/eclipse/updates"

rsync --recursive --delete "${fromDir}" "${toDir}"

