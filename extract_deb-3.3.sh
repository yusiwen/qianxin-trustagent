#!/usr/bin/env bash

OS_ARCH=$(uname -m)
ARCH="$OS_ARCH"
if [ "$ARCH" = 'x86_64' ]; then
  ARCH='amd64'
fi
echo "ARCH=$ARCH"

curl -L "https://share.yusiwen.cn/public/vpn/qianxin/TrustAgent_standard_${ARCH}_3.3.1.1155_linux.deb" -o /vpn-client.deb && \
dpkg-deb -R /vpn-client.deb /build/
