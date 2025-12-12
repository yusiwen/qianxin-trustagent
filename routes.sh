#!/usr/bin/env bash

DEFAULT_GW=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
if [ -n "$DEFAULT_GW" ]; then
  if [ -n "$BYPASS_ROUTES" ]; then
    echo "Bypassing routes: $BYPASS_ROUTES ..."
    echo '100 bypass' >> /etc/iproute2/rt_tables
    ip rule add from all lookup bypass priority 100
    IFS=',' read -r -a routes <<< "$BYPASS_ROUTES"
    for r in "${routes[@]}"; do
      ip route add "$r" via "$DEFAULT_GW" dev eth0 table bypass
    done
  fi
fi

if [ -n "$DNAT_RULES" ]; then
  IFS=',' read -r -a dnats <<< "$DNAT_RULES"
  for d in "${dnats[@]}"; do
    IFS='-' read -r -a ips <<< "${d}"
    iptables -t nat -A PREROUTING -i eth0 -d "${ips[0]}" -j DNAT --to-destination "${ips[1]}"
  done
fi

for i in {0..9}; do
  iptables -t nat -A POSTROUTING -o "vnic$i" -j MASQUERADE
  iptables -t mangle -A FORWARD -o "vnic$i" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
done
