CONF=./test/tomato.conf
REPO=/tmp/tomato
with=
makepkgconf=./docker/makepkg.conf

help:
	echo -e \
		"Available $(MAKE) targets:\n"\
		"$(MAKE) image             # build docker test image\n"\
		"$(MAKE) run with=\"args\" # test tomato with args\n"\
		"$(MAKE) version           # show and ensure version\n"\
		"$(MAKE) tar               # create a source archive\n"\
		"$(MAKE) pkg               # create a pacman package."


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
	tar -c -j \
		--exclude ".git*" \
		--exclude "tomato-*.tar.bz2" \
		-f "tomato-$(VERSION).tar.bz2" *

pkg:	tar
	mkdir pkg || rm -r pkg/*
	cp "tomato-$(VERSION).tar.bz2" pkg
	sed "s:#sums=:$(shell makepkg --config "$(makepkgconf)" -g):" PKGBUILD > pkg/PKGBUILD
	cd pkg && namcap PKGBUILD && makepkg

.PHONY: help image run _version version tar
.SILENT: help test _version version
