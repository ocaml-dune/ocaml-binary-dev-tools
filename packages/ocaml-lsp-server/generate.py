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
        return "ocaml-lsp-server.{source_version}+binary-ocaml-{ocaml_version}-built-{tag}-{target_triple}".format(
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
name: "ocaml-lsp-server"
synopsis: "LSP Server for OCaml"
description: "An LSP server for OCaml."
maintainer: "Rudi Grinberg <me@rgrinberg.com>"
authors: [
  "Andrey Popp <8mayday@gmail.com>"
  "Rusty Key <iam@stfoo.ru>"
  "Louis Roché <louis@louisroche.net>"
  "Oleksiy Golovko <alexei.golovko@gmail.com>"
  "Rudi Grinberg <me@rgrinberg.com>"
  "Sacha Ayoun <sachaayoun@gmail.com>"
  "cannorin <cannorin@gmail.com>"
  "Ulugbek Abdullaev <ulugbekna@gmail.com>"
  "Thibaut Mattio <thibaut.mattio@gmail.com>"
  "Max Lantas <mnxndev@outlook.com>"
]
license: "ISC"
homepage: "https://github.com/ocaml/ocaml-lsp"
bug-reports: "https://github.com/ocaml/ocaml-lsp/issues"
install: [
  [ "find" "." "-type" "d" "-exec" "mkdir" "-p" "%%{prefix}%%/{}" ";" ]
  [ "find" "." "-type" "f" "-exec" "cp" "{}" "%%{prefix}%%/{}" ";" ]
]
dev-repo: "git+https://github.com/ocaml/ocaml-lsp.git"
available: arch = "%(opam_arch)s" & os = "%(opam_os)s"
conflicts: "ocaml" {!= "%(ocaml_version)s"}
%(url_opam_block)s""" % dict(
            opam_arch=self.opam_arch(),
            opam_os=self.opam_os(),
            ocaml_version=self.ocaml_version,
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
        ("1.18.0", "5.1.1"),
        ("1.19.0", "5.2.0"),
        ("1.19.0", "5.2.1"),
    ]
]

for v in versions:
    print(v.name())
    v.make()
