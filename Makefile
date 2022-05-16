CONF=./test/tomato.conf
REPO=/tmp/tomato
with=
makepkgconf=${CURDIR}/docker/makepkg.conf

SEED=$(shell date +'%s')
TEMP=/tmp/tomato-$(SEED)

AUR_REPO=ssh://aur@aur.archlinux.org/tomato.git
HUB_REPO=https://raw.githubusercontent.com/aji-prod/tomato

help:
	echo -e \
		"Available $(MAKE) targets:\n"\
		"$(MAKE) image                      # build docker test image\n"\
		"$(MAKE) run with=\"args\"            # test tomato with args\n"\
		"$(MAKE) version                    # show and ensure version\n"\
		"$(MAKE) tar                        # create a source archive\n"\
		"$(MAKE) pkg [makepkgconf=\"path\"]   # create a pacman package."


image:	docker/Dockerfile
	./tomato "--tomato-config=$(CONF)" --rebuild-image "$(with)"

$(REPO):
	-mkdir "$(REPO)"

run:	$(REPO)
	./tomato "--tomato-config=$(CONF)" "$(with)"

_version:
	sh version

version: _version
	$(eval VERSION := $(shell sh version 2> /dev/null))

$(TEMP):
	-mkdir "$(TEMP)"

tar:	version $(TEMP)
	ln -s "${CURDIR}" "$(TEMP)/tomato-$(VERSION)"
	bsdtar -c -H -z \
		--exclude ".git/*" \
		--exclude "tomato-*.tar.*" \
		--exclude "pkg" \
		--exclude "src" \
		-f "tomato-$(VERSION).tar.gz" -C "$(TEMP)" "tomato-$(VERSION)"
pkg:	tar
	mkdir pkg || rm -r pkg/* || true
	cp PKGBUILD "tomato-$(VERSION).tar.gz" pkg
	sh geninteg --config "$(makepkgconf)" --inplace pkg/PKGBUILD
	cd pkg && namcap PKGBUILD && makepkg --config "$(makepkgconf)"

aur:	version $(TEMP)
	test -n "${AUR_USERNAME}" -a -n "${AUR_USEREMAIL}"
	git clone -c "user.name=${AUR_USERNAME}" \
		  -c "user.email=${AUR_USEREMAIL}" \
		  $(AUR_REPO) "$(TEMP)/v$(VERSION)"
	curl "$(HUB_REPO)/v$(VERSION)/PKGBUILD" > "$(TEMP)/v$(VERSION)/PKGBUILD"
	sh geninteg --config "$(makepkgconf)" --inplace "$(TEMP)/v$(VERSION)/PKGBUILD"
	cd "$(TEMP)/v$(VERSION)" && \
	makepkg --config "$(makepkgconf)" --printsrcinfo > .SRCINFO && \
	git add -f PKGBUILD .SRCINFO && \
	makepkg --config "$(makepkgconf)" -c

.PHONY: help image run _version version tar aur
.SILENT: help test _version version
