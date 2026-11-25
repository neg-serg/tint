{
  description = "tint — fast colouriser for command-line program output";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c5688f72f465acd2dc53167e410f19fd599a9533";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./default.nix { };
          tint = self.packages.${system}.default;
        }
      );

      overlays.default = final: _prev: {
        tint = final.callPackage ./default.nix { };
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
