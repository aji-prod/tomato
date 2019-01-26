CONF=./test/tomato.conf
REPO=/tmp/tomato
with=
makepkgconf=${CURDIR}/docker/makepkg.conf

help:
	echo -e \
		"Available $(MAKE) targets:\n"\
		"$(MAKE) image                      # build docker test image\n"\
		"$(MAKE) run with=\"args\"            # test tomato with args\n"\
		"$(MAKE) version                    # show and ensure version\n"\
		"$(MAKE) tar                        # create a source archive\n"\
		"$(MAKE) pkg [makepkgconf=\"path\"]   # create a pacman package."


image:	docker/Dockerfile
	./tomato "--tomato-config=$(CONF)" --rebuild-image

$(REPO):
	-mkdir "$(REPO)"

run:	$(REPO)
	./tomato "--tomato-config=$(CONF)" "$(with)"

_version:
	sh version

version: _version
	$(eval VERSION := $(shell sh version 2> /dev/null))

tar:	version
	tar -c -z \
		--exclude ".git*" \
		--exclude "tomato-*.tar.gz" \
		-f "tomato-$(VERSION).tar.gz" *

pkg:	tar
	mkdir pkg || rm -r pkg/* || true
	cp "tomato-$(VERSION).tar.gz" pkg
	sed "s:#sums=:$(shell makepkg --config "$(makepkgconf)" -g):" PKGBUILD > pkg/PKGBUILD
	cd pkg && namcap PKGBUILD && makepkg --config "$(makepkgconf)"

.PHONY: help image run _version version tar
.SILENT: help test _version version
