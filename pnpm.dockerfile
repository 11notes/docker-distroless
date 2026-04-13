# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: PNPM
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG TARGETARCH \
      TARGETVARIANT \
      APP_VERSION

  RUN set -ex; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      "amd64") \
        TARGETARCH=x64; \
      ;; \
    esac; \
    eleven github asset pnpm/pnpm v${APP_VERSION} pnpm-linuxstatic-${TARGETARCH}${TARGETVARIANT}; \
    mkdir -p /distroless/usr/local/bin; \
    mv pnpm-linuxstatic-${TARGETARCH}${TARGETVARIANT} /distroless/usr/local/bin/pnpm;


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
    COPY --from=distroless / /
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/pnpm"]
  CMD ["--version"]