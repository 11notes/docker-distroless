![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# DISTROLESS
[<img src="https://img.shields.io/badge/github-source-blue?logo=github&color=040308">](https://github.com/11notes/docker-DISTROLESS)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![size](https://img.shields.io/docker/image-size/11notes/distroless/latest?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/distroless/latest?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/distroless?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-DISTROLESS?color=7842f5">](https://github.com/11notes/docker-DISTROLESS/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Im0wIDBoMzJ2MzJoLTMyeiIgZmlsbD0iI2YwMCIvPjxwYXRoIGQ9Im0xMyA2aDZ2N2g3djZoLTd2N2gtNnYtN2gtN3YtNmg3eiIgZmlsbD0iI2ZmZiIvPjwvc3ZnPg==)

Build your own distroless images with this mini file system and some binaries

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [latest](https://hub.docker.com/r/11notes/distroless/tags?name=latest)

# REPOSITORIES ☁️
```
docker pull 11notes/distroless:latest
docker pull ghcr.io/11notes/distroless:latest
docker pull quay.io/11notes/distroless:latest
```

# SYNOPSIS 📖
**What can I do with this?** This image and its different layers can be used to build a distroless boiler plate for your application. Simply add the base layer and any additional layers (tags) with the stuff you need to run your application. The base layer containers Root CA certificates as well as time zone data and the user configuration for root and docker. Additional layers (tags) with statically linked binaries are:

* [11notes/distroless:curl](https://github.com/11notes/docker-distroless/blob/master/curl.dockerfile) - curl
* [11notes/distroless:dnslookup](https://github.com/11notes/docker-distroless/blob/master/dnslookup.dockerfile) - dnslookup
* [11notes/distroless:node](https://github.com/11notes/docker-node/blob/master/arch.dockerfile) - node

If you need more binaries, open a PR or feature request.

# BUILD 🚧
```yaml
FROM 11notes/distroless AS distroless
FROM 11notes/distroless:curl AS distroless-curl
FROM scratch
COPY --from=distroless --chown=1000:1000 / /
COPY --from=distroless-curl --chown=1000:1000 / /
USER docker
ENTRYPOINT ["curl"]
```

# SOURCE 💾
* [11notes/distroless](https://github.com/11notes/docker-DISTROLESS)

# PATCHED CVE 🦟
Unlike other popular image providers, this image contains individual CVE fixes to create a clean container image even if the developers of the original app simply forgot or refuse to do that. Why not add a PR with these fixes? Well, many developers ignore PR for CVE fixes and don’t run any code security scanners against their repos. Some simply don’t care.


| ID | Severity | Risk | Vector | Source |
| --- | --- | --- | --- | --- |
| CVE-2024-45337 | critical | low | [CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N) | [nvd.nist.gov](https://nvd.nist.gov/vuln/detail/CVE-2024-45337) |

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-distroless/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-distroless/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-distroless/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 10.04.2025, 10:10:52 (CET)*