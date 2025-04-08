ARG APP_VERSION=stable

# :: Distroless
  FROM 11notes/node:${APP_VERSION} AS node
  FROM scratch
  COPY --from=node /usr/local/bin/node /usr/local/bin/node

# :: Start
  ENTRYPOINT ["/usr/local/bin/node"]