# Build Scripts

## Why not just use nix?

It's necessary to produce binaries which are statically-linked with muslc as
they can be used on all distros of linux (including distros that don't link
with the gnu linker such as alpine and nixos). While it's possible to also
produce MacOS binaries with the same nix derivations, we found that aarch64
binaries for MacOS don't work correctly when built with nix due to [this
issue](https://discuss.ocaml.org/t/corrupted-compiled-interface-after-dune-build/14919).
