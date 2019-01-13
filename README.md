<!--
vi:wrap:linebreak:nolist:spell:spelllang=en:
-->
# tomato

> A contained [AUR] (_[ArchLinux] User Respository_) packages and local repository builder.


## Overview

[tomato] builds a selection of [AUR packages] with [pikaur] in a [Docker] image, and publishes them through [repose] to a local [pacman repository] named _tomato_.

As such [tomato] is not a [pacman wrapper], it is more an indirect [AUR helper]. It let the host system clean of build's dependencies, like [base-devel].

The selection of [AUR packages] can be installed by a common [pacman usage] on the host.

## Usage

```sh
usage: tomato [<options>] <operation> [...]

operations:
  tomato add      <package(s)>  # add a package to the maintained list;
  tomato del      <package(s)>  # remove a package from the maintained list;
  tomato refresh [<package(s)>] # update tomato repository;
  tomato list    [all|status]   # list maintained packages;
  tomato search   <package(s)>  # search an AUR package;
  tomato version [number]       # show version 0.2.0;
  tomato (usage|help)           # this help message.

options:
  tomato --rebuild-image        # build or rebuild the tomato Docker image;
  tomato --remove-image         # remove the tomato Docker image;
  tomato --tomato-config <path> # path to custom tomato config.

  Tomato v0.2.0
```

### Manage AUR packages

#### Search for an AUR package to include in the tomato repository

> `tomato search packagedesc`

#### Include an AUR package to the tomato repository

> `tomato add packagename`

It can be then installed on the host with the [pacman install command]:

> `pacman -S packagename`

#### Remove an AUR package from the tomato repository

> `tomato del packagename`

If the package is installed on the host, it can be removed with the [pacman uninstall command]:

> `pacman -Rs packagename`

#### Update the tomato repository with the latest AUR packages versions

> `tomato refresh`

The host can be updated with [pacman update command]:

> `pacman -Syu`

##### Update the tomato repository then the host in one shot

[tomato] provides a shortcut to update the host right after refreshing the tomato repository:

> `tomato -Syu`

Which is a an alias to:

> `pacman -Syuw && tomato refresh && pacman -Syu`

#### List tomato repository packages

To list the packages explicitly included to the [tomato] repository:

> `tomato list`

To list all packages and versions available from the [tomato] repository:

> `tomato list all`

To list all packages available from the [tomato] repository with theirs [AUR status]:

> `tomato list status`

## Configuration

[tomato] provides some defaults to tell how to bind the [Docker volumes] with the host, and can be overridden with a [key=value configuration file] using:

  * The `tomato --tomato-config=tomato.conf` flag,
  * Editing the `/etc/tomato.conf` file,
  * Or setting a local user configuration at `~/.config/tomato.conf`.

The default settings are defined as:
```sh
TOMATO_NAME=tomato                        # The tomato's docker image
TOMATO_IMGDIR=/usr/share/tomato           # The tomato's docker files
TOMATO_PKGDIR=/var/pkg/tomato             # The tomato's repository directory
TOMATO_PACDIR=/etc/pacman.d /mirrorlist   # The host's mirrorlist
TOMATO_MAKEPKGCONF=                       # Let to use a specific makepkg.conf
TOMATO_PKGCACHEDIR=/var/cache/pacman/pkg  # The pacman's cache directory
```

## GPG Signatures

For now, neither the [GPG signatures] from the [AUR packages] nor to build a package are supported and ignored.


## Docker Image

[tomato] uses a local [Docker image] based against the official [ArchLinux Docker image].

Before using the first time [tomato], it is required to build the local [Docker image] with the `--rebuild-image` option, as `tomato --rebuild-image [command]`.

The [tomato]'s core resides in the script launched inside the [Docker image], any [tomato] update will only be available after passing the `--rebuild-image` option. It is also recommended to pass this option each new month as the official [ArchLinux Docker image] is updated monthly.

### Initializing the Docker Image

> `tomato --rebuild-image`

The `--rebuild-image` option can be combined with any other flags or commands.

### Pruning the Docker Image

> `tomato --remove-image`

Will ask [Docker] do delete the [Docker image], can be combined with any other flags and takes precedence over the `--rebuild-image` option.

### Docker Volumes

[tomato] binds a few [Docker volumes] to share files between the host and the image.

#### Volume `/var/pkg/tomato`

The repository and the packages are stored in this volume, always mounted with _read_ and _write_ permissions.

> host default: `/etc/pkg/tomato`

#### Volume `/var/cache/pacman/pkg`

To minimize the network access, the image shares the same [pacman's cache] with the host.

> host default: `/var/cache/pacman/pkg`

#### Volume `/home/tomato/mirrorlist`

The [mirrorlist] used by the image is read from this volume, always mounted with a _read only_ permission.

> host default: `/etc/pacman.d/mirrorlist`.

#### Volume `/home/tomato/makepkg.conf`

A special volume which needs to points to a host _file_ to be used, always mounted with a _read only_ permission.

> not mounted by default

## Tomato's Name

The [tomato name] is a reference to a main character of the [Cowboy Bebop] series, [Edward Wong Hau Pepelu Tivrusky IV].

> Her best friend during her time [in an orphanage on Earth] was a boy named Tomato who was also passionate about computer science. She named her computer Tomato after him.[^](http://cowboybebop.wikia.com/wiki/Edward#Early_Life)

Or you can try to repeat indefinitely and rapidly _"automate AUR"_.

## Licenses

> As most of the used tools have a [GPLv2], [GPLv3] or a [compatible license](https://www.gnu.org/licenses/license-list.html#apache2), [tomato] follows the same path.

[Docker] – [Apache 2.0](https://www.docker.com/legal/components-licenses);
[pikaur] – [GPLv3](https://github.com/actionless/pikaur/blob/master/LICENSE);
[repose] – [GPLv2](https://github.com/vodik/repose/blob/master/COPYING);
[tomato] – [GPLv3](https://github.com/aji-prod/tomato/blob/master/LICENSE).



  [AUR helper]: https://wiki.archlinux.org/index.php/AUR_helpers
  [AUR packages]: https://www.archlinux.org/packages/
  [AUR status]: https://aur.archlinux.org/packages/?K=status&SB=m&SO+=+d
  [AUR]: https://aur.archlinux.org/
  [ArchLinux Docker image]: https://wiki.archlinux.org/index.php/Docker#Arch_Linux
  [ArchLinux]: https://www.archlinux.org/
  [Cowboy Bebop]: https://en.wikipedia.org/wiki/Cowboy_Bebop
  [Docker image]: https://docs.docker.com/engine/docker-overview/#docker-objects
  [Docker volumes]: https://docs.docker.com/storage/volumes/
  [Docker]: https://docs.docker.com/
  [Edward Wong Hau Pepelu Tivrusky IV]: http://cowboybebop.wikia.com/wiki/Edward
  [GPG signatures]: https://wiki.archlinux.org/index.php/Makepkg#Signature_checking
  [GPLv2]: https://www.gnu.org/licenses/gpl-2.0.html
  [GPLv3]: https://www.gnu.org/licenses/gpl-3.0.html
  [base-devel]: https://wiki.archlinux.org/index.php/Arch_User_Repository#Prerequisites
  [key=value configuration file]: https://www.freedesktop.org/software/systemd/man/systemd.exec.html#EnvironmentFile=
  [mirrorlist]: https://wiki.archlinux.org/index.php/Pacman#Repositories_and_mirrors
  [pacman install command]: https://wiki.archlinux.org/index.php/Pacman#Installing_specific_packages
  [pacman repository]: https://wiki.archlinux.org/index.php/Pacman#Repositories_and_mirrors
  [pacman uninstall command]: https://wiki.archlinux.org/index.php/Pacman#Removing_packages
  [pacman update command]: https://wiki.archlinux.org/index.php/Pacman#Upgrading_packages
  [pacman usage]: https://wiki.archlinux.org/index.php/Pacman#Usage
  [pacman wrapper]: https://wiki.archlinux.org/index.php/AUR_helpers#Pacman_wrappers
  [pacman's cache]: https://wiki.archlinux.org/index.php/Pacman#Cleaning_the_package_cache
  [pacman]: https://wiki.archlinux.org/index.php/Pacman
  [pikaur]: https://github.com/actionless/pikaur
  [repose]: https://github.com/vodik/repose
  [tomato name]: http://cowboybebop.wikia.com/wiki/Tomato
  [tomato]: https://github.com/aji-prod/tomato
