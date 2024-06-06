#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 09_cleanup.sh : Clean up the new chroot prior to image finalisation
echo "--> Archlinux 09_cleanup.sh"

set -e
if [ "${VERBOSE:-0}" -ge 2 ] || [ "${DEBUG:-0}" -eq 1 ]; then
    set -x
fi

# Remove unused packages and their dependencies (make dependencies)
cleanuppkgs="$("${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c 'pacman -Qdt | grep -v kernel | cut -d " " -f 1')"
if [ -n "$cleanuppkgs" ] ; then
    echo "  --> Packages that will be cleaned up: $cleanuppkgs"
    "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c "pacman --noconfirm -Rsc $cleanuppkgs"
else
    echo "  --> NB: No packages to clean up"
fi

echo "${INSTALL_DIR}"

echo "  --> Cleaning up repository definitions..."
sed -i s^http://HTTPS///^https://^  "${INSTALL_DIR}"/etc/pacman.d/*.disabled
sed -i s^http://HTTPS///^https://^  "${INSTALL_DIR}"/etc/pacman.d/*mirrorlist
sed -i s^http://HTTPS///^https://^  "${INSTALL_DIR}"/etc/pacman.d/10-qubes-options.conf

# TODO: Be more deliberate here; is the umount necessary?
# Moreover, given where this script is called, should we be bothering
# arch-chroot-lite?
echo "  --> Cleaning up pacman state..."
umount "${INSTALL_DIR}/var/cache/pacman" || true
unset PACMAN_CACHE_DIR
"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
    "pacman --noconfirm -Scc"

echo " --> Cleaning /etc/resolv.conf"
rm -f "${INSTALL_DIR}/etc/resolv.conf"
cat > "${INSTALL_DIR}/etc/resolv.conf" << EOF
# This file intentionally left blank

EOF
