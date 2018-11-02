CONF=./test/tomato.conf
REPO=/tmp/tomato
with=

help:
	echo -e \
		"Available $(MAKE) targets:\n"\
		"$(MAKE) image             # build docker test image\n"\
		"$(MAKE) run with=\"args\" # test tomato with args\n"


image:	docker/Dockerfile
	./tomato "--tomato-config=$(CONF)" --rebuild-image

$(REPO):
	-mkdir "$(REPO)"

run:	$(REPO)
	./tomato "--tomato-config=$(CONF)" "$(with)"


.PHONY: help image run
.SILENT: help test
