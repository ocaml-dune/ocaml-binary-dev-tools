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

## Adding a new version of a package

We'll use the release of `ocaml-lsp-server.1.20.0` as an example here. This is
a list of steps for making the binary versions of this package available.

1. Add entries to the `strategy.matrix.include` list for the
   `ocaml-lsp-server-build-script` _and_ `ocaml-lsp-server-dockerfile` jobs in
   the file `.github/workflows/build.yml`. Each package has two different jobs -
   one that builds the packages natively for MacOS, and another that builds the
   packages in a docker container for Linux (this makes it easier to distribute
   statically-linked binaries on Linux). Each entry in the `include` lists
   specifies a package version (`version`) and an OCaml version (`ocaml`). For
   ocamllsp specifically it's useful to build each version of the package with
   as many different versions of the compiler as possible since the ocamllsp
   executable can only analyze code that was compiled with the same version of
   the compiler as itself. Find out which versions of the compiler are
   supported by running `opam show ocamllsp.1.20.0`.

   In this case, the new entries were:
```
jobs:
  ocaml-lsp-server-build-script:
    ...
          - os: macos-14
            version: "1.20.0"
            ocaml: "5.2.1"
            target_triple: aarch64-apple-darwin
          - os: macos-13
            version: "1.20.0"
            ocaml: "5.2.1"
            target_triple: x86_64-apple-darwin
          - os: macos-14
            version: "1.20.0"
            ocaml: "5.2.0"
            target_triple: aarch64-apple-darwin
          - os: macos-13
            version: "1.20.0"
            ocaml: "5.2.0"
            target_triple: x86_64-apple-darwin

  ocaml-lsp-server-dockerfile:
    ...
          - os: ubuntu-latest
            version: "1.20.0"
            ocaml: "5.2.1"
            target_triple: x86_64-unknown-linux-musl
          - os: ubuntu-latest
            version: "1.20.0"
            ocaml: "5.2.0"
            target_triple: x86_64-unknown-linux-musl
```

2. Trigger a build of all binary packages by pushing a new tag to [this repo](https://github.com/ocaml-dune/ocaml-binary-packages).
   Name the tag `<date>.<count>` where `date` is today's date in `YYYY-MM-DD`,
   and `count` is how many times a tag has been pushed to the repo on the
   current day (ie. the number of the release starting from 0). So the second
   release on `2024-12-12` would have a tag named `2024-12-12.1`. Push to your
   own fork of the repo if you want to do experiments with the build scripts.

3. Create the opam files for the new packages. Opam files are generated with
   python scripts inside the `packages/<package>` directory for each package.
   The scripts have a `versions` list which contains all the different opam
   versions of the package. There are potentially many versions of each package
   because a there's a different versions for each OS, arch, and package
   version, and in ocamllsp's case for each compiler version. Add the new
   versions of the package to the `versions` list (programatically of course).
