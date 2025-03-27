FROM 11notes/distroless AS distroless
FROM 11notes/distroless:curl AS distroless-curl
FROM scratch
COPY --from=distroless / /
COPY --from=distroless-curl / /
USER docker
ENTRYPOINT ["curl"]