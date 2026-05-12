{
  pkgs ? import ../utils/default/pkgs.nix,
}:

import ./mk-out-archive/default.nix {
  inherit pkgs;
  format = (import ../utils/constants/formats.nix).libs;
  os = (import ../utils/constants/oses.nix).macos;
  arch = (import ../utils/constants/archs.nix).universal;
  variant = (import ../utils/constants/variants.nix).video;
  flavor = (import ../utils/constants/flavors.nix).default;
}
