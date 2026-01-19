#!/usr/bin/env bash

DEFAULT_GW=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
if [ -n "$DEFAULT_GW" ]; then
  if [ -n "$BYPASS_ROUTES" ]; then
    echo "Bypassing routes: $BYPASS_ROUTES ..."
    echo '100 bypass' >> /etc/iproute2/rt_tables
    ip rule add from all lookup bypass priority 100
    ip rule add from all lookup dnat priority 101
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
