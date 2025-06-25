# this will create a distroless image that just contains the curl binary
FROM 11notes/distroless:curl AS distroless-curl
FROM scratch
COPY --from=distroless-curl / /
USER docker
ENTRYPOINT ["/usr/local/bin/curl"]