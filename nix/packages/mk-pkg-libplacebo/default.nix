{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "libplacebo";
  packageLock = (import ../../../packages.lock.nix).${name};
  gladLock = (import ../../../packages.lock.nix).libplaceboGlad;
  jinjaLock = (import ../../../packages.lock.nix).libplaceboJinja;
  markupsafeLock = (import ../../../packages.lock.nix).libplaceboMarkupSafe;
  fastFloatLock = (import ../../../packages.lock.nix).libplaceboFastFloat;
  vulkanHeadersLock = (import ../../../packages.lock.nix).libplaceboVulkanHeaders;
  inherit (packageLock) version;

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };
  gladSrc = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-glad-source-${gladLock.version}";
    inherit (gladLock) url sha256;
  };
  jinjaSrc = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-jinja-source-${jinjaLock.version}";
    inherit (jinjaLock) url sha256;
  };
  markupsafeSrc = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-markupsafe-source-${markupsafeLock.version}";
    inherit (markupsafeLock) url sha256;
  };
  fastFloatSrc = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-fast-float-source-${fastFloatLock.version}";
    inherit (fastFloatLock) url sha256;
  };
  vulkanHeadersSrc = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-vulkan-headers-source-${vulkanHeadersLock.version}";
    inherit (vulkanHeadersLock) url sha256;
  };
  patchedSource = pkgs.runCommand "${pname}-patched-source-${version}" { } ''
    cp -r ${src} src
    chmod -R 777 src

    rm -rf src/3rdparty/glad src/3rdparty/jinja src/3rdparty/markupsafe src/3rdparty/fast_float src/3rdparty/Vulkan-Headers
    cp -r ${gladSrc} src/3rdparty/glad
    cp -r ${jinjaSrc} src/3rdparty/jinja
    cp -r ${markupsafeSrc} src/3rdparty/markupsafe
    cp -r ${fastFloatSrc} src/3rdparty/fast_float
    cp -r ${vulkanHeadersSrc} src/3rdparty/Vulkan-Headers

    cp -r src $out
  '';
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  pname = pname;
  inherit version;
  src = patchedSource;
  dontUnpack = true;
  enableParallelBuilding = true;
  nativeBuildInputs = [
    pkgs.git
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pkgs.python3
  ];
  configurePhase = ''
    meson setup build $src \
      --native-file ${nativeFile} \
      --cross-file ${crossFile} \
      --prefix=$out \
      -Ddefault_library=shared \
      -Dvulkan=disabled \
      -Dvk-proc-addr=disabled \
      -Dvulkan-registry= \
      -Dopengl=enabled \
      -Dgl-proc-addr=disabled \
      -Dd3d11=disabled \
      -Dglslang=disabled \
      -Dshaderc=disabled \
      -Dlcms=disabled \
      -Ddovi=disabled \
      -Dlibdovi=disabled \
      -Ddemos=false \
      -Dtests=false \
      -Dbench=false \
      -Dfuzz=false \
      -Dunwind=disabled \
      -Dxxhash=disabled \
      -Ddebug-abort=false
  '';
  buildPhase = ''
    meson compile -vC build
  '';
  installPhase = ''
    meson install -C build
  '';
}
