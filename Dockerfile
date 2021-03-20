FROM archlinux

RUN pacman -Syu --noconfirm

COPY run.sh /run.sh

# makepkg cannot (and should not) be run as root:
RUN useradd -m notroot

# Fix permissions
RUN chown notroot /run.sh
RUN chmod +x /run.sh

# Generally, refreshing without sync'ing is discouraged, but we've a clean
# environment here.
RUN pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Sy --noconfirm base-devel git && \
    pacman -Sy --noconfirm wget curl jq && \
    pacman -Syu --noconfirm

# Allow notroot to run stuff as root (to install dependencies):
RUN echo "notroot ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/notroot


# Continue execution (and CMD) as notroot:
USER notroot
WORKDIR /home/notroot

# Auto-fetch GPG keys (for checking signatures):
RUN mkdir .gnupg && \
    touch .gnupg/gpg.conf && \
    echo "keyserver-options auto-key-retrieve" > .gnupg/gpg.conf

# Install yay (for building AUR dependencies):
RUN git clone https://aur.archlinux.org/yay-bin.git && \
    cd yay-bin && \
    makepkg --noconfirm --syncdeps --rmdeps --install --clean

# Set to root User again for building pipeline
USER 0

# create dir (optional)
RUN mkdir -p /drone/src

# Build the package
WORKDIR /drone/src

# Define command
CMD /bin/su -s /bin/sh -c '/run.sh /drone/src/"$DRONE_STEP_NAME" "$OUTPUT_DIR"' notroot
