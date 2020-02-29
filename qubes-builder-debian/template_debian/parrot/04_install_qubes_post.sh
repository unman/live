
#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### "=========================================================================
debug " Provisioning machine for Parrot installation
##### "=========================================================================
chroot_cmd apt-key add - < ${SCRIPTSDIR}/../keys/parrot.asc
chroot_cmd apt-mark hold qubes-core-agent
chroot_cmd apt-mark hold qubes-core-agent-networking
chroot_cmd apt-mark hold qubes-gui-agent

sudo cat <<EOF > "${INSTALLDIR}/etc/apt/sources.list.d/parrot.list"  
# ParrotOS repository  
deb http://deb.parrotsec.org/parrot stable main contrib non-free  
#deb-src http://deb.parrotsec.org/parrot stable main contrib non-free  
EOF



##### "=========================================================================
debug " Installing packages from ParrotOS
##### "=========================================================================
aptDistUpgrade
cat <<EOF >> "${INSTALLDIR}/etc/apt/preferences.d/1hold"  

Package: wireguard
Pin: release *
Pin-Priority: -999
EOF

installPackages ${SCRIPTSDIR}/packages_parrot.list

##### "=========================================================================
debug " ParrotOS
##### "=========================================================================
