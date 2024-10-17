{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlays.url = "github:nix-ocaml/nix-overlays";
  };

  outputs = { self, nixpkgs, flake-utils, ocaml-overlays, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs { inherit system; }).appendOverlays
          [ ocaml-overlays.overlays.default ];
        fixMissingStripInOcaml_5_2 =
          # The ocaml.5.2.0 derivation is missing a depenency on the "strip"
          # program when cross compiling with muslc, so this overlay adds a
          # dependency on binutils which contains that program.
          (self: super: {
            ocaml-ng = super.ocaml-ng // {
              ocamlPackages_5_2 = super.ocaml-ng.ocamlPackages_5_2.overrideScope
                (oself: osuper: {
                  ocaml = osuper.ocaml.overrideAttrs {
                    nativeBuildInputs = osuper.ocaml.nativeBuildInputs
                      ++ [ pkgs.pkgsCross.musl64.binutils ];
                  };
                });
            };
          });
        pkgsStatic =
          (import nixpkgs { inherit system; }).pkgsCross.musl64.appendOverlays [
            ocaml-overlays.overlays.default
            fixMissingStripInOcaml_5_2
          ];
        sha256ByVersion = {
          "1.18.0" = "sha256-tZ2kPM/S/9J3yeX2laDjnHLA144b8svy9iwae32nXwM=";
          "1.19.0" = "sha256-54PZ8af4nOG/TJFIqjSiKDaL0Um7zKQ96AtFkiHe5ew=";
        };
        ocamllspPackage = { version, ocamlPackages, isStatic }:
          let
            tarballName = "lsp-${version}.tbz";
            src = pkgs.fetchurl {
              url =
                "https://github.com/ocaml/ocaml-lsp/releases/download/${version}/${tarballName}";
              sha256 = sha256ByVersion."${version}";
            };
            lsp = ocamlPackages.buildDunePackage {
              pname = "lsp";
              inherit src version;
              buildInputs = with ocamlPackages; [
                jsonrpc
                ppx_yojson_conv_lib
                uutf
                yojson
              ];
            };
          in (ocamlPackages.buildDunePackage {
            pname = "ocaml-lsp-server";
            inherit src version;
            buildInputs = with ocamlPackages; [
              astring
              base
              camlp-streams
              chrome-trace
              dune-build-info
              dune-rpc
              fiber
              jsonrpc
              lsp
              merlin-lib
              ocamlc-loc
              ocamlformat-rpc-lib
              ppx_yojson_conv_lib
              re
              spawn
              stdune
              uutf
              yojson
            ];
          }).overrideAttrs {
            patches = if isStatic then [ ./static.diff ] else [ ];
            postInstall = ''
              find $out -type f -executable -exec chmod +w {} +
              find $out -type f -executable -exec ${pkgs.binutils}/bin/strip --strip-all {} +
              find $out -type f -executable -exec chmod a-w {} +
            '';
          };
        staticPackages = with pkgsStatic.ocaml-ng; {
          ocaml_lsp_server_1_19_0_ocaml_5_2_0_static = ocamllspPackage {
            version = "1.19.0";
            ocamlPackages = ocamlPackages_5_2;
            isStatic = true;
          };
        };
        dynamicPackages = with pkgs.ocaml-ng; {
          ocaml_lsp_server_1_19_0_ocaml_5_2_0_dynamic = ocamllspPackage {
            version = "1.19.0";
            ocamlPackages = ocamlPackages_5_2;
            isStatic = false;
          };
        };
      in { packages = staticPackages // dynamicPackages; });
}
