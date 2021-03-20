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

# Check if exists in Nexus
PKGNAME=$(cat PKGBUILD | grep pkgname= | cut -d = -f 2)
PKGVERSION=$(cat PKGBUILD | grep pkgver= | cut -d = -f 2)
PKKARCH=$(cat PKGBUILD | grep arch= | cut -d = -f 2 | cut -c 3- | rev | cut -c 3- | rev)
NEXUSPKGNAME="$PKGNAME-$PKGVERSION-$PKKARCH.pkg.tar.zst"

curl -sSL -k -X GET -G "$REPO_API_URL/assets?repository=oblivion-os" > output
cat output | jq '.items | map(.path)' > jq-output
echo "Packages existing:"
cat jq-output
for k in $(jq -r ".[]" jq-output); do 
    if [ "$k" == "$NEXUSPKGNAME" ]
        echo "Package allready exists"
        then exit 0
    fi
done

# Do the actual building
makepkg -f

# Store the built package(s). Ensure permissions match the original PKGBUILD.
if [ -z "$2" ]; then
    sudo chown $(stat -c '%u:%g' "$DOCKER_MAKEPKG_PATH"/PKGBUILD) ./*pkg.tar*
    sudo mv ./*pkg.tar* "$DOCKER_OUT_PATH"
fi
