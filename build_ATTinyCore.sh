#!/bin/bash

##########################################################
##                                                      ##
## Shell script for generating a boards manager release ##
## Created by MCUdude                                   ##
## Requires wget, jq and a bash environment             ##
##                                                      ##
##########################################################

# Change these to match your repo
AUTHOR=SpenceKonde      # Github username
REPOSITORY=ATTinyCore # Github repo name

# Get the download URL for the latest release from Github
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/$AUTHOR/$REPOSITORY/releases/latest | grep "tarball_url" | awk -F\" '{print $4}')

# Download file
wget --no-verbose $DOWNLOAD_URL

# Get filename
DOWNLOADED_FILE=$(echo $DOWNLOAD_URL | awk -F/ '{print $8}')

# Add .tar.bz2 extension to downloaded file
mv $DOWNLOADED_FILE ${DOWNLOADED_FILE}.tar.bz2

# Extract downloaded file and place it in a folder (the #"v"} part removes the v in the version number if it is present)
printf "\nExtracting folder ${DOWNLOADED_FILE}.tar.bz2 to $REPOSITORY-${DOWNLOADED_FILE#"v"}\n"
mkdir -p "$REPOSITORY-${DOWNLOADED_FILE#"v"}" && tar -xzf ${DOWNLOADED_FILE}.tar.bz2 -C "$REPOSITORY-${DOWNLOADED_FILE#"v"}" --strip-components=1
printf "Done!\n"

# Move files out of the avr folder
mv $REPOSITORY-${DOWNLOADED_FILE#"v"}/avr/* $REPOSITORY-${DOWNLOADED_FILE#"v"}

# Delete the extras folder
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras

# Delete downloaded file and empty avr folder
rm -rf ${DOWNLOADED_FILE}.tar.bz2 $REPOSITORY-${DOWNLOADED_FILE#"v"}/avr

# Compress folder to tar.bz2
printf "\nCompressing folder $REPOSITORY-${DOWNLOADED_FILE#"v"} to $REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2\n"
tar -cjSf $REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2 $REPOSITORY-${DOWNLOADED_FILE#"v"}
printf "Done!\n"

# Get file size on bytes
FILE_SIZE=$(wc -c "$REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2" | awk '{print $1}')

# Get SHA256 hash
SHA256="SHA-256:$(shasum -a 256 "$REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2" | awk '{print $1}')"

# Create Github download URL
URL="https://${AUTHOR}.github.io/${REPOSITORY}/$REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2"

cp "package_drazzy.com_index.json" "package_drazzy.com_index.json.tmp"

# Add new boards release entry
jq -r                                   \
--arg repository $REPOSITORY            \
--arg version    ${DOWNLOADED_FILE#"v"} \
--arg url        $URL                   \
--arg checksum   $SHA256                \
--arg file_size  $FILE_SIZE             \
--arg file_name  $REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2  \
'(.packages[] | select(.name==$repository)).platforms[(.packages[] | select(.name==$repository)).platforms | length] |= . +
{
  "name": $repository,
  "architecture": "avr",
  "version": $version,
  "category": "Contributed",
  "url": $url,
  "archiveFileName": $file_name,
  "checksum": $checksum,
  "size": $file_size,
  "boards": [
    {"name": "Program via ISP or Serial:"},
    {"name": "ATtiny841/441, ATtiny85/45/25, ATtiny43"},
    {"name": "ATtiny84/44/24, ATtiny1634, ATtiny828"},
    {"name": "ATtiny861/461/261, ATtiny167/87"},
    {"name": "ATtiny88/48, ATtiny4313/2313"},
    {"name": "USB (Micronucleus) boards:"},
    {"name": "DigiSpark (t85), Digispark Pro (t167)"},
    {"name": "Wattuino Nano (t841), CaliforniaSTEAM (t84)"},,
    {"name": "AzduinoUSB (t84, t841, t861, t1634)"}
  ],
  "toolsDependencies": [
    {
      "packager": "arduino",
      "name": "avr-gcc",
      "version": "7.3.0-atmel3.6.1-arduino7"
    },
    {
      "packager": "arduino",
      "name": "avrdude",
      "version": "6.3.0-arduino18"
    },
    {
      "packager": "ATTinyCore",
      "name": "micronucleus",
      "version": "2.0a4"
    }
  ]
}' "package_drazzy.com_index.json.tmp" > "package_drazzy.com_index.json"

# Remove files that's no longer needed
rm -rf "$REPOSITORY-${DOWNLOADED_FILE#"v"}" "package_drazzy.com_index.json.tmp"
