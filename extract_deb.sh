#!/usr/bin/env bash

VERSION="$TRUSTAGENT_VERSION"
OS_ARCH=$(uname -m)
ARCH="$OS_ARCH"
if [ "$ARCH" = 'x86_64' ]; then
  ARCH='amd64'
fi
echo "ARCH=$ARCH"
echo "VERSION=$VERSION"

curl -L "https://media.githubusercontent.com/media/yusiwen/qianxin-clients/refs/heads/master/trustagent/TrustAgent_standard_${ARCH}_${VERSION}_linux.deb" -o /vpn-client.deb && \
dpkg-deb -R /vpn-client.deb /build/
