#!/usr/bin/env bash

DEVICE="$1"

# 检查参数
if [ -z "$DEVICE" ]; then
  /usr/bin/logger "Error: no device specified"
  exit 1
fi


iptables -t nat -D POSTROUTING -o "$DEVICE" -j MASQUERADE
iptables -t mangle -D FORWARD -o "$DEVICE" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360

DNAT_FILE=/run/trustagent_dnat
if [ -f "$DNAT_FILE" ];then
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines or lines starting with # (comments)
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    
    # Execute the line as a command
    eval "$line"
  done < "$DNAT_FILE"
  rm -f "$DNAT_FILE"
fi

/usr/bin/logger "route table & iptables rules deleted for $1"
