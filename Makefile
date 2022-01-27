# iPXE Build automation

# SPDX-FileCopyrightText: © 2020 Open Networking Foundation <support@opennetworking.org>
# SPDX-License-Identifier: Apache-2.0

SHELL = bash -eu -o pipefail

# iPXE configuration
IPXE_VERSION  ?= v1.21.1
TARGETS       ?= bin/undionly.kpxe bin/ipxe.usb bin/ipxe.iso bin/ipxe.pdsk
TARGETS_EFI32 ?= bin-i386-efi/ipxe.usb
TARGETS_EFI64 ?= bin-x86_64-efi/ipxe.usb
OPTIONS       ?= EMBED=chain.ipxe
COPY_FILES    ?= chain.ipxe

# Build configuration
OUTDIR        ?= $(shell pwd)/out
BUILDER       := ipxebuilder-$(shell date +"%Y%m%d%H%M%S")# timestamp for each run

# print help by default
.DEFAULT_GOAL := help

# phony (doesn't make files) targets
.PHONY: base image clean clean-all license help

ipxe: ## download and patch iPXE
	git clone git://git.ipxe.org/ipxe.git \
  && cd ipxe \
  && git checkout $(IPXE_VERSION) \
  && git apply ../patches/*

out:
	mkdir -p out

base: | ipxe  ## create base iPXE build container using Docker
	docker build . -t ipxe-builder:$(IPXE_VERSION)

image: | out base  ## create iPXE binaries using Docker
	docker run -v $(OUTDIR):/tmp/out --name $(BUILDER) -d ipxe-builder:$(IPXE_VERSION)
	for file in $(COPY_FILES); do \
    docker cp $$file $(BUILDER):/ipxe/src/ ;\
  done
	docker exec -w /ipxe/src $(BUILDER) \
    bash -c "make -j4 $(TARGETS) $(OPTIONS); cp $(TARGETS) /tmp/out; \
		         make -j4 $(TARGETS_EFI32) $(OPTIONS); cp $(TARGETS_EFI32) /tmp/out/ipxe_efi32.usb; \
		         make -j4 $(TARGETS_EFI64) $(OPTIONS); cp $(TARGETS_EFI64) /tmp/out/ipxe_efi64.usb"
	docker rm --force $(BUILDER)

test: image  ## test (currently only runs an image build)

clean:  ## remove output artifacts
	rm -rf out/*

clean-all: clean  ## full clean (delete iPXE git repo)
	rm -rf ipxe

license: ## check licenses
	reuse --version ;\
  reuse --root . lint

help: ## Print help for each target
	@echo infra-playbooks make targets
	@echo
	@grep '^[[:alnum:]_-]*:.* ## ' $(MAKEFILE_LIST) \
    | sort | awk 'BEGIN {FS=":.* ## "}; {printf "%-25s %s\n", $$1, $$2};'
