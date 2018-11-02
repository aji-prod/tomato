FROM base/archlinux

# Prerequists
VOLUME /etc/pacman.d
VOLUME /var/cache/pacman
# Note: One more volume available, declared later, as:
#       VOLUME /var/pkg/tomato

RUN pacman -Syuu --noconfirm --noprogressbar --needed            && \
    pacman -S    --noconfirm --noprogressbar --needed base-devel    \
                                                      python        \
                                                      repose
# Note: python package is a prerequist for pikaur, we are installing it
#       as soon as possible.
#
# Note: repose is used by the tomato.sh script, to update cleanly
#       the packages files within the repository directory.


# Declare context for the build user
#
# Note: Why tomato?
#       Tomato is the computer, and a friend from earth,
#       of Ed from Cowboy Bebop.
RUN useradd -m tomato            && \
    mkdir -p /var/pkg/tomato     && \
    chown tomato /var/pkg/tomato
VOLUME /var/pkg/tomato
VOLUME /home/tomato/makepkg.conf
COPY pacman.sudoer /etc/sudoers.d/pacman

# Everything from now is done from the tomato home dir with the tomato user.
USER tomato
WORKDIR /home/tomato

# Setup pikaur
# Note: pikaur has no build dependencies, we can pass the --nodeps here and
#       let pacman to install its dependencies;
#       BUT IT HAS a (non declared) pakckage() deps, wich is python, see above.
ADD --chown=tomato \
    https://aur.archlinux.org/cgit/aur.git/snapshot/pikaur.tar.gz .
RUN tar -xf pikaur.tar.gz                                              && \
    cd pikaur                                                          && \
    sudo pacman -Syuu --noconfirm --noprogressbar --needed             && \
    makepkg --nocolor --noprogressbar --nodeps                         && \
    sudo pacman -U --noconfirm --noprogressbar pikaur-*-any.pkg.tar.xz && \
    cd && rm -rf pikaur*

COPY --chown=tomato pikaur.conf .config/pikaur.conf
COPY --chown=tomato tomato.sh .
RUN chmod u+x tomato.sh
COPY --chown=tomato makepkg.conf .config/pacman/makepkg.conf

ENTRYPOINT ["/home/tomato/tomato.sh"]
CMD ["-V"]
