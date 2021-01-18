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
REPOSITORY=DxCore       # Github repo name

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

# Move files out of the megaavr folder
mv $REPOSITORY-${DOWNLOADED_FILE#"v"}/megaavr/* $REPOSITORY-${DOWNLOADED_FILE#"v"}

# Delete the extras folder
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras

# Delete downloaded file and empty megaavr folder
rm -rf ${DOWNLOADED_FILE}.tar.bz2 $REPOSITORY-${DOWNLOADED_FILE#"v"}/megaavr

# Comment out the github/manual installation's tools.pymcuprog.cmd...
sed -i 's/^tools.pymcuprog.cmd/#tools.pymcuprog.cmd/' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

#
sed -i 's/^#REMOVE#//' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt


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
  "architecture": "megaavr",
  "version": $version,
  "category": "Contributed",
  "url": $url,
  "archiveFileName": $file_name,
  "checksum": $checksum,
  "size": $file_size,
  "boards": [
    {
      "name": "AVR128DA28,AVR128DA32,AVR128DA48,AVR128DA64"
    },
    {
      "name": "AVR64DA28,AVR64DA32,AVR64DA48,AVR64DA64"
    },
    {
      "name": "AVR32DA28,AVR32DA32,AVR32DA48"
    },
    {
      "name": "AVR128DB28,AVR128DB32,AVR128DB48,AVR128DB64"
    },
    {
      "name": "AVR64DB28,AVR64DB32,AVR64DB48,AVR6BDA64"
    },
    {
      "name": "AVR32DB28,AVR32DB32,AVR32DB48"
    }
  ],
  "toolsDependencies": [
    {
      "packager": "DxCore",
      "name": "avr-gcc",
      "version": "7.3.0-atmel3.6.1-azduino1"
    },
    {
      "packager": "arduino",
      "name": "avrdude",
      "version": "6.3.0-arduino18"
    },
    {
      "packager": "arduino",
      "name": "arduinoOTA",
      "version": "1.3.0"
    },
    {
      "packager": "megaTinyCore",
      "version": "3.7.2-post1",
      "name": "python3"
    }
  ]
}' "package_drazzy.com_index.json.tmp" > "package_drazzy.com_index.json"

# Remove files that's no longer needed
rm -rf "$REPOSITORY-${DOWNLOADED_FILE#"v"}" "package_drazzy.com_index.json.tmp"
