# Note: Use the base base-devel docker image as we want the base-devel
#       packages anyway for building the AUR's packages.
FROM archlinux:base-devel

# Volume:
# 	Let to share the same writeable pacman's cache from the host
VOLUME ["/var/cache/pacman/pkg"]
# 	Publish to the host our packages
VOLUME ["/var/pkg/tomato"]

# Note: Activate the [multilib] repository as it can be required to build
#       some AUR packages.
#
# Note: We need to fallback to a manual update from the cache in case of
#       an archlinux-keyring auto update error, to fixe:
#       > error: key "6D42BDD116E0068F" could not be looked up remotely
#       > error: required key missing from keyring
#       > error: failed to commit transaction (unexpected error)
ARG TOMATO_MIRROR=""
RUN echo ARG TOMATO_MIRROR=\"${TOMATO_MIRROR}\"                         && \
    ( ( test -n "${TOMATO_MIRROR}"                                      && \
        echo "${TOMATO_MIRROR}" > /etc/pacman.d/mirrorlist ) || true )  && \
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist"             \
    >> /etc/pacman.conf                                                 && \
    pacman-key   --init && pacman-key --populate                        && \
    ( pacman -Sy --noconfirm --noprogressbar archlinux-keyring || \
      pacman -U  --noconfirm --noprogressbar /var/cache/pacman/pkg/archlinux-keyring-* ) && \
    pacman -Suu  --noconfirm --noprogressbar --needed                   && \
    pacman -S    --noconfirm --noprogressbar --needed python               \
                                                      repose               \
						      base-devel           \
                                                      pacman-contrib    && \
    pacman -Scc --noconfirm --noprogressbar
# Note: python package is a prerequist for pikaur, we are installing it
#       as soon as possible.
#
# Note: repose is used by the tomato.sh script, to update cleanly
#       the packages files within the repository directory.
#
# Note: base-devel is required to build the AUR package, be sure that one
#       is installed, the base-devel image may skip it.
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
COPY pikaur.sudoer /etc/sudoers.d/pikaur

# Everything from now is done from the tomato home dir with the tomato user.
USER tomato
WORKDIR /home/tomato

# Setup pikaur
# Note: `python-commonmark` is required by pikaur and registered by its
#       dependencies but some pikaur's scripts are trigged too soon.
ADD --chown=tomato \
    https://aur.archlinux.org/cgit/aur.git/snapshot/pikaur.tar.gz .
RUN tar -xf pikaur.tar.gz                                              && \
    cd pikaur                                                          && \
    sudo pacman -Sy --noconfirm --noprogressbar archlinux-keyring      && \
    sudo pacman -Syuu --noconfirm --noprogressbar --needed --asdeps python-commonmark && \
    makepkg --noconfirm --nocolor --noprogressbar --syncdeps --rmdeps  && \
    sudo pacman -U --noconfirm --noprogressbar pikaur-*-any.pkg.tar.*  && \
    sudo pacman -Scc --noconfirm --noprogressbar                       && \
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
RUN test -z "${TOMATO_EDITOR}"          || \
    sudo -n -- /home/tomato/tomato.sh editor "${TOMATO_EDITOR}" && \
    sudo pacman -Scc --noconfirm --noprogressbar

# Volume:
# 	Let to share a same mirrorlist
VOLUME ["/home/tomato/mirrorlist"]
#	Let the host to define a makepkg.conf
VOLUME ["/home/tomato/makepkg.conf"]

ENTRYPOINT [ "/bin/sudo", "/home/tomato/tomato.sh" ]
CMD ["help"]
