let
  oses = import ../constants/oses.nix;
  archs = import ../constants/archs.nix;
in
[
  {
    os = oses.macos;
    arch = archs.arm64;
  }
  {
    os = oses.macos;
    arch = archs.amd64;
  }
  {
    os = oses.macos;
    arch = archs.universal;
  }
]
