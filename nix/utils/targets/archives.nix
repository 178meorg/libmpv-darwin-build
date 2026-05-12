let
  formats = import ../constants/formats.nix;
  libs = import ./libs-frameworks.nix;
in

(builtins.map (target: {
  format = formats.libs;
  inherit (target) os arch;
}) libs)
