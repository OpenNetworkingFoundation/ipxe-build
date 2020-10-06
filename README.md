<!--
SPDX-FileCopyrightText: © 2020 Open Networking Foundation <support@opennetworking.org>
SPDX-License-Identifier: Apache-2.0
--!>
# iPXE Build

This repo will builds an [iPXE](https://ipxe.org/) payload that can be used for
network booting of systems.

It uses Docker to build iPXE, wrapping [all build
dependencies](https://ipxe.org/download#source_code) in the Dockerfile, An
[embedded script](https://ipxe.org/embed) (`chain.ipxe`) is added which will
chainload a complicated iPXE script with menus and other configurations.

iPXE is patched to give it [HTTPS
Support](https://ipxe.org/buildcfg/download_proto_https).

# Requirements

- git
- make
- Docker

# Usage

Run `make image`, artifacts will be created in `out`. By default it will build:

- `undionly.kxpe` - Can be served by a DHCP server and chainloads with the
  NIC's built in PXE implementation
- `ipxe.usb` - write to a USB stick with `dd if=bin/ipxe.usb of=/dev/<rawdevice>`

See also [build targets](https://ipxe.org/appnote/buildtargets).

## TODO

- Add a [TLS Server and Client cert](https://ipxe.org/crypto) into the image,
  to allow trust to be established between systems.

