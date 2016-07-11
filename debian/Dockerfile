FROM debian:jessie

MAINTAINER Paolo Furini <p.furini@nexbit.it>

# Docker Build Arguments
ENV OPENRESTY_PREFIX /opt/openresty
ENV NGINX_PREFIX /opt/openresty/nginx
ENV VAR_PREFIX /var/nginx
ENV LUAROCKS_BIN $OPENRESTY_PREFIX/luajit/bin

ARG RESTY_VERSION="1.9.15.1"
ARG RESTY_LUAROCKS_VERSION="2.3.0"
ARG RESTY_OPENSSL_VERSION="1.0.2h"
ARG RESTY_PCRE_VERSION="8.38"
ARG RESTY_CONFIG_OPTIONS="\
    --with-luajit \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-threads \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_fastcgi_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    "

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="\
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} \
    --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION} \
    "


# 1) Install apt dependencies
# 2) Download and untar OpenSSL, PCRE, LuaRocks, and OpenResty
# 3) Build OpenResty and LuaRocks
# 4) Cleanup

RUN \
    echo "==> Installing dependences (apt)..." \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
#        libgd-dev \
# Only for http_geoip_module
#        libgeoip-dev \
        libncurses5-dev \
        libperl-dev \
        libreadline-dev \
# Only for http_xslt_module
#        libxslt1-dev \ 
        make \
        perl \
        unzip \
        zlib1g-dev \
        git \
    && cd /tmp \
    && echo "==> Downloading OpenSSL (${RESTY_OPENSSL_VERSION})..." \
    && curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && echo "==> Configuring OpenSSL..." \
    && cd /tmp/openssl-${RESTY_OPENSSL_VERSION} \
    && ./config --prefix=/usr/ shared \
    && echo "==> Building OpenSSL..." \
    && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && make -j${NPROC} depend \
    && make -j${NPROC} \
    && echo "==> Installing OpenSSL..." \
    && make install \
    && cd /tmp \
    && echo "==> Downloading PCRE (${RESTY_PCRE_VERSION})..." \
    && curl -fSL https://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && echo "==> Downloading OpenResty (${RESTY_VERSION})..." \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && echo "==> Configuring OpenResty..." \
    && echo "using upto $NPROC threads" \
    && ./configure -j${NPROC} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    && echo "==> Building OpenResty..." \
    && make -j${NPROC} \
    && echo "==> Installing OpenResty..." \
    && make -j${NPROC} install \
    && cd /tmp \
    && echo "==> Downloading Luarocks..." \
    && curl -fSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && echo "==> Configuring Luarocks..." \
    && ./configure --prefix=$OPENRESTY_PREFIX/luajit \
        --with-lua=$OPENRESTY_PREFIX/luajit \
        --lua-suffix=jit-2.1.0-beta2 \
        --with-lua-include=$OPENRESTY_PREFIX/luajit/include/luajit-2.1 \
        --force-config \
    && echo "==> Building Luarocks..." \
    && make -j${NPROC} build \
    && echo "==> Installing Luarocks..." \
    && make install \
    && echo "==> Cleaning up..." \
    && cd /tmp \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION} \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
#    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
#    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log \
    && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx \
    && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/openresty \
    && ln -sf $OPENRESTY_PREFIX/bin/resty /usr/local/bin/resty \
    && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
    && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* /usr/local/bin/lua
# TODO: remove any other apt packages?

WORKDIR $NGINX_PREFIX/
# Use ENTRYPOINT instead of CMD because this isn't intended to be user overridden
ENTRYPOINT ["nginx", "-g", "daemon off; error_log /dev/stderr error;"]

# Don't expose here - use docker-compose for finer grade control
#EXPOSE 8080
#EXPOSE 8443