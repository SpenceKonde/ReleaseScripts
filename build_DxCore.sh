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

# Change: Don't delete extras. We started doing that because of all the bloat from pinout images. But that's also where all of our docs are!
# So let's just delete the images...
# Delete the extras png files -
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/*.png
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/*.jpg
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/*.jpeg
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/*.gif
# SVGs are very small and can stay. When we move to all SVG diagrams, we'll actually be able to distribute the pinmapping diagrams :-P

# Delete the extras subfolders. IO headers goes because people will think those are the ones that get used and that they can edit them there.
# and the rest have no purpose outside of core development, so can be left manual only.
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/ioheaders
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/development
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/ci
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras/GenPinoutSVG

# Delete downloaded file and empty megaavr folder
rm -rf ${DOWNLOADED_FILE}.tar.bz2 $REPOSITORY-${DOWNLOADED_FILE#"v"}/megaavr

# Comment out the github/manual installation's tools.serialupdi.cmd...
sed -i 's/^tools.pymcuprog.cmd/#tools.pymcuprog.cmd/' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

sed -i 's/^tools.serialupdi.cmd/#tools.serialupdi.cmd/' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

#Remove any #REMOVE#'s in the platform.txt to replace them.
sed -i 's/^#REMOVE#//' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

# Guarantee that the version is set to the current version.
sed -i 's/^version=.*/version=${DOWNLOADED_FILE#"v"}' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

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
      "name": "DxCore: For all non-tinyAVR modern AVR devices: All AVRxxDAyy, AVRxxDByy, AVRxxDDyy (where xx = flash size, and yy is pincount <br/>
      DA and DB come with 128k 64k or 32k flash and 64, 48, 32, or 28 pins. AVR DD comes with 64k, 32k or 16k flash, in pincounts of 32, 28, 20 or 14 pins<br/>
      This core also supports the AVR Ex-series AVRxxEAyy and, pending release, will support the AVRxxDUyy and AVRxxEByy parts,"
    },
    {
      "name":"<b> Supported</b>: AVR128DA28/32/48/64, AVR128DB28/32/48/64, AVR64DD14/20/28/32, AVR64DA28/32/48/64, AVR64DB28/32/48/64<br/>
      AVR32DD14/20/28/32, AVR32DA28/32/48, AVR32DB28/32/48, AVR16DD14/20/28/32, AVR64EA28/32/48, AVR32EA28/32/48, AVR16EA28/32/48"
    },
    {
      "name":"<b> Planned pending release</b>: AVR32EB14/20/28/32, AVR16EB14/20/28/32, AVR8EB14/20/28/32, AVR64DU28/32, AVR32DU14/20/28/32, AVR16DU14/20/28/32<br/>"
    },
    {
      "name":"<b>Release Notes</b>: 1.5.11 - TBD"
    },
    {
      "name":"<b>Supported UPDI programmers</b>: SerialUPDI (serial adapter w/diode or resistor), jtag2updi, nEDBG, mEDBG, EDBG, SNAP, Atmel-ICE and PICkit4 - or use one of those to <br/>load Optiboot (included) for serial programming if you determine that it is appropriate for your application. <br/>SerialUPDI may not be functionally spectacular, but it supports the latest parts released, and it is fast as all hell, and the adapters cost practically nothing."
    }
  ],
  "toolsDependencies": [
    {
      "packager": "DxCore",
      "name": "avr-gcc",
      "version": "7.3.0-atmel3.6.1-azduino7b"
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
