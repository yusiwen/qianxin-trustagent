#!/usr/bin/env bash

OS_ARCH=$(uname -m)
ARCH="$OS_ARCH"
if [ "$ARCH" = 'x86_64' ]; then
  ARCH='amd64'
fi
echo "ARCH=$ARCH"

curl -L "https://media.githubusercontent.com/media/yusiwen/qianxin-clients/refs/heads/master/trustagent/TrustAgent_standard_${ARCH}_3.4.1.1010.15_linux.deb" -o /vpn-client.deb && \
dpkg-deb -R /vpn-client.deb /build/
