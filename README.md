# iPXE Build

This repo builds an [iPXE](https://ipxe.org/) payload that can be used for
USB or network booting of systems.

Docker is used to build iPXE, wrapping [all build
dependencies](https://ipxe.org/download#source_code) in the Dockerfile, An
[embedded script](https://ipxe.org/embed) (`chain.ipxe`) is added which will
chainload another iPXE script from a remote HTTP(S) server and continue the
boot process.

The chainloaded iPXE script which has the menu, OS files, and Debian preseed
config is in the
[pxeboot](https://gerrit.opencord.org/plugins/gitiles/ansible/role/pxeboot)
ansible role.

## Requirements

- git
- make
- Docker

## Usage

Run `make image`, artifacts will be created in `out`. By default it will build:

- `undionly.kxpe` - Can be served by a DHCP server and chainloads with the
  NIC's built in PXE UNDI network driver implementation

- `ipxe.usb` - write to a USB stick with `dd if=bin/ipxe.usb
  of=/dev/<rawdevice>`.  There are also 32 and 64 bit EFI versions of this
  payload.

- `ipxe.pdisk` - padded to floppy size, useful for some LOM implementations

- `ipxe.iso` - ISO image for writing to optical discs, and some other tools.


See also [build targets](https://ipxe.org/appnote/buildtargets).

## Mutual TLS

Mutual TLS can be used secure the connection between the iPXE payload and
and images.

Using mTLS requires [cryptography support](https://ipxe.org/crypto) to be added
to the generated binaries. A patch is included that enables [HTTPS
Support](https://ipxe.org/buildcfg/download_proto_https).

To use this support, the CA key, and public/private client certificates must
copied and built into the iPXE artifacts. As the private client certs are
embedded, care must be taken with the resulting artifacts as they contain those
client certs.

Steps:

1. Modify the chain.ipxe file to use the mTLS HTTPS URL

2. Put the CA public key (ca.pem), Client public key (client.pem) and
   private key (client.key) in the same directory

2. Build the artifacts incorporating all these files using Makefile options:

    make COPY_FILES="chain.ipxe onfca.pem client.pem client.key" \
      OPTIONS="EMBED=chain.ipxe CERT=onfca.pem,client.pem TRUST=onfca.pem PRIVKEY=client.key" \
      image

