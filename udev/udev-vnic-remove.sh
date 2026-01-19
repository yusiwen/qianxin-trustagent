#!/usr/bin/env bash

iptables -t nat -D POSTROUTING -o "$1" -j MASQUERADE
iptables -t mangle -D FORWARD -o "$1" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
/usr/bin/logger "iptables rules deleted for $1"

if [ -n "$DNAT_RULES" ]; then
  IFS=',' read -r -a dnats <<< "$DNAT_RULES"
  for d in "${dnats[@]}"; do
    IFS='-' read -r -a ips <<< "${d}"
    ip route del "${ips[1]}" dev "$1" table dnat
  done
fi
/usr/bin/logger "route table rules deleted for $1"