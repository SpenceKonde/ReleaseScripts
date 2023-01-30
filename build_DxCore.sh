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

# Comment out the github/manual installation's tools.serialupdi.cmd...
sed -i 's/^tools.pymcuprog.cmd/#tools.pymcuprog.cmd/' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

sed -i 's/^tools.serialupdi.cmd/#tools.serialupdi.cmd/' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

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
      "name": "AVR Dx-series: All AVRxxDAyy, AVRxxDByy, AVRxxDDyy (where xx = flash size, and yy is pincount <br/>
      DA and DB come with 128k 64k or 32k flash and 64, 48, 32, or 28 pins. AVR DD comes with 64k, 32k or 16k flash, in pincounts of 32, 28, 20 or 14 pins<br/>
      This core will (despite the name) support the AVRxxEAyy and AVRxxEByy series parts when they become available."
    },
    {
      "name": "1.5.4 picks up a single bugfix from a PR, written by someone who has a Microchip logo as their avatar called it critical. New attachInterrupt implementation on PORTC was broken, and somehow nobody noticed until now. "
    },
    {
      "name": "Supported UPDI programmers: SerialUPDI (serial adapter w/diode or resistor), jtag2updi, nEDBG, mEDBG, EDBG, SNAP, Atmel-ICE and PICkit4 - or use one of those to <br/>load Optiboot (included) for serial programming if you determine that it is appropriate for your application.<br/>SerialUPDI may not be functionality spectacular, it supports the latest parts released, and it is fast as all hell, and the adapters cost practically nothing."
    }
  ],
  "toolsDependencies": [
    {
      "packager": "DxCore",
      "name": "avr-gcc",
      "version": "7.3.0-atmel3.6.1-azduino6"
    },
    {
      "packager": "DxCore",
      "name": "avrdude",
      "version": "6.3.0-arduino17or18"
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
