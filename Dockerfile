# iPXE build Dockerfile

# SPDX-FileCopyrightText: © 2020 Open Networking Foundation <support@opennetworking.org>
# SPDX-License-Identifier: Apache-2.0

FROM debian:11

# Install Build packages
RUN apt-get -y update \
  && apt-get -y install build-essential genisoimage git isolinux liblzma-dev mtools syslinux \
  && apt-get autoremove \
  && apt-get clean \
  && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* \
  && mkdir /build

# Copy ipxe source and chainloader into container
COPY ipxe /ipxe

# Perform a basic build
WORKDIR /ipxe/src
RUN make -j4 bin/undionly.kpxe

# Sleep for 10m, should be enough to perform build.
CMD ["sleep", "600"]
