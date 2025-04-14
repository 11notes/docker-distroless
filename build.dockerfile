# this will create a distroless image that just contains the curl binary
FROM 11notes/distroless AS distroless
FROM 11notes/distroless:curl AS distroless-curl
FROM scratch
COPY --from=distroless --chown=1000:1000 / /
COPY --from=distroless-curl --chown=1000:1000 / /
USER docker
ENTRYPOINT ["curl"]