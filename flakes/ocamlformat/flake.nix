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
          # The ocaml.5.2.0 derivation is missing a dependency on the "strip"
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
          "0.19.0" = "0ihgwl7d489g938m1jvgx8azdgq9f5np5mzqwwya797hx2m4dz32";
          "0.20.0" = "sha256-JtmNCgwjbCyUE4bWqdH5Nc2YSit+rekwS43DcviIfgk=";
          "0.20.1" = "sha256-fTpRZFQW+ngoc0T6A69reEUAZ6GmHkeQvxspd5zRAjU=";
          "0.21.0" = "sha256-KhgX9rxYH/DM6fCqloe4l7AnJuKrdXSe6Y1XY3BXMy0=";
          "0.22.4" = "sha256-61TeK4GsfMLmjYGn3ICzkagbc3/Po++Wnqkb2tbJwGA=";
          "0.23.0" = "sha256-m9Pjz7DaGy917M1GjyfqG5Lm5ne7YSlJF2SVcDHe3+0=";
          "0.24.0" = "sha256-Zil0wceeXmq2xy0OVLxa/Ujl4Dtsmc4COyv6Jo7rVaM=";
          "0.24.1" = "sha256-AjQl6YGPgOpQU3sjcaSnZsFJqZV9BYB+iKAE0tX0Qc4=";
          "0.25.1" = "sha256-3I8qMwyjkws2yssmI7s2Dti99uSorNKT29niJBpv0z0=";
          "0.26.0" = "sha256-AxSUq3cM7xCo9qocvrVmDkbDqmwM1FexEP7IWadeh30=";
          "0.26.1" = "sha256-2gBuQn8VuexhL7gI1EZZm9m3w+4lq+s9VVdHpw10xtc=";
          "0.26.2" = "sha256-Lk9Za/eqNnqET+g7oPawvxSyplF53cCCNj/peT0DdcU=";
        };
        ocamlformatPackage = { version, ocamlPackages, isStatic, strip }:
          let
            tarballName = "ocamlformat-${version}.tbz";
            src = pkgs.fetchurl {
              url =
                "https://github.com/ocaml-ppx/ocamlformat/releases/download/${version}/${tarballName}";
              sha256 = sha256ByVersion."${version}";
            };
            ocamlformat-lib = ocamlPackages.buildDunePackage {
              pname = "ocamlformat-lib";
              inherit src version;
              nativeBuildInputs = with ocamlPackages; [ menhir ];
              buildInputs = with ocamlPackages; [
                astring
                camlp-streams
                cmdliner
                dune-build-info
                either
                fpath
                fix
                menhirLib
                menhirSdk
                ocaml-version
                ocp-indent
                result
                stdio
                uuseg
              ];
            };
          in (ocamlPackages.buildDunePackage {
            pname = "ocamlformat";
            inherit src version;
            buildInputs = with ocamlPackages; [
              camlp-streams
              cmdliner
              csexp
              dune-build-info
              either
              fpath
              menhirLib
              ocamlformat-lib
              ocaml-version
              ocp-indent
              re
              result
              stdio
              uuseg
            ];
          }).overrideAttrs {
            patches = if isStatic then [ ./static.diff ] else [ ];
            postInstall = if strip then ''
              find $out -type f -executable -exec chmod +w {} +
              find $out -type f -executable -exec ${pkgs.binutils}/bin/strip --strip-all {} +
              find $out -type f -executable -exec chmod a-w {} +
            '' else
              "";
          };
        staticPackages = with pkgsStatic.ocaml-ng; {
          ocamlformat_0_26_2_ocaml_5_2_0_static = ocamlformatPackage {
            version = "0.26.2";
            ocamlPackages = ocamlPackages_5_2;
            isStatic = true;
            strip = true;
          };
          ocamlformat_0_26_2_ocaml_5_1_1_static = ocamlformatPackage {
            version = "0.26.2";
            ocamlPackages = ocamlPackages_5_1;
            isStatic = true;
            strip = true;
          };
          ocamlformat_0_26_2_ocaml_5_0_0_static = ocamlformatPackage {
            version = "0.26.2";
            ocamlPackages = ocamlPackages_5_0;
            isStatic = true;
            strip = true;
          };
        };
        dynamicPackages = with pkgs.ocaml-ng; {
          ocamlformat_0_26_2_ocaml_5_2_0_dynamic = ocamlformatPackage {
            version = "0.26.2";
            ocamlPackages = ocamlPackages_5_2;
            isStatic = false;
            strip =
              false; # stripping on macos produces executables that don't work
          };
          ocamlformat_0_26_2_ocaml_5_1_1_dynamic = ocamlformatPackage {
            version = "0.26.2";
            ocamlPackages = ocamlPackages_5_1;
            isStatic = false;
            strip =
              false; # stripping on macos produces executables that don't work
          };
          ocamlformat_0_26_2_ocaml_5_0_0_dynamic = ocamlformatPackage {
            version = "0.26.2";
            ocamlPackages = ocamlPackages_5_0;
            isStatic = false;
            strip =
              false; # stripping on macos produces executables that don't work
          };
        };
      in { packages = staticPackages // dynamicPackages; });
}
