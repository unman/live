#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### '=========================================================================
debug ' Mint post Qubes...'
##### '=========================================================================

chroot_cmd apt-key add - < ${SCRIPTSDIR}/../keys/unman.pub

cat >> "${INSTALLDIR}/etc/apt/sources.list.d/qubes-3isec.list" <<EOF
deb https://qubes.3isec.org/4.0 ${DIST} main
EOF


chroot_cmd apt-get update
