#!/usr/bin/env bash

DEFAULT_GW=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
if [ -n "$DEFAULT_GW" ]; then
  if [ -n "$BYPASS_ROUTES" ]; then
    IFS=',' read -r -a routes <<< "$BYPASS_ROUTES"
    for r in "${routes[@]}"; do
      ip route add "$r" via "$DEFAULT_GW" dev eth0 metric 50
    done
  fi
fi

for i in {0..9}; do
  iptables -t nat -A POSTROUTING -o "vnic$i" -j MASQUERADE
  iptables -t mangle -A FORWARD -o "vnic$i" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
done
