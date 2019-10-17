ARG GO_VERSION=1.12.10

FROM golang:${GO_VERSION}-alpine AS build

RUN mkdir -p /go/src/github.com/yudai/gotty
WORKDIR /go/src/github.com/yudai/gotty

COPY . .
RUN go install -v github.com/yudai/gotty

FROM alpine
EXPOSE 8080
ENV TERM=xterm-256color
COPY --from=justincormack/nsenter1 /usr/bin/nsenter1 /usr/bin/nsenter1
COPY --from=build /go/bin/gotty /usr/bin/gotty
CMD ["nsenter1"]
ENTRYPOINT ["/usr/bin/gotty", "--title-format", "Docker Shell - ID:{{ .Hostname }}", "--once", "--permit-write"]
