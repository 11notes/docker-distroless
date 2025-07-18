# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=https://github.com/go-acme/lego.git \
      BUILD_ROOT=/go/lego
  ARG BUILD_BIN=${BUILD_ROOT}/dist/lego

  # :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: LEGO
  FROM 11notes/go:1.24 AS build
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    git clone ${BUILD_SRC} -b v${APP_VERSION};

  RUN set -ex; \
    # fix CVE's
    cd ${BUILD_ROOT}; \
    eleven patchGoMod ${BUILD_ROOT}/go.mod "github.com/go-viper/mapstructure/v2|v2.3.0|GHSA-fv92-fjc5-jj9h"; \
    eleven patchGoMod ${BUILD_ROOT}/go.mod "github.com/golang-jwt/jwt/v4|v4.5.2|CVE-2025-30204"; \
    eleven patchGoMod ${BUILD_ROOT}/go.mod "github.com/golang-jwt/jwt/v5|v5.2.2|CVE-2025-30204"; \
    eleven patchGoMod ${BUILD_ROOT}/go.mod "golang.org/x/net|v0.38.0|CVE-2025-22872"; \
    go mod tidy;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    go build -trimpath -ldflags '-X "main.version='${APP_VERSION}'" -extldflags=-static' -o  dist/lego ./cmd/lego/;

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};

    
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
  ENTRYPOINT ["/usr/local/bin/lego"]
  CMD ["--version"]