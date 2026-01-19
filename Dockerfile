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
    # 1. 架构源修复 (保持 arm64 兼容)
    if [ "$TARGETARCH" = "arm64" ]; then \
        sed -i 's/x86\/64/armvirt\/64/g' /etc/opkg/distfeeds.conf && \
        sed -i 's/x86_64/aarch64_generic/g' /etc/opkg/distfeeds.conf; \
    fi && \
    \
    # 2. 暂时降级为 http 以便在没有 SSL 库时也能安装包
    sed -i 's/https/http/g' /etc/opkg/distfeeds.conf && \
    opkg update && \
    \
    # 3. 只安装最核心的依赖，不强求替换 openssl
    # 安装 wget-ssl 会自动处理它需要的依赖
    opkg install wget-ssl kmod-tun || true && \
    rm -rf /var/opkg-lists

# 4. 下载 GOST
# 关键：加上 --no-check-certificate 确保万无一失
RUN wget --no-check-certificate "https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_${TARGETARCH}.tar.gz" -O /tmp/gost.tar.gz && \
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

