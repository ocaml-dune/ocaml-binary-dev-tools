#!/usr/bin/env python
import os
import tempfile
import pathlib
from dataclasses import dataclass, asdict
from urllib.request import urlretrieve
from hashlib import file_digest

aarch64_apple_darwin = "aarch64-apple-darwin"
x86_64_apple_darwin = "x86_64-apple-darwin"
x86_64_unknown_linux_musl = "x86_64-unknown-linux-musl"


@dataclass
class Version:
    tag: str
    source_version: str
    ocaml_version: str
    target_triple: str

    def opam_os(self) -> str:
        if self.target_triple == aarch64_apple_darwin:
            return "macos"
        if self.target_triple == x86_64_apple_darwin:
            return "macos"
        if self.target_triple == x86_64_unknown_linux_musl:
            return "linux"
        raise Exception("unknown target triple: %s" % self.target_triple)

    def opam_arch(self) -> str:
        if self.target_triple == aarch64_apple_darwin:
            return "arm64"
        if self.target_triple == x86_64_apple_darwin:
            return "x86_64"
        if self.target_triple == x86_64_unknown_linux_musl:
            return "x86_64"
        raise Exception("unknown target triple: %s" % self.target_triple)

    def name(self) -> str:
        return "ocamlformat.{source_version}+binary-ocaml-{ocaml_version}-built-{tag}-{target_triple}".format(
            **asdict(self)
        )

    def archive_name(self) -> str:
        return "%s.tar.gz" % self.name()

    def url(self) -> str:
        return "https://github.com/ocaml-dune/ocaml-binary-packages/releases/download/{tag}/{archive_name}".format(
            tag=self.tag, archive_name=self.archive_name()
        )

    def url_opam_block(self) -> str:
        path = os.path.join(tempfile.gettempdir(), self.archive_name())
        urlretrieve(self.url(), path)
        with open(path, "rb") as f:
            sha256 = file_digest(f, "sha256").hexdigest()
            f.seek(0)
            sha512 = file_digest(f, "sha512").hexdigest()
        lines = [
            "url {",
            '  src: "%s"' % self.url(),
            "  checksum: [",
            '    "sha256=%s"' % sha256,
            '    "sha512=%s"' % sha512,
            "  ]",
            "}",
        ]
        return "\n".join(lines)

    def opam_file(self) -> str:
        return """opam-version: "2.0"
name: "ocamlformat"
version: "%(source_version)s"
synopsis: "Auto-formatter for OCaml code"
description: \"""\\
**ocamlformat** is a code formatter for OCaml. It comes with opinionated default settings but is also fully customizable to suit your coding style.

- **Profiles:** ocamlformat offers profiles we predefined formatting configurations. Profiles include `default`, `ocamlformat`, `janestreet`.
- **Configurable:** Users can change the formatting profile and configure every option in their `.ocamlformat` configuration file.
- **Format Comments:** ocamlformat can format comments, docstrings, and even code blocks in your comments.
- **RPC:** ocamlformat provides an RPC server that can be used by other tools to easily format OCaml Code.\"""
maintainer: [
  "Guillaume Petiot <guillaume@tarides.com>"
  "Jules Aguillon <jules@j3s.fr>"
  "Emile Trotignon <emile@tarides.com>"
]
authors: [
  "Josh Berdine <jjb@fb.com>"
  "Hugo Heuzard <hugo.heuzard@gmail.com>"
  "Etienne Millon <etienne@tarides.com>"
  "Guillaume Petiot <guillaume@tarides.com>"
  "Jules Aguillon <jules@j3s.fr>"
]
license: ["MIT" "LGPL-2.1-only WITH OCaml-LGPL-linkiexception"]
homepage: "https://github.com/ocaml-ppx/ocamlformat"
bug-reports: "https://github.com/ocaml-ppx/ocamlformat/issues"
install: [
  [ "find" "." "-type" "d" "-exec" "mkdir" "-p" "%%{prefix}%%/{}" ";" ]
  [ "find" "." "-type" "f" "-exec" "cp" "{}" "%%{prefix}%%/{}" ";" ]
]
dev-repo: "git+https://github.com/ocaml-ppx/ocamlformat.git"
available: arch = "%(opam_arch)s" & os = "%(opam_os)s"
%(url_opam_block)s""" % dict(
            source_version=self.source_version,
            opam_arch=self.opam_arch(),
            opam_os=self.opam_os(),
            url_opam_block=self.url_opam_block(),
        )

    def make(self):
        pathlib.Path(self.name()).mkdir(parents=True, exist_ok=True)
        with open(os.path.join(self.name(), "opam"), "w") as f:
            f.write(self.opam_file())


versions = [
    Version(
        tag="2024-11-21.0",
        source_version=source_version,
        ocaml_version=ocaml_version,
        target_triple=target_triple,
    )
    for target_triple in [
        aarch64_apple_darwin,
        x86_64_apple_darwin,
        x86_64_unknown_linux_musl,
    ]
    for (source_version, ocaml_version) in [
        ("0.26.1", "5.1.1"),
        ("0.26.2", "5.2.1"),
    ]
]

for v in versions:
    print(v.name())
    v.make()
