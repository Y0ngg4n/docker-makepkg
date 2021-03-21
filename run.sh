#!/bin/sh

set -e

if [ -z "$1" ]
  then
    DOCKER_MAKEPKG_PATH="/pkg"
else
    DOCKER_MAKEPKG_PATH="$1"
fi

echo "$DOCKER_MAKEPKG_PATH"
echo "$DOCKER_OUT_PATH"
echo "$REPO_API_URL"

# Make a copy so we never alter the original
cp -rv "$DOCKER_MAKEPKG_PATH" /tmp/pkg
cd /tmp/pkg

# Check if exists in Nexus
PKGNAME=$(cat PKGBUILD | grep pkgname= | cut -d = -f 2)
PKGVERSION=$(cat PKGBUILD | grep pkgver= | cut -d = -f 2)
#PKGARCH=$(cat PKGBUILD | grep arch= | cut -d = -f 2 | cut -c 3- | rev | cut -c 3- | rev)
PKGARCH=x86_64
NEXUSPKGNAME="$PKGNAME-$PKGVERSION-$PKGARCH.pkg.tar.zst"

curl -sSL -k -X GET -G "$REPO_API_URL/assets?repository=oblivion-os" > output
cat output | jq '.items | map(.path)' > jq-output

echo "Package: $NEXUSPKGNAME"
echo "Packages existing:"
cat jq-output

for k in $(jq -r ".[]" jq-output); do 
    if [ "$k" == "$NEXUSPKGNAME" ]
      then
         echo "Package allready exists"
         exit 0
    fi
done

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
