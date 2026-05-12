{
  pkgs ? import ../default/pkgs.nix,
}:

pkgs.runCommand "mk-xctoolchain-swiftc" { } ''
  mkdir -p $out/usr/bin $out/usr/lib/swift $out/nix-support
  ln -s ${pkgs.darwin.xcode}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc $out/usr/bin/swiftc
  ln -s ${pkgs.darwin.xcode}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx $out/usr/lib/swift/macosx
  mkdir -p $out/bin
  ln -s $out/usr/bin/swiftc $out/bin/swiftc
  echo "export SDKROOT=${pkgs.darwin.xcode}/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk" > $out/nix-support/setup-hook
''
