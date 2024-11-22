# OCaml Binary Packages

Binary distributions of some OCaml packages.

This project contains:
 - `build-scripts` - shell scripts and dockerfiles for building packages
 - `packages` - opam package manifests for the packages in this repo

## How to use

Add this repo to the current opam switch:
```
$ opam repository add binary-packages git+https://github.com/ocaml-dune/ocaml-binary-packages
```

## Maintenance notes

Binary packages are automatically built and released on github when a tag of
this repo is pushed. The convention for naming tags is `<date>.<count>`, for
example `2024-10-17.3` would be the 4th release on 2024-10-17 (the count starts
at 0).

The version of the compiler used to build a package is included in its version
number. This is mostly so that packages that need binary versions to be
available from specific compiler versions (e.g. ocaml-lsp-server) can co-exist
in the repo, however it's also included for debugging purposes.

The tag of the release is also included in the version number for traceability.
