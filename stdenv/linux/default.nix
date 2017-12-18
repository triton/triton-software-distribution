# This file constructs the standard build environment for the
# Linux platform.  It's completely pure; that is, it relies on no
# external (non-Nix) tools, such as /usr/bin/gcc, and it contains a C
# compiler and linker that do not search in default locations,
# ensuring purity of components produced by it.

{ allPackages
, lib
, targetSystem
, hostSystem
, config
}:

let
  bootstrapSystem =
    if [ hostSystem ] == lib.platforms.x86_64-linux ||
        [ hostSystem ] == lib.platforms.i686-linux then
      lib.head lib.platforms.i686-linux
    else
      throw "Unsupported Configuration";

  bootstrap-files = import ./bootstrap.nix {
    inherit
      lib;
    targetSystem = bootstrapSystem;
  };

  bootstrap-tools = (derivation {
    name = "bootstrap-tools";

    builder = bootstrap-files.busybox;

    args = [
      "ash"
      "-e" ./unpack-bootstrap-tools.sh
    ];

    tarball = bootstrap-files.bootstrap-tools;

    outputs = [
      "out"
      "glibc"
    ];

    system = bootstrapSystem;
  }) // {
    inherit (bootstrap-files)
      isGNU;
    libc = bootstrap-tools.glibc;
    langAda = false;
    langFortran = false;
    langJava = false;
    langGo = false;
    langVhdl = false;
  };

  bootstrap-bash = "${bootstrap-tools}/bin/bash";

  bootstrap-hook = { name, bin, setupHook, extraCmd ? "" }: derivation {
    name = "bootstrap-tools-${name}";

    builder = bootstrap-bash;
    bootstrap = bootstrap-tools;

    args = [
      ./make-bootstrap-hook.sh
    ];

    inherit
      bin
      extraCmd
      setupHook;

    system = bootstrapSystem;
  };

  bootstrap-stdenv-tools = derivation {
    name = "bootstrap-stdenv-tools";

    builder = bootstrap-bash;
    bootstrap = bootstrap-tools;

    args = [
      ./make-bootstrap-stdenv-tools.sh
    ];

    system = bootstrapSystem;
  };

  srcOnly = pkg: {
    inherit (pkg)
      src;
  };

  commonStdenvOptions = a: a // {
    inherit
      config;
  };

  commonBootstrapOptions = a: a // {
    bash = bootstrap-bash;
    initialPath = [
      bootstrap-stdenv-tools
    ];
  };

  # This is not a real set of packages or stdenv.
  # This is just enough for us to use stdenv.mkDerivation to build our
  # first cc-wrapper and fetchurlBoot.
  # This does not provide any actual packages.
  stage0Pkgs = allPackages {
    inherit
      config;
    hostSystem = bootstrapSystem;
    targetSystem = bootstrapSystem;

    stdenv = import ../generic { inherit lib; } (commonStdenvOptions (commonBootstrapOptions {
      name = "bootstrap-stdenv-linux-stage0";

      hostSystem = bootstrapSystem;
      targetSystem = bootstrapSystem;

      overrides = pkgs: (lib.mapAttrs (n: _: throw "stage0Pkgs is missing package definition for `${n}`") pkgs) // rec {
        inherit (pkgs)
          stdenv
          lib
          fetchTritonPatch
          gcc
          gcc_unwrapped;

        fetchurl = pkgs.fetchurl.override {
          inherit (finalPkgs)
            stdenv
            curl
            openssl
            gnupg
            minisign
            signify;
        };

        bison = bootstrap-hook {
          name = "bison";
          bin = "bison";
          setupHook = pkgs.bison.setupHook;
          extraCmd = ''
            mkdir -p "$out"/share
            ln -sv "${bootstrap-tools}"/share/bison "$out"/share
          '';
        };

        gnumake = bootstrap-hook {
          name = "gnumake";
          bin = "make";
          setupHook = pkgs.gnumake.setupHook;
        };

        gnupatch = bootstrap-hook {
          name = "gnupatch";
          bin = "patch";
          setupHook = pkgs.gnupatch.setupHook;
        };

        gnutar = bootstrap-hook {
          name = "gnutar";
          bin = "tar";
          setupHook = pkgs.gnutar.setupHook;
        };

        xz = bootstrap-hook {
          name = "xz";
          bin = "xz";
          setupHook = pkgs.xz.setupHook;
        };

        gcc_unwrapped_7 = bootstrap-tools;

        gcc_7 = lib.makeOverridable (import ../../build-support/cc-wrapper) {
          name = "bootstrap-cc-wrapper-stage0";
          impureLibc = null;
          impurePrefix = null;
          cc = gcc_unwrapped_7;
          libc = bootstrap-tools.glibc;
          binutils = bootstrap-tools;
          coreutils = bootstrap-tools;
          inherit
            stdenv
            lib;
        };
      };
    }));
  };

  # This is the first package set which builds the cross toolchain
  # and any packages not needing the target compiler
  # This is primarily for building binutils
  stage1Pkgs = allPackages {
    inherit
      config;
    hostSystem = bootstrapSystem;
    targetSystem = bootstrapSystem;

    stdenv = import ../generic { inherit lib; } (commonStdenvOptions (commonBootstrapOptions {
      name = "bootstrap-stdenv-linux-stage1";

      hostSystem = bootstrapSystem;
      targetSystem = bootstrapSystem;

      overrides = pkgs: (lib.mapAttrs (n: _: throw "stage1Pkgs is missing package definition for `${n}`") pkgs) // rec {
        inherit (pkgs)
          stdenv
          lib
          gcc
          gcc_unwrapped;

        gcc_unwrapped_7 = pkgs.gcc_unwrapped_7.override {
          gmp = srcOnly pkgs.gmp;
          isl = srcOnly pkgs.isl_0-18;
          mpc = srcOnly pkgs.mpc;
          mpfr = srcOnly pkgs.mpfr;
          bootstrap = true;
          outputSystem = hostSystem;
        };

        gcc_7 = lib.makeOverridable (import ../../build-support/cc-wrapper) {
          impureLibc = null;
          impurePrefix = null;
          cc = gcc_unwrapped_7;
          libc = bootstrap-tools.glibc;
          binutils = binutils;
          coreutils = bootstrap-tools;
          name = "bootstrap-cc-wrapper-stage1";
          inherit
            stdenv
            lib;
        };

        # These should not be used outside of the bootstrapping binutils / gcc
        inherit (stage0Pkgs)
          fetchurl
          fetchTritonPatch
          gnumake
          gnupatch
          gnutar
          xz;
        inherit (pkgs)
          autotools;
        binutils = pkgs.binutils.override {
          bootstrap = true;
          outputSystem = hostSystem;
        };
      };
    }));
  };

  # This is the second cross compile stage
  # We use this for building glibc used in the rest of the cross compile stage
  stage2Pkgs = allPackages {
    inherit
      config;
    hostSystem = bootstrapSystem;
    targetSystem = hostSystem;

    stdenv = import ../generic { inherit lib; } (commonStdenvOptions (commonBootstrapOptions {
      name = "bootstrap-stdenv-linux-stage2";

      cc = stage1Pkgs.gcc;
      hostSystem = bootstrapSystem;
      targetSystem = hostSystem;

      extraAttrs = {
        # stdenv.libc is used by GCC build to figure out the system-level
        # /usr/include directory.
        libc = stage2Pkgs.stdenv.cc.libc;
      };

      overrides = pkgs: (lib.mapAttrs (n: _: throw "stage2Pkgs is missing package definition for `${n}`") pkgs) // rec {
        inherit (pkgs)
          stdenv
          lib
          gcc
          gcc_unwrapped
          linux-headers
          linux-headers_4-9;

        glibc = pkgs.glibc.override {
          bootstrap = true;
        };

        gcc_unwrapped_7 = bootstrap-tools;

        gcc_7 = lib.makeOverridable (import ../../build-support/cc-wrapper) {
          impureLibc = null;
          impurePrefix = null;
          cc = gcc_unwrapped_7;
          libc = glibc;
          binutils = binutils;
          coreutils = bootstrap-tools;
          gnugrep = bootstrap-tools;
          name = "bootstrap-cc-wrapper-stage1";
          inherit stdenv;
        };

        # These should not be used outside of the bootstrapping binutils / gcc
        inherit (stage0Pkgs)
          fetchurl
          fetchTritonPatch;
        inherit (stage1Pkgs)
          binutils;
      };
    }));
  };

  # This is the first package set and real stdenv using only the bootstrap tools
  # for building.
  # This stage is used for building the bootstrap libc.
  stage3Pkgs = allPackages {
    inherit targetSystem hostSystem config;
    stdenv = import ../generic { inherit lib; } (commonStdenvOptions (commonBootstrapOptions {
      name = "bootstrap-stdenv-linux-stage3";
      cc = stage2Pkgs.gcc;
      extraBuildInputs = [
        stage0Pkgs.patchelf
      ];

      extraAttrs = {
        # stdenv.libc is used by GCC build to figure out the system-level
        # /usr/include directory.
        libc = stage3Pkgs.stdenv.cc.libc;
      };

      overrides = pkgs: (lib.mapAttrs (n: _: throw "stage3Pkgs is missing package definition for `${n}`") pkgs) // rec {
        inherit (pkgs) stdenv gcc gcc_unwrapped glibc;

        gcc_7 = lib.makeOverridable (import ../../build-support/cc-wrapper) {
          nativeLibc = null;
          nativePrefix = null;
          cc = gcc_unwrapped_7;
          libc = glibc;
          binutils = binutils;
          coreutils = bootstrap-tools;
          gnugrep = bootstrap-tools;
          name = "bootstrap-cc-wrapper-stage2";
          inherit stdenv;
        };

        # These should not be used outside of this stage
        inherit (stage0Pkgs) fetchurl fetchTritonPatch;
        inherit (stage1Pkgs) binutils linux-headers linux-headers_4-4;
        inherit (stage2Pkgs) gcc_unwrapped_7;
      };
    }));
  };

  # This is the second package set using the final glibc and bootstrap tools.
  # This stage is used for building the final gcc, which, and gnum4.
  # Propagates stage1 glibc and linux-headers.
  stage5Pkgs = allPackages rec {
    inherit targetSystem hostSystem config;
    stdenv = import ../generic { inherit lib; } (commonStdenvOptions // commonBootstrapOptions // {
      name = "bootstrap-stdenv-linux-stage2";
      cc = stage1Pkgs.gcc;
      extraBuildInputs = [ stage0Pkgs.patchelf ];

      extraAttrs = {
        # stdenv.libc is used by GCC build to figure out the system-level
        # /usr/include directory.
        libc = stage1Pkgs.glibc;
      };

      overrides = pkgs: (lib.mapAttrs (n: _: throw "stage2Pkgs is missing package definition for `${n}`") pkgs) // {
        inherit (stage1Pkgs) glibc linux-headers;
        inherit (pkgs) stdenv gnum4 which gettext elfutils gcc;
        bzip2 = pkgs.bzip2.override { static = true; shared = false; };
        libelf = pkgs.libelf.override { static = true; shared = false; };
        gmp = pkgs.gmp.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
        isl_0-18 = pkgs.isl_0-18.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
        libmpc = pkgs.libmpc.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
        mpfr = pkgs.mpfr.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
        xz = pkgs.xz.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
        zlib = pkgs.zlib.override { static = true; shared = false; };

        gcc7 = lib.makeOverridable (import ../../build-support/cc-wrapper) {
          nativeTools = false;
          nativeLibc = false;
          cc = pkgs.gcc7.cc.override {
            shouldBootstrap = true;
            libPathExcludes = [ "${bootstrap-tools}/lib"];
          };
          libc = stage1Pkgs.glibc;
          binutils = bootstrap-tools;
          coreutils = bootstrap-tools;
          gnugrep = bootstrap-tools;
          name = "bootstrap-cc-wrapper-stage2";
          stdenv = stage0Pkgs.stdenv;
        };

        # These are only needed to evaluate
        inherit (stage0Pkgs) fetchurl fetchTritonPatch patchelf;
        coreutils = bootstrap-tools;
        binutils = bootstrap-tools;
        gnugrep = bootstrap-tools;
        perl = null;
        texinfo = null;
      };
    });
  };


  # This is the third package set using the final gcc, glibc and bootstrap tools.
  # This stage is used for building the final versions of all stdenv utilities.
  stage10Pkgs = allPackages rec {
    inherit targetSystem hostSystem config;
    stdenv = import ../generic { inherit lib; } (commonStdenvOptions // commonBootstrapOptions // {
      name = "stdenv-linux-boot-stage3";
      cc = stage2Pkgs.gcc;
      extraBuildInputs = [ stage0Pkgs.patchelf ];

      extraAttrs = {
        # stdenv.libc is used by GCC build to figure out the system-level
        # /usr/include directory.
        libc = stage1Pkgs.glibc;
      };

      overrides = pkgs: (lib.mapAttrs (n: _: throw "stage3Pkgs is missing package definition for `${n}`") pkgs) // {
        pkgs = stage3Pkgs;
        inherit (stage1Pkgs) glibc linux-headers_4-4 linux-headers;
        inherit (stage2Pkgs) m4 gnum4 which;
        inherit (pkgs) stdenv lib gcc xz zlib attr acl gmp coreutils binutils
          gpm ncurses readline bash nghttp2_lib cryptodev_headers gettext bison flex
          openssl_1-1-0 openssl c-ares curl libsigsegv pcre findutils diffutils
          gnused gnugrep gawk gnutar gnutar_1-30 gzip brotli brotli_1-0-4 bzip2
          gnumake gnupatch pkgconf pkgconfig patchelf mpfr;

        gcc7 = lib.makeOverridable (import ../../build-support/cc-wrapper) {
          nativeTools = false;
          nativeLibc = false;
          cc = stage2Pkgs.gcc7.cc;
          libc = stage1Pkgs.glibc;
          binutils = stage3Pkgs.binutils;
          coreutils = stage3Pkgs.coreutils;
          gnugrep = stage3Pkgs.gnugrep;
          name = "cc-wrapper";
          stdenv = stage3Pkgs.stdenv;
          shell = stage3Pkgs.bash + "/bin/bash";
        };

        # Do not export these packages to the final stdenv
        inherit (stage0Pkgs) fetchurl fetchTritonPatch;
        libiconv = null;
        texinfo = pkgs.texinfo.override {
          interactive = false;
        };
        inherit (pkgs) perl autoconf automake perlPackages
          libtool buildPerlPackage help2man makeWrapper autoreconfHook nghttp2_full;
        jansson = null;
      };
    });
  };

  # Construct the final stdenv.  It uses the Glibc and GCC, and adds
  # in a new binutils that doesn't depend on bootstrap-tools, as well
  # as dynamically linked versions of all other tools.
  stdenv = import ../generic { inherit lib; } (commonStdenvOptions // rec {
    name = "stdenv-final";

    # We want common applications in the path like gcc, mv, cp, tar, xz ...
    initialPath = lib.attrValues ((import ../generic/common-path.nix) { pkgs = stage3Pkgs; });

    # We need patchelf to be a buildInput since it has to install a setup-hook.
    # We need pkgconfig to be a buildInput as it has aclocal files needed to
    # generate PKG_CHECK_MODULES.
    extraBuildInputs = with stage3Pkgs; [ patchelf pkgconfig ];

    cc = stage3Pkgs.gcc;

    shell = stage3Pkgs.gcc.shell;

    extraArgs = rec {
      stdenvDeps = stage3Pkgs.stdenv.mkDerivation {
        name = "stdenv-deps";
        buildCommand = ''
          mkdir -p $out
        '' + lib.flip lib.concatMapStrings extraAttrs.bootstrappedPackages' (n: ''
          [ -h "$out/$(basename "${n}")" ] || ln -s "${n}" "$out"
        '');
      };
      stdenvDepTest = stage3Pkgs.stdenv.mkDerivation {
        name = "stdenv-dep-test";
        buildCommand = ''
          mkdir -p $out
          ln -s "${stdenvDeps}" $out
        '';
        allowedRequisites = extraAttrs.bootstrappedPackages' ++ [ stdenvDeps ];
      };
    };

    extraAttrs = rec {
      libc = stage1Pkgs.glibc;
      shellPackage = stage3Pkgs.gcc.shell;
      bootstrappedPackages' = lib.attrValues (overrides {}) ++ [ cc.cc cc ] ++ extraBuildInputs;
      bootstrappedPackages = [ stdenv ] ++ bootstrappedPackages';
    };

    overrides = pkgs: {
      inherit (stage1Pkgs) glibc linux-headers_4-4 linux-headers;
      inherit (stage2Pkgs) m4 gnum4 which;
      inherit (stage3Pkgs) gcc7 gcc xz zlib attr acl gmp coreutils binutils
        gpm ncurses readline bash nghttp2_lib cryptodev_headers gettext bison flex
        openssl_1-1-0 openssl c-ares curl libsigsegv pcre findutils diffutils
        gnused gnugrep gawk gnutar gnutar_1-30 gzip brotli brotli_1-0-4 bzip2
        gnumake gnupatch pkgconf pkgconfig patchelf mpfr;
    };
  });

  finalPkgs = allPackages {
    inherit targetSystem hostSystem config stdenv;
  };
in {
  inherit bootstrap-tools stage0Pkgs stage1Pkgs stage2Pkgs stage3Pkgs stdenv;
}
