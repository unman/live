#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Installing firmware'
#### '----------------------------------------------------------------------
chroot_cmd sh -c 'echo "firmware-ipw2x00/license/accepted select true" |debconf-set-selections'
packages="atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 firmware-iwlwifi firmware-misc-nonfree firmware-realtek firmware-zd1211"
aptInstall $packages
