{
  description = "Zig development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zig-overlay }:
    let
      system = "x86_64-linux";  # Adjust this for your system
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ zig-overlay.overlays.default ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          zigpkgs.master  # Use the latest nightly build
          # Add other tools you need for Zig development
          zls  # Zig Language Server
        ];

        shellHook = ''
          echo "Zig development environment loaded"
          echo "Zig version: $(zig version)"
        '';
      };
    };
}
