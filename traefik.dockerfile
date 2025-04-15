ARG APP_VERSION=stable

# :: Distroless
  FROM 11notes/traefik:${APP_VERSION} AS traefik
  FROM scratch
  COPY --from=traefik /usr/local/bin/traefik /usr/local/bin
  COPY --from=traefik /traefik /

# :: Start
  ENTRYPOINT ["/usr/local/bin/traefik"]