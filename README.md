<!--
SPDX-FileCopyrightText: © 2020 Open Networking Foundation <support@opennetworking.org>
SPDX-License-Identifier: Apache-2.0
--!>
# iPXE Build

This repo will builds an [iPXE](https://ipxe.org/) payload that can be used for
network booting of systems.


Docker is used to build iPXE, wrapping [all build
dependencies](https://ipxe.org/download#source_code) in the Dockerfile, An
[embedded script](https://ipxe.org/embed) (`chain.ipxe`) is added which will
chainload another iPXE script from a remote HTTP server and continue the boot
process.

The chainloaded iPXE script is configured in the pxeboot role repo, which
describes the menu, downloads boot images, etc.

## Requirements

- git
- make
- Docker

## Usage

Run `make image`, artifacts will be created in `out`. By default it will build:

- `undionly.kxpe` - Can be served by a DHCP server and chainloads with the
  NIC's built in PXE and network driver implementation
- `ipxe.usb` - write to a USB stick with `dd if=bin/ipxe.usb of=/dev/<rawdevice>`

See also [build targets](https://ipxe.org/appnote/buildtargets).

## Mutual TLS

Mutual TLS can be used secure the connection between the iPXE payload and
and images.

Using mTLS requires [cryptography support](https://ipxe.org/crypto) to be added
to the generated binaries. A patch is included that enables [HTTPS
Support](https://ipxe.org/buildcfg/download_proto_https).

To use this support, the CA key, and public/private client keys must copied and
built into the iPXE artifacts. As the private client keys are embedded, care
must be taken with the resulting artifacts.

Steps:

1. Modify the chain.ipxe file to use the mTLS HTTPS URL

2. Put the CA public key (ca.pem), Client public key (client.pem) and
   private key (client.key) in the same directory

2. Build the artifacts incorporating all these files using Makefile options:

    make COPY_FILES="chain.ipxe ca.pem client.pem client.key" OPTIONS="EMBED=chain.ipxe CERT=ca.pem,client.pem TRUST=onfca.pem
PRIVKEY=client.key"

