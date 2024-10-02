<!--
vi:wrap:linebreak:nolist:spell:spelllang=en:
-->

# tomato

> A contained [AUR] (_[ArchLinux] User Respository_) packages and local repository builder.


## Overview

[tomato] builds a selection of [AUR packages] with [pikaur] in a [Docker] image, and publishes them through [pacman] tooling to a local [pacman repository] named _tomato_.

As such [tomato] is not a [pacman wrapper], it is more an indirect [AUR helper]. It let the host system clean of build's dependencies, like [base-devel].

The selection of [AUR packages] can be installed with a common [pacman usage] on the host.


```sh
usage: tomato [<options>] <operation> [...]

operations:
  tomato add      <package(s)>  # add a package to the maintained list;
  tomato del      <package(s)>  # remove a package from the maintained list;
  tomato refresh [<package(s)>] # update tomato repository;
  tomato sweep                  # rebuild tomato repository,
                                # will remove non building or non existing 
                                # packages;
  tomato list    [all|status|split]
                                # list maintained packages;
  tomato search   <package(s)>  # search an AUR package;
  tomato version [number]       # show version 0.9.0;
  tomato (usage|help)           # this help message.

  tomato -Syu                   # or any other short variant (-Syuu, -Suy,
                                # ...), will update the tomato repository,
                                # and the host system.

options:
  tomato --rebuild-image        # build or rebuild the tomato Docker image;
  tomato --default-mirrors      # use the default mirrors of the base Docker
                                # image, when building or rebuilding the
                                # tomato Docker image;
  tomato --remove-image         # remove the tomato Docker image;
  tomato --tomato-config <path> # path to custom tomato config;
  tomato --edit                 # prompt to edit PKGBUILDs or build files;
  tomato --remote-update        # update tomato from the remote pre-built
                                # package.

  Tomato v0.9.0
```

## Installation

### Install [tomato]

#### As an [prebuilt package]

[tomato] provides a [prebuilt package] with no other dependencies than [pacman] and can be installed with a [pacman install command]:

```sh
curl -L https://github.com/aji-prod/tomato/releases/download/v0.9.0/tomato-0.9.0-1-any.pkg.tar.zst > tomato-0.9.0-1-any.pkg.tar.zst
pacman -U ./tomato-0.9.0-1-any.pkg.tar.zst
```

#### As an [AUR package]

The [AUR package] can be installed with [makepkg] or any other [AUR helper].

#### From sources

```sh
git clone --branch v0.9.0 --depth 1 https://github.com/aji-prod/tomato/ tomato  
cd tomato  
make pkg  
pacman -U pkg/tomato-0.9.0-1-any.pkg.tar.zst
```

### Enable [tomato]  [pacman repository]

To install the [AUR packages] maintained by [tomato] the local [pacman repository] must be active for the host.
Add the following section to [pacman.conf]:

> \[tomato]  
> SigLevel = Optional TrustAll  
> Server = file:///var/pkg/tomato


### Enable the [docker] service

As [tomato] runs inside a [docker image] it is recommended to activate the [docker] service first.

```sh
systemctl enable docker  
systemctl start docker
```


### Enable [tomato] auto-update

As an [AUR package], [tomato] can update itself[^](Update the tomato repository with the latest AUR packages versions), by first registering[^](Include an AUR package to the tomato repository) it:

> `tomato add tomato`

## Manage [AUR packages]

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

Which is an alias to:

> `pacman -Syu && tomato refresh && pacman -Syu`

Note that any variation of the flag `-Syu` flag will refresh the [tomato] repository and be passed to the
[pacman] command, such as:

> `tomato -Suuy`

will be an alias to:

> `pacman -Suuy && tomato refresh && pacman -Suuy`

### Rebuild all the packages and remove leftover dependencies

Some package dependencies may resides over time within the [tomato] repository, like after a `tomato del` command.

To removed unused dependencies from the [tomato] repository:

> `tomato sweep`

Note that every packages will be rebuilt, packages that can no longer be built will be marked as waiting for an update, and will no more be available from the [tomato] repository until fixed.

### List tomato repository packages

To list the packages explicitly included to the [tomato] repository:

> `tomato list`

To list all packages and versions available from the [tomato] repository:

> `tomato list all`

To list all packages available from the [tomato] repository with theirs [AUR status]:

> `tomato list status`

To list the [split package]s, or to list the packages explicitly included but not found from the [tomato] repository:

> `tomato list split`

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
TOMATO_PACDIR=/etc/pacman.d/mirrorlist    # The host's mirrorlist
TOMATO_MAKEPKGCONF=                       # Let to use a specific makepkg.conf
TOMATO_PKGCACHEDIR=/var/cache/pacman/pkg  # The pacman's cache directory
TOMATO_EDITOR=extra/vim:/usr/bin/vim      # The tomato's editor
TOMATO_ULIMIT=nofile=1024:524288          # The docker's ulimit option
```

### makepkg.conf

[tomato] provides a default [makepkg.conf] at `/usr/share/tomato/makepkg.conf`.
All the packages built by [tomato] will be attributed to the [Françoise 'Ed' Appledelhi &lt;ed@tomato.earth&gt;] packager. The others options have the [makepkg.conf defaults] provided by [ArchLinux].

To use another [makepkg.conf] override the `TOMATO_MAKEPKGCONF=` key.

### $EDITOR and TOMATO_EDITOR=

[tomato] uses the environment variable [$EDITOR] as editor if no `TOMATO_EDITOR=` configuration was defined, or [vim] if neither is set.

To use another [$EDITOR] override the `TOMATO_EDITOR=` key.

#### TOMATO_ULIMIT

To prevent [fakeroot] to hang inside [Docker] a default [ulimit], through the `--ulimit` option, is passed to the [docker build] and [docker run] commands.

To remove the `--ulimit` option, or to use another value, override the `TOMATO_ULIMIT=` key.

## GPG Signatures

For now, neither the [GPG signatures] from the [AUR packages] nor to build a package are supported and ignored.

## Systemd

[tomato] management can be helped with [systemd] and two [systemd timers]:

  - `tomato-update-image.timer`,
  - `tomato-update-repository.timer`.

## tomato-update-image.timer

Calls `tomato --rebuild-image`[^](Docker Image) monthly to synchronize the [tomato] local [Docker image] against the official [ArchLinux Docker image].

## tomato-update-repository.timer

Calls `tomato refresh`[^](Update the tomato repository with the latest AUR packages versions) weekly to update the local _[tomato]_ [pacman repository].

## tomato-update.conf

To pass arguments to the [systemd timers] you can edit the `TOMATO_ARGS=` key, located at `/etc/conf.d/tomato-update.conf`.  
`/etc/conf.d/tomato-update.conf` needs first to be copied from `/usr/share/tomato/tomato-update.conf`.


## Docker Image

[tomato] uses a local [Docker image] based against the official [ArchLinux Docker image].

Before using the first time [tomato], it is required to build the local [Docker image] with the `--rebuild-image` option, as `tomato --rebuild-image [command]`.

The [tomato]'s core resides in the script launched inside the [Docker image], any [tomato] update will only be available after passing the `--rebuild-image` option. It is also recommended to pass this option each new month as the official [ArchLinux Docker image] is updated monthly.

### Initializing the Docker Image

> `tomato --rebuild-image`

The `--rebuild-image` option can be combined with any other flags or commands.

#### Using the Default Mirrors of the Docker Image

> `tomato --rebuild-image --default-mirrors`

The `--default-mirrors` option avoids using the host's best first [pacman mirror] to use the default [ArchLinux Docker image mirrors].

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

[Docker] – [Apache 2.0](https://github.com/moby/moby/blob/master/LICENSE);
[pikaur] – [GPLv3](https://github.com/actionless/pikaur/blob/master/LICENSE);
[tomato] – [GPLv3](https://github.com/aji-prod/tomato/blob/master/LICENSE).



[$EDITOR]: https://wiki.archlinux.org/index.php/Environment_variables#Default_programs
[AUR helper]: https://wiki.archlinux.org/index.php/AUR_helpers
[AUR package]: https://aur.archlinux.org/packages/tomato/
[AUR packages]: https://www.archlinux.org/packages/
[AUR status]: https://aur.archlinux.org/packages/?K=status&SB=m&SO+=+d
[AUR]: https://aur.archlinux.org/
[ArchLinux Docker image mirrors]: https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/rootfs/etc/pacman.d/mirrorlist
[ArchLinux Docker image]: https://wiki.archlinux.org/index.php/Docker#Arch_Linux
[ArchLinux]: https://www.archlinux.org/
[Cowboy Bebop]: https://en.wikipedia.org/wiki/Cowboy_Bebop
[Docker image]: https://docs.docker.com/engine/docker-overview/#docker-objects
[Docker volumes]: https://docs.docker.com/storage/volumes/
[Docker]: https://docs.docker.com/
[Edward Wong Hau Pepelu Tivrusky IV]: http://cowboybebop.wikia.com/wiki/Edward
[Françoise 'Ed' Appledelhi &lt;ed@tomato.earth&gt;]: http://cowboybebop.wikia.com/wiki/Edward
[GPG signatures]: https://wiki.archlinux.org/index.php/Makepkg#Signature_checking
[GPLv2]: https://www.gnu.org/licenses/gpl-2.0.html
[GPLv3]: https://www.gnu.org/licenses/gpl-3.0.html
[base-devel]: https://wiki.archlinux.org/index.php/Arch_User_Repository#Prerequisites
[docker build]: https://docs.docker.com/engine/reference/commandline/build/
[docker run]: https://docs.docker.com/engine/reference/commandline/run/
[fakeroot]: https://man.archlinux.org/man/fakeroot.1.en
[key=value configuration file]: https://www.freedesktop.org/software/systemd/man/systemd.exec.html#EnvironmentFile=
[makepkg.conf defaults]: https://git.archlinux.org/svntogit/packages.git/tree/trunk/makepkg.conf?h=packages/pacman
[makepkg.conf]: https://www.archlinux.org/pacman/makepkg.conf.5.html
[makepkg]: https://wiki.archlinux.org/index.php/Makepkg#Usage
[mirrorlist]: https://wiki.archlinux.org/index.php/Pacman#Repositories_and_mirrors
[pacman install command]: https://wiki.archlinux.org/index.php/Pacman#Installing_specific_packages
[pacman mirror]: https://wiki.archlinux.org/index.php/Pacman#Repositories_and_mirrors
[pacman repository]: https://wiki.archlinux.org/index.php/Pacman#Repositories_and_mirrors
[pacman uninstall command]: https://wiki.archlinux.org/index.php/Pacman#Removing_packages
[pacman update command]: https://wiki.archlinux.org/index.php/Pacman#Upgrading_packages
[pacman usage]: https://wiki.archlinux.org/index.php/Pacman#Usage
[pacman wrapper]: https://wiki.archlinux.org/index.php/AUR_helpers#Pacman_wrappers
[pacman's cache]: https://wiki.archlinux.org/index.php/Pacman#Cleaning_the_package_cache
[pacman.conf]: https://wiki.archlinux.org/index.php/Pacman#Configuration
[pacman]: https://wiki.archlinux.org/index.php/Pacman
[pikaur]: https://github.com/actionless/pikaur
[prebuilt package]: https://github.com/aji-prod/tomato/releases/download/v0.9.0/tomato-0.9.0-1-any.pkg.tar.zst
[split package]: https://jlk.fjfi.cvut.cz/arch/manpages/man/PKGBUILD.5#PACKAGE_SPLITTING
[systemd timers]: https://wiki.archlinux.org/index.php/Systemd#Timers
[systemd]: https://wiki.archlinux.org/index.php/Systemd
[tomato name]: http://cowboybebop.wikia.com/wiki/Tomato
[tomato]: https://github.com/aji-prod/tomato
[ulimit]: https://man.archlinux.org/man/ulimit.1p
[vim]: https://www.vim.org/
