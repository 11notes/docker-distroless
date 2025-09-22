# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/git \
      DEP_OPENSSL_VERSION=3.5.3 \
      DEP_ZLIB_VERSION=1.3.1 \
      DEP_CURL_VERSION=8.16.0
  ARG BUILD_BIN=${BUILD_ROOT}/git

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: OPENSSL & ZLIB & CURL
  FROM alpine AS build
  COPY --from=util-bin / /

  ARG APP_VERSION \
      APP_ROOT \
      TARGETARCH \
      TARGETVARIANT \
      DEP_OPENSSL_VERSION \
      DEP_ZLIB_VERSION \
      DEP_CURL_VERSION \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    apk --update --no-cache add \
      gpg \
      gpg-agent \
      perl \
      g++ \
      make \
      linux-headers \
      git \
      cmake \
      build-base \
      samurai \
      python3 \
      py3-pkgconfig \
      pkgconfig \
      pv \
      autoconf \
      automake \
      xz \
      wget \
      pcre-dev \
      pcre-static \
      pcre2-dev \
      pcre2-static \
      expat-dev \
      expat-static \
      musl-libintl;

  # OPENSSL
  RUN set -ex; \
    eleven github asset openssl/openssl openssl-${DEP_OPENSSL_VERSION} openssl-${DEP_OPENSSL_VERSION}.tar.gz;

  RUN set -ex; \
    cd /openssl-${DEP_OPENSSL_VERSION}; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      "amd64"|"arm64") \
        ./Configure \
          -static \
          --openssldir=/etc/ssl; \
      ;; \
      \
      "armv7") \
        ./Configure \
          linux-generic32 \
          -static \
          --openssldir=/etc/ssl; \
      ;; \
    esac; \
    make -s -j $(nproc) 2>&1 > /dev/null; \
    make -s -j $(nproc) install_sw 2>&1 > /dev/null;

  RUN set -ex; \
    cp -af /openssl-${DEP_OPENSSL_VERSION}/libssl.a /usr/lib; \
    cp -af /openssl-${DEP_OPENSSL_VERSION}/libcrypto.a /usr/lib;

  # ZLIB
  RUN set -ex; \
    eleven github asset madler/zlib v${DEP_ZLIB_VERSION} zlib-${DEP_ZLIB_VERSION}.tar.gz;

  RUN set -ex; \
    cd /zlib-${DEP_ZLIB_VERSION}; \
    ./configure --static; \
    make -s -j $(nproc) 2>&1 > /dev/null; \
    make -s -j $(nproc) install 2>&1 > /dev/null;

  RUN set -ex; \
    cp -af /zlib-${DEP_ZLIB_VERSION}/libz.a /usr/lib;

  # CURL
  RUN set -ex; \
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2; \
    wget -q --show-progress --progress=bar:force https://curl.se/download/curl-${DEP_CURL_VERSION}.tar.xz; \
    wget -q --show-progress --progress=bar:force https://curl.se/download/curl-${DEP_CURL_VERSION}.tar.xz.asc;

  RUN set -ex; \
    gpg --verify curl-${DEP_CURL_VERSION}.tar.xz.asc curl-${DEP_CURL_VERSION}.tar.xz; \
    pv curl-${DEP_CURL_VERSION}.tar.xz | tar xJ;

  RUN set -ex; \
    cd /curl-${DEP_CURL_VERSION}; \
    LDFLAGS="-static" PKG_CONFIG="pkg-config --static" \
      ./configure \
        --disable-shared \
        --enable-static \
        --disable-ldap \
        --disable-ipv6 \
        --enable-unix-sockets \
        --with-ssl  \
        --disable-docs \
        --disable-manual \
        --without-libpsl; \
    make -s -j $(nproc) V=1 LDFLAGS="-static -all-static"  2>&1 > /dev/null;

  RUN set -ex; \
    cp -af /curl-${DEP_CURL_VERSION}/lib/.libs/libcurl.a /usr/lib;

    # GIT
    RUN set -ex; \
      eleven git clone git/git.git v${APP_VERSION};

    RUN set -ex; \
      cd ${BUILD_ROOT}; \
      make \
        NO_GETTEXT=YesPlease \
        NO_SVN_TESTS=YesPlease \
        NO_REGEX=YesPlease \
        NO_SYS_POLL_H=1 \
        INSTALL_SYMLINKS=1 \
        NO_PYTHON=YesPlease \
        NO_TCLTK=YesPlease \
        ICONV_OMITS_BOM=Yes \
        USE_LIBPCRE2=YesPlease \
        ZLIB_PATH=/zlib-${DEP_ZLIB_VERSION} \
        OPENSSLDIR=/openssl-${DEP_OPENSSL_VERSION} \
        CURLDIR=/curl-${DEP_CURL_VERSION} \
        CURL_LDFLAGS="-lcurl -lssl -lcrypto -lz" \
        LDFLAGS="-static"

    RUN set -ex; \
      cd ${BUILD_ROOT}; \
      eleven distroless ${BUILD_BIN}; \
      eleven distroless ${BUILD_ROOT}/git-difftool--helper; \
      eleven distroless ${BUILD_ROOT}/git-filter-branch; \
      eleven distroless ${BUILD_ROOT}/git-http-fetch; \
      eleven distroless ${BUILD_ROOT}/git-http-push; \
      eleven distroless ${BUILD_ROOT}/git-merge-octopus; \
      eleven distroless ${BUILD_ROOT}/git-merge-one-file; \
      eleven distroless ${BUILD_ROOT}/git-merge-resolve; \
      eleven distroless ${BUILD_ROOT}/git-mergetool; \
      eleven distroless ${BUILD_ROOT}/git-mergetool--lib; \
      eleven distroless ${BUILD_ROOT}/git-quiltimport; \
      eleven distroless ${BUILD_ROOT}/git-remote-http; \
      eleven distroless ${BUILD_ROOT}/git-request-pull; \
      eleven distroless ${BUILD_ROOT}/git-sh-i18n; \
      eleven distroless ${BUILD_ROOT}/git-sh-i18n--envsubst; \
      eleven distroless ${BUILD_ROOT}/git-sh-setup; \
      eleven distroless ${BUILD_ROOT}/git-submodule; \
      eleven distroless ${BUILD_ROOT}/git-web--browse;

    RUN set -ex; \
      mkdir -p ${APP_ROOT}/opt/git; \
      cp -af ${BUILD_ROOT}/templates ${APP_ROOT}/opt/git;

    RUN set -ex; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-add; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-am; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-annotate; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-apply; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-archive; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-backfill; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-bisect; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-blame; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-branch; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-bugreport; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-bundle; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-cat-file; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-check-attr; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-check-ignore; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-check-mailmap; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-check-ref-format; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-checkout; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-checkout--worker; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-checkout-index; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-cherry; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-cherry-pick; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-clean; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-clone; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-column; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-commit; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-commit-graph; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-commit-tree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-config; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-count-objects; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-credential; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-credential-cache; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-credential-cache--daemon; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-credential-store; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-describe; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-diagnose; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-diff; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-diff-files; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-diff-index; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-diff-tree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-difftool; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-fast-export; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-fetch; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-fetch-pack; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-fmt-merge-msg; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-for-each-ref; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-for-each-repo; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-format-patch; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-fsck; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-fsck-objects; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-fsmonitor--daemon; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-gc; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-get-tar-commit-id; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-grep; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-hash-object; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-help; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-hook; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-index-pack; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-init; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-init-db; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-interpret-trailers; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-log; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-ls-files; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-ls-remote; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-ls-tree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-mailinfo; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-mailsplit; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-maintenance; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge-base; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge-file; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge-index; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge-ours; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge-recursive; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge-subtree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-merge-tree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-mktag; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-mktree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-multi-pack-index; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-mv; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-name-rev; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-notes; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-pack-objects; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-pack-redundant; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-pack-refs; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-patch-id; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-prune; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-prune-packed; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-pull; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-push; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-range-diff; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-read-tree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-rebase; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-receive-pack; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-reflog; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-refs; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-remote; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-remote-ext; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-remote-fd; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-repack; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-replace; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-replay; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-rerere; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-reset; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-restore; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-rev-list; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-rev-parse; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-revert; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-rm; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-send-pack; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-shortlog; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-show; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-show-branch; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-show-index; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-show-ref; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-sparse-checkout; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-stage; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-stash; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-status; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-stripspace; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-submodule--helper; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-switch; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-symbolic-ref; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-tag; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-unpack-file; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-unpack-objects; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-update-index; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-update-ref; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-update-server-info; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-upload-archive; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-upload-pack; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-var; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-verify-commit; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-verify-pack; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-verify-tag; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-version; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-whatchanged; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-worktree; \
      ln -sf /usr/local/bin/git ${APP_ROOT}/opt/git/git-write-tree; \
      ln -sf /usr/local/bin/git-remote-http ${APP_ROOT}/opt/git/git-remote-ftp; \
      ln -sf /usr/local/bin/git-remote-http ${APP_ROOT}/opt/git/git-remote-ftps; \
      ln -sf /usr/local/bin/git-remote-http ${APP_ROOT}/opt/git/git-remote-http; \
      ln -sf /usr/local/bin/git-remote-http ${APP_ROOT}/opt/git/git-remote-https; \
      ln -sf /usr/local/bin/git-difftool--helper ${APP_ROOT}/opt/git/git-difftool--helper; \
      ln -sf /usr/local/bin/git-filter-branch ${APP_ROOT}/opt/git/git-filter-branch; \
      ln -sf /usr/local/bin/git-http-fetch ${APP_ROOT}/opt/git/git-http-fetch; \
      ln -sf /usr/local/bin/git-http-push ${APP_ROOT}/opt/git/git-http-push; \
      ln -sf /usr/local/bin/git-merge-octopus ${APP_ROOT}/opt/git/git-merge-octopus; \
      ln -sf /usr/local/bin/git-merge-one-file ${APP_ROOT}/opt/git/git-merge-one-file; \
      ln -sf /usr/local/bin/git-merge-resolve ${APP_ROOT}/opt/git/git-merge-resolve; \
      ln -sf /usr/local/bin/git-mergetool ${APP_ROOT}/opt/git/git-mergetool; \
      ln -sf /usr/local/bin/git-mergetool--lib ${APP_ROOT}/opt/git/git-mergetool--lib; \
      ln -sf /usr/local/bin/git-quiltimport ${APP_ROOT}/opt/git/git-quiltimport; \
      ln -sf /usr/local/bin/git-request-pull ${APP_ROOT}/opt/git/git-request-pull; \
      ln -sf /usr/local/bin/git-sh-i18n ${APP_ROOT}/opt/git/git-sh-i18n; \
      ln -sf /usr/local/bin/git-sh-i18n--envsubst ${APP_ROOT}/opt/git/git-sh-i18n--envsubst; \
      ln -sf /usr/local/bin/git-sh-setup ${APP_ROOT}/opt/git/git-sh-setup; \
      ln -sf /usr/local/bin/git-submodule ${APP_ROOT}/opt/git/git-submodule; \
      ln -sf /usr/local/bin/git-web--browse ${APP_ROOT}/opt/git/git-web--browse;

      
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

  # :: app specific environment
    ENV GIT_TEMPLATE_DIR=/opt/git/templates \
        GIT_EXEC_PATH=/opt/git

  # :: multi-stage
    COPY --from=build /distroless/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/git"]
  CMD ["--version"]