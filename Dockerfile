# build stage
FROM golang:alpine as build-env
MAINTAINER mdouchement

RUN apk upgrade
RUN apk add --update --no-cache git curl

ARG TASK_VERSION=v3.11.0
ARG TASK_SUM=a5b90d84ee5a2d6132634c3c922e7d9ac082ba9211e3adc96c00ff70f2c6a16d

RUN curl -LO https://github.com/go-task/task/releases/download/$TASK_VERSION/task_linux_arm64.tar.gz && \
    echo "$TASK_SUM  task_linux_arm64.tar.gz" | sha256sum -c && \
    tar -xf task_linux_arm64.tar.gz && \
    cp task /usr/local/bin/

RUN mkdir -p /go/src/github.com/mdouchement/standardfile
WORKDIR /go/src/github.com/mdouchement/standardfile

ENV CGO_ENABLED 0
ENV GO111MODULE on
ENV GOPROXY https://proxy.golang.org

COPY . /go/src/github.com/mdouchement/standardfile
# Dependencies
RUN go mod download

RUN task build-server

# final stage
FROM alpine
MAINTAINER mdouchement
ARG ARCH=arm64v8

ENV DATABASE_PATH /data/database

RUN mkdir -p ${DATABASE_PATH}

COPY --from=build-env /go/src/github.com/mdouchement/standardfile/dist/standardfile /usr/local/bin/

EXPOSE 5000
CMD ["standardfile", "server", "-c", "/etc/standardfile/standardfile.yml"]

# docker build -f Dockerfile -t jayknyn/standardfile:0.10.1-arm64 --platform=linux/arm64 .