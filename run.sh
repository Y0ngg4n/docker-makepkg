#!/bin/sh

set -e

if [ -z "$1" ]
  then
    DOCKER_MAKEPKG_PATH="/pkg"
else
  then
    DOCKER_MAKEPKG_PATH="$1"
fi

# Make a copy so we never alter the original
cp -r "$DOCKER_MAKEPKG_PATH" /tmp/pkg
cd /tmp/pkg

# Install (official repo + AUR) dependencies using yay. We avoid using makepkg
# -s since it is unable to install AUR dependencies.
yay -Sy --noconfirm \
    $(pacman --deptest $(source ./PKGBUILD && echo ${depends[@]} ${makedepends[@]}))

# Do the actual building
makepkg -f

# Store the built package(s). Ensure permissions match the original PKGBUILD.
if [ -n "$EXPORT_PKG" ]; then
    sudo chown $(stat -c '%u:%g' "$DOCKER_MAKEPKG_PATH"/PKGBUILD) ./*pkg.tar*
    sudo mv ./*pkg.tar* "$DOCKER_MAKEPKG_PATH"
fi
