#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### "=========================================================================
debug " Provisioning machine for Kali installation
##### "=========================================================================

# Create system mount points
prepareChroot

chroot_cmd apt-key add - < ${SCRIPTSDIR}/../keys/kali-archive-key.asc
chroot_cmd apt-mark hold qubes-core-agent
chroot_cmd apt-mark hold qubes-core-agent-networking
chroot_cmd apt-mark hold qubes-gui-agent
chroot_cmd apt-mark hold linux-image-amd64
chroot_cmd apt-mark hold grub-pc

sudo cat <<EOF > "${INSTALLDIR}/etc/apt/sources.list.d/kali.list"  
# Kali repository  
deb http://HTTPS///http.kali.org/kali kali-rolling main non-free contrib
EOF

## Ensure proxy handling is set
chroot_cmd sh -c 'sed -i s%https://%http://HTTPS///% /etc/apt/sources.list.d/* '


##### "=========================================================================
debug " Installing packages from Kali
##### "=========================================================================
aptDistUpgrade

cat <<EOF >> "${INSTALLDIR}/etc/apt/preferences.d/1hold"  

Package: wireguard
Pin: release *
Pin-Priority: -999

Package: linux-image-amd64
Pin: release *
Pin-Priority: -999
EOF

chroot_cmd sh -c 'sed -i s%https://%http://HTTPS///% /etc/apt/sources.list.d/* '
aptUpdate

APT_GET_OPTIONS+=" --allow-downgrades"
installPackages ${SCRIPTSDIR}/packages_kali.list


# ==============================================================================
# Kill all processes and umount all mounts within ${INSTALLDIR}, but not
# ${INSTALLDIR} itself (extra '/' prevents ${INSTALLDIR} from being umounted)
# ==============================================================================
umount_all "${INSTALLDIR}/" || true
