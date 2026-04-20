#!/usr/bin/env bash

DEVICE="$1"
DNS_ENABLED=0
DNAT_FILE=/run/trustagent_dnat

function process_dnat() {
  local source_ip="$1"
  local target="$2"
  local target_ip=""
  local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
  
  if [[ "$target" =~ $ip_regex ]]; then
    target_ip="$target"
  else
    if [ "$DNS_ENABLED" = 1 ]; then
      local resolved_ip
      resolved_ip=$(dig "$target" +short)
      if [ -n "$resolved_ip" ]; then
        /usr/bin/logger "resolved domain: $target to $resolved_ip"
        target_ip="$resolved_ip"
      else
        /usr/bin/logger "failed resolve domain: $target"
        return 0
      fi
    else
      return 0
    fi
  fi

  ip route add "$target_ip" dev "$DEVICE" table dnat
  echo "ip route del $target_ip dev $DEVICE table dnat" >> "$DNAT_FILE"
  if [ "$source_ip" != "$target_ip" ]; then
    iptables -t nat -A PREROUTING -i eth0 -d "$source_ip" -j DNAT --to-destination "$target_ip"
    echo "iptables -t nat -D PREROUTING -i eth0 -d $source_ip -j DNAT --to-destination $target_ip" >> "$DNAT_FILE"
  else
    /usr/bin/logger 'source and target IPs are identical'
  fi
}

iptables -t nat -A POSTROUTING -o "$DEVICE" -j MASQUERADE
iptables -t mangle -A FORWARD -o "$DEVICE" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360

# Wait for up to 5 seconds for the process to appear
timeout 5s bash -c 'until pgrep -x "trustdns" > /dev/null; do sleep 0.5; done'

if [ $? -eq 0 ]; then
    /usr/bin/logger "trustdns is running."
    DNS_ENABLED=1
else
    /usr/bin/logger "cannot find trustdns process."
fi

if [ -n "$DNAT_RULES" ]; then
  IFS=',' read -r -a dnats <<< "$DNAT_RULES"
  for d in "${dnats[@]}"; do
    IFS='-' read -r -a ips <<< "${d}"
    process_dnat "${ips[0]}" "${ips[1]}"
  done
fi

/usr/bin/logger "route table & iptables rules added for $DEVICE"
