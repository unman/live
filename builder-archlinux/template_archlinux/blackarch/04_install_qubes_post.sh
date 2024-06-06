#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 04_install_qubes_blackarch_post.sh : Update and convert to BlackArch system
echo "--> Archlinux 05_install_blackarch.sh "

set -e
if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

# Support for legacy builder
if [ -n "$CACHEDIR" ]; then
    CACHE_DIR="$CACHEDIR"
fi

PACMAN_CACHE_DIR="${CACHE_DIR}/pacman_cache"

if [ "0${IS_LEGACY_BUILDER}" -eq 1 ]; then
    PACMAN_CUSTOM_REPO_DIR="${PWD}/pkgs-for-template/${DIST}"
else
    PACMAN_CUSTOM_REPO_DIR="${PACKAGES_DIR}"
fi

export PACMAN_CACHE_DIR PACMAN_CUSTOM_REPO_DIR "ALL_PROXY=$REPO_PROXY"

KEYS_DIR="${TEMPLATE_CONTENT_DIR}/../keys"
export KEYS_DIR

run_pacman () {
    "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
        'proxy=$1; shift; trap break SIGINT SIGTERM; for i in 1 2 3 4 5; do ALL_PROXY=$proxy http_proxy=$proxy https_proxy=$proxy "$@" && exit; done; exit 1' sh "$REPO_PROXY" pacman "$@"
}

echo " --> Allow weak key signatures"
echo 'allow-weak-key-signatures' >> "$INSTALL_DIR"/etc/pacman.d/gnupg/gpg.conf

echo " --> Installing blackarch keyring"
key_package="${TEMPLATE_CONTENT_DIR}/blackarch/blackarch-keyring.pkg.tar.xz"
key_path="${KEYS_DIR}/blackarch/pubring.gpg"

"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" pacman-key --add /proc/self/fd/0 < "${key_path}"
key_fpr=$(gpg --with-colons --show-key "${key_path}"| grep ^fpr: | cut -d : -f 10)
for key in $key_fpr; do "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" pacman-key --lsign "$key"; done

echo " --> Preparing for Proxy use"
sed -i s^https://^http://HTTPS///^  "$INSTALL_DIR"/etc/pacman.d/*disabled || true
sed -i s^https://^http://HTTPS///^  "$INSTALL_DIR"/etc/pacman.d/*mirrorlist* || true
echo " --> Installing BlackArch key package"
run_pacman -Syu --noconfirm --noprogressbar
sudo cp -v "${key_package}" "$INSTALL_DIR"/root/blackarch-keyring.pkg.tar.xz
"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" pacman -U --noconfirm /root/blackarch-keyring.pkg.tar.xz
rm "$INSTALL_DIR"/root/blackarch-keyring.pkg.tar.xz

echo " --> Installing BlackArch repository"
repos_basename="${TEMPLATE_CONTENT_DIR}/../repos/blackarch-mirrorlist.conf"
cat "${repos_basename}" >> "$INSTALL_DIR/etc/pacman.d/blackarch-mirrorlist.conf"
sed -i s^https://^http://HTTPS///^  "$INSTALL_DIR"/etc/pacman.d/blackarch-mirrorlist.conf
cat >> "$INSTALL_DIR/etc/pacman.conf" << EOF
[blackarch]
Include = /etc/pacman.d/blackarch-mirrorlist.conf
EOF

echo "  --> Updating BlackArch repository..."
run_pacman -Syu --noconfirm --noprogressbar

echo "  --> BlackArch Linux is ready"
