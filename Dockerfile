ARG debian=buster
ARG go=1.14
ARG grpc=1.35
ARG buf_version=0.36.0
ARG grpc_web=1.2.1

FROM  grpckit/grpckit:1.35_0 AS grpckitbuild


FROM thethingsindustries/protoc AS thethingsindustriesprotoc
FROM rust AS rustdocker
RUN cargo install protobuf-codegen

FROM debian:$debian-slim AS grpckit
RUN mkdir -p /usr/share/man/man1
RUN set -ex && apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    zlib1g \
    libssl1.1

WORKDIR /workspace

COPY --from=thethingsindustriesprotoc /usr/bin/ /usr/local/bin/
COPY --from=thethingsindustriesprotoc /usr/include/ /usr/include/
COPY --from=grpckitbuild /usr/local/bin/ /usr/local/bin/
COPY --from=grpckitbuild /usr/local/include/ /usr/local/include/
COPY --from=grpckitbuild /usr/local/lib/ /usr/local/lib/
COPY --from=grpckitbuild /usr/local/share/ /usr/local/share/
COPY --from=rustdocker /usr/local/cargo/bin/protoc-gen-rust /usr/local/bin/protoc-gen-rust
# NB(MLH) We shouldn't need to copy these to include, as protofiles should be sourced elsewhere
# COPY --from=build /go/src/github.com/envoyproxy/protoc-gen-validate/ /opt/include/github.com/envoyproxy/protoc-gen-validate/
# COPY --from=build /go/src/github.com/mwitkow/go-proto-validators/ /opt/include/github.com/mwitkow/go-proto-validators/

# protoc
FROM grpckit AS protoc
ENTRYPOINT [ "protoc" ]

# buf
FROM grpckit AS buf
ENTRYPOINT [ "buf" ]

# omnikit
FROM grpckit AS omniproto
ENTRYPOINT [ "omniproto" ]

FROM grpckit
