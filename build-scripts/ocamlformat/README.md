# Build scripts for ocamlformat

The shell scripts build dynamically-linked binaries of ocamlformat, suitable for
macOS (provided they were built on macOS of course). The dockerfiles build
statically-linked binaries suitable for linux, regardless of distro.

## Dockerfile

Creates a package archive containing a statically-linked `ocamlformat` and
`ocamlformat-rpc` binary in the `out` directory (which will be created if
necessary).

Example usage:
```
$ docker buildx build . --target=export --output type=local,dest=$(pwd)/out/ --build-arg TAG=2024-11-21.0 --build-arg TARGET=x86_64-unknown-linux-musl --build-arg OCAML_VERSION=5.1.1 --build-arg OCAMLFORMAT_VERSION=1.18.0

```

## build.sh

Creates a package archive containing a dynamically-linked `ocamlformat` and
`ocamlformat-rpc` binary at the absolute path specified by `$OUTPUT`.

Example usage:
```
$ TAG=2024-11-21.0 TARGET=aarch64-apple-darwin OCAML_VERSION=5.1.1 OCAMLFORMAT_VERSION=0.26.2 OUTPUT=$(pwd)/ocamlformat.0.26.2+binary-ocaml-5.1.1-built-2024-11-21.0-aarch64-apple-darwin.tar.gz ./build.sh
```
