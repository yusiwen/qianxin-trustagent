Packing official Qianxin TrustAgent zero-trust Linux client (https://ztna.qianxin.com/authn/download/app) from base image: kasmweb/core-ubuntu-noble （https://hub.docker.com/r/kasmweb/core-ubuntu-noble).

## Usage

Start container:

```bash
docker run --rm --name qianxin-trustagent -e VNC_PW=password -p 6901:6901 -e BYPASS_ROUTES=10.1.0.0/16,10.2.0.0/16 --shm-size=512m --privileged --device=/dev/net/tun:/dev/net/tun -v=/sys/fs/cgroup:/sys/fs/cgroup:rw --ulimit nofile=1048576:1048576 --cgroupns=host --entrypoint=/lib/systemd/systemd --user=root yusiwen/qianxin-trustagent:3.4.1.1010.15
```

Access the workspace via https://HOST_IP:6901, username is `kasm_user`, password is `password` (password must contains at least 6 characters).

To use via plain HTTP and no HTTP Basic Auth:

```bash
docker run --rm --name qianxin-trustagent -e KASM_VNC_SSL=0 -e KASM_NO_AUTH=1 -p 6901:6901 -e BYPASS_ROUTES=10.1.0.0/16,10.2.0.0/16 --shm-size=512m --privileged --device=/dev/net/tun:/dev/net/tun -v=/sys/fs/cgroup:/sys/fs/cgroup:rw --ulimit nofile=1048576:1048576 --cgroupns=host --entrypoint=/lib/systemd/systemd --user=root yusiwen/qianxin-trustagent:3.4.1.1010.15
```

The TrustAgent zero-trust client is deeply binded with systemd, so a privileged container is needed to run systemd instance inside.

The comma separated `BYPASS_ROUTES` is the routes should be bypassed from VPN using the default GW in the container, in case some host's routes are incorrectly overrided by the VPN server settings. 

## Example compose file

This example use a macvlan network for easily add static routes at the router in the same LAN.

```yaml
---
services:
  qianxin-trustagent:
    image: yusiwen/qianxin-trustagent:3.4.1.1010.15
    container_name: qianxin-trustagent
    restart: unless-stopped
    privileged: true
    environment:
      - KASM_NO_VETH=1
      - KASM_NO_AUTH=1
      - KASM_VNC_SSL=0
      - TZ=Asia/Shanghai
    devices:
      - "/dev/net/tun:/dev/net/tun"
    cgroup: host
    user: root
    shm_size: 512m
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576 
    volumes:
      - user-data:/home/kasm-user/.TrustAgent
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    entrypoint: ["/lib/systemd/systemd"]
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "1"
    networks:
      macvlan:
        ipv4_address: "192.168.2.193"

volumes:
  user-data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${HOME}/.cache/qianxin-trustagent/user-data

networks:
  macvlan:
    name: macvlan
    driver: macvlan
    driver_opts:
      parent: ${MACVLAN_PARENT_DEVICE:-ens18}
    ipam:
      config:
        - subnet: "192.168.2.0/24"
          ip_range: "192.168.2.192/27"
          gateway: "192.168.2.1"
          aux_addresses:
            host: "192.168.2.223"
```
