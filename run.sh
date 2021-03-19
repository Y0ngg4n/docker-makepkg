#!/bin/sh

set -e

if [ -z "$1" ]
  then
    DOCKER_MAKEPKG_PATH="/pkg"
else
    DOCKER_MAKEPKG_PATH="$1"
fi

if [ -z "$2" ]
  then
    DOCKER_OUT_PATH="/pkg"
else
    DOCKER_OUT_PATH="$2"
fi

# Make a copy so we never alter the original
cp -rv "$DOCKER_MAKEPKG_PATH" /tmp/pkg
cd /tmp/pkg

# Install (official repo + AUR) dependencies using yay. We avoid using makepkg
# -s since it is unable to install AUR dependencies.
yay -Sy --noconfirm \
    $(pacman --deptest $(source ./PKGBUILD && echo ${depends[@]} ${makedepends[@]}))

# Do the actual building
makepkg -f

# Store the built package(s). Ensure permissions match the original PKGBUILD.
if [ -z "$2" ]; then
    sudo chown $(stat -c '%u:%g' "$DOCKER_MAKEPKG_PATH"/PKGBUILD) ./*pkg.tar*
    sudo mv ./*pkg.tar* "$DOCKER_OUT_PATH"
fi
