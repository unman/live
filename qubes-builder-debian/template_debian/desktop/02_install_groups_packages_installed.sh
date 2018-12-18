#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Installing Desktop packages'
#### '----------------------------------------------------------------------
packages="audacity brasero gimp libreoffice-writer libreoffice-calc pidgin pidgin-otr scribus simple-scan vlc"
aptInstall $packages
