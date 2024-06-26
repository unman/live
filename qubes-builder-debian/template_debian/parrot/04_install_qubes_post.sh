#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${TEMPLATE_CONTENT_DIR}/vars.sh"
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

##### "=========================================================================
debug " Provisioning machine for Parrot installation
##### "=========================================================================

# Create system mount points
prepareChroot

chroot_cmd apt-key add - < ${TEMPLATE_CONTENT_DIR}/../keys/parrot-debian-archive-keyring.gpg 
chroot_cmd apt-mark hold qubes-core-agent
chroot_cmd apt-mark hold qubes-core-agent-networking
chroot_cmd apt-mark hold qubes-gui-agent
chroot_cmd apt-mark hold linux-image-amd64
chroot_cmd apt-mark hold grub-pc


sudo rm "${INSTALL_DIR}/etc/apt/sources.list"
#sudo cat <<EOF > "${INSTALL_DIR}/etc/apt/sources.list.d/parrot.list"  
# ParrotOS repository  
#deb http://HTTPS///deb.parrot.sh/parrot rolling main contrib non-free non-free-firmware
#deb http://HTTPS///deb.parrot.sh/parrot lory main contrib non-free non-free-firmware
#deb http://HTTPS///deb.parrot.sh/parrot lory-security main contrib non-free non-free-firmware
#deb http://HTTPS///deb.parrot.sh/parrot lory-backports main contrib non-free non-free-firmware
#deb-src http://HTTPS///deb.parrot.sh/parrot lory main contrib non-free non-free-firmware
#deb-src http://HTTPS///deb.parrot.sh/parrot lory-security main contrib non-free non-free-firmware
#deb-src http://HTTPS///deb.parrot.sh/parrot lory-backports main contrib non-free non-free-firmware
#EOF
sudo cp ${TEMPLATE_CONTENT_DIR}/parrot/parrot.list "${INSTALL_DIR}/etc/apt/sources.list.d/parrot.list"  

## Ensure proxy handling is set
chroot_cmd sh -c 'sed -i s%https://%http://HTTPS///% /etc/apt/sources.list.d/* '

read -p "Before Installing Parrot Packages "

##### "=========================================================================
debug " Installing packages from ParrotOS
##### "=========================================================================
aptDistUpgrade

cat <<EOF >> "${INSTALL_DIR}/etc/apt/preferences.d/1hold"  

Package: wireguard
Pin: release *
Pin-Priority: -999

Package: linux-image-5.4.0-4parrot1-amd64
Pin: release *
Pin-Priority: -999

Package: linux-image-amd64
Pin: release *
Pin-Priority: -999
EOF


## Parrot rewrites the sources lists
## Ensure proxy handling is still set
chroot_cmd sh -c 'sed -i s%https://%http://HTTPS///% /etc/apt/sources.list.d/* '
aptUpdate

APT_GET_OPTIONS+=" --allow-downgrades=yes"
installPackages ${TEMPLATE_CONTENT_DIR}/packages_parrot.list
read -p "After Installing Parrot Packages "

##### "=========================================================================
debug " ParrotOS
##### "=========================================================================

# ==============================================================================
# Kill all processes and umount all mounts within ${INSTALL_DIR}, but not
# ${INSTALL_DIR} itself (extra '/' prevents ${INSTALL_DIR} from being umounted)
# ==============================================================================
umount_all "${INSTALL_DIR}/" || true
