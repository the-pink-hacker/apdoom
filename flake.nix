{
  description = "Crispy Doom with Archipelago support";
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.05";
  };
  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        localSystem.system = system;
      });
  in {
    packages =
      lib.mapAttrs (system: pkgs: {
        crispy-apdoom = pkgs.clangStdenv.mkDerivation (finalAttrs: {
          pname = "crispy-apdoom";
          version = "1.2.0";
          src = pkgs.fetchFromGitHub {
            owner = "Daivuk";
            repo = "apdoom";
            tag = finalAttrs.version;
            hash = "sha256-uaMTXpuAUPkGpO0Bb2inb03ERQa6Tj6xed2Wh9v1XZw=";
          };

          postPatch = ''
            for script in $(grep -lr '^#!/usr/bin/env python3$'); do patchShebangs $script; done
          '';

          #configureFlags = lib.optional enableTruecolor [ "--enable-truecolor" ];

          nativeBuildInputs = with pkgs; [
            #autoreconfHook
            pkg-config
            python3
            cmake
          ];

          buildInputs = with pkgs; [
            libpng
            libsamplerate
            SDL2
            SDL2_mixer
            SDL2_net
            zlib
            openssl
            libGLU
            curl
          ];

          enableParallelBuilding = true;

          strictDeps = true;
          hardeningDisable = ["format"];

          meta = {
            homepage = "https://github.com/Daivuk/apdoom";
            changelog = "https://github.com/Daivuk/apdoom/releases/tag/crispy-doom-${finalAttrs.version}";
            description = "Crispy Doom with Archipelago support";
            mainProgram = "crispy-apdoom";
            license = lib.licenses.gpl2Plus;
            platforms = lib.platforms.unix;
          };
        });
        default = self.packages.${system}.crispy-apdoom;
      })
      pkgsFor;
    formatter = lib.mapAttrs (_: pkgs: pkgs.alejandra) pkgsFor;
    devShells =
      lib.mapAttrs (system: pkgs: {
        default = pkgs.mkShell.override {
            stdenv = pkgs.clangStdenv;
        } {
          inputsFrom = [self.packages.${system}.crispy-apdoom];
        };
      })
      pkgsFor;
    overlays.default = final: prev: {inherit (self.packages.${prev.ssytem}) crispy-apdoom;};
  };
}
