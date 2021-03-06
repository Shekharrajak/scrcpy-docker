### builder
FROM alpine:edge AS builder

ARG SCRCPY_VER=1.8
ARG SERVER_HASH="839055ef905903bf98ead1b9b8a127fe402b39ad657a81f9a914b2dbcb2ce5c0"

RUN apk add --no-cache \
        curl \
        ffmpeg-dev \
        gcc \
        git \
        make \
        meson \
        musl-dev \
        openjdk8 \
        pkgconf \
        sdl2-dev

RUN PATH=$PATH:/usr/lib/jvm/java-1.8-openjdk/bin
RUN curl -L -o scrcpy-server.jar https://github.com/Genymobile/scrcpy/releases/download/v${SCRCPY_VER}/scrcpy-server-v${SCRCPY_VER}.jar
RUN echo "$SERVER_HASH  /scrcpy-server.jar" | sha256sum -c -
RUN git clone https://github.com/Genymobile/scrcpy.git
RUN cd scrcpy && meson x --buildtype release --strip -Db_lto=true -Dprebuilt_server=/scrcpy-server.jar
RUN cd scrcpy/x && ninja

### runner
FROM alpine:edge AS runner

# needed for android-tools
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories

LABEL maintainer="Pierre Gordon <pierregordon@protonmail.com>"

RUN apk add --no-cache \
        android-tools \
        ffmpeg \
        virtualgl

COPY --from=builder /scrcpy-server.jar /usr/local/share/scrcpy/
COPY --from=builder /scrcpy/x/app/scrcpy /usr/local/bin/

### runner (amd)
FROM runner AS amd

RUN apk add --no-cache mesa-dri-swrast

### runner (intel)
FROM runner AS intel

RUN apk add --no-cache mesa-dri-intel

### runner (nvidia)
FROM runner AS nvidia

RUN apk add --no-cache mesa-dri-nouveau
