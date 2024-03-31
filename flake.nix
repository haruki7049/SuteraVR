{
  description = "An overlay for Godot";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.11";
    godot-overlay.url = "github:haruki7049/godot-overlay/ed1745ddebcf8acdc2b2d945189a9fab98036619";
    rust-overlay.url = "github:oxalica/rust-overlay";
    treefmt-nix.url = "github:haruki7049/treefmt-nix/gdformat";
  };

  outputs = { self, systems, nixpkgs, treefmt-nix, godot-overlay, rust-overlay }:
    let
      overlays = [
        (import rust-overlay)
        (import godot-overlay)
      ];
      pkgs = import nixpkgs {
        inherit overlays;
        system = "x86_64-linux";
      };
      rustVersion = "1.75.0";
      rust = pkgs.rust-bin.stable.${rustVersion}.default.override {
        extensions = [
          "rust-src"
          "rust-analyzer"
        ];
      };
      godotVersion = "4.2.1";
      godot = pkgs.godot-mono-bin.${godotVersion};
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
        (system: f nixpkgs.legacyPackages.${system});
      treefmtEval =
        eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in {
      # Use `nix fmt`
      formatter =
        eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      # Use `nix flake check`
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            godot
            rust
            dotnet-sdk
          ];
          shellHook = ''
            export "PS1=\n[nix-shell:\w]$ "
          '';
        };
      });
    };
}
