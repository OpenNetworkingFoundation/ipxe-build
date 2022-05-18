# iPXE Build automation

# SPDX-FileCopyrightText: © 2020 Open Networking Foundation <support@opennetworking.org>
# SPDX-License-Identifier: Apache-2.0

SHELL = bash -eu -o pipefail

# iPXE configuration
IPXE_VERSION  ?= v1.21.1
TARGETS_BIOS  ?= bin/undionly.kpxe bin/ipxe.usb bin/ipxe.iso bin/ipxe.pdsk
TARGETS_EFI32 ?= bin-i386-efi/snponly.efi bin-i386-efi/ipxe.usb
TARGETS_EFI64 ?= bin-x86_64-efi/snponly.efi bin-x86_64-efi/ipxe.usb
OPTIONS       ?= EMBED=chain.ipxe
COPY_FILES    ?= chain.ipxe

# Build configuration
DOCKER_ARGS   ?=
TMP_DIR       ?= /tmp
OUTDIR        ?= $(shell pwd)/out
BUILDER       := ipxebuilder-$(shell date +"%Y%m%d%H%M%S")# timestamp for each run

# print help by default
.DEFAULT_GOAL := help

# phony (doesn't make files) targets
.PHONY: base image clean clean-all license help

ipxe: ## download and patch iPXE
	git clone https://github.com/ipxe/ipxe.git \
  && cd ipxe \
  && git checkout $(IPXE_VERSION) \
  && git apply ../patches/*

out:
	mkdir -p out

base: | ipxe  ## create base iPXE build container using Docker
	docker build $(DOCKER_ARGS) . -t ipxe-builder:$(IPXE_VERSION)

image: | out base  ## create iPXE binaries using Docker
	mkdir -p $(TMP_DIR)/ipxeout/bios
	mkdir -p $(TMP_DIR)/ipxeout/efi32
	mkdir -p $(TMP_DIR)/ipxeout/efi64
	docker run $(DOCKER_ARGS) -v $(TMP_DIR)/ipxeout:/tmp/out --name $(BUILDER) -d ipxe-builder:$(IPXE_VERSION)
	for file in $(COPY_FILES); do \
    docker cp $$file $(BUILDER):/ipxe/src/ ;\
  done
	docker exec -w /ipxe/src $(BUILDER) \
    bash -c "make -j4 $(TARGETS_BIOS)  $(OPTIONS); cp $(TARGETS_BIOS)  /tmp/out/bios  ; \
	           make -j4 $(TARGETS_EFI32) $(OPTIONS); cp $(TARGETS_EFI32) /tmp/out/efi32 ; \
	           make -j4 $(TARGETS_EFI64) $(OPTIONS); cp $(TARGETS_EFI64) /tmp/out/efi64"
	cp -r  $(TMP_DIR)/ipxeout/* $(OUTDIR)
	rm -rf $(TMP_DIR)/ipxeout
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
