{ stdenv
, cmake
, fetchTritonPatch
, fetchurl
, ninja
, perl
, python
, swig

, libedit
, libffi
, libtirpc
, libxml2
, ncurses
, zlib

, channel
}:

let
  sources = import ./sources.nix;

  inherit (sources."${channel}")
    version
    patches
    srcs;

  gcc = if stdenv.cc.isGNU then stdenv.cc.cc else stdenv.cc.cc.gcc;

  inherit (stdenv.lib)
    flip
    makeOverridable
    mapAttrsToList
    replaceChars;

  srcs' = flip mapAttrsToList srcs (n: d:
    let
      version' = d.version or version;
    in makeOverridable fetchurl {
      urls = map (u: "${u}/${replaceChars ["-"] ["/"] version'}/${n}-${replaceChars ["-"] [""] version'}.src.tar.xz") [
        "https://distfiles.macports.org/llvm"
        "http://llvm.org/releases"
        "http://llvm.org/pre-releases"
      ];
      inherit (d) sha256;
    }
  );
in
stdenv.mkDerivation {
  name = "llvm-${version}";

  srcs = flip map srcs' (src: src.override {
    hashOutput = false;
  });

  sourceRoot = "llvm-${replaceChars ["-"] [""] version}.src";

  nativeBuildInputs = [
    cmake
    ninja
    perl
    python
    swig
  ];

  buildInputs = [
    libedit
    libffi
    libtirpc
    libxml2
    ncurses
    zlib
  ];

  prePatch = ''
    mkdir -p projects
    ls .. \
      | grep '[0-9]\.[0-9]\.[0-9]' \
      | grep -v 'llvm' \
      | sed 's,\(.*\)-[0-9]\.[0-9]\.[0-9]\(\|rc[0-9]\).src$,../\0 projects/\1,g' \
      | xargs -n 2 mv
    mv projects/cfe tools/clang
    mv projects/clang-tools-extra tools/clang/tools/extra
  '';

  patches = map (d: fetchTritonPatch d) patches;

  # Remove impurities from llvm-config
  postPatch = ''
    sed -i 's,@LLVM_.*_ROOT@,/no-such-path,g' tools/llvm-config/BuildVariables.inc.in
  '';

  cmakeFlags = with stdenv; [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_CXX_FLAGS=-std=c++11"

    "-DLLVM_INCLUDE_EXAMPLES=OFF"
    "-DLLVM_BUILD_TESTS=ON"
    "-DLLVM_ENABLE_RTTI=ON"
    "-DLLVM_INSTALL_UTILS=ON"  # Needed by rustc
    "-DLLVM_ENABLE_FFI=ON"

    # Not sure why these are needed
    "-DGCC_INSTALL_PREFIX=${gcc}"
    "-DC_INCLUDE_DIRS=${stdenv.cc.libc}/include"

    "-DLIBCXXABI_USE_LLVM_UNWINDER=ON"

    # TODO: Figure out how to make the single shared library work
    # for external builds
    "-DLLVM_BUILD_LLVM_DYLIB=ON"
    "-DLLVM_LINK_LLVM_DYLIB=ON"
  ];

  doCheck = true;

  preBuild = ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I$(pwd)/tools/clang/include"
  '';

  passthru = {
    isClang = true;
    inherit gcc;

    srcsVerification = flip map srcs' (src: src.override {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprints = [
        "11E5 21D6 4698 2372 EB57  7A1F 8F08 71F2 0211 9294"
        "B6C8 F982 82B9 44E3 B0D5  C253 0FC3 042E 345A D05D"
      ];
    });
  };

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
