{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "lua";
  packageLock = (import ../../../packages.lock.nix).${name};
  inherit (packageLock) version;

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  pname = pname;
  inherit version;
  inherit src;
  dontUnpack = true;
  enableParallelBuilding = true;
  nativeBuildInputs = [
    pkgs.pkg-config
  ];
  buildPhase = ''
    mkdir -p $out/lib $out/include $out/lib/pkgconfig

    cross_file=${crossFile}
    cc=$(sed -n "s/^c *= *'\\(.*\\)'/\\1/p" "$cross_file")
    cflags=$(sed -n "s/^c_args *= *\\[\\(.*\\)\\]/\\1/p" "$cross_file" | sed "s/', '/ /g; s/'//g; s/,/ /g")

    cd $src/src

    objs=$(printf '%s\n' *.c | rg -v '^(lua|luac)\\.c$')
    $cc $cflags -fPIC -c $objs
    $cc $cflags -dynamiclib -install_name @rpath/liblua.dylib -current_version ${version} -compatibility_version 5.2 -o liblua.dylib *.o -lm

    cat > lua5.2.pc <<EOF
prefix=$out
exec_prefix=''${prefix}
includedir=''${prefix}/include
libdir=''${prefix}/lib

Name: Lua
Description: An Extensible Extension Language
Version: ${version}
Libs: -L''${libdir} -llua
Cflags: -I''${includedir}
EOF

    cp lua5.2.pc lua.pc
    cp lua5.2.pc lua-5.2.pc

    cp liblua.dylib $out/lib/
    cp lua.h luaconf.h lualib.h lauxlib.h lua.hpp $out/include/
    cp lua.pc lua5.2.pc lua-5.2.pc $out/lib/pkgconfig/
  '';
  installPhase = "true";
}
