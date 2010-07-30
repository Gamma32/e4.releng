#!/bin/bash
#


update_http () {
wget -O index.txt http://${1}.eclipse.org/e4/${2}/createIndex.php
scp index.txt pwebster@dev.eclipse.org:/home/data/httpd/${1}.eclipse.org/e4/${2}/index.html
}

update_http download downloads
update_http download sdk
update_http archive downloads
update_http archive sdk

