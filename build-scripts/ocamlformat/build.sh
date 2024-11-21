#!/bin/sh
set -eu

TMP_DIR="$(mktemp -d -t ocaml-binary-packages-build.XXXXXXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"
opam switch create . "ocaml.$OCAML_VERSION"
eval "$(opam env)"
opam install -y "ocamlformat.$OCAMLFORMAT_VERSION"

ARCHIVE_NAME="ocamlformat.$OCAMLFORMAT_VERSION+binary-ocaml-$OCAML_VERSION-built-$TAG-$TARGET"

mkdir -p "$ARCHIVE_NAME/bin"
cp _opam/bin/ocamlformat "$ARCHIVE_NAME/bin"
cp _opam/bin/ocamlformat-rpc "$ARCHIVE_NAME/bin"
cat > "$ARCHIVE_NAME/README.md" <<EOF
# ocamlformat binary distribution

See https://github.com/ocaml-dune/ocaml-binary-packages for more information.
EOF
tar --format=posix -cvf "$ARCHIVE_NAME.tar" "$ARCHIVE_NAME"
gzip -9 "$ARCHIVE_NAME.tar"
mv "$ARCHIVE_NAME.tar.gz" $OUTPUT
