#
#Copyright (C) 2010  Rubén Rodríguez <ruben@trisquel.info>
#Adapted for Qubes OS by unman <unman@thirdeyesecurity.org>
#

#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#GNU General Public License for more details.

#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#

#!/bin/bash -e
# vim: set ts=2 sw=2 sts=2 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

#if ! touch /etc/apt/sources.list 2>/dev/null
#then
#echo You need to run this script with sudo!
#echo Try: sudo sh $0
#fi

# Edit these lines if you want to use a different mirror, release or edition.
# Available editions are trisquel and trisquel-mini
MIRROR="http://es.archive.trisquel.info/trisquel/"
RELEASE="etiona"
EDITION="trisquel"

chroot_cmd cp /etc/apt/sources.list /etc/apt/sources.list.ubuntu-orig
cat << EOF > "${INSTALLDIR}/etc/apt/sources.list"
deb $MIRROR $RELEASE main
deb $MIRROR $RELEASE-security main
deb $MIRROR $RELEASE-updates main
#deb $MIRROR $RELEASE-backports main
deb-src $MIRROR $RELEASE main
deb-src $MIRROR $RELEASE-security main
deb-src $MIRROR $RELEASE-updates main
#deb $MIRROR $RELEASE-backports main
EOF

#sed -i 's/\(.*\)/#\1/' "${INSTALLDIR}/etc/apt/sources.list.d/*" || true

cat << EOF > "${INSTALLDIR}/etc/apt/preferences.d/pinning"
Package: *
Pin: release o=Trisquel
Pin-Priority: 1001
EOF

chroot_cmd apt-key add - < ${SCRIPTSDIR}/../keys/trisquel.asc
aptUpdate 2>&1 | COLUMNS=500 tee /var/log/trisquelize.log
aptInstall trisquel-keyring 2>&1 | COLUMNS=500 tee -a /var/log/trisquelize.log

aptRemove --purge plymouth-theme-ubuntu 2>&1 | COLUMNS=500 tee -a /var/log/trisquelize.log
aptRemove --purge plymouth-theme-ubuntu-text 2>&1 | COLUMNS=500 tee -a /var/log/trisquelize.log
aptDistUpgrade 2>&1 | COLUMNS=500 tee -a /var/log/trisquelize.log

echo -------------------------------------------
#echo "Need to remove linux-firmware BEFORE installing firmware-linux-free"
#echo Your system may still have some non-free packages installed,
#echo Now removing them.
files="chromium-browser linux-firmware ubufox "
aptRemove --purge $files
aptInstall --no-install-recommends $EDITION $EDITION-recommended 2>&1 | COLUMNS=500 tee -a /var/log/trisquelize.log
aptInstall --no-install-recommends linux-image-generic 2>&1 | COLUMNS=500 tee -a /var/log/trisquelize.log
chroot_cmd rm /etc/apt/preferences.d/pinning


#for i in aee afio app-install-data-commercial app-install-data-partner app-install-data-ubuntu b43-fwcutter capiutils chromium-browser chromium-browser-dbg chromium-browser-inspector chromium-browser-l10n chromium-codecs-ffmpeg chromium-codecs-ffmpeg-dbg chromium-codecs-ffmpeg-extra chromium-codecs-ffmpeg-extra-dbg chromium-codecs-ffmpeg-nonfree chromium-codecs-ffmpeg-nonfree-dbg d4x-common envyng-core envyng-gtk envyng-qt fglrx-modaliases firefox-3.5-branding firefox-branding flashplugin-installer freesci freesci-doc gstreamer0.10-pitfdll helix-player ipppd isdnactivecards isdneurofile isdnlog isdnlog-data isdnutils isdnutils-base isdnutils-doc isdnutils-xtools isdnvbox isdnvboxclient isdnvboxserver ivman jockey jockey-common jockey-gtk jockey-kde libmoon libmoonlight-desktop2.0-cil-dev libmoonlight-gtk3.0-cil libmoonlight-system-windows-controls2.0-cil libmoonlight-system-windows3.0-cil libmoonlight-windows-desktop3.0-cil libubuntuone libubuntuone-1.0-1 libubuntuone-dev libubuntuone1.0-cil libubuntuone1.0-cil-dev monodoc-moonlight-manual moon moonlight-plugin-core moonlight-plugin-mozilla moonlight-tools moonlight-web-devel mozilla-helix-player ndisgtk ndiswrapper ndiswrapper-common ndiswrapper-utils-1.9 nvidia-173-modaliases nvidia-180-modaliases nvidia-185-modaliases nvidia-96-modaliases nvidia-common nvidia-current-modaliases nvidia-settings ophcrack ophcrack-cli pdftk pppdcapiplugin rman scribus-ng-doc scsi-firmware linux-firmware software-center tatan ubufox ubuntu-drivers-common ubuntuone-client ubuntuone-client-gnome ubuntuone-client-tools ubuntuone-storage-protocol user-mode-linux vrms
#do
#
#echo WARNING: non-free package found: $i
#echo Do you want to remove it?
#apt-get remove --purge $i
#done



echo -------------------------------------------
echo System successfully Trisquelized!
echo If you want to use the Trisquel default desktop layout and
echo other gconf settings, run this as user:
echo gconftool --recursive-unset /apps
