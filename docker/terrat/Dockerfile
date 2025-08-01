# Define an argument for the base image
ARG BASE_IMAGE

# Optional base setup stage if BASE_IMAGE is not provided
FROM alpine:3.22 AS build-base

# Install base packages
RUN apk add --no-cache \
    bash \
    bsd-compat-headers \
    ca-certificates \
    cargo \
    clang \
    cmake \
    coreutils \
    curl \
    curl-dev \
    git \
    gmp-dev \
    libffi-dev \
    libretls \
    libretls-dev \
    m4 \
    make \
    mercurial \
    musl-dev \
    npm \
    opam \
    openssh \
    perl \
    pkgconf \
    py3-yaml \
    python3 \
    rsync \
    rust \
    sqlite-dev \
    zlib-dev

# Initialize opam
RUN opam init -ay --disable-sandboxing --bare

# Build libkqueue
COPY ./vendor/libkqueue /mono/vendor/libkqueue
WORKDIR /mono/vendor/libkqueue
RUN cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib $PWD && \
    make && \
    make install

# Copy source files
COPY ./ /mono
WORKDIR /

# Set up opam repositories and dependencies
RUN eval $(opam env) && \
    opam switch create -y 5.3.0 && \
    eval $(opam env) && \
    opam repository add opam-acsl mono/opam && \
    opam pin add -y containers 3.12 && \
    opam pin add -y pds 6.54 --no-depexts && \
    opam pin add -y hll 4.3 --no-depexts && \
    mkdir -p opam-mono/compilers opam-mono/packages && \
    echo 'opam-version: "2.0"' > opam-mono/repo && \
    opam repository add opam-mono opam-mono && \
    cd /mono/code && \
    hll generate \
      -n monorepo \
      --opam-dir ../../opam-mono \
      --tag 1.0 \
      --test-deps-as-regular-deps \
      --url-override file://$PWD && \
    opam update opam-mono && \
    opam info monorepo && \
    opam install -j$(nproc --all) -y --deps-only --no-depexts monorepo && \
    ulimit -s 524288 && ulimit -a && \
    time pds -d && \
    time make -j$(nproc --all) release-terrat && \
    mv build /build-cache

# Use provided BASE_IMAGE if specified, otherwise use the build-base stage
FROM ${BASE_IMAGE:-build-base} AS build-setup

# Copy source files
RUN rm -rfv /mono
COPY ./ /mono

# Build target for code-indexer
FROM build-setup AS code-indexer-build
WORKDIR /mono/code
RUN ulimit -s 524288 && ulimit -a && \
    mv /build-cache ./build && \
    eval $(opam env) && pds && \
    (time make -j$(nproc --all) -k release_terrat_code_indexer test \
        || time make -j1 release_terrat_code_indexer test) && \
    find . -name '*.tap' -exec cat '{}' \;

# Build target for terrat-ee
FROM build-setup AS terrat-ee-build
WORKDIR /mono/code
RUN ulimit -s 524288 && ulimit -a && \
    mv /build-cache ./build && \
    eval $(opam env) && pds && \
    (time make -j$(nproc --all) -k test release_terrat_ee release_iris \
     || time make -j1 test release_terrat_ee release_iris) && \
    find . -name '*.tap' -exec cat '{}' \;

# Build target for terrat-oss
FROM build-setup AS terrat-oss-build
WORKDIR /mono/code
RUN ulimit -s 524288 && ulimit -a && \
    mv /build-cache ./build && \
    eval $(opam env) && pds && \
    (time make -j$(nproc --all) -k test release_terrat_oss release_iris \
     || time make -j1 test release_terrat_oss release_iris) && \
    find . -name '*.tap' -exec cat '{}' \;

# Final code-indexer image
FROM alpine:3.18 AS code-indexer
COPY --from=code-indexer-build /mono/code/build/release/terrat_code_indexer/terrat_code_indexer.native /usr/local/bin/terrat_code_indexer
WORKDIR /mnt
ENTRYPOINT ["/usr/local/bin/terrat_code_indexer"]

# Final terrat-ee image
FROM alpine:3.18 AS terrat-ee
RUN apk add --no-cache \
    bash \
    curl \
    gettext \
    gmp \
    jq \
    libffi \
    libretls \
    nginx \
    py3-cryptography \
    py3-jwt \
    py3-requests \
    py3-yaml \
    python3 \
    runit \
    strace \
    yj
RUN mkdir -p /usr/local/bin /etc/service/terrat /etc/service/nginx /usr/local/share/terrat/ui/assets
COPY docker/terrat/service/terrat /etc/service/terrat/run
COPY docker/terrat/service/nginx /etc/service/nginx/run
COPY docker/terrat/nginx.conf.template /etc/nginx/nginx.conf.template
COPY --from=terrat-ee-build /usr/lib/libkqueue.so /usr/lib/libkqueue.so
COPY --from=terrat-ee-build /usr/lib/libkqueue.so.0 /usr/lib/libkqueue.so.0
COPY --from=terrat-ee-build /mono/code/build/release/terrat_ee/terrat_ee.native /usr/local/bin/terrat
COPY --from=terrat-ee-build /mono/code/build/release/iris/dist/ /usr/local/share/terrat/ui/assets/
EXPOSE 8080
CMD ["runsvdir", "/etc/service"]

# Final terrat-oss image
FROM alpine:3.18 AS terrat-oss
RUN apk add --no-cache \
    bash \
    curl \
    gettext \
    gmp \
    jq \
    libffi \
    libretls \
    nginx \
    py3-cryptography \
    py3-jwt \
    py3-requests \
    py3-yaml \
    python3 \
    runit \
    strace \
    yj
RUN mkdir -p /usr/local/bin /etc/service/terrat /etc/service/nginx /usr/local/share/terrat/ui/assets
COPY docker/terrat/service/terrat /etc/service/terrat/run
COPY docker/terrat/service/nginx /etc/service/nginx/run
COPY docker/terrat/nginx.conf.template /etc/nginx/nginx.conf.template
COPY --from=terrat-oss-build /usr/lib/libkqueue.so /usr/lib/libkqueue.so
COPY --from=terrat-oss-build /usr/lib/libkqueue.so.0 /usr/lib/libkqueue.so.0
COPY --from=terrat-oss-build /mono/code/build/release/terrat_oss/terrat_oss.native /usr/local/bin/terrat
COPY --from=terrat-oss-build /mono/code/build/release/iris/dist/ /usr/local/share/terrat/ui/assets/
EXPOSE 8080
CMD ["runsvdir", "/etc/service"]
