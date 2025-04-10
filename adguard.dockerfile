ARG APP_VERSION=stable

# :: Distroless
  FROM 11notes/adguard:${APP_VERSION} AS adguard
  FROM scratch
  COPY --from=adguard /usr/local/bin/AdGuardHome /usr/local/bin/AdGuardHome

# :: Start
  ENTRYPOINT ["/usr/local/bin/AdGuardHome"]