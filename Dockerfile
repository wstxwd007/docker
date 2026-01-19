FROM openwrt/rootfs:21.02.5

ENV GOSTAPI="18080"
ENV UU_LAN_IPADDR=
ENV UU_LAN_GATEWAY=
ENV UU_LAN_NETMASK="255.255.255.0"
ENV UU_LAN_DNS="119.29.29.29"

USER root

# 显式声明架构变量
ARG TARGETARCH

RUN mkdir -p /var/lock && \
    # 1. 架构源修复 (已验证成功)
    if [ "$TARGETARCH" = "arm64" ]; then \
        sed -i 's/x86\/64/armvirt\/64/g' /etc/opkg/distfeeds.conf && \
        sed -i 's/x86_64/aarch64_generic/g' /etc/opkg/distfeeds.conf; \
    fi && \
    \
    opkg update && \
    # 2. 暴力卸载 wolfssl：使用 --force-depends 忽略依赖警告，并删除冲突文件
    opkg remove libustream-wolfssl* --force-remove --force-depends || true && \
    # 强制清理可能冲突的软链接/文件（这是为了保险）
    rm -f /lib/libustream-ssl.so || true && \
    \
    # 3. 安装依赖：安装 openssl 版本的 ustream 以支持 HTTPS
    opkg install libustream-openssl ca-bundle ca-certificates kmod-tun wget || true && \
    rm -rf /var/opkg-lists

# 3. 动态下载 GOST
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

