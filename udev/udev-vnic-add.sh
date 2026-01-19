#!/usr/bin/env sh

iptables -t nat -A POSTROUTING -o "$1" -j MASQUERADE
iptables -t mangle -A FORWARD -o "$1" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
/usr/bin/logger "iptables rules added for $1"
