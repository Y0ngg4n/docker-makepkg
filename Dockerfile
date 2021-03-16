FROM archlinux

RUN pacman -Syu --noconfirm

# Generally, refreshing without sync'ing is discouraged, but we've a clean
# environment here.
RUN pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Sy --noconfirm base-devel git && \
    pacman -Syu --noconfirm

# Allow notroot to run stuff as root (to install dependencies):
RUN echo "notroot ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/notroot

# makepkg cannot (and should not) be run as root:
RUN useradd -m notroot

# Continue execution (and CMD) as notroot:
USER notroot
WORKDIR /home/notroot

COPY run.sh /run.sh

RUN chown notroot /run.sh
RUN chmod +x /run.sh

# Auto-fetch GPG keys (for checking signatures):
RUN mkdir .gnupg && \
    touch .gnupg/gpg.conf && \
    echo "keyserver-options auto-key-retrieve" > .gnupg/gpg.conf

# Install yay (for building AUR dependencies):
RUN git clone https://aur.archlinux.org/yay-bin.git && \
    cd yay-bin && \
    makepkg --noconfirm --syncdeps --rmdeps --install --clean

# Build the package
WORKDIR /pkg
CMD /bin/sh /run.sh
