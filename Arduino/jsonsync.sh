#! /bin/bash

echo "Start automatic board manager json file sync..."
rm -rf /var/boardmgr/scratch
git clone https://github.com/SpenceKonde/ReleaseScripts /var/boardmgr/scratch

cp /var/boardmgr/scratch *.json /var/www/html/
