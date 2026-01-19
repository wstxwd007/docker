FROM openwrt/rootfs:v21.02.5

ENV GOSTAPI="18080"
ENV UU_LAN_IPADDR=
ENV UU_LAN_GATEWAY=
ENV UU_LAN_NETMASK="255.255.255.0"
ENV UU_LAN_DNS="119.29.29.29"

USER root

# 使用 TARGETARCH 自动识别架构 (amd64 或 arm64)
ARG TARGETARCH

RUN mkdir -p /var/lock && \
    opkg update && \
    opkg install libustream-openssl ca-bundle ca-certificates kmod-tun wget || true && \
    rm -rf /var/opkg-lists

# 动态下载/拷贝 gost
# 技巧：如果是从本地 COPY，你需要准备好两个架构的压缩包
RUN wget https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_${TARGETARCH}.tar.gz -O /tmp/gost.tar.gz && \
    tar -zxvf /tmp/gost.tar.gz -C /usr/bin/ gost && \
    chmod +x /usr/bin/gost && \
    rm /tmp/gost.tar.gz

COPY ux_prepare /etc/init.d/ux_prepare
RUN chmod +x /etc/init.d/ux_prepare \
    && /etc/init.d/ux_prepare enable \
    && /etc/init.d/odhcpd disable \
    && /etc/init.d/firewall disable \
    && /etc/init.d/uhttpd disable \
    && /etc/init.d/dropbear disable

CMD ["/sbin/init"]
