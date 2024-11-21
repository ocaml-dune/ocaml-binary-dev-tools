FROM alpine:3.20.3 AS build

ARG TAG
ARG TARGET
ARG OCAML_VERSION
ARG OCAML_LSP_SERVER_VERSION

ENV PACKAGE=ocaml-lsp-server
ENV ARCHIVE_NAME="$PACKAGE.$OCAML_LSP_SERVER_VERSION+binary-ocaml-$OCAML_VERSION-built-$TAG-$TARGET"

RUN apk update && apk add \
    clang \
    make \
    opam \
    bash \
    rsync \
    gzip \
    ;

ENV USERNAME=user
ENV HOME=/home/$USERNAME
RUN adduser -D $USERNAME
USER $USERNAME
WORKDIR $HOME

RUN opam init --disable-sandboxing --auto-setup --bare

# Build ocamllsp
RUN mkdir switch
WORKDIR switch
RUN opam switch create . "ocaml.$OCAML_VERSION"
RUN opam install -y --deps-only "$PACKAGE.$OCAML_LSP_SERVER_VERSION"
RUN opam source "$PACKAGE.$OCAML_LSP_SERVER_VERSION" --dir=app
WORKDIR app
COPY statically-link.diff ./statically-link.diff
RUN patch -p1 < statically-link.diff
RUN opam install -y "./$PACKAGE.opam"

# Make the package
RUN mkdir -p "$ARCHIVE_NAME/bin"
RUN cp ../_opam/bin/ocamllsp "$ARCHIVE_NAME/bin"
COPY static/README.md "$ARCHIVE_NAME/README.md"
RUN mkdir -p out
RUN tar -cvf "out/$ARCHIVE_NAME.tar" "$ARCHIVE_NAME"
RUN gzip -9 "out/$ARCHIVE_NAME.tar"


FROM scratch AS export
COPY --from=build /home/user/switch/app/out /
