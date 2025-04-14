ARG APP_VERSION=stable

# :: Distroless
  FROM 11notes/nginx:${APP_VERSION} AS nginx
  FROM scratch
  COPY --from=nginx /usr/local/bin/nginx /usr/local/bin/nginx
  COPY --from=nginx /nginx /
  COPY --from=nginx /etc/nginx /etc

# :: Start
  ENTRYPOINT ["/usr/local/bin/nginx"]