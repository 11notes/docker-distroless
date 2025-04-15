${{ content_synopsis }} This image and its different layers can be used to build a distroless boiler plate for your application. Simply add the base layer and any additional layers (tags) with the stuff you need to run your application. All binaries are statically compiled and do not depend on any OS libraries or clib. The base layer contains Root CA certificates as well as time zone data and the user configuration for root and docker. Additional layers (tags) with statically compiled binaries are:

* [11notes/distroless:curl](https://github.com/11notes/docker-distroless/blob/master/curl.dockerfile) - curl (for healthchecks)
* [11notes/distroless:dnslookup](https://github.com/11notes/docker-distroless/blob/master/dnslookup.dockerfile) - dnslookup (for healthchecks)
* [11notes/distroless:node](https://github.com/11notes/docker-node) - node
* [11notes/distroless:adguard](https://github.com/11notes/docker-adguard) - adguard
* [11notes/distroless:nginx](https://github.com/11notes/docker-nginx) - nginx
* [11notes/distroless:traefik](https://github.com/11notes/docker-traefik) - traefik
* [11notes/distroless:tini-pm](https://github.com/11notes/go-tini-pm) - tini-pm

Each tag has sub tags like latest, stable or semver, check the tags available for each binary. If you need more binaries, open a PR or feature request.

${{ content_build }}

${{ content_source }}