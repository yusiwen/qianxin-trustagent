#!/usr/bin/env sh

iptables -t nat -D POSTROUTING -o "$1" -j MASQUERADE
iptables -t mangle -D FORWARD -o "$1" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
/usr/bin/logger "iptables rules deleted for $1"
