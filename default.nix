# tint — colouriser for command-line programs that print plain text.
#
# Packaging only. The design, the modes and the measured numbers live in
# README.md and docs/design.md.
{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "tint";
  version = (lib.importTOML ./Cargo.toml).package.version;

  # Keep build outputs, screenshots and the flake out of the store copy.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Colouriser for command-line program output (scanners + rulesets, no dependencies)";
    homepage = "https://github.com/neg-serg/tint";
    license = lib.licenses.mit;
    mainProgram = "tint";
    platforms = lib.platforms.unix;
  };
}
