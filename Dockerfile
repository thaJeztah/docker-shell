ARG GO_VERSION=1.17

FROM golang:${GO_VERSION}-alpine AS build
RUN apk add --no-cache git
RUN mkdir -p /go/src/github.com/yudai/gotty
WORKDIR /go/src/github.com/yudai/gotty

RUN git init . \
 && git remote add origin "https://github.com/yudai/gotty.git" \
 && git fetch --update-head-ok --depth 1 origin \
 && git checkout -q "v2.0.0-alpha.3"

RUN GO111MODULE=off go install -v github.com/yudai/gotty

FROM alpine
EXPOSE 8080
ENV TERM=xterm-256color
COPY --from=justincormack/nsenter1 /usr/bin/nsenter1 /usr/bin/nsenter1
COPY --from=build /go/bin/gotty /usr/bin/gotty
COPY rootfs/. /

LABEL org.opencontainers.image.title="DDShell" \
     org.opencontainers.image.description="Docker Desktop Shell Extension" \
     org.opencontainers.image.vendor="Docker Inc." \
     com.docker.desktop.extension.api.version="0.1.0"

CMD ["/usr/bin/gotty", "--title-format", "Docker Shell - ID:{{ .Hostname }}", "--permit-write", "nsenter1"]
