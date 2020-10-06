# iPXE Build automation

# SPDX-FileCopyrightText: © 2020 Open Networking Foundation <support@opennetworking.org>
# SPDX-License-Identifier: Apache-2.0

SHELL = bash -eu -o pipefail

# iPXE configuration
IPXE_VERSION ?= v1.20.1
TARGETS      ?= bin/undionly.kpxe bin/ipxe.usb
OPTIONS      ?= EMBED=chain.ipxe
COPY_FILES   ?= chain.ipxe

# Build configuration
OUTDIR       ?= $(shell pwd)/out
BUILDER      := ipxebuilder-$(shell date +"%Y%m%d%H%M%S")# timestamp for each run

# phony (doesn't make files) targets
.PHONY: base image clean clean-all license help

ipxe: ## download and patch iPXE
	git clone git://git.ipxe.org/ipxe.git \
  && cd ipxe \
  && git checkout $(IPXE_VERSION) \
  && git apply ../patches/*

out:
	mkdir -p out

base: | ipxe  ## create bas iPXE build container using Docker
	docker build . -t ipxe-builder:$(IPXE_VERSION)

image: | out base ## create iPXE binary artifacts using Docker
	docker run -v $(OUTDIR):/tmp/out --name $(BUILDER) -d ipxe-builder:$(IPXE_VERSION)
	docker cp $(COPY_FILES) $(BUILDER):/ipxe/src/
	docker exec -w /ipxe/src $(BUILDER) \
    bash -c "make -j4 $(TARGETS) $(OPTIONS); cp $(TARGETS) /tmp/out"
	docker rm --force $(BUILDER)

test: image  ## test (currently only runs an image build)

clean: ## remove output artifacts
	rm -rf out/*

clean-all: clean ## full clean (delete iPXE git repo)
	rm -rf ipxe

license: ## check licenses
	reuse --version ;\
  reuse --root . lint

help: ## Print help for each target
	@echo infra-playbooks make targets
	@echo
	@grep '^[[:alnum:]_-]*:.* ##' $(MAKEFILE_LIST) \
    | sort | awk 'BEGIN {FS=":.* ## "}; {printf "%-25s %s\n", $$1, $$2};'
