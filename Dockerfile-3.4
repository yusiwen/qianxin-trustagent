FROM ubuntu:noble AS builder

RUN apt-get update && \
    apt-get install -y curl
COPY ./extract_deb.sh /extract_deb.sh
ARG TRUSTAGENT_VERSION
RUN /extract_deb.sh

FROM yusiwen/kasm-core-minimal:1.3.4-systemd
LABEL Author=yusiwen@gmail.com
LABEL Description="Qianxin(奇安信) TrustAgent VPN client within a minimal KASM core desktop" \
	License="GPLv2" \
	Version="3.4.1.1010.15"

USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates fonts-wqy-microhei libqt5gui5 python3-xdg python-is-python3 git psmisc zip net-tools iputils-ping dmidecode \
    && echo 'kasm-user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && apt-get autoclean && rm -rf /var/lib/apt/list/*

COPY --from=builder /build/usr/ /usr/
COPY --from=builder /build/opt/ /opt/

COPY ./systemd/trustdservice.service /usr/lib/systemd/system/trustdservice.service
COPY ./systemd/trustfrontservice.service /usr/lib/systemd/system/trustfrontservice.service
COPY ./systemd/trustservicemgr.service /usr/lib/systemd/system/trustservicemgr.service
COPY ./systemd/trustnet.service /usr/lib/systemd/system/trustnet.service
COPY ./install.sh /install.sh
COPY ./routes.sh /routes.sh

RUN /install.sh

ENV BYPASS_ROUTES=

USER 1000

COPY ./defaults/menu.xml /home/kasm-user/.config/openbox/menu.xml
