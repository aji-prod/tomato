# Maintainer: Johannes Löthberg <johannes@kyriasis.com>
# Contributor: Simon Gomizelj <simongmzlj@gmail.com>

pkgname=repose
pkgver=7.1
pkgrel=10

pkgdesc="Arch Linux repo building tool"
url="https://github.com/vodik/repose"
arch=('x86_64')
license=('GPL')

depends=('pacman' 'libarchive' 'gnupg')
makedepends=('ragel')
checkdepends=('python-pytest' 'python-cffi' 'python-pytest-xdist')

source=("repose-$pkgver.tar.gz::https://github.com/vodik/repose/archive/$pkgver.tar.gz")

sha256sums=('c23e93aca416e08e80b4d17a98fd593e6345d7da8806bdd3c5484977ac2c800d')

build() {
  make -C repose-$pkgver
}

check() {
  cd repose-$pkgver
  pytest
}

package() {
  make -C repose-$pkgver DESTDIR="$pkgdir" install
}

# vim: ft=PKGBUILD et
