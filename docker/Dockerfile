FROM archlinux/base

# Volume:
# 	Let to share the same writeable pacman's cache from the host
VOLUME ["/var/cache/pacman/pkg"]
# 	Publish to the host our packages
VOLUME ["/var/pkg/tomato"]

# Note: /usr/share/libalpm/hooks/package-cleanup.hook is a bit aggressive
#       and tries to rm -rf /var/cache/pacman/pkg.
#
# Note: Activate the [multilib] repository as it can be required to build
#       some AUR packages.
RUN echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch'    \
    > /etc/pacman.d/mirrorlist                                          && \
    rm /usr/share/libalpm/hooks/package-cleanup.hook                    && \
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist"             \
    >> /etc/pacman.conf                                                 && \
    pacman-key --init && pacman-key --populate                          && \
    pacman -Sy   --noconfirm --noprogressbar --needed archlinux-keyring && \
    pacman -Suu  --noconfirm --noprogressbar --needed                   && \
    pacman -S    --noconfirm --noprogressbar --needed base-devel           \
                                                      python               \
                                                      repose               \
                                                      pacman-contrib
# Note: python package is a prerequist for pikaur, we are installing it
#       as soon as possible.
#
# Note: repose is used by the tomato.sh script, to update cleanly
#       the packages files within the repository directory.
#
# Note: pacman-contrib is only required for paccache, to clean up the
#       the old packages within the tomato repository.

# Declare context for the build user
#
# Note: Why tomato?
#       Tomato is the computer, and a friend from earth,
#       of Ed from Cowboy Bebop.
RUN useradd -m tomato
COPY pacman.sudoer /etc/sudoers.d/pacman
COPY tomato.sudoer /etc/sudoers.d/tomato

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

# Fixup pikaur
# Note: pikaur packaging disables read on its __init__.py, allowing
#       only the root to execute pikaur; even if by design it calls by itself
#       the sudo command; to allow as expected to a non root user to install a
#       package with pikaur, we need to correct the __init__.py permissions.
#       otherwise we will enable the systemd user feature which doesn't work
#       within a docker image.
RUN sudo -n -- /home/tomato/tomato.sh fixup

# Setup EDITOR
# Note: as the editor is a volatile argument, set it up last to avoid
#       rebuilding all the the previous stages in case of change.
#
# Note: core/vi doesn't cope well with pikaur where the PKGBUILDs
#       cannot be edited - let to use vim by default.
ARG TOMATO_EDITOR=extra/vim:/usr/bin/vim
RUN test -n "${TOMATO_EDITOR}" && \
    sudo -n -- /home/tomato/tomato.sh editor "${TOMATO_EDITOR}"

# Volume:
# 	Let to share a same mirrorlist
VOLUME ["/home/tomato/mirrorlist"]
#	Let the host to define a makepkg.conf
VOLUME ["/home/tomato/makepkg.conf"]

ENTRYPOINT [ "/bin/sudo", "/home/tomato/tomato.sh" ]
CMD ["help"]
