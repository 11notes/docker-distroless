# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: IPTABLES
  FROM alpine AS build
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_ROOT="/iptables"

  RUN set -ex; \
    apk --update --no-cache add \
      git \
      build-base \
      autoconf \
      automake \
      libtool \
      pkgconf \
      libmnl-dev \
      jansson-dev \
      linux-headers \
      libnftnl-dev \
      linux-pam-dev \
      libmnl-static;

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/usr/local/bin;

  RUN set -ex; \
    git clone git://git.netfilter.org/libnftnl;

  RUN set -ex; \
    cd libnftnl; \
    ./autogen.sh; \
    ./configure --enable-static --disable-shared; \
    make -j$(nproc); \
    make install;

  RUN set -ex; \
    git clone https://git.netfilter.org/iptables;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./autogen.sh; \
    ./configure --enable-static --disable-shared \
      CFLAGS="-no-pie" \
      LDFLAGS="-static -no-pie"; \
    make -s -j $(nproc) V=1 LDFLAGS="-static -all-static -no-pie" 2>&1 > /dev/null; \
    mv ${BUILD_ROOT}/iptables/xtables-nft-multi ${APP_ROOT}/usr/local/bin;

  RUN set -ex; \
    cd ${APP_ROOT}/usr/local/bin; \
    ln -s xtables-nft-multi iptables; \
    ln -s xtables-nft-multi iptables-restore; \
    ln -s xtables-nft-multi iptables-save; \
    ln -s xtables-nft-multi ip6tables; \
    ln -s xtables-nft-multi ip6tables-restore; \
    ln -s xtables-nft-multi ip6tables-save; \
    ln -s xtables-nft-multi iptables-translate; \
    ln -s xtables-nft-multi ip6tables-translate; \
    ln -s xtables-nft-multi xtables-monitor;

  RUN set -ex; \
    cd ${APP_ROOT}/usr/local/bin; \
    ./iptables --version | grep -q "${APP_VERSION}";


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/jq"]
  CMD ["--version"]