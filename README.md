<!--
vi:wrap:linebreak:nolist:
-->
# tomato

> A contained [AUR] (_[ArchLinux] User Respository_) packages and local repository builder.


## Overview

[tomato] builds a selection of [AUR packages] with [pikaur] in a [Docker] image, and publishes them through [repose] to a local [pacman repository] named _tomato_.

As such [tomato] is not a [pacman wrapper], it is more an indirect [AUR helper]. It let the host system clean of build's dependencies, like [base-devel].

The selection of [AUR packages] can be installed by a common [pacman usage] on the host.

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
  [Docker]: https://docs.docker.com/
  [base-devel]: https://wiki.archlinux.org/index.php/Arch_User_Repository#Prerequisites
  [pacman repository]: https://wiki.archlinux.org/index.php/Pacman#Repositories_and_mirrors
  [pacman wrapper]: https://wiki.archlinux.org/index.php/AUR_helpers#Pacman_wrappers
  [pacman]: https://wiki.archlinux.org/index.php/Pacman
  [pikaur]: https://github.com/actionless/pikaur
  [repose]: https://github.com/vodik/repose
  [tomato]: https://github.com/aji-prod/tomato
  [pacman usage]: https://wiki.archlinux.org/index.php/Pacman#Usage
  [GPLv2]: https://www.gnu.org/licenses/gpl-2.0.html
  [GPLv3]: https://www.gnu.org/licenses/gpl-3.0.html
