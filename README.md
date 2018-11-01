<!--
vi:wrap:linebreak:nolist:
-->
# tomato

> A contained [AUR] (_[ArchLinux] User Respository_) packages and local repository builder.


## Overview

[tomato] builds a selection of [AUR packages] with [pikaur] in a [Docker] image, and publishes them through [repose] to a local [pacman repository] named _tomato_.

As such [tomato] is not a [pacman wrapper], it is more an indirect [AUR helper]. It let the host system clean of build's dependencies, like [base-devel].

The selection of [AUR packages] can be installed by a common [pacman usage] on the host.

## Manage AUR packages

### Search for an AUR package to include in the tomato repository

> `tomato search packagedesc`

### Include an AUR package to the tomato repository

> `tomato add packagename`

It can be then installed on the host with the [pacman install command]:

> `pacman -S packagename`

### Remove an AUR package from the tomato repository

> `tomato del packagename`

If the package is installed on the host, it can be removed with the [pacman uninstall command]:

> `pacman -Rs packagename`

### Update the tomato repository with the latest AUR packages versions

> `tomato refresh`

The host can be updated with [pacman update command]:

> `pacman -Syu`

#### Update the tomato repository then the host in one shot

[tomato] provides a shortcut to update the host right after refreshing the tomato repository:

> `tomato -Syu`

Which is a an alias to:

> `pacman -Syuw && tomato refresh && pacman -Syu`

### List tomato repository packages

To list the packages explicitly included to the [tomato] repository:

> `tomato list`

To list all packages and versions available from the [tomato] repository:

> `tomato list all`

## Configuration

[tomato] provides some defaults to tell how to bind the [Docker volumes] with the host, and can be overridden with a [key=value configuration file] using:

  * The `tomato --tomato-config=tomato.conf` flag,
  * Editing the `/etc/tomato.conf` file,
  * Or setting a local user configuration at `~/.config/tomato.conf`.

The default settings are defined as:
```sh
TOMATO_NAME=tomato              # The tomato's docker image
TOMATO_IMGDIR=/usr/share/tomato # The tomato's docker files
TOMATO_PKGDIR=/var/pkg/tomato   # The tomato's repository directory
TOMATO_PACDIR=/etc/pacman.d     # The host's mirrorlist directory
TOMATO_MAKEPKGCONF=             # Let to use a specific makepkg.conf
TOMATO_PKGCACHEDIR=/var/cache/pacman/pkg # The pacman's cache directory
```

## Licenses

> As most of the used tools have a [GPLv2], [GPLv3] or a [compatible license](https://www.gnu.org/licenses/license-list.html#apache2), [tomato] follows the same path.

[Docker] – [Apache 2.0](https://www.docker.com/legal/components-licenses);
[pikaur] – [GPLv3](https://github.com/actionless/pikaur/blob/master/LICENSE);
[repose] – [GPLv2](https://github.com/vodik/repose/blob/master/COPYING);
[tomato] – [GPLv3](https://github.com/aji-prod/tomato/blob/master/LICENSE).



  [AUR helper]: https://wiki.archlinux.org/index.php/AUR_helpers
  [AUR packages]: https://www.archlinux.org/packages/
  [AUR]: https://aur.archlinux.org/
  [ArchLinux]: https://www.archlinux.org/
  [Docker volumes]: https://docs.docker.com/storage/volumes/
  [Docker]: https://docs.docker.com/
  [GPLv2]: https://www.gnu.org/licenses/gpl-2.0.html
  [GPLv3]: https://www.gnu.org/licenses/gpl-3.0.html
  [base-devel]: https://wiki.archlinux.org/index.php/Arch_User_Repository#Prerequisites
  [key=value configuration file]: https://www.freedesktop.org/software/systemd/man/systemd.exec.html#EnvironmentFile=
  [pacman install command]: https://wiki.archlinux.org/index.php/Pacman#Installing_specific_packages
  [pacman repository]: https://wiki.archlinux.org/index.php/Pacman#Repositories_and_mirrors
  [pacman uninstall command]: https://wiki.archlinux.org/index.php/Pacman#Removing_packages
  [pacman update command]: https://wiki.archlinux.org/index.php/Pacman#Upgrading_packages
  [pacman usage]: https://wiki.archlinux.org/index.php/Pacman#Usage
  [pacman wrapper]: https://wiki.archlinux.org/index.php/AUR_helpers#Pacman_wrappers
  [pacman]: https://wiki.archlinux.org/index.php/Pacman
  [pikaur]: https://github.com/actionless/pikaur
  [repose]: https://github.com/vodik/repose
  [tomato]: https://github.com/aji-prod/tomato
