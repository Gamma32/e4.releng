#!/bin/bash

#*******************************************************************************
# Copyright (c) 2011 IBM Corporation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     IBM Corporation - initial API and implementation
#*******************************************************************************

baseBuilder=/shared/eclipse/e4/build/e4/org.eclipse.releng.basebuilder
launcherJar=$( find $baseBuilder/ -name "org.eclipse.equinox.launcher_*.jar" | sort | head -1 )
java=/shared/common/jdk-1.5.0-22.x86_64/jre/bin/java

remoteBase=/home/data/httpd/download.eclipse.org

e4Builds=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0
e4Repo=$e4Builds/targets/updates/0.12-I-builds
e4Drops=$remoteBase/e4/downloads/drops

sdkBuilds=/shared/eclipse/e4/build/e4/downloads/drops/4.0.0/40builds
sdkRepo=$e4Builds/targets/updates/4.2-I-builds
sdkDrops=$remoteBase/e4/sdk/drops

generateCleanupXML() {
        cat > cleanupScript.xml << "EOF"
<project>
        <target name="cleanup">
                <p2.composite.repository destination="file:${compositeRepo}">
			<remove>
EOF
        for f in $builds; do 
		echo "				<repository location=\"$f\" />" >> cleanupScript.xml
        done
cat >> cleanupScript.xml << "EOF"
			</remove>
                </p2.composite.repository>
        </target>
</project>
EOF

}

clean-e4() {
        pushd $e4Builds

        builds=$( ls --format=single-column -d I* | sort | head -n-5 )

	if [[ ! -z $builds ]]; then
		#remove from p2 composite repository
		generateCleanupXML
		$java -jar $baseBuilder/$launcherJar -application org.eclipse.ant.core.antRunner -f cleanupScript.xml -DcompositeRepo=$e4Repo

		for f in $builds; do
			rm -rf $f						#delete from build directory
			ssh pwebster@dev.eclipse.org rm -rf $e4Drops/$f		#delete from dev.eclipse.org drops
			rm -rf $e4Repo/$f					#delete from composite repo
		done

		#update website index and rsync the repo
		wget -O index.txt http://download.eclipse.org/e4/downloads/createIndex.php
		scp index.txt pwebster@dev.eclipse.org:$remoteBase/e4/downloads/index.html
		rm index.txt
		rsync --delete --recursive $e4Repo pwebster@dev.eclipse.org:$remoteBase/e4/updates
	fi
	popd
}

clean-sdk() {
	pushd $sdkBuilds
	
	builds=$( ls --format=single-column -d I* | sort | head -n-5 )
	
	if [[ ! -z $builds ]]; then
		generateCleanupXML
		$java -jar $baseBuilder/$launcherJar -application org.eclipse.ant.core.antRunner -f cleanupScript.xml -DcompositeRepo=$sdkRepo

		for f in $builds; do
			rm -rf $f						#delete from build directory
			ssh pwebster@dev.eclipse.org rm -rf $sdkDrops/$f	#delete from dev.eclipse.org drops
			rm -rf $sdkRepo/$f  					#delete from composite repo
			rm -rf /shared/eclipse/e4/sdk/$f			#delete from staging
		done

		#update website index and rsync the repo
		wget -O index.txt http://download.eclipse.org/e4/sdk/createIndex.php
		scp index.txt pwebster@dev.eclipse.org:$remoteBase/e4/sdk/index.html
		rm index.txt
		rsync --delete --recursive $sdkRepo pwebster@dev.eclipse.org:$remoteBase/eclipse/updates
	fi
	popd
}

clean-e4
clean-sdk

