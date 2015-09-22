#! /bin/bash

echo "Start automatic board manager json file sync..."
rm -rf /var/boardmgr/scratch
git clone https://github.com/SpenceKonde/ReleaseScripts /var/boardmgr/scratch

cp /var/boardmgr/scratch/Arduino/scriptup.sh /var/boardmgr
chmod 774 /var/boardmgr/scriptup.sh

cp /var/boardmgr/scratch/*.json /var/www/html/
