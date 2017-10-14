/* This file composes the Nix Packages collection.  That is, it
   imports the functions that build the various packages, and calls
   them with appropriate arguments.  The result is a set of all the
   packages in the Nix Packages collection for some particular
   platform. */


{ targetSystem
, hostSystem

# Allow a configuration attribute set to be passed in as an
# argument.  Otherwise, it's read from $NIXPKGS_CONFIG or
# ~/.nixpkgs/config.nix.
, config

# Allows the standard environment to be swapped out
# This is typically most useful for bootstrapping
, stdenv
} @ args:

let  # BEGIN let/in 1

  lib = import ../../lib;

  # The contents of the configuration file found at $NIXPKGS_CONFIG or
  # $HOME/.nixpkgs/config.nix.
  # for NIXOS (nixos-rebuild): use nixpkgs.config option
  config =
    if args.config != null then
      args.config
    else if builtins.getEnv "NIXPKGS_CONFIG" != "" then
      import (builtins.toPath (builtins.getEnv "NIXPKGS_CONFIG")) {
        inherit pkgs;
      }
    else
      let
        home = builtins.getEnv "HOME";
        homePath =
          if home != "" then
            builtins.toPath (home + "/.nixpkgs/config.nix")
          else
            null;
      in
        if homePath != null && builtins.pathExists homePath then
          import homePath { inherit pkgs; }
        else
          { };

  # Helper functions that are exported through `pkgs'.
  helperFunctions = stdenvAdapters // (
    import ../build-support/trivial-builders.nix {
      inherit lib;
      inherit (pkgs) stdenv;
      inherit (pkgs.xorg) lndir;
    }
  );

  stdenvAdapters = import ../stdenv/adapters.nix pkgs;


  # Allow packages to be overriden globally via the `packageOverrides'
  # configuration option, which must be a function that takes `pkgs'
  # as an argument and returns a set of new or overriden packages.
  # The `packageOverrides' function is called with the *original*
  # (un-overriden) set of packages, allowing packageOverrides
  # attributes to refer to the original attributes (e.g. "foo =
  # ... pkgs.foo ...").
  pkgs = applyGlobalOverrides (config.packageOverrides or (pkgs: {}));

  mkOverrides = pkgsOrig: overrides:
    overrides // (
      lib.optionalAttrs (pkgsOrig.stdenv ? overrides)
          (pkgsOrig.stdenv.overrides pkgsOrig)
    );

  # Return the complete set of packages, after applying the overrides
  # returned by the `overrider' function (see above).  Warning: this
  # function is very expensive!
  applyGlobalOverrides = overrider:
    let
      # Call the overrider function.  We don't want stdenv overrides
      # in the case of cross-building, or otherwise the basic
      # overrided packages will not be built with the crossStdenv
      # adapter.
      overrides = mkOverrides pkgsOrig (overrider pkgsOrig);

      # The un-overriden packages, passed to `overrider'.
      pkgsOrig = pkgsFun pkgs {};

      # The overriden, final packages.
      pkgs = pkgsFun pkgs overrides;
    in
    pkgs;


  # The package compositions.  Yes, this isn't properly indented.
  pkgsFun = pkgs: overrides:
    with helperFunctions;
    let  # BEGIN let/in 2
      defaultScope = pkgs;
      self = self_ // overrides;
      self_ =
        let
          inherit (self_)
            callPackage
            callPackages
            callPackageAlias
            recurseIntoAttrs
            wrapCCWith
            wrapCC;
          inherit (lib)
            hiPrio
            hiPrioSet
            lowPrio
            lowPrioSet;
        in
        helperFunctions // {  # BEGIN helperFunctions merge

  # Make some arguments passed to all-packages.nix available
  targetSystem = args.targetSystem;
  hostSystem = args.hostSystem;

  # Allow callPackage to fill in the pkgs argument
  inherit pkgs;


  # We use `callPackage' to be able to omit function arguments that
  # can be obtained from `pkgs' or `pkgs.xorg' (i.e. `defaultScope').
  # Use `newScope' for sets of packages in `pkgs' (see e.g. `gnome'
  # below).
  callPackage = self_.newScope { };

  callPackages = lib.callPackagesWith defaultScope;

  newScope = extra: lib.callPackageWith (defaultScope // extra);

  callPackageAlias = package: newAttrs: pkgs."${package}".override newAttrs;

  # Easily override this package set.
  # Warning: this function is very expensive and must not be used
  # from within the nixpkgs repository.
  #
  # Example:
  #  pkgs.overridePackages (self: super: {
  #    foo = super.foo.override { ... };
  #  }
  #
  # The result is `pkgs' where all the derivations depending on `foo'
  # will use the new version.
  overridePackages = f:
    let
      newpkgs = pkgsFun newpkgs overrides;
      overrides = mkOverrides pkgs (f newpkgs pkgs);
    in
    newpkgs;

  # Override system. This is useful to build i686 packages on x86_64-linux.
  forceSystem = { targetSystem, hostSystem }: (import ./all-packages.nix) {
    inherit
      targetSystem
      hostSystem
      config
      stdenv;
  };

  pkgs_32 =
    let
      hostSystem' =
        if [ hostSystem ] == lib.platforms.x86_64-linux
            && [ targetSystem' ] == lib.platforms.i686-linux then
          lib.head lib.platforms.i686-linux
        else if [ hostSystem ] == lib.platforms.i686-linux
            && [ targetSystem' ] == lib.platforms.i686-linux then
          lib.head lib.platforms.i686-linux
        else
          throw "Couldn't determine the 32 bit host system.";

      targetSystem' =
        if [ targetSystem ] == lib.platforms.x86_64-linux then
          lib.head lib.platforms.i686-linux
        else if [ targetSystem ] == lib.platforms.i686-linux then
          lib.head lib.platforms.i686-linux
        else
          throw "Couldn't determine the 32 bit target system.";
    in
    pkgs.forceSystem {
      hostSystem = hostSystem';
      targetSystem = targetSystem';
    };

  # For convenience, allow callers to get the path to Nixpkgs.
  path = ../..;

  ### Helper functions.
  inherit
    lib
    config
    stdenvAdapters;

  # Applying this to an attribute set will cause nix-env to look
  # inside the set for derivations.
  recurseIntoAttrs = attrs: attrs // { recurseForDerivations = true; };

  stringsWithDeps = lib.stringsWithDeps;


  ### Nixpkgs maintainer tools

  nix-generate-from-cpan =
    callPackage ../../maintainers/scripts/nix-generate-from-cpan.nix { };

  nixpkgs-lint = callPackage ../../maintainers/scripts/nixpkgs-lint.nix { };


  ### STANDARD ENVIRONMENT

  stdenv =
    if args.stdenv != null then
      args.stdenv
    else
      import ../stdenv {
        allPackages = args': import ./all-packages.nix (args // args');
        inherit
          lib
          targetSystem
          hostSystem
          config;
      };

  ### BUILD SUPPORT

  attrSetToDir = arg:
    callPackage ../build-support/upstream-updater/attrset-to-dir.nix {
      theAttrSet = arg;
    };

  autoreconfHook = makeSetupHook {
    substitutions = {
      inherit (pkgs)
        autoconf
        automake
        gettext
        libtool;
    };
  } ../build-support/setup-hooks/autoreconf.sh;

  ensureNewerSourcesHook = { year }: makeSetupHook { } (
    writeScript "ensure-newer-sources-hook.sh" ''
      postUnpackHooks+=(_ensureNewerSources)
      _ensureNewerSources() {
        '${pkgs.findutils}/bin/find' "$sourceRoot" \
          '!' -newermt '${year}-01-01' \
          -exec touch -h -d '${year}-01-02' '{}' '+'
      }
    ''
  );

  # not actually a package
  buildEnv = callPackage ../build-support/buildenv { };

  #buildFHSEnv = callPackage ../build-support/build-fhs-chrootenv/env.nix { };

  chrootFHSEnv = callPackage ../build-support/build-fhs-chrootenv { };
  userFHSEnv = callPackage ../build-support/build-fhs-userenv { };

  #buildFHSChrootEnv = args: chrootFHSEnv {
  #  env = buildFHSEnv (removeAttrs args [ "extraInstallCommands" ]);
  #  extraInstallCommands = args.extraInstallCommands or "";
  #};

  #buildFHSUserEnv = args: userFHSEnv {
  #  env = buildFHSEnv (removeAttrs args [
  #    "runScript"
  #    "extraBindMounts"
  #    "extraInstallCommands"
  #    "meta"
  #  ]);
  #  runScript = args.runScript or "bash";
  #  extraBindMounts = args.extraBindMounts or [];
  #  extraInstallCommands = args.extraInstallCommands or "";
  #  importMeta = args.meta or {};
  #};

  #buildMaven = callPackage ../build-support/build-maven.nix {};

  cmark = callPackage ../development/libraries/cmark { };

  #dockerTools = callPackage ../build-support/docker { };

  fetchbower = callPackage ../build-support/fetchbower {
    inherit (nodePackages) fetch-bower;
  };

  fetchbzr = callPackage ../build-support/fetchbzr { };

  #fetchcvs = callPackage ../build-support/fetchcvs { };

  #fetchdarcs = callPackage ../build-support/fetchdarcs { };

  fetchgit = callPackage ../build-support/fetchgit { };

  fetchgitPrivate = callPackage ../build-support/fetchgit/private.nix { };

  fetchgitrevision =
    import ../build-support/fetchgitrevision runCommand pkgs.git;

  fetchgitLocal = callPackage ../build-support/fetchgitlocal { };

  fetchpatch = callPackage ../build-support/fetchpatch { };

  fetchsvn = callPackage ../build-support/fetchsvn {
    sshSupport = true;
  };

  fetchsvnrevision =
    import ../build-support/fetchsvnrevision runCommand pkgs.subversion;

  fetchsvnssh = callPackage ../build-support/fetchsvnssh {
    sshSupport = true;
  };

  fetchhg = callPackage ../build-support/fetchhg { };

  # `fetchurl' downloads a file from the network.
  fetchurl = callPackage ../build-support/fetchurl { };

  fetchTritonPatch = { rev, file, sha256 }: pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/triton/triton-patches/"
      + "${rev}/${file}";
    hashOutput = false;
    inherit sha256;
  };

  fetchzip = callPackage ../build-support/fetchzip { };

  fetchFromGitHub =
    { owner
    , repo
    , rev
    , sha256
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit
        name
        sha256
        version;
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      meta.homepage = "https://github.com/${owner}/${repo}/";
    } // {
      inherit rev;
    };

  fetchFromBitbucket =
    { owner
    , repo
    , rev
    , sha256
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit
        name
        sha256
        version;
      url = "https://bitbucket.org/${owner}/${repo}/get/${rev}.tar.gz";
      meta.homepage = "https://bitbucket.org/${owner}/${repo}/";
      extraPostFetch = ''
        # impure file, see https://github.com/NixOS/nixpkgs/pull/12002
        find . -name .hg_archival.txt -delete
      '';
    };

  fetchFromSavannah =
    { repo
    , rev
    , sha256
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit
        name
        sha256
        version;
      # cgit, snapshot support is optional in cgit
      url = "http://git.savannah.gnu.org/cgit/${repo}.git/snapshot/"
        + "${repo}-${rev}.tar.gz";
      meta.homepage = "http://git.savannah.gnu.org/cgit/${repo}.git/";
    };

  fetchFromGitLab =
    { owner
    , repo
    , rev
    , sha256
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit name sha256 version;
      url = "https://gitlab.com/${owner}/${repo}/repository/"
        + "archive.tar.gz?ref=${rev}";
      meta.homepage = "https://gitlab.com/${owner}/${repo}/";
    };

  fetchFromRepoOrCz =
    { repo
    , rev
    , sha256
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit name sha256 version;
      # gitweb, snapshot support is optional in gitweb
      url = "http://repo.or.cz/${repo}.git/snapshot/${rev}.tar.gz";
      meta.homepage = "http://repo.or.cz/${repo}.git/";
    };

  fetchFromSourceforge =
    { repo
    , rev
    , sha256
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit name sha256;
      url = "http://sourceforge.net/code-snapshots/git/"
        + "${lib.substring 0 1 repo}/"
        + "${lib.substring 0 2 repo}/"
        + "${repo}/code.git/"
        + "${repo}-code-${rev}.zip";
      meta.homepage = "http://sourceforge.net/p/${repo}/code";
      preFetch = ''
        echo "Telling sourceforge to generate code tarball..."
        $curl --data "path=&" \
          "http://sourceforge.net/p/${repo}/code/ci/${rev}/tarball" >/dev/null
        local found
        found=0
        for i in {1..30}; do
          echo "Checking tarball generation status..." >&2
          status="$(
            $curl \
              "http://sourceforge.net/p/${repo}/code/ci/${rev}/tarball_status?path="
          )"
          echo "$status"
          if echo "$status" | grep -q '{"status": "complete"}'; then
            found=1
            break
          fi
          if ! echo "$status" | grep -q '{"status": "\(ready\|busy\)"}'; then
            break
          fi
          sleep 1
        done
        if [ "$found" -ne "1" ]; then
          echo "Sourceforge failed to generate tarball"
          exit 1
        fi
      '';
    };

  resolveMirrorURLs = { url }: pkgs.fetchurl {
    showURLs = true;
    inherit url;
  };

  libredirect = callPackage ../build-support/libredirect { };

  makeDesktopItem = callPackage ../build-support/make-desktopitem { };

  makeAutostartItem = callPackage ../build-support/make-startupitem { };

  makeInitrd = { contents, compressor ? "gzip -9n", prepend ? [ ] }:
    callPackage ../build-support/kernel/make-initrd.nix {
      inherit contents compressor prepend;
    };

  makeWrapper = makeSetupHook { } ../build-support/setup-hooks/make-wrapper.sh;

  makeModulesClosure = { kernel, rootModules, allowMissing ? false }:
    callPackage ../build-support/kernel/modules-closure.nix {
      inherit kernel rootModules allowMissing;
    };

  pathsFromGraph = ../build-support/kernel/paths-from-graph.pl;

  srcOnly = args: callPackage ../build-support/src-only args;

  substituteAll =
    callPackage ../build-support/substitute/substitute-all.nix { };

  substituteAllFiles =
    callPackage ../build-support/substitute-files/substitute-all-files.nix { };

  replaceDependency = callPackage ../build-support/replace-dependency.nix { };

  nukeReferences = callPackage ../build-support/nuke-references/default.nix { };

  vmTools = callPackage ../build-support/vm/default.nix { };

  releaseTools = callPackage ../build-support/release/default.nix { };

  composableDerivation = callPackage ../../lib/composable-derivation.nix { };

  #platforms = import ./platforms.nix;

  setJavaClassPath =
    makeSetupHook { } ../build-support/setup-hooks/set-java-classpath.sh;

  keepBuildTree =
    makeSetupHook { } ../build-support/setup-hooks/keep-build-tree.sh;

  enableGCOVInstrumentation =
    makeSetupHook { }
      ../build-support/setup-hooks/enable-coverage-instrumentation.sh;

  makeGCOVReport = makeSetupHook
    { deps = [ pkgs.lcov pkgs.enableGCOVInstrumentation ]; }
    ../build-support/setup-hooks/make-coverage-analysis-report.sh;

  # intended to be used like:
  # nix-build -E 'with <nixpkgs> {}; enableDebugging fooPackage'
  enableDebugging = pkg: pkg.override {
    stdenv = stdenvAdapters.keepDebugInfo pkgs.stdenv;
  };

  findXMLCatalogs =
    makeSetupHook { } ../build-support/setup-hooks/find-xml-catalogs.sh;

  wrapGAppsHook = makeSetupHook {
    deps = [ makeWrapper ];
  } ../build-support/setup-hooks/wrap-gapps-hook.sh;

  separateDebugInfo =
    makeSetupHook { } ../build-support/setup-hooks/separate-debug-info.sh;

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
############################# BEGIN ALL BUILDERS ###############################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################


wrapCCWith = ccWrapper: libc: extraBuildCommands: baseCC: ccWrapper {
  nativeTools = pkgs.stdenv.cc.nativeTools or false;
  nativeLibc = pkgs.stdenv.cc.nativeLibc or false;
  nativePrefix = pkgs.stdenv.cc.nativePrefix or "";
  cc = baseCC;
  isGNU = baseCC.isGNU or false;
  isClang = baseCC.isClang or false;
  inherit libc extraBuildCommands;
};

wrapCC =
  wrapCCWith (callPackage ../build-support/cc-wrapper) pkgs.stdenv.cc.libc "";

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
############################## END ALL BUILDERS ################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
############################### BEGIN ALL PKGS #################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

"389-ds-base" = callPackage ../all-pkgs/3/389-ds-base { };

accountsservice = callPackage ../all-pkgs/a/accountsservice { };

acl = callPackage ../all-pkgs/a/acl { };

acme-client = callPackage ../all-pkgs/a/acme-client { };

acpi = callPackage ../all-pkgs/a/acpi { };

acpid = callPackage ../all-pkgs/a/acpid { };

adns = callPackage ../all-pkgs/a/adns { };

adobe-flash-player_stable = callPackage ../all-pkgs/a/adobe-flash-player {
  channel = "stable";
};
adobe-flash-player_beta = callPackage ../all-pkgs/a/adobe-flash-player {
  channel = "beta";
};
adobe-flash-player = callPackageAlias "adobe-flash-player_stable" { };

adwaita-icon-theme_3-26 = callPackage ../all-pkgs/a/adwaita-icon-theme {
  channel = "3.26";
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
adwaita-icon-theme = callPackageAlias "adwaita-icon-theme_3-26" { };

afflib = callPackage ../all-pkgs/a/afflib { };

alsa-firmware = callPackage ../all-pkgs/a/alsa-firmware { };

alsa-lib = callPackage ../all-pkgs/a/alsa-lib { };

alsa-plugins = callPackage ../all-pkgs/a/alsa-plugins { };

alsa-utils = callPackage ../all-pkgs/a/alsa-utils { };

amd-microcode = callPackage ../all-pkgs/a/amd-microcode { };

amrnb = callPackage ../all-pkgs/a/amrnb { };

amrwb = callPackage ../all-pkgs/a/amrwb { };

aomedia = callPackage ../all-pkgs/a/aomedia { };

appstream-glib = callPackage ../all-pkgs/a/appstream-glib { };

apr = callPackage ../all-pkgs/a/apr { };

apr-util = callPackage ../all-pkgs/a/apr-util { };

apt = callPackage ../all-pkgs/a/apt { };

#ardour =  callPackage ../all-pkgs/a/ardour { };

argyllcms = callPackage ../all-pkgs/a/argyllcms { };

aria2 = callPackage ../all-pkgs/a/aria2 { };
aria = callPackageAlias "aria2" { };

arkive = callPackage ../all-pkgs/a/arkive { };

asciidoc = callPackage ../all-pkgs/a/asciidoc { };

asciinema = pkgs.python3Packages.asciinema;

asio = callPackage ../all-pkgs/a/asio { };

aspell = callPackage ../all-pkgs/a/aspell { };

at-spi2-atk_2-26 = callPackage ../all-pkgs/a/at-spi2-atk {
  channel = "2.26";
  at-spi2-core = pkgs.at-spi2-core_2-26;
  atk = pkgs.atk_2-26;
};
at-spi2-atk = callPackageAlias "at-spi2-atk_2-26" { };

at-spi2-core_2-26 = callPackage ../all-pkgs/a/at-spi2-core {
  channel = "2.26";
};
at-spi2-core = callPackageAlias "at-spi2-core_2-26" { };

atftp = callPackage ../all-pkgs/a/atftp { };

atk_2-26 = callPackage ../all-pkgs/a/atk {
  channel = "2.26";
};
atk = callPackageAlias "atk_2-26" { };

atkmm_2-24 = callPackage ../all-pkgs/a/atkmm {
  channel = "2.24";
  atk = pkgs.atk_2-26;
};
atkmm = callPackageAlias "atkmm_2-24" { };

atom_stable = callPackage ../all-pkgs/a/atom {
  channel = "stable";
};
atom_beta = callPackage ../all-pkgs/a/atom {
  channel = "beta";
};
atom = callPackageAlias "atom_stable" { };

atop = callPackage ../all-pkgs/a/atop { };

attr = callPackage ../all-pkgs/a/attr { };

audiofile = callPackage ../all-pkgs/a/audiofile { };

audit_full = callPackage ../all-pkgs/a/audit { };
audit_lib = callPackageAlias "audit_full" {
  prefix = "lib";
};

augeas = callPackage ../all-pkgs/a/augeas { };

autoconf = callPackage ../all-pkgs/a/autoconf { };

autoconf_21x = callPackageAlias "autoconf" {
  channel = "2.1x";
};

autoconf-archive = callPackage ../all-pkgs/a/autoconf-archive { };

autogen = callPackage ../all-pkgs/a/autogen { };

automake = callPackage ../all-pkgs/a/automake { };

avahi = callPackage ../all-pkgs/a/avahi { };

aws-sdk-cpp = callPackage ../all-pkgs/a/aws-sdk-cpp { };

babl = callPackage ../all-pkgs/b/babl { };

bash = callPackage ../all-pkgs/b/bash { };

bash-completion = callPackage ../all-pkgs/b/bash-completion { };

bc = callPackage ../all-pkgs/b/bc { };

bcache-tools = callPackage ../all-pkgs/b/bcache-tools { };

bcachefs-tools = callPackage ../all-pkgs/b/bcachefs-tools { };

beecrypt = callPackage ../all-pkgs/b/beecrypt { };

bigreqsproto = callPackage ../all-pkgs/b/bigreqsproto { };

bind = callPackage ../all-pkgs/b/bind { };

bind_tools = callPackageAlias "bind" {
  suffix = "tools";
};

bison = callPackage ../all-pkgs/b/bison { };

bluez = callPackage ../all-pkgs/b/bluez { };

boehm-gc = callPackage ../all-pkgs/b/boehm-gc { };

boost_1-64 = callPackage ../all-pkgs/b/boost {
  channel = "1.64";
};
boost_1-65 = callPackage ../all-pkgs/b/boost {
  channel = "1.65";
};
boost = callPackageAlias "boost_1-65" { };

borgbackup = pkgs.python3Packages.borgbackup;

brotli_0-4-0 = callPackage ../all-pkgs/b/brotli {
  version = "0.4.0";
};
brotli_0-5-2 = callPackage ../all-pkgs/b/brotli {
  version = "0.5.2";
};
brotli_0-6-0 = callPackage ../all-pkgs/b/brotli {
  version = "0.6.0";
};
brotli = callPackageAlias "brotli_0-6-0" { };

bs1770gain = callPackage ../all-pkgs/b/bs1770gain { };

btrfs-progs = callPackage ../all-pkgs/b/btrfs-progs { };

build-dir-check = callPackage ../all-pkgs/b/build-dir-check { };

busybox = callPackage ../all-pkgs/b/busybox { };

busyboxBootstrap = callPackageAlias "busybox" {
  static = true;
  minimal = true;
  extraConfig = ''
    CONFIG_ASH y
    CONFIG_ASH_ECHO y
    CONFIG_ASH_TEST y
    CONFIG_ASH_OPTIMIZE_FOR_SIZE y
    CONFIG_MKDIR y
    CONFIG_TAR y
    CONFIG_UNXZ y
  '';
};

bzip2 = callPackage ../all-pkgs/b/bzip2 { };

cacert = callPackage ../all-pkgs/c/cacert { };

c-ares = callPackage ../all-pkgs/c/c-ares { };

cairo = callPackage ../all-pkgs/c/cairo { };

cairomm = callPackage ../all-pkgs/c/cairomm { };

caribou = callPackage ../all-pkgs/c/caribou { };

ccid = callPackage ../all-pkgs/c/ccid { };

cdparanoia = callPackage ../all-pkgs/c/cdparanoia { };

cdrtools = callPackage ../all-pkgs/c/cdrtools { };

# Only ever add ceph LTS releases
# The default channel should be the latest LTS
# Dev should always point to the latest versioned release
ceph_lib = pkgs.ceph.lib;
ceph = hiPrio pkgs.ceph_12;
ceph_10 = callPackage ../all-pkgs/c/ceph {
  channel = "10";
};
ceph_11 = callPackage ../all-pkgs/c/ceph/cmake.nix {
  channel = "11";
};
ceph_12 = callPackage ../all-pkgs/c/ceph/cmake.nix {
  channel = "12";
};
ceph_dev = callPackage ../all-pkgs/c/ceph/cmake.nix {
  channel = "dev";
};
ceph_git = callPackage ../all-pkgs/c/ceph/cmake.nix {
  channel = "git";
};

cgit = callPackage ../all-pkgs/c/cgit { };

cgmanager = callPackage ../all-pkgs/c/cgmanager { };

chck = callPackage ../all-pkgs/c/chck { };

check = callPackage ../all-pkgs/c/check { };

chromaprint = callPackage ../all-pkgs/c/chromaprint { };

chromium_old = callPackage ../all-pkgs/c/chromium_old {
  channel = "stable";
};
chromium_old_beta = callPackageAlias "chromium_old" {
  channel = "beta";
};
chromium_old_dev = callPackageAlias "chromium_old" {
  channel = "dev";
};

chrony = callPackage ../all-pkgs/c/chrony { };

cifs-utils = callPackage ../all-pkgs/c/cifs-utils { };

civetweb = callPackage ../all-pkgs/c/civetweb { };

cjdns = callPackage ../all-pkgs/c/cjdns { };

clang = wrapCC (callPackageAlias "llvm" { });

clutter_1-26 = callPackage ../all-pkgs/c/clutter {
  channel = "1.26";
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
clutter = callPackageAlias "clutter_1-26" { };

clutter-gst_2 = callPackage ../all-pkgs/c/clutter-gst {
  channel = "2.0";
};
clutter-gst_3 = callPackage ../all-pkgs/c/clutter-gst {
  channel = "3.0";
};
clutter-gst = callPackageAlias "clutter-gst_3" { };

clutter-gtk_1-8 = callPackage ../all-pkgs/c/clutter-gtk {
  channel = "1.8";
};
clutter-gtk = callPackageAlias "clutter-gtk_1-8" { };

cmake = callPackage ../all-pkgs/c/cmake {
  cmake = pkgs.cmake_bootstrap;
};
cmake_bootstrap = callPackageAlias "cmake" {
  bootstrap = true;
};

cmocka = callPackage ../all-pkgs/c/cmocka { };

cogl_1-22 = callPackage ../all-pkgs/c/cogl {
  channel = "1.22";
};
cogl = callPackageAlias "cogl_1-22" { };

collectd_lib = callPackageAlias "collectd" { };
collectd = callPackage ../all-pkgs/c/collectd {
  type = "base";
};
collectd_plugins = callPackage ../all-pkgs/c/collectd {
  type = "plugins";
};

colord = callPackage ../all-pkgs/c/colord { };

colord-gtk = callPackage ../all-pkgs/c/colord-gtk { };

compositeproto = callPackage ../all-pkgs/c/compositeproto { };

conntrack-tools = callPackage ../all-pkgs/c/conntrack-tools { };

consul = pkgs.goPackages.consul.bin // { outputs = [ "bin" ]; };

consulfs = pkgs.goPackages.consulfs.bin // { outputs = [ "bin" ]; };

consul-replicate = pkgs.goPackages.consul-replicate.bin // { outputs = [ "bin" ]; };

consul-template = pkgs.goPackages.consul-template.bin // { outputs = [ "bin" ]; };

coreutils = callPackage ../all-pkgs/c/coreutils { };

cpio = callPackage ../all-pkgs/c/cpio { };

cpp-netlib = callPackage ../all-pkgs/c/cpp-netlib { };

cppunit = callPackage ../all-pkgs/c/cppunit { };

cracklib = callPackage ../all-pkgs/c/cracklib { };

cryptodev_headers = callPackage ../all-pkgs/c/cryptodev {
  onlyHeaders = true;
  kernel = null;
};

cryptsetup = callPackage ../all-pkgs/c/cryptsetup { };

cscope = callPackage ../all-pkgs/c/cscope { };

cuetools = callPackage ../all-pkgs/c/cuetools { };

cunit = callPackage ../all-pkgs/c/cunit { };

cups = callPackage ../all-pkgs/c/cups { };

curl = callPackage ../all-pkgs/c/curl {
  suffix = "";
};
curl_full = callPackage ../all-pkgs/c/curl {
  suffix = "full";
};

cyrus-sasl = callPackage ../all-pkgs/c/cyrus-sasl { };

damageproto = callPackage ../all-pkgs/d/damageproto { };

dash = callPackage ../all-pkgs/d/dash { };

db_5 = callPackage ../all-pkgs/d/db {
  channel = "5";
};
db_6 = callPackage ../all-pkgs/d/db {
  channel = "6";
};
db = callPackageAlias "db_5" { };

dbus = callPackage ../all-pkgs/d/dbus { };

dbus-glib = callPackage ../all-pkgs/d/dbus-glib { };

dcadec = callPackage ../all-pkgs/d/dcadec { };

dconf_0-26 = callPackage ../all-pkgs/d/dconf {
  channel = "0.26";
};
dconf = callPackageAlias "dconf_0-26" { };

dconf-editor_3-22 = callPackage ../all-pkgs/d/dconf-editor {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
dconf-editor = callPackageAlias "dconf-editor_3-22" { };

ddrescue = callPackage ../all-pkgs/d/ddrescue { };

dejagnu = callPackage ../all-pkgs/d/dejagnu { };

dejavu-fonts = callPackage ../all-pkgs/d/dejavu-fonts { };

desktop-file-utils = callPackage ../all-pkgs/d/desktop-file-utils { };
# Deprecated alias
desktop_file_utils = callPackageAlias "desktop-file-utils" { };

devil_nox = callPackageAlias "devil" {
  xorg = null;
  mesa = null;
};
devil = callPackage ../all-pkgs/d/devil { };

dhcp = callPackage ../all-pkgs/d/dhcp { };

dhcpcd = callPackage ../all-pkgs/d/dhcpcd { };

dht = callPackage ../all-pkgs/d/dht { };

dialog = callPackage ../all-pkgs/d/dialog { };

diffoscope = pkgs.python3Packages.diffoscope;

diffutils = callPackage ../all-pkgs/d/diffutils { };

ding-libs = callPackage ../all-pkgs/d/ding-libs { };

dmenu = callPackage ../all-pkgs/d/dmenu { };

dmidecode = callPackage ../all-pkgs/d/dmidecode { };

dmraid = callPackage ../all-pkgs/d/dmraid { };

dmxproto = callPackage ../all-pkgs/d/dmxproto { };

dnscrypt-proxy = callPackage ../all-pkgs/d/dnscrypt-proxy { };

dnscrypt-wrapper = callPackage ../all-pkgs/d/dnscrypt-wrapper { };

dnsdiag = pkgs.python3Packages.dnsdiag;

dnsmasq = callPackage ../all-pkgs/d/dnsmasq { };

dnstop = callPackage ../all-pkgs/d/dnstop { };

docbook-xsl = callPackage ../all-pkgs/d/docbook-xsl { };

docbook-xsl-ns = callPackageAlias "docbook-xsl" {
  type = "ns";
};

dosfstools = callPackage ../all-pkgs/d/dosfstools { };

dos2unix = callPackage ../all-pkgs/d/dos2unix { };

dotconf = callPackage ../all-pkgs/d/dotconf { };

double-conversion = callPackage ../all-pkgs/d/double-conversion { };

dpdk = callPackage ../all-pkgs/d/dpdk { };

dpkg = callPackage ../all-pkgs/d/dpkg { };

dri2proto = callPackage ../all-pkgs/d/dri2proto { };

dri3proto = callPackage ../all-pkgs/d/dri3proto { };

#dropbox = callPackage ../all-pkgs/d/dropbox { };

dtc = callPackage ../all-pkgs/d/dtc { };

duplicity = pkgs.pythonPackages.duplicity;

e2fsprogs = callPackage ../all-pkgs/e/e2fsprogs { };

ed = callPackage ../all-pkgs/e/ed { };

edac-utils = callPackage ../all-pkgs/e/edac-utils { };

efibootmgr = callPackage ../all-pkgs/e/efibootmgr { };

efivar = callPackage ../all-pkgs/e/efivar { };

egl-headers = callPackage ../all-pkgs/e/egl-headers { };

egl-wayland = callPackage ../all-pkgs/e/egl-wayland { };

eglexternalplatform = callPackage ../all-pkgs/e/eglexternalplatform { };

eigen = callPackage ../all-pkgs/e/eigen { };

elasticsearch_5 = callPackage ../all-pkgs/e/elasticsearch {
  channel = "5";
};
elasticsearch_6 = callPackage ../all-pkgs/e/elasticsearch {
  channel = "6";
};
elasticsearch = callPackageAlias "elasticsearch_5" { };

elfutils = callPackage ../all-pkgs/e/elfutils { };

emacs = callPackage ../all-pkgs/e/emacs { };

enca = callPackage ../all-pkgs/e/enca { };

enchant = callPackage ../all-pkgs/e/enchant { };

eog_3-24 = callPackage ../all-pkgs/e/eog {
  channel = "3.24";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
};
eog = callPackageAlias "eog_3-24" { };

erlang = callPackage ../all-pkgs/e/erlang { };

erlang_graphical = callPackageAlias "erlang" {
  graphical = true;
};

etcd = pkgs.goPackages.etcd.bin // { outputs = [ "bin" ]; };

ethtool = callPackage ../all-pkgs/e/ethtool { };

evieext = callPackage ../all-pkgs/e/evieext { };

evince_3-22 = callPackage ../all-pkgs/e/evince {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
  gvfs = pkgs.gvfs_1-34;
  nautilus = pkgs.nautilus_3-26;
};
evince = callPackageAlias "evince_3-22" { };

#evolution = callPackage ../all-pkgs/e/evolution { };

evolution-data-server_3-26 = callPackage ../all-pkgs/e/evolution-data-server {
  channel = "3.26";
  #gnome-online-accounts
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
  libsoup = pkgs.libsoup_2-60;
};
evolution-data-server = callPackageAlias "evolution-data-server_3-26" { };

ewlc = callPackage ../all-pkgs/e/ewlc { };

exempi = callPackage ../all-pkgs/e/exempi { };

exfat-utils = callPackage ../all-pkgs/e/exfat-utils { };

exiv2 = callPackage ../all-pkgs/e/exiv2 { };

exo = callPackage ../all-pkgs/e/exo { };

expat = callPackage ../all-pkgs/e/expat { };

expect = callPackage ../all-pkgs/e/expect { };

extra-cmake-modules = callPackage ../all-pkgs/e/extra-cmake-modules { };

f2fs-tools = callPackage ../all-pkgs/f/f2fs-tools { };

faac = callPackage ../all-pkgs/f/faac { };

factorio = callPackage ../all-pkgs/f/factorio { };
factorio_headless = callPackage ../all-pkgs/f/factorio {
  type = "headless";
};

fbterm = callPackage ../all-pkgs/f/fbterm { };

fcgi = callPackage ../all-pkgs/f/fcgi { };

fdk-aac_stable = callPackage ../all-pkgs/f/fdk-aac {
  channel = "stable";
};
fdk-aac_head = callPackage ../all-pkgs/f/fdk-aac {
  channel = "head";
};
fdk-aac = callPackageAlias "fdk-aac_stable" { };

feh = callPackage ../all-pkgs/f/feh { };

ffado_full = callPackage ../all-pkgs/f/ffado { };
ffado_lib = callPackage ../all-pkgs/f/ffado {
  prefix = "lib";
};

ffmpeg_generic = overrides: callPackage ../all-pkgs/f/ffmpeg ({
  # The following are disabled by default
  celt = null;
  chromaprint = null;
  fdk-aac = null;
  flite = null;
  frei0r-plugins = null;
  fribidi = null;
  game-music-emu = null;
  gmp = null;
  gsm = null;
  #iblc = null;
  jni = null;
  kvazaar = null;
  ladspa-sdk = null;
  #libavc1394 = null;
  libbs2b = null;
  libcaca = null;
  libdc1394 = null;
  #libiec61883 = null;
  libmysofa = null;
  libraw1394 = null;
  libmodplug = null;
  #libnpp = null;
  libssh = null;
  libwebp = null; # ???
  libzimg = null;
  mfx-dispatcher = null;
  mmal = null;
  nvenc = false;
  nvidia-cuda-toolkit = null;
  nvidia-drivers = null;
  openal = null;
  #opencl = null;
  #opencore-amr = null;
  opencv = null;
  openh264 = null;
  openjpeg = null;
  openssl = null;
  samba_client = null;
  #schannel = null;
  #shine = null;
  snappy = null;
  rtmpdump = null;
  rubberband = null;
  tesseract = null;
  #twolame = null;
  #utvideo = null;
  vid-stab = null;
  vo-amrwbenc = null;
  wavpack = null;
  xavs = null;
  xvidcore = null;
  zeromq4 = null;
  #zvbi = null;
} // overrides);
ffmpeg_3-3 = pkgs.ffmpeg_generic {
  channel = "3.3";
};
ffmpeg_3 = callPackageAlias "ffmpeg_3-3" { };
ffmpeg_head = pkgs.ffmpeg_generic {
  channel = "9.9";
  # Use latest dependencies
  opus = pkgs.opus_head;
  libvpx = pkgs.libvpx_head;
  x265 = pkgs.x265_head;
};
ffmpeg = callPackageAlias "ffmpeg_3" { };

ffms = callPackage ../all-pkgs/f/ffms { };

fftw_double = callPackage ../all-pkgs/f/fftw {
  precision = "double";
};
fftw_long-double = callPackage ../all-pkgs/f/fftw {
  precision = "long-double";
};
fftw_quad = callPackage ../all-pkgs/f/fftw {
  precision = "quad-precision";
};
fftw_single = callPackage ../all-pkgs/f/fftw {
  precision = "single";
};

file = callPackage ../all-pkgs/f/file { };

file-roller_3-22 = callPackage ../all-pkgs/f/file-roller {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
file-roller = callPackageAlias "file-roller_3-22" { };

filezilla = callPackage ../all-pkgs/f/filezilla { };

findutils = callPackage ../all-pkgs/f/findutils { };

fio = callPackage ../all-pkgs/f/fio { };

firefox = pkgs.firefox_wrapper pkgs.firefox-unwrapped { };
firefox-esr = pkgs.firefox_wrapper pkgs.firefox-esr-unwrapped { };
firefox-unwrapped = callPackage ../all-pkgs/f/firefox { };
firefox-esr-unwrapped = callPackage ../all-pkgs/f/firefox {
  channel = "esr";
};
firefox_wrapper = callPackage ../all-pkgs/f/firefox/wrapper.nix { };

#firefox-bin = callPackage ../applications/networking/browsers/firefox-bin { };

fish = callPackage ../all-pkgs/f/fish { };

fixesproto = callPackage ../all-pkgs/f/fixesproto { };

flac = callPackage ../all-pkgs/f/flac { };

flashmap = callPackage ../all-pkgs/f/flashmap { };

flashrom = callPackage ../all-pkgs/f/flashrom { };

flashrom_chromium = callPackage ../all-pkgs/f/flashrom/chromium.nix { };

flex = callPackage ../all-pkgs/f/flex { };

flite = callPackage ../all-pkgs/f/flite { };

fontcacheproto = callPackage ../all-pkgs/f/fontcacheproto { };

fontconfig = callPackage ../all-pkgs/f/fontconfig { };

fontforge = callPackage ../all-pkgs/f/fontforge { };

fontsproto = callPackage ../all-pkgs/f/fontsproto { };

fox = callPackage ../all-pkgs/f/fox { };

freeglut = callPackage ../all-pkgs/f/freeglut { };

freeipmi = callPackage ../all-pkgs/f/freeipmi { };

freetype_for-harfbuzz = callPackage ../all-pkgs/f/freetype {
  type = "harfbuzz";
};
freetype = callPackage ../all-pkgs/f/freetype {
  type = "full";
};

frei0r-plugins = callPackage ../all-pkgs/f/frei0r-plugins { };

fs-repo-migrations = pkgs.goPackages.fs-repo-migrations.bin // { outputs = [ "bin" ]; };

fstrm = callPackage ../all-pkgs/f/fstrm { };

fuse_2 = callPackage ../all-pkgs/f/fuse/2.nix { };
fuse_3 = callPackage ../all-pkgs/f/fuse/3.nix { };

fuse-exfat = callPackage ../all-pkgs/f/fuse-exfat { };

fwupd = callPackage ../all-pkgs/f/fwupd {
  fwupdate = null; # Broken until binutils update
};

fwupdate = callPackage ../all-pkgs/f/fwupdate { };

game-music-emu = callPackage ../all-pkgs/g/game-music-emu { };

gawk = callPackage ../all-pkgs/g/gawk { };

gcab = callPackage ../all-pkgs/g/gcab { };

gconf = callPackage ../all-pkgs/g/gconf { };

gcr = callPackage ../all-pkgs/g/gcr { };

gdb = callPackage ../all-pkgs/g/gdb { };

gdbm = callPackage ../all-pkgs/g/gdbm { };

# Combined gdk-pixbuf loaders.cache
gdk-pixbuf_wrapped_2-36 = callPackage ../all-pkgs/g/gdk-pixbuf {
  gdk-pixbuf_unwrapped = pkgs.gdk-pixbuf_unwrapped_2-36;
};
gdk-pixbuf_wrapped = callPackageAlias "gdk-pixbuf_wrapped_2-36" { };

# Actual gdk-pixbuf
gdk-pixbuf_unwrapped_2-36 = callPackage ../all-pkgs/g/gdk-pixbuf/unwrapped.nix {
  channel = "2.36";
};
gdk-pixbuf_unwrapped = callPackageAlias "gdk-pixbuf_unwrapped_2-36" { };

gdk-pixbuf_2-36 = callPackageAlias "gdk-pixbuf_wrapped_2-36" { };
gdk-pixbuf = callPackageAlias "gdk-pixbuf_wrapped_2-36" { };

gdm = callPackage ../all-pkgs/g/gdm { };

geoclue = callPackage ../all-pkgs/g/geoclue { };

gegl = callPackage ../all-pkgs/g/gegl { };

geocode-glib = callPackage ../all-pkgs/g/geocode-glib { };

geoip = callPackage ../all-pkgs/g/geoip { };

getopt = callPackage ../all-pkgs/g/getopt { };

gettext = callPackage ../all-pkgs/g/gettext { };

gexiv2_0-10 = callPackage ../all-pkgs/g/gexiv2 {
  channel = "0.10";
};
gexiv2 = callPackageAlias "gexiv2_0-10" { };

gflags = callPackage ../all-pkgs/g/gflags { };

ghostscript = callPackage ../all-pkgs/g/ghostscript { };

giflib = callPackage ../all-pkgs/g/giflib { };

gimp = callPackage ../all-pkgs/g/gimp { };

git = callPackage ../all-pkgs/g/git { };

gjs_1-46 = callPackage ../all-pkgs/g/gjs {
  channel = "1.46";
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
gjs_1-48 = callPackage ../all-pkgs/g/gjs {
  channel = "1.48";
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
gjs = callPackageAlias "gjs_1-46" { };

gksu = callPackage ../all-pkgs/g/gksu { };

glew = callPackage ../all-pkgs/g/glew { };

glfw = callPackage ../all-pkgs/g/glfw { };

glib = callPackage ../all-pkgs/g/glib { };

glib-networking_2-50 = callPackage ../all-pkgs/g/glib-networking {
  channel = "2.50";
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
};
glib-networking = callPackageAlias "glib-networking_2-50" { };

glibmm_2-52 = callPackage ../all-pkgs/g/glibmm {
  channel = "2.52";
  libsigcxx = pkgs.libsigcxx_2-10;
};
glibmm = callPackageAlias "glibmm_2-52" { };

glog = callPackage ../all-pkgs/g/glog { };

glproto = callPackage ../all-pkgs/g/glproto { };

glu = callPackage ../all-pkgs/g/glu { };
mesa_glu =  callPackageAlias "glu" { };  # DEPRECATED

glusterfs = callPackage ../all-pkgs/g/glusterfs { };

gmime = callPackage ../all-pkgs/g/gmime { };

gmp = callPackage ../all-pkgs/g/gmp { };

gn = callPackage ../all-pkgs/g/gn { };

gnome-autoar = callPackage ../all-pkgs/g/gnome-autoar { };

gnome-backgrounds_3-24 = callPackage ../all-pkgs/g/gnome-backgrounds {
  channel = "3.24";
};
gnome-backgrounds = callPackageAlias "gnome-backgrounds_3-24" { };

gnome-bluetooth_3-20 = callPackage ../all-pkgs/g/gnome-bluetooth {
  channel = "3.20";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
gnome-bluetooth = callPackageAlias "gnome-bluetooth_3-20" { };

gnome-calculator_3-22 = callPackage ../all-pkgs/g/gnome-calculator {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gnome-themes-standard = pkgs.gnome-themes-standard_3-22;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
  gtksourceview = pkgs.gtksourceview_3-22;
  libsoup = pkgs.libsoup_2-60;
};
gnome-calculator = callPackageAlias "gnome-calculator_3-22" { };

gnome-clocks = callPackage ../all-pkgs/g/gnome-clocks { };

gnome-common = callPackage ../all-pkgs/g/gnome-common { };

gnome-control-center = callPackage ../all-pkgs/g/gnome-control-center { };

gnome-desktop_3-26 = callPackage ../all-pkgs/g/gnome-desktop {
  channel = "3.26";
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
};
gnome-desktop = callPackageAlias "gnome-desktop_3-26" { };

gnome-documents_3-20 = callPackage ../all-pkgs/g/gnome-documents {
  channel = "3.20";
};
gnome-documents = callPackageAlias "gnome-documents_3-20" { };

gnome-keyring = callPackage ../all-pkgs/g/gnome-keyring { };

gnome-menus_3-13 = callPackage ../all-pkgs/g/gnome-menus {
  channel = "3.13";
};
gnome-menus = callPackageAlias "gnome-menus_3-13" { };

gnome-mpv = callPackage ../all-pkgs/g/gnome-mpv { };

gnome-online-accounts_3-22 = callPackage ../all-pkgs/g/gnome-online-accounts {
  channel = "3.22";
};
gnome-online-accounts = callPackageAlias "gnome-online-accounts_3-22" { };

gnome-online-miners = callPackage ../all-pkgs/g/gnome-online-miners { };

gnome-screenshot_3-22 = callPackage ../all-pkgs/g/gnome-screenshot {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
};
gnome-screenshot = callPackageAlias "gnome-screenshot_3-22" { };

gnome-session_3-22 = callPackage ../all-pkgs/g/gnome-session {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gnome-desktop = pkgs.gnome-desktop_3-26;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
};
gnome-session = callPackageAlias "gnome-session_3-22" { };

gnome-settings-daemon_3-22 =
  callPackage ../all-pkgs/g/gnome-settings-daemon {
    channel = "3.22";
    adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
    gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
    gnome-desktop = pkgs.gnome-desktop_3-26;
    gnome-themes-standard = pkgs.gnome-themes-standard_3-22;
    gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
  };
gnome-settings-daemon = callPackageAlias "gnome-settings-daemon_3-22" { };

gnome-shell = callPackage ../all-pkgs/g/gnome-shell { };

gnome-shell-extensions = callPackage ../all-pkgs/g/gnome-shell-extensions { };

gnome-terminal_3-26 = callPackage ../all-pkgs/g/gnome-terminal {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
  nautilus = pkgs.nautilus_3-26;
  vala = pkgs.vala_0-36;
  vte = pkgs.vte_0-50;
};
gnome-terminal = callPackageAlias "gnome-terminal_3-26" { };

gnome-themes-standard_3-22 = callPackage ../all-pkgs/g/gnome-themes-standard {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
gnome-themes-standard = callPackageAlias "gnome-themes-standard_3-22" { };

gnome-user-share = callPackage ../all-pkgs/g/gnome-user-share { };

gnome-wrapper = makeSetupHook {
  deps = [ makeWrapper ];
} ../build-support/setup-hooks/gnome-wrapper.sh;

gnu-efi = callPackage ../all-pkgs/g/gnu-efi { };

gnugrep = callPackage ../all-pkgs/g/gnugrep { };

gnulib = callPackage ../all-pkgs/g/gnulib { };

gnum4 = callPackage ../all-pkgs/g/gnum4 { };

gnumake = callPackage ../all-pkgs/g/gnumake { };

gnupatch = callPackage ../all-pkgs/g/gnupatch { };

gnupg = callPackage ../all-pkgs/g/gnupg { };

gnused = callPackage ../all-pkgs/g/gnused { };

gnutar_1-29 = callPackage ../all-pkgs/g/gnutar {
  version = "1.29";
};
gnutar = callPackage ../all-pkgs/g/gnutar { };

gnutls = callPackage ../all-pkgs/g/gnutls { };

go_1-8 = callPackage ../all-pkgs/g/go {
  channel = "1.8";
};
go_1-9 = callPackage ../all-pkgs/g/go {
  channel = "1.9";
};
go = callPackageAlias "go_1-9" { };

goPackages_1-8 = callPackage ./go-packages.nix {
  go = callPackageAlias "go_1-8" { };
  buildGoPackage = callPackage ../all-pkgs/b/build-go-package {
    go = callPackageAlias "go_1-8" { };
  };
  overrides = (config.goPackageOverrides or (p: { })) pkgs;
};
goPackages_1-9 = callPackage ./go-packages.nix {
  go = callPackageAlias "go_1-9" { };
  buildGoPackage = callPackage ../all-pkgs/b/build-go-package {
    go = callPackageAlias "go_1-9" { };
  };
  overrides = (config.goPackageOverrides or (p: { })) pkgs;
};
goPackages = callPackageAlias "goPackages_1-9" { };

gobject-introspection = callPackage ../all-pkgs/g/gobject-introspection { };

google-chrome_stable = callPackage ../all-pkgs/g/google-chrome {
  channel = "stable";
};
google-chrome_beta = callPackage ../all-pkgs/g/google-chrome {
  channel = "beta";
};
google-chrome_unstable = callPackage ../all-pkgs/g/google-chrome {
  channel = "unstable";
};
google-chrome = callPackageAlias "google-chrome_stable" { };

gperf = pkgs.gperf_3-1;
gperf_3-1 = callPackage ../all-pkgs/g/gperf {
  channel = "3.1";
};
gperf_3-0 = callPackage ../all-pkgs/g/gperf {
  channel = "3.0";
};

gperftools = callPackage ../all-pkgs/g/gperftools { };

gpgme = callPackage ../all-pkgs/g/gpgme { };

gpm = callPackage ../all-pkgs/g/gpm-ncurses { };

gpsd = callPackage ../all-pkgs/g/gpsd { };

gptfdisk = callPackage ../all-pkgs/g/gptfdisk { };

grafana = pkgs.goPackages.grafana.bin // { outputs = [ "bin" ]; };

granite = callPackage ../all-pkgs/g/granite { };

graphite2 = callPackage ../all-pkgs/g/graphite2 { };

graphviz = callPackage ../all-pkgs/g/graphviz { };

grilo = callPackage ../all-pkgs/g/grilo { };

grilo-plugins = callPackage ../all-pkgs/g/grilo-plugins { };

groff = callPackage ../all-pkgs/g/groff { };

grub_bios-i386 = callPackage ../all-pkgs/g/grub {
  type = "bios-i386";
};

grub_efi-x86_64 = callPackage ../all-pkgs/g/grub {
  type = "efi-x86_64";
};

grub_efi-i386 = callPackage ../all-pkgs/g/grub {
  type = "efi-i386";
};

gsettings-desktop-schemas_3-24 =
  callPackage ../all-pkgs/g/gsettings-desktop-schemas {
    channel = "3.24";
    gnome-backgrounds = pkgs.gnome-backgrounds_3-24;
  };
gsettings-desktop-schemas =
  callPackageAlias "gsettings-desktop-schemas_3-24" { };

grpc = callPackage ../all-pkgs/g/grpc { };

gsm = callPackage ../all-pkgs/g/gsm { };

gsound = callPackage ../all-pkgs/g/gsound { };

gssdp_1-0 = callPackage ../all-pkgs/g/gssdp {
  channel = "1.0";
  libsoup = pkgs.libsoup_2-60;
  vala = pkgs.vala_0-34;
};
gssdp = callPackageAlias "gssdp_1-0" { };

gst-libav_1-12 = callPackage ../all-pkgs/g/gst-libav {
  channel = "1.12";
  gst-plugins-base = pkgs.gst-plugins-base_1-12;
  gstreamer = pkgs.gstreamer_1-12;
};
gst-libav = callPackageAlias "gst-libav_1-12" { };

gst-plugins-bad_generics = overrides:
  callPackage ../all-pkgs/g/gst-plugins-bad ({
    chromaprint = null;
    faac = null;
    faad2 = null;
    flite = null;
    game-music-emu = null;
    gsm = null;
    ladspa-sdk = null;
    libbs2b = null;
    libmms = null;
    libmodplug = null;
    libvisual = null;
    musepack = null;
    openal = null;
    opencv = null;
    openexr = null;
    openjpeg = null;
    rtmpdump = null;
    schroedinger = null;
    soundtouch = null;
    spandsp = null;
    gtk_3 = null;
    qt5 = null;
  } // overrides);
gst-plugins-bad_1-12 = pkgs.gst-plugins-bad_generics {
  channel = "1.12";
  gst-plugins-base = pkgs.gst-plugins-base_1-12;
  gstreamer = pkgs.gstreamer_1-12;
};
gst-plugins-bad = callPackageAlias "gst-plugins-bad_1-12" { };

gst-plugins-base_1-12 = callPackage ../all-pkgs/g/gst-plugins-base {
  channel = "1.12";
  gstreamer = pkgs.gstreamer_1-12;
};
gst-plugins-base = callPackageAlias "gst-plugins-base_1-12" { };

gst-plugins-good_1-12 = callPackage ../all-pkgs/g/gst-plugins-good {
  channel = "1.12";
  gst-plugins-base = pkgs.gst-plugins-base_1-12;
  gstreamer = pkgs.gstreamer_1-12;
};
gst-plugins-good = callPackageAlias "gst-plugins-good_1-12" { };

gst-plugins-ugly_generics = overrides:
  callPackage ../all-pkgs/g/gst-plugins-ugly ({
    amrnb = null;
    amrwb = null;
  } // overrides);
gst-plugins-ugly_1-12 = pkgs.gst-plugins-ugly_generics {
  channel = "1.12";
  gst-plugins-base = pkgs.gst-plugins-base_1-12;
  gstreamer = pkgs.gstreamer_1-12;
};
gst-plugins-ugly = callPackageAlias "gst-plugins-ugly_1-12" { };

gst-validate_1-12 = callPackage ../all-pkgs/g/gst-validate {
  channel = "1.12";
  gst-plugins-base = pkgs.gst-plugins-base_1-12;
  gstreamer = pkgs.gstreamer_1-12;
};
gst-validate = callPackageAlias "gst-validate_1-12" { };

gstreamer_1-12 = callPackage ../all-pkgs/g/gstreamer {
  channel = "1.12";
};
gstreamer = callPackageAlias "gstreamer_1-12" { };

gstreamer-editing-services_1-12 =
  callPackage ../all-pkgs/g/gstreamer-editing-services {
    channel = "1.12";
    gnonlin = callPackageAlias "gnonlin" {
      gst-plugins-base = pkgs.gst-plugins-base_1-12;
      gstreamer = pkgs.gstreamer_1-12;
    };
    gst-plugins-base = pkgs.gst-plugins-base_1-12;
    gstreamer = pkgs.gstreamer_1-12;
  };
gstreamer-editing-services =
  callPackageAlias "gstreamer-editing-services_1-12" { };

gstreamer-vaapi_1-12 = callPackage ../all-pkgs/g/gstreamer-vaapi {
  channel = "1.12";
  gst-plugins-bad = pkgs.gst-plugins-bad_1-12;
  gst-plugins-base = pkgs.gst-plugins-base_1-12;
  gstreamer = pkgs.gstreamer_1-12;
};
gstreamer-vaapi = callPackageAlias "gstreamer-vaapi_1-12" { };

googletest = callPackage ../all-pkgs/g/googletest { };

gtk_2 = callPackage ../all-pkgs/g/gtk/2.x.nix { };
# Deprecated alias
gtk2 = callPackageAlias "gtk_2" { };
gtk_3-22 = callPackage ../all-pkgs/g/gtk {
  channel = "3.22";
  atk = pkgs.atk_2-26;
  at-spi2-atk = pkgs.at-spi2-atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
gtk_3 = callPackageAlias "gtk_3-22" { };
# Deprecated alias
gtk3 = callPackageAlias "gtk_3" { };
gtk = callPackageAlias "gtk_3" { };

gtk-doc = callPackage ../all-pkgs/g/gtk-doc { };

gtkhtml = callPackage ../all-pkgs/g/gtkhtml { };

gtkimageview = callPackage ../all-pkgs/g/gtkimageview { };

gtkmm_2 = callPackage ../all-pkgs/g/gtkmm/2.x.nix { };
gtkmm_3-22 = callPackage ../all-pkgs/g/gtkmm {
  channel = "3.22";
  atkmm = pkgs.atkmm_2-24;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gtk = pkgs.gtk_3-22;
  pangomm = pkgs.pangomm_2-40;
};
gtkmm_3 = callPackageAlias "gtkmm_3-22" { };

gtksourceview_3-22 = callPackage ../all-pkgs/g/gtksourceview {
  channel = "3.22";
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  vala = pkgs.vala_0-34;
};
gtksourceview = callPackageAlias "gtksourceview_3-22" { };

gtkspell_2 = callPackage ../all-pkgs/g/gtkspell/2.x.nix { };
gtkspell_3 = callPackage ../all-pkgs/g/gtkspell/3.x.nix { };
gtkspell = callPackageAlias "gtkspell_3" { };

guile = callPackage ../all-pkgs/g/guile { };

guitarix = callPackage ../all-pkgs/g/guitarix {
  fftw = pkgs.fftw_single;
};

gupnp_1-0 = callPackage ../all-pkgs/g/gupnp {
  channel = "1.0";
  gssdp = pkgs.gssdp_1-0;
  libsoup = pkgs.libsoup_2-60;
  vala = pkgs.vala_0-34;
};
gupnp = callPackageAlias "gupnp_1-0" { };

gupnp-av_0-12 = callPackage ../all-pkgs/g/gupnp-av {
  channel = "0.12";
};
gupnp-av = callPackageAlias "gupnp-av_0-12" { };

gupnp-igd = callPackage ../all-pkgs/g/gupnp-igd { };

gvfs_1-34 = callPackage ../all-pkgs/g/gvfs {
  channel = "1.34";
  libsoup = pkgs.libsoup_2-60;
};
gvfs = callPackageAlias "gvfs_1-34" { };

gx = pkgs.goPackages.gx.bin // { outputs = [ "bin" ]; };

gzip = callPackage ../all-pkgs/g/gzip { };

hadoop = callPackage ../all-pkgs/h/hadoop { };

harfbuzz_lib = callPackage ../all-pkgs/h/harfbuzz {
  type = "lib";
};
harfbuzz_full = callPackage ../all-pkgs/h/harfbuzz {
  type = "full";
};

hdparm = callPackage ../all-pkgs/h/hdparm { };

help2man = callPackage ../all-pkgs/h/help2man { };

hexchat = callPackage ../all-pkgs/h/hexchat { };

hicolor-icon-theme = callPackage ../all-pkgs/h/hicolor-icon-theme { };

hidapi = callPackage ../all-pkgs/h/hidapi { };

highlight = callPackage ../all-pkgs/h/highlight { };

hiredis = callPackage ../all-pkgs/h/hiredis { };

hsts-list = callPackage ../all-pkgs/h/hsts-list { };

htop = callPackage ../all-pkgs/h/htop { };

http-parser = callPackage ../all-pkgs/h/http-parser { };

httping = callPackage ../all-pkgs/h/httping { };

hugo = pkgs.goPackages.hugo.bin // { outputs = [ "bin" ]; };

hunspell = callPackage ../all-pkgs/h/hunspell { };

hwdata = callPackage ../all-pkgs/h/hwdata { };

i2c-tools = callPackage ../all-pkgs/i/i2c-tools { };

iana-etc = callPackage ../all-pkgs/i/iana-etc { };

iasl = callPackage ../all-pkgs/i/iasl { };

ibus = callPackage ../all-pkgs/i/ibus { };

ice = callPackage ../all-pkgs/i/ice { };

icu = callPackage ../all-pkgs/i/icu { };

id3lib = callPackage ../all-pkgs/i/id3lib { };

id3v2 = callPackage ../all-pkgs/i/id3v2 { };

idnkit = callPackage ../all-pkgs/i/idnkit { };

iftop = callPackage ../all-pkgs/i/iftop { };

imagemagick = callPackage ../all-pkgs/i/imagemagick { };

imlib2 = callPackage ../all-pkgs/i/imlib2 { };

iniparser = callPackage ../all-pkgs/i/iniparser { };

inkscape = callPackage ../all-pkgs/i/inkscape { };

inotify-tools = callPackage ../all-pkgs/i/inotify-tools { };

inputproto = callPackage ../all-pkgs/i/inputproto { };

intel-microcode = callPackage ../all-pkgs/i/intel-microcode { };

intel-vaapi-driver = callPackage ../all-pkgs/i/intel-vaapi-driver { };

intltool = callPackage ../all-pkgs/i/intltool { };

iotop = pkgs.python3Packages.iotop;

iperf_2 = callPackage ../all-pkgs/i/iperf {
  channel = "2";
};
iperf_3 = callPackage ../all-pkgs/i/iperf {
  channel = "3";
};
iperf = callPackageAlias "iperf_3" { };

ipfs = pkgs.goPackages.ipfs.bin // { outputs = [ "bin" ]; };

ipfs-hasher = callPackage ../all-pkgs/i/ipfs-hasher { };

ipmitool = callPackage ../all-pkgs/i/ipmitool { };

iproute = callPackage ../all-pkgs/i/iproute { };

ipset = callPackage ../all-pkgs/i/ipset { };

iptables = callPackage ../all-pkgs/i/iptables { };

iputils = callPackage ../all-pkgs/i/iputils { };

isl_0-14 = callPackage ../all-pkgs/i/isl {
  channel = "0.14";
};
isl_0-18 = callPackage ../all-pkgs/i/isl {
  channel = "0.18";
};
isl = callPackageAlias "isl_0-18" { };

iso-codes = callPackage ../all-pkgs/i/iso-codes { };

itstool = callPackage ../all-pkgs/i/itstool { };

iw = callPackage ../all-pkgs/i/iw { };

jam = callPackage ../all-pkgs/j/jam { };

jansson = callPackage ../all-pkgs/j/jansson { };

jasper = callPackage ../all-pkgs/j/jasper { };

jbig2dec = callPackage ../all-pkgs/j/jbig2dec { };

jemalloc = callPackage ../all-pkgs/j/jemalloc { };

jq = callPackage ../all-pkgs/j/jq { };

jshon = callPackage ../all-pkgs/j/jshon { };

json-c = callPackage ../all-pkgs/j/json-c { };

json-glib = callPackage ../all-pkgs/j/json-glib { };

jsoncpp = callPackage ../all-pkgs/j/jsoncpp {
  cmake = pkgs.cmake_bootstrap;
};

judy = callPackage ../all-pkgs/j/judy { };

kbd = callPackage ../all-pkgs/k/kbd { };

kbproto = callPackage ../all-pkgs/k/kbproto { };

kea = callPackage ../all-pkgs/k/kea { };

keepalived = callPackage ../all-pkgs/k/keepalived { };

keepassx = callPackage ../all-pkgs/k/keepassx { };

kerberos = callPackageAlias "krb5_lib" { };

kexec-tools = callPackage ../all-pkgs/k/kexec-tools { };

keyutils = callPackage ../all-pkgs/k/keyutils { };

kid3 = callPackage ../all-pkgs/k/kid3 { };

kmod = callPackage ../all-pkgs/k/kmod { };

kmscon = callPackage ../all-pkgs/k/kmscon { };

knot = callPackage ../all-pkgs/k/knot { };

krb5_full = callPackage ../all-pkgs/k/krb5 { };
krb5_lib = callPackageAlias "krb5_full" {
  type = "lib";
};

#kubernetes = callPackage ../all-pkgs/k/kubernetes { };

kyotocabinet = callPackage ../all-pkgs/k/kyotocabinet { };

kytea = callPackage ../all-pkgs/k/kytea { };

ladspa-sdk = callPackage ../all-pkgs/l/ladspa-sdk { };

lame = callPackage ../all-pkgs/l/lame {
  libsndfile = null;
};

lcms = callPackage ../all-pkgs/l/lcms { };
# Deprecated alias
lcms2 = callPackageAlias "lcms" { };

ldb = callPackage ../all-pkgs/l/ldb { };

ldns = callPackage ../all-pkgs/l/ldns { };

lego = pkgs.goPackages.lego.bin // { outputs = [ "bin" ]; };

lensfun = callPackage ../all-pkgs/l/lensfun { };

leptonica = callPackage ../all-pkgs/l/leptonica { };

less = callPackage ../all-pkgs/l/less { };

leveldb = callPackage ../all-pkgs/l/leveldb { };

lftp = callPackage ../all-pkgs/l/lftp { };

lib-bash = callPackage ../all-pkgs/l/lib-bash { };

libaacs = callPackage ../all-pkgs/l/libaacs { };

libaccounts-glib = callPackage ../all-pkgs/l/libaccounts-glib { };

libaio = callPackage ../all-pkgs/l/libaio { };

libao = callPackage ../all-pkgs/l/libao { };

libarchive = callPackage ../all-pkgs/l/libarchive { };

libasr = callPackage ../all-pkgs/l/libasr { };

libass = callPackage ../all-pkgs/l/libass { };

libassuan = callPackage ../all-pkgs/l/libassuan { };

libatasmart = callPackage ../all-pkgs/l/libatasmart { };

libatomic_ops = callPackage ../all-pkgs/l/libatomic_ops { };

libavc1394 = callPackage ../all-pkgs/l/libavc1394 { };

libb64 = callPackage ../all-pkgs/l/libb64 { };

libblockdev = callPackage ../all-pkgs/l/libblockdev { };

libbluray = callPackage ../all-pkgs/l/libbluray { };

libbsd = callPackage ../all-pkgs/l/libbsd { };

libbson = callPackage ../all-pkgs/l/libbson { };

libburn = callPackage ../all-pkgs/l/libburn { };

libbytesize = callPackage ../all-pkgs/l/libbytesize { };

libcacard = callPackage ../all-pkgs/l/libcacard { };

libcanberra = callPackage ../all-pkgs/l/libcanberra { };

libcap-ng = callPackage ../all-pkgs/l/libcap-ng { };

libcddb = callPackage ../all-pkgs/l/libcddb { };

libcdio = callPackage ../all-pkgs/l/libcdio { };

libclc = callPackage ../all-pkgs/l/libclc { };

libconfig = callPackage ../all-pkgs/l/libconfig { };

libconfuse = callPackage ../all-pkgs/l/libconfuse { };

libcroco = callPackage ../all-pkgs/l/libcroco { };

libcue = callPackage ../all-pkgs/l/libcue { };

libdaemon = callPackage ../all-pkgs/l/libdaemon { };

libdbi = callPackage ../all-pkgs/l/libdbi { };

libdc1394 = callPackage ../all-pkgs/l/libdc1394 { };

libdmx = callPackage ../all-pkgs/l/libdmx { };

libdrm = callPackage ../all-pkgs/l/libdrm { };

libdvdcss = callPackage ../all-pkgs/l/libdvdcss { };

libdvdnav = callPackage ../all-pkgs/l/libdvdnav { };

libdvdread = callPackage ../all-pkgs/l/libdvdread { };

libebml = callPackage ../all-pkgs/l/libebml { };

libebur128 = callPackage ../all-pkgs/l/libebur128 { };

libedit = callPackage ../all-pkgs/l/libedit { };

libelf = callPackage ../all-pkgs/l/libelf { };

libepoxy = callPackage ../all-pkgs/l/libepoxy { };

liberation-fonts = callPackage ../all-pkgs/l/liberation-fonts { };

libev = callPackage ../all-pkgs/l/libev { };

libevdev = callPackage ../all-pkgs/l/libevdev { };

libevent = callPackage ../all-pkgs/l/libevent { };

libexif = callPackage ../all-pkgs/l/libexif { };

libfaketime = callPackage ../all-pkgs/l/libfaketime { };

libffi = callPackage ../all-pkgs/l/libffi { };

libfilezilla = callPackage ../all-pkgs/l/libfilezilla { };

libfontenc = callPackage ../all-pkgs/l/libfontenc { };

libfpx = callPackage ../all-pkgs/l/libfpx { };

libftdi = callPackage ../all-pkgs/l/libftdi { };

libgcrypt = callPackage ../all-pkgs/l/libgcrypt { };

libgd = callPackage ../all-pkgs/l/libgd { };

libgda = callPackage ../all-pkgs/l/libgda { };

libgdata = callPackage ../all-pkgs/l/libgdata { };

libgdiplus = callPackage ../all-pkgs/l/libgdiplus { };

libgee_0-20 = callPackage ../all-pkgs/l/libgee {
  channel = "0.20";
  vala = pkgs.vala_0-36;
};
libgee = callPackageAlias "libgee_0-20" { };

libgfbgraph = callPackage ../all-pkgs/l/libgfbgraph { };

libgit2 = callPackage ../all-pkgs/l/libgit2 { };

libgksu = callPackage ../all-pkgs/l/libgksu { };

libglade = callPackage ../all-pkgs/l/libglade { };

libglvnd = callPackage ../all-pkgs/l/libglvnd { };

libgnome-keyring = callPackage ../all-pkgs/l/libgnome-keyring { };

libgnomekbd_3-22 = callPackage ../all-pkgs/l/libgnomekbd {
  channel = "3.22";
};
libgnomekbd = callPackageAlias "libgnomekbd_3-22" { };

libgpg-error = callPackage ../all-pkgs/l/libgpg-error { };

libgphoto2 = callPackage ../all-pkgs/l/libgphoto2 { };

libgpod = callPackage ../all-pkgs/l/libgpod {
  inherit (pkgs.pythonPackages) mutagen;
};

libgsf_1-14 = callPackage ../all-pkgs/l/libgsf {
  channel = "1.14";
};
libgsf = callPackageAlias "libgsf_1-14" { };

libgudev = callPackage ../all-pkgs/l/libgudev { };

libgusb = callPackage ../all-pkgs/l/libgusb { };

libgweather_3-24 = callPackage ../all-pkgs/l/libgweather {
  channel = "3.24";
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  libsoup = pkgs.libsoup_2-60;
  vala = pkgs.vala_0-36;
};
libgweather = callPackageAlias "libgweather_3-24" { };

libgxps_0-3 = callPackage ../all-pkgs/l/libgxps {
  channel = "0.3";
};
libgxps = callPackageAlias "libgxps_0-3" { };

libical = callPackage ../all-pkgs/l/libical { };

libice = callPackage ../all-pkgs/l/libice { };

libid3tag = callPackage ../all-pkgs/l/libid3tag { };

libidl = callPackage ../all-pkgs/l/libidl { };

libidn = callPackage ../all-pkgs/l/libidn { };

libidn2 = callPackage ../all-pkgs/l/libidn2 { };

libimobiledevice = callPackage ../all-pkgs/l/libimobiledevice { };

libiodbc = callPackage ../all-pkgs/l/libiodbc {
  gtk_2 = null;
};

libinput = callPackage ../all-pkgs/l/libinput { };

libiscsi = callPackage ../all-pkgs/l/libiscsi { };

libisoburn = callPackage ../all-pkgs/l/libisoburn { };

libisofs = callPackage ../all-pkgs/l/libisofs { };

libjpeg_original = callPackage ../all-pkgs/l/libjpeg { };
libjpeg-turbo_1-4 = callPackage ../all-pkgs/l/libjpeg-turbo {
  channel = "1.4";
};
libjpeg-turbo_1-5 = callPackage ../all-pkgs/l/libjpeg-turbo {
  channel = "1.5";
};
libjpeg-turbo = callPackageAlias "libjpeg-turbo_1-5" { };
libjpeg = callPackageAlias "libjpeg-turbo" { };

libkate = callPackage ../all-pkgs/l/libkate { };

libksba = callPackage ../all-pkgs/l/libksba { };

liblfds = callPackage ../all-pkgs/l/liblfds { };

liblogging = callPackage ../all-pkgs/l/liblogging { };

libmatroska = callPackage ../all-pkgs/l/libmatroska { };

libmbim = callPackage ../all-pkgs/l/libmbim { };

libmcrypt = callPackage ../all-pkgs/l/libmcrypt { };

libmediaart = callPackage ../all-pkgs/l/libmediaart { };

libmediainfo = callPackage ../all-pkgs/l/libmediainfo { };

libmhash = callPackage ../all-pkgs/l/libmhash { };

libmicrohttpd = callPackage ../all-pkgs/l/libmicrohttpd { };

libmms = callPackage ../all-pkgs/l/libmms { };

libmnl = callPackage ../all-pkgs/l/libmnl { };

libmodplug = callPackage ../all-pkgs/l/libmodplug { };

libmpc = callPackage ../all-pkgs/l/libmpc { };

libmpdclient = callPackage ../all-pkgs/l/libmpdclient { };

libmpeg2 = callPackage ../all-pkgs/l/libmpeg2 {
  libSDL = null;
  xorg = null;
};

libmtp = callPackage ../all-pkgs/l/libmtp { };

libmusicbrainz = callPackage ../all-pkgs/l/libmusicbrainz { };

libmypaint = callPackage ../all-pkgs/l/libmypaint { };

libnatpmp = callPackage ../all-pkgs/l/libnatpmp { };

libnetfilter_acct = callPackage ../all-pkgs/l/libnetfilter_acct { };

libnetfilter_conntrack = callPackage ../all-pkgs/l/libnetfilter_conntrack { };

libnetfilter_cthelper = callPackage ../all-pkgs/l/libnetfilter_cthelper { };

libnetfilter_cttimeout = callPackage ../all-pkgs/l/libnetfilter_cttimeout { };

libnetfilter_queue = callPackage ../all-pkgs/l/libnetfilter_queue { };

libnfnetlink = callPackage ../all-pkgs/l/libnfnetlink { };

libnfsidmap = callPackage ../all-pkgs/l/libnfsidmap { };

libnftnl = callPackage ../all-pkgs/l/libnftnl { };

libnih = callPackage ../all-pkgs/l/libnih { };

libnl = callPackage ../all-pkgs/l/libnl { };

libnotify = callPackage ../all-pkgs/l/libnotify { };

libogg = callPackage ../all-pkgs/l/libogg { };

libomxil-bellagio = callPackage ../all-pkgs/l/libomxil-bellagio { };

liboping = callPackage ../all-pkgs/l/liboping { };

libosinfo = callPackage ../all-pkgs/l/libosinfo { };

libossp-uuid = callPackage ../all-pkgs/l/libossp-uuid { };

libpcap = callPackage ../all-pkgs/l/libpcap { };

libpeas_1-22 = callPackage ../all-pkgs/l/libpeas {
  channel = "1.22";
};
libpeas = callPackageAlias "libpeas_1-22" { };

libpipeline = callPackage ../all-pkgs/l/libpipeline { };

libplist = callPackage ../all-pkgs/l/libplist { };

libpng = callPackage ../all-pkgs/l/libpng { };

libproxy = callPackage ../all-pkgs/l/libproxy { };

libpsl = callPackage ../all-pkgs/l/libpsl { };

libpthread-stubs = callPackage ../all-pkgs/l/libpthread-stubs { };

libpwquality = callPackage ../all-pkgs/l/libpwquality { };

libqmi = callPackage ../all-pkgs/l/libqmi { };

libraw = callPackage ../all-pkgs/l/libraw { };

libraw1394 = callPackage ../all-pkgs/l/libraw1394 { };

librelp = callPackage ../all-pkgs/l/librelp { };

libressl = callPackage ../all-pkgs/l/libressl { };

librsvg = callPackage ../all-pkgs/l/librsvg { };

librsync = callPackage ../all-pkgs/l/librsync { };

libs3 = callPackage ../all-pkgs/l/libs3 { };

libsamplerate = callPackage ../all-pkgs/l/libsamplerate { };

libscrypt = callPackage ../all-pkgs/l/libscrypt { };

libseccomp = callPackage ../all-pkgs/l/libseccomp { };

libsecret = callPackage ../all-pkgs/l/libsecret { };

libselinux = callPackage ../all-pkgs/l/libselinux { };

libsepol = callPackage ../all-pkgs/l/libsepol { };

libshout = callPackage ../all-pkgs/l/libshout { };

libsigcxx_2-10 = callPackage ../all-pkgs/l/libsigcxx {
  channel = "2.10";
};
libsigcxx = callPackageAlias "libsigcxx_2-10" { };

libsigsegv = callPackage ../all-pkgs/l/libsigsegv { };

libsm = callPackage ../all-pkgs/l/libsm { };

libsmbios = callPackage ../all-pkgs/l/libsmbios { };

libsmi = callPackage ../all-pkgs/l/libsmi { };

libsndfile = callPackage ../all-pkgs/l/libsndfile { };

libsodium = callPackage ../all-pkgs/l/libsodium { };

libsoup_2-60 = callPackage ../all-pkgs/l/libsoup {
  channel = "2.60";
};
libsoup = callPackageAlias "libsoup_2-60" { };

libspectre = callPackage ../all-pkgs/l/libspectre { };

libssh = callPackage ../all-pkgs/l/libssh { };

libssh2 = callPackage ../all-pkgs/l/libssh2 { };

libstoragemgmt = callPackage ../all-pkgs/l/libstoragemgmt { };

libtasn1 = callPackage ../all-pkgs/l/libtasn1 { };

libtheora = callPackage ../all-pkgs/l/libtheora { };

libtiger = callPackage ../all-pkgs/l/libtiger { };

libtiff = callPackage ../all-pkgs/l/libtiff { };

libtirpc = callPackage ../all-pkgs/l/libtirpc { };

libtool = callPackage ../all-pkgs/l/libtool { };

libtorrent = callPackage ../all-pkgs/l/libtorrent { };

libtorrent-rasterbar_1-1 = callPackage ../all-pkgs/l/libtorrent-rasterbar {
  channel = "1.1";
};
libtorrent-rasterbar_1-1_head = callPackage ../all-pkgs/l/libtorrent-rasterbar {
  channel = "1.1-head";
};
libtorrent-rasterbar_head = callPackage ../all-pkgs/l/libtorrent-rasterbar {
  channel = "head";
};
libtorrent-rasterbar = callPackageAlias "libtorrent-rasterbar_1-1" { };

libtsm = callPackage ../all-pkgs/l/libtsm { };

libtxc_dxtn = callPackage ../all-pkgs/l/libtxc_dxtn { };

libu2f-host = callPackage ../all-pkgs/l/libu2f-host { };

libungif = callPackage ../all-pkgs/l/libungif { };

libunique_1 = callPackage ../all-pkgs/l/libunique/1.x.nix { };
libunique_3 = callPackage ../all-pkgs/l/libunique/3.x.nix { };
libunique = callPackageAlias "libunique_3" { };

libunistring = callPackage ../all-pkgs/l/libunistring { };

libunwind = callPackage ../all-pkgs/l/libunwind { };

liburcu = callPackage ../all-pkgs/l/liburcu { };

libusb_0 = callPackageAlias "libusb-compat" { };
libusb_1 = callPackage ../all-pkgs/l/libusb { };
libusb = callPackageAlias "libusb_1" { };

libusb-compat = callPackage ../all-pkgs/l/libusb-compat { };

libusbmuxd = callPackage ../all-pkgs/l/libusbmuxd { };

libutempter = callPackage ../all-pkgs/l/libutempter { };

libutp = callPackage ../all-pkgs/l/libutp { };

libuv = callPackage ../all-pkgs/l/libuv { };

libva = callPackage ../all-pkgs/l/libva { };

libva-vdpau-driver = callPackage ../all-pkgs/l/libva-vdpau-driver { };

libvdpau = callPackage ../all-pkgs/l/libvdpau { };

libvdpau-va-gl = callPackage ../all-pkgs/l/libvdpau-va-gl { };

libverto = callPackage ../all-pkgs/l/libverto { };

libvorbis = callPackage ../all-pkgs/l/libvorbis { };

libvpx_1-6 = callPackage ../all-pkgs/l/libvpx {
  channel = "1.6";
};
libvpx_head = callPackage ../all-pkgs/l/libvpx {
  channel = "1.999";
};
libvpx = callPackageAlias "libvpx_1-6" { };

libwacom = callPackage ../all-pkgs/l/libwacom { };

libwebp = callPackage ../all-pkgs/l/libwebp { };

libwps = callPackage ../all-pkgs/l/libwps { };

libx11 = callPackage ../all-pkgs/l/libx11 { };

libxau = callPackage ../all-pkgs/l/libxau { };

libxcb = callPackage ../all-pkgs/l/libxcb { };

libxcomposite = callPackage ../all-pkgs/l/libxcomposite { };

libxcursor = callPackage ../all-pkgs/l/libxcursor { };

libxdamage = callPackage ../all-pkgs/l/libxdamage { };

libxdmcp = callPackage ../all-pkgs/l/libxdmcp { };

libxext = callPackage ../all-pkgs/l/libxext { };

libxfce4ui_4-12 = callPackage ../all-pkgs/l/libxfce4ui {
  channel = "4.12";
};
libxfce4ui = callPackageAlias "libxfce4ui_4-12" { };

libxfce4util_4-12 = callPackage ../all-pkgs/l/libxfce4util {
  channel = "4.12";
};
libxfce4util = callPackageAlias "libxfce4util_4-12" { };

libxfixes = callPackage ../all-pkgs/l/libxfixes { };

libxfont = callPackage ../all-pkgs/l/libxfont {
  channel = "1";
};

libxfont2 = callPackage ../all-pkgs/l/libxfont {
  channel = "2";
};

libxft = callPackage ../all-pkgs/l/libxft { };

libxi = callPackage ../all-pkgs/l/libxi { };

libxinerama = callPackage ../all-pkgs/l/libxinerama { };

libxkbcommon = callPackage ../all-pkgs/l/libxkbcommon { };

libxkbfile = callPackage ../all-pkgs/l/libxkbfile { };

libxklavier = callPackage ../all-pkgs/l/libxklavier { };

libxml2 = callPackage ../all-pkgs/l/libxml2 { };

libxrandr = callPackage ../all-pkgs/l/libxrandr { };

libxrender = callPackage ../all-pkgs/l/libxrender { };

libxres = callPackage ../all-pkgs/l/libxres { };

libxscrnsaver = callPackage ../all-pkgs/l/libxscrnsaver { };

libxslt = callPackage ../all-pkgs/l/libxslt { };

libxt = callPackage ../all-pkgs/l/libxt { };

libxtst = callPackage ../all-pkgs/l/libxtst { };

libxv = callPackage ../all-pkgs/l/libxv { };

libyaml = callPackage ../all-pkgs/l/libyaml { };

libzapojit = callPackage ../all-pkgs/l/libzapojit { };

libzip = callPackage ../all-pkgs/l/libzip { };

lightdm = callPackage ../all-pkgs/l/lightdm { };

lightdm-gtk-greeter = callPackage ../all-pkgs/l/lightdm-gtk-greeter { };

lilv = callPackage ../all-pkgs/l/lilv { };

linenoise = callPackage ../all-pkgs/l/linenoise { };

linenoise-ng = callPackage ../all-pkgs/l/linenoise-ng { };

linux-firmware = callPackage ../all-pkgs/l/linux-firmware { };

# Minimum version for external distros
linux-headers_4-4 = callPackage ../all-pkgs/l/linux-headers {
  channel = "4.4";
};
# Minimum version for triton
linux-headers_4-9 = callPackage ../all-pkgs/l/linux-headers {
  channel = "4.9";
};
linux-headers = callPackageAlias "linux-headers_4-4" { };

lirc = callPackage ../all-pkgs/l/lirc { };

live555 = callPackage ../all-pkgs/l/live555 { };

llvm_4 = callPackage ../all-pkgs/l/llvm {
  channel = "4";
};
llvm_5 = callPackage ../all-pkgs/l/llvm {
  channel = "5";
};
llvm = callPackageAlias "llvm_5" { };

lm-sensors = callPackage ../all-pkgs/l/lm-sensors { };

lmdb = callPackage ../all-pkgs/l/lmdb { };

lrdf = callPackage ../all-pkgs/l/lrdf { };

lsof = callPackage ../all-pkgs/l/lsof { };

luajit = callPackage ../all-pkgs/l/luajit { };

lv2 = callPackage ../all-pkgs/l/lv2 { };

lvm2 = callPackage ../all-pkgs/l/lvm2 { };

lxc = callPackage ../all-pkgs/l/lxc { };

lxd = pkgs.goPackages.lxd.bin // { outputs = [ "bin" ]; };

lz4 = callPackage ../all-pkgs/l/lz4 { };

lzip = callPackage ../all-pkgs/l/lzip { };

lzo = callPackage ../all-pkgs/l/lzo { };

m4 = callPackageAlias "gnum4" { };

mac = callPackage ../all-pkgs/m/mac { };

man = callPackage ../all-pkgs/m/man { };

man-db = callPackage ../all-pkgs/m/man-db { };

man-pages = callPackage ../all-pkgs/m/man-pages { };

mariadb = callPackage ../all-pkgs/m/mariadb { };
mysql = callPackageAlias "mariadb" { };
mysql_lib = callPackageAlias "mysql" { };

mariadb-connector-c = callPackage ../all-pkgs/m/mariadb-connector-c { };

mcelog = callPackage ../all-pkgs/m/mcelog { };

mcpp = callPackage ../all-pkgs/m/mcpp { };

mdadm = callPackage ../all-pkgs/m/mdadm { };

mediainfo = callPackage ../all-pkgs/m/mediainfo { };

mercurial = pkgs.python2Packages.mercurial;

mesa_noglu = callPackage ../all-pkgs/m/mesa {
  libglvnd = null;
  buildConfig = "full";
};
mesa_drivers = pkgs.mesa_noglu.drivers;
mesa = pkgs.buildEnv {
  name = "mesa-${pkgs.mesa_noglu.version}";
  paths = with pkgs; [ mesa_noglu mesa_glu ];
  passthru = pkgs.mesa_glu.passthru // pkgs.mesa_noglu.passthru;
};

mesa-demos = callPackage ../all-pkgs/m/mesa-demos { };

meson = pkgs.python3Packages.meson;

#mesos = callPackage ../all-pkgs/m/mesos {
#  inherit (pythonPackages) python boto setuptools wrapPython;
#  pythonProtobuf = pythonPackages.protobuf2_5;
#  perf = linuxPackages.perf;
#};

mft = callPackage ../all-pkgs/m/mft {
  kernel = null;
};

mfx-dispatcher = callPackage ../all-pkgs/m/mfx-dispatcher { };

mg = callPackage ../all-pkgs/m/mg { };

mime-types = callPackage ../all-pkgs/m/mime-types { };

minicom = callPackage ../all-pkgs/m/minicom { };

minidlna = callPackage ../all-pkgs/m/minidlna { };

minio = pkgs.goPackages.minio.bin // { outputs = [ "bin" ]; };

minipro = callPackage ../all-pkgs/m/minipro { };

minisign = callPackage ../all-pkgs/m/minisign { };

miniupnpc = callPackage ../all-pkgs/m/miniupnpc { };

mixxx = callPackage ../all-pkgs/m/mixxx { };

mkvtoolnix = callPackage ../all-pkgs/m/mkvtoolnix { };

mm-common = callPackage ../all-pkgs/m/mm-common { };

modemmanager = callPackage ../all-pkgs/m/modemmanager { };

mongo-c-driver = callPackage ../all-pkgs/m/mongo-c-driver { };

mongodb = callPackage ../all-pkgs/m/mongodb { };

mongodb-tools = pkgs.goPackages.mongo-tools.bin // { outputs = [ "bin" ]; };

mosh = callPackage ../all-pkgs/m/mosh { };

motif = callPackage ../all-pkgs/m/motif { };

mp3val = callPackage ../all-pkgs/m/mp3val { };

mp4v2 = callPackage ../all-pkgs/m/mp4v2 { };

mpd = callPackage ../all-pkgs/m/mpd { };

mpdris2 = callPackage ../all-pkgs/m/mpdris2 { };

mpfr = callPackage ../all-pkgs/m/mpfr { };

mpv = callPackage ../all-pkgs/m/mpv {
  jack2_lib = null;
  lcms2 = null;
  libcaca = null;
  nvidia-cuda-toolkit = null;
  nvidia-drivers = null;
  openal = null;
  rubberband = null;
  samba_client = null;
};

ms-sys = callPackage ../all-pkgs/m/ms-sys { };

msgpack-c = callPackage ../all-pkgs/m/msgpack-c { };

mtdev = callPackage ../all-pkgs/m/mtdev { };

mtools = callPackage ../all-pkgs/m/mtools { };

mtr = callPackage ../all-pkgs/m/mtr { };

mumble_generics = overrides: callPackage ../all-pkgs/m/mumble ({
  jack2_lib = null;
  portaudio = null;
  pulseaudio_lib = null;
  speech-dispatcher = null;
} // overrides);
mumble_git = pkgs.mumble_generics {
  channel = "git";
  config = "mumble";
};
mumble = callPackageAlias "mumble_git" { };

mupdf = callPackage ../all-pkgs/m/mupdf { };

murmur_git = pkgs.mumble_generics {
  channel = "git";
  config = "murmur";
};
murmur = callPackageAlias "murmur_git" { };

musepack = callPackage ../all-pkgs/m/musepack { };

musl = callPackage ../all-pkgs/m/musl { };

mutter_3-26 = callPackage ../all-pkgs/m/mutter {
  channel = "3.26";
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gnome-desktop = pkgs.gnome-desktop_3-26;
  #gnome-settings-daemon = pkgs.gnome-settings-daemon_3-22;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
};
mutter = callPackageAlias "mutter_3-26" { };

mxml = callPackage ../all-pkgs/m/mxml { };

nano = callPackage ../all-pkgs/n/nano { };

nasm = callPackage ../all-pkgs/n/nasm { };

nautilus_3-26 = callPackage ../all-pkgs/n/nautilus {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  atk = pkgs.atk_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gnome-desktop = pkgs.gnome-desktop_3-26;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
  gvfs = pkgs.gvfs_1-34;
  tracker = pkgs.tracker_2-0;
};
nautilus = callPackageAlias "nautilus_3-26" { };

nbd = callPackage ../all-pkgs/n/nbd { };

ncdc = callPackage ../all-pkgs/n/ncdc { };

ncdu = callPackage ../all-pkgs/n/ncdu { };

ncmpc = callPackage ../all-pkgs/n/ncmpc { };

ncmpcpp = callPackage ../all-pkgs/n/ncmpcpp { };

ncurses = callPackage ../all-pkgs/g/gpm-ncurses { };

ndisc6 = callPackage ../all-pkgs/n/ndisc6 { };

net-snmp = callPackage ../all-pkgs/n/net-snmp { };

net-tools = callPackage ../all-pkgs/n/net-tools { };

nettle = callPackage ../all-pkgs/n/nettle { };

networkmanager_1-8 = callPackage ../all-pkgs/n/networkmanager {
  channel = "1.8";
};
networkmanager = callPackageAlias "networkmanager_1-8" { };

networkmanager-applet_1-8 = callPackage ../all-pkgs/n/networkmanager-applet {
  channel = "1.8";
  networkmanager = pkgs.networkmanager_1-8;
};
networkmanager-applet = callPackageAlias "networkmanager-applet_1-8" { };

networkmanager-l2tp = callPackage ../all-pkgs/n/networkmanager-l2tp { };

networkmanager-openconnect_1-2 =
  callPackage ../all-pkgs/n/networkmanager-openconnect {
    channel = "1.2";
  };
networkmanager-openconnect =
  callPackageAlias "networkmanager-openconnect_1-2" { };

networkmanager-openvpn_1-2 = callPackage ../all-pkgs/n/networkmanager-openvpn {
  channel = "1.2";
};
networkmanager-openvpn = callPackageAlias "networkmanager-openvpn_1-2" { };

networkmanager-pptp_1-2 = callPackage ../all-pkgs/n/networkmanager-pptp {
  channel = "1.2";
};
networkmanager-pptp = callPackageAlias "networkmanager-pptp_1-2" { };

networkmanager-vpnc_1-2 = callPackage ../all-pkgs/n/networkmanager-vpnc {
  channel = "1.2";
};
networkmanager-vpnc = callPackageAlias "networkmanager-vpnc_1-2" { };

nfacct = callPackage ../all-pkgs/n/nfacct { };

nfs-utils = callPackage ../all-pkgs/n/nfs-utils { };

nftables = callPackage ../all-pkgs/n/nftables { };

nghttp2_full = callPackage ../all-pkgs/n/nghttp2 { };
nghttp2_lib = callPackage ../all-pkgs/n/nghttp2 {
  prefix = "lib";
};

nginx_stable = callPackage ../all-pkgs/n/nginx {
  channel = "stable";
};
nginx_unstable = callPackage ../all-pkgs/n/nginx {
  channel = "unstable";
};
nginx = callPackageAlias "nginx_stable" { };

ninja = callPackage ../all-pkgs/n/ninja { };

nix = callPackage ../all-pkgs/n/nix { };

nix_dev = callPackageAlias "nix" {
  channel = "dev";
};

nixos-utils = callPackage ../all-pkgs/n/nixos-utils { };

nmap = callPackage ../all-pkgs/n/nmap { };

nodejs = callPackage ../all-pkgs/n/nodejs { };

noise = callPackage ../all-pkgs/n/noise { };

nomad = pkgs.goPackages.nomad.bin // { outputs = [ "bin" ]; };

notmuch = callPackage ../all-pkgs/n/notmuch { };

npth = callPackage ../all-pkgs/n/npth { };

nspr = callPackage ../all-pkgs/n/nspr { };

nss = callPackage ../all-pkgs/n/nss { };

nss_wrapper = callPackage ../all-pkgs/n/nss_wrapper { };

ntfs-3g = callPackage ../all-pkgs/n/ntfs-3g { };

ntp = callPackage ../all-pkgs/n/ntp { };

numactl = callPackage ../all-pkgs/n/numactl { };

nvidia-cuda-toolkit_8-0 = callPackage ../all-pkgs/n/nvidia-cuda-toolkit {
 channel = "8.0";
};
nvidia-cuda-toolkit = callPackageAlias "nvidia-cuda-toolkit_8-0" { };

nvidia-drivers_tesla = callPackage ../all-pkgs/n/nvidia-drivers {
  channel = "tesla";
  buildConfig = "userspace";
};
nvidia-drivers_long-lived = callPackage ../all-pkgs/n/nvidia-drivers {
  channel = "long-lived";
  buildConfig = "userspace";
};
nvidia-drivers_short-lived = callPackage ../all-pkgs/n/nvidia-drivers {
  channel = "short-lived";
  buildConfig = "userspace";
};
nvidia-drivers_beta = callPackage ../all-pkgs/n/nvidia-drivers {
  channel = "beta";
  buildConfig = "userspace";
};
nvidia-drivers_latest = callPackage ../all-pkgs/n/nvidia-drivers {
  channel = "latest";
  buildConfig = "userspace";
};
nvidia-drivers = callPackageAlias "nvidia-drivers_long-lived" { };

nvidia-gpu-deployment-kit =
  callPackage ../all-pkgs/n/nvidia-gpu-deployment-kit { };

nvidia-settings = callPackage ../all-pkgs/n/nvidia-settings { };

nvidia-video-codec-sdk = callPackage ../all-pkgs/n/nvidia-video-codec-sdk { };

nunc-stans = callPackage ../all-pkgs/n/nunc-stans { };

obexftp = callPackage ../all-pkgs/o/obexftp { };

oniguruma = callPackage ../all-pkgs/o/oniguruma { };

open-iscsi = callPackage ../all-pkgs/o/open-iscsi { };

open-isns = callPackage ../all-pkgs/o/open-isns { };

openal-soft = callPackage ../all-pkgs/o/openal-soft { };
openal = callPackageAlias "openal-soft" { };

opencv_2 = callPackage ../all-pkgs/o/opencv {
  channel = "2";
  gtk_3 = null;
};
opencv_3 = callPackage ../all-pkgs/o/opencv {
  channel = "3";
  gtk_2 = null;
};
opencv = callPackageAlias "opencv_3" { };

opengl-dummy = callPackage ../all-pkgs/m/mesa {
  buildConfig = "opengl-dummy";
};

opengl-headers = callPackage ../all-pkgs/o/opengl-headers { };

openh264 = callPackage ../all-pkgs/o/openh264 { };

openjpeg_1 = callPackage ../all-pkgs/o/openjpeg {
  channel = "1.5";
};
openjpeg = callPackage ../all-pkgs/o/openjpeg { };

openldap = callPackage ../all-pkgs/o/openldap { };

openntpd = callPackage ../all-pkgs/o/openntpd { };

openobex = callPackage ../all-pkgs/o/openobex { };

openresolv = callPackage ../all-pkgs/o/openresolv { };

opensmtpd = callPackage ../all-pkgs/o/opensmtpd { };

opensmtpd-extras = callPackage ../all-pkgs/o/opensmtpd-extras { };

openssh = callPackage ../all-pkgs/o/openssh { };

openssl_1-0-2 = callPackage ../all-pkgs/o/openssl {
  channel = "1.0.2";
};
openssl_1-1-0 = callPackage ../all-pkgs/o/openssl {
  channel = "1.1.0";
};
openssl = callPackageAlias "openssl_1-0-2" { };

openvpn = callPackage ../all-pkgs/o/openvpn { };

opus_stable = callPackage ../all-pkgs/o/opus {
  channel = "stable";
};
opus_head = callPackage ../all-pkgs/o/opus {
  channel = "head";
};
opus = callPackageAlias "opus_stable" { };

opus-tools = callPackage ../all-pkgs/o/opus-tools { };

opusfile = callPackage ../all-pkgs/o/opusfile { };

orbit2 = callPackage ../all-pkgs/o/orbit2 { };

orc = callPackage ../all-pkgs/o/orc { };

osquery = callPackage ../all-pkgs/o/osquery { };

p11-kit = callPackage ../all-pkgs/p/p11-kit { };

p7zip = callPackage ../all-pkgs/p/p7zip { };

pam = callPackage ../all-pkgs/p/pam { };

pango = callPackage ../all-pkgs/p/pango { };

pangomm_2-40 = callPackage ../all-pkgs/p/pangomm {
  channel = "2.40";
};
pangomm = callPackageAlias "pangomm_2-40" { };

pangox-compat = callPackage ../all-pkgs/p/pangox-compat { };

parallel = callPackage ../all-pkgs/p/parallel { };

parted = callPackage ../all-pkgs/p/parted { };

patchelf = callPackage ../all-pkgs/p/patchelf { };

patchutils = callPackage ../all-pkgs/p/patchutils { };

pavucontrol = callPackage ../all-pkgs/p/pavucontrol { };

pciutils = callPackage ../all-pkgs/p/pciutils { };

pcre = callPackage ../all-pkgs/p/pcre { };

pcre2 = callPackage ../all-pkgs/p/pcre2 { };

pcsc-lite_full = callPackage ../all-pkgs/p/pcsc-lite {
  libOnly = false;
};
pcsc-lite_lib = callPackageAlias "pcsc-lite_full" {
  libOnly = true;
};

perl = callPackage ../all-pkgs/p/perl { };

pf-ring = callPackage ../all-pkgs/p/pf-ring { };

pgbouncer = callPackage ../all-pkgs/p/pgbouncer { };

picocom = callPackage ../all-pkgs/p/picocom { };

pinentry_gtk = callPackage ../all-pkgs/p/pinentry {
  type = "gtk";
};
pinentry_qt = callPackage ../all-pkgs/p/pinentry {
  type = "qt";
};
pinentry = callPackage ../all-pkgs/p/pinentry {
  type = "nox";
};

pipewire = callPackage ../all-pkgs/p/pipewire { };

pkcs11-helper = callPackage ../all-pkgs/p/pkcs11-helper { };

pkg-config = callPackage ../all-pkgs/p/pkg-config { };

pkgconf = callPackage ../all-pkgs/p/pkgconf { };
pkgconfig = callPackageAlias "pkgconf" { };

plex-media-server = callPackage ../all-pkgs/p/plex-media-server { };

plymouth = callPackage ../all-pkgs/p/plymouth { };

pngcrush = callPackage ../all-pkgs/p/pngcrush { };

po4a = callPackage ../all-pkgs/p/po4a { };

polkit = callPackage ../all-pkgs/p/polkit { };

poppler_qt = callPackageAlias "poppler" {
  suffix = "qt5";
  qt5 = pkgs.qt5;
};
poppler_utils = callPackageAlias "poppler" {
  suffix = "utils";
  utils = true;
};
poppler = callPackage ../all-pkgs/p/poppler {
  qt5 = null;
};

popt = callPackage ../all-pkgs/p/popt { };

portaudio = callPackage ../all-pkgs/p/portaudio { };

postgresql_10 = callPackage ../all-pkgs/p/postgresql {
  channel = "10";
};
postgresql_9-6 = callPackage ../all-pkgs/p/postgresql {
  channel = "9.6";
};
postgresql_9-5 = callPackage ../all-pkgs/p/postgresql {
  channel = "9.5";
};
postgresql_9-4 = callPackage ../all-pkgs/p/postgresql {
  channel = "9.4";
};
postgresql_9-3 = callPackage ../all-pkgs/p/postgresql {
  channel = "9.3";
};
postgresql = callPackageAlias "postgresql_10" { };

potrace = callPackage ../all-pkgs/p/potrace { };

powertop = callPackage ../all-pkgs/p/powertop { };

ppp = callPackage ../all-pkgs/p/ppp { };

pptp = callPackage ../all-pkgs/p/pptp { };

presentproto = callPackage ../all-pkgs/p/presentproto { };

printproto = callPackage ../all-pkgs/p/printproto { };

procps = callPackageAlias "procps-ng" { };

procps-ng = callPackage ../all-pkgs/p/procps-ng { };

progress = callPackage ../all-pkgs/p/progress { };

prometheus = pkgs.goPackages.prometheus.bin // { outputs = [ "bin" ]; };

protobuf-c = callPackage ../all-pkgs/p/protobuf-c { };

protobuf-cpp = callPackage ../all-pkgs/p/protobuf-cpp { };

psmisc = callPackage ../all-pkgs/p/psmisc { };

pth = callPackage ../all-pkgs/p/pth { };

pugixml = callPackage ../all-pkgs/p/pugixml { };

pulseaudio_full = callPackage ../all-pkgs/p/pulseaudio { };
pulseaudio_lib = callPackageAlias "pulseaudio_full" {
  prefix = "lib";
};

python27 = callPackage ../all-pkgs/p/python {
  channel = "2.7";
  self = callPackageAlias "python27" { };
};
python36 = hiPrio (callPackage ../all-pkgs/p/python {
  channel = "3.6";
  self = callPackageAlias "python36" { };
});
#pypy = callPackage ../all-pkgs/p/pypy {
#  self = callPackageAlias "pypy" { };
#};
python2 = callPackageAlias "python27" { };
python3 = callPackageAlias "python36" { };
python = callPackageAlias "python2" { };

python27Packages = hiPrioSet (
  recurseIntoAttrs (callPackage ../top-level/python-packages.nix {
    python = callPackageAlias "python27" { };
    self = callPackageAlias "python27Packages" { };
  })
);
python36Packages =
  recurseIntoAttrs (callPackage ../top-level/python-packages.nix {
    python = callPackageAlias "python36" { };
    self = callPackageAlias "python36Packages" { };
  });
#pypyPackages =
#  recurseIntoAttrs (callPackage ../top-level/python-packages.nix {
#    python = callPackageAlias "pypy" { };
#    self = callPackageAlias "pypyPackages" { };
#  });
python2Packages = callPackageAlias "python27Packages" { };
python3Packages = callPackageAlias "python36Packages" { };
pythonPackages = callPackageAlias "python2Packages" { };

qbittorrent = callPackage ../all-pkgs/q/qbittorrent { };
qbittorrent_head = callPackage ../all-pkgs/q/qbittorrent {
  channel = "head";
  libtorrent-rasterbar = pkgs.libtorrent-rasterbar_1-1_head;
};
qbittorrent_nox = callPackage ../all-pkgs/q/qbittorrent { };
qbittorrent_nox_head = callPackage ../all-pkgs/q/qbittorrent {
  channel = "head";
  guiSupport = false;
  libtorrent-rasterbar = pkgs.libtorrent-rasterbar_1-1_head;
};

qca = callPackage ../all-pkgs/q/qca { };

qemu = callPackage ../all-pkgs/q/qemu { };

qjackctl = callPackage ../all-pkgs/q/qjackctl { };

qpdf = callPackage ../all-pkgs/q/qpdf { };

qrencode = callPackage ../all-pkgs/q/qrencode { };

qt5 = callPackage ../all-pkgs/q/qt { };

quassel = callPackage ../all-pkgs/q/quassel rec {
  monolithic = true;
  daemon = false;
  client = false;
};
quasselDaemon = pkgs.quassel.override {
  monolithic = false;
  daemon = true;
  client = false;
  tag = "-daemon";
};
quasselClient = hiPrio (pkgs.quassel.override {
  monolithic = false;
  daemon = false;
  client = true;
  tag = "-client";
});

quazip = callPackage ../all-pkgs/q/quazip { };

radvd = callPackage ../all-pkgs/r/radvd { };

randrproto = callPackage ../all-pkgs/r/randrproto { };

rapidjson = callPackage ../all-pkgs/r/rapidjson { };

raptor2 = callPackage ../all-pkgs/r/raptor2 { };

rclone = pkgs.goPackages.rclone.bin // { outputs = [ "bin" ]; };

rdma-core = callPackage ../all-pkgs/r/rdma-core { };

re2c = callPackage ../all-pkgs/r/re2c { };

readline = callPackage ../all-pkgs/r/readline { };

recode = callPackage ../all-pkgs/r/recode { };

recordproto = callPackage ../all-pkgs/r/recordproto { };

redis = callPackage ../all-pkgs/r/redis { };

renderproto = callPackage ../all-pkgs/r/renderproto { };

resilio = callPackage ../all-pkgs/r/resilio { };

resolv_wrapper = callPackage ../all-pkgs/r/resolv_wrapper { };

resourceproto = callPackage ../all-pkgs/r/resourceproto { };

rest = callPackage ../all-pkgs/r/rest { };

rfkill = callPackage ../all-pkgs/r/rfkill { };

rhash = callPackage ../all-pkgs/r/rhash { };

riot = callPackage ../all-pkgs/r/riot { };

rocksdb = callPackage ../all-pkgs/r/rocksdb { };

root-nameservers = callPackage ../all-pkgs/r/root-nameservers { };

rpm = callPackage ../all-pkgs/r/rpm { };

rrdtool = callPackage ../all-pkgs/r/rrdtool { };

rtkit = callPackage ../all-pkgs/r/rtkit { };

rtmpdump = callPackage ../all-pkgs/r/rtmpdump { };

rtorrent = callPackage ../all-pkgs/r/rtorrent { };

ruby = callPackage ../all-pkgs/r/ruby { };

rustPackages = recurseIntoAttrs (callPackage ./rust-packages.nix {
  self = callPackageAlias "rustPackages" { };
  channel = "stable";
});

rustPackages_beta = callPackageAlias "rustPackages" {
  self = callPackageAlias "rustPackages_beta" { };
  channel = "beta";
};

rustPackages_dev = callPackageAlias "rustPackages" {
  self = callPackageAlias "rustPackages_dev" { };
  channel = "dev";
};

sakura = callPackage ../all-pkgs/s/sakura { };

samba_full = callPackage ../all-pkgs/s/samba { };
samba_client = callPackageAlias "samba_full" {
  type = "client";
};

sas2flash = callPackage ../all-pkgs/s/sas2flash { };

sbc = callPackage ../all-pkgs/s/sbc { };

schroedinger = callPackage ../all-pkgs/s/schroedinger { };

scons = pkgs.python2Packages.scons;

screen = callPackage ../all-pkgs/s/screen { };

scrnsaverproto = callPackage ../all-pkgs/s/scrnsaverproto { };

scrot = callPackage ../all-pkgs/s/scrot { };

sddm = callPackage ../all-pkgs/s/sddm { };

sdl_2 = callPackage ../all-pkgs/s/sdl { };
sdl = callPackageAlias "sdl_2" { };

SDL_2_image = callPackage ../all-pkgs/s/SDL_image {
  SDL = pkgs.sdl_2;
};

sdparm = callPackage ../all-pkgs/s/sdparm { };

seabios_qemu = callPackage ../all-pkgs/s/seabios {
  type = "qemu";
};

seahorse = callPackage ../all-pkgs/s/seahorse { };

serd = callPackage ../all-pkgs/s/serd { };

serf = callPackage ../all-pkgs/s/serf { };

sg3-utils = callPackage ../all-pkgs/s/sg3-utils { };

shadow = callPackage ../all-pkgs/s/shadow { };

shared-mime-info = callPackage ../all-pkgs/s/shared-mime-info { };

sharutils = callPackage ../all-pkgs/s/sharutils { };

shntool = callPackage ../all-pkgs/s/shntool { };

signify = callPackage ../all-pkgs/s/signify { };

sl = callPackage ../all-pkgs/s/sl { };

sleuthkit = callPackage ../all-pkgs/s/sleuthkit { };

slock = callPackage ../all-pkgs/s/slock { };

smartmontools = callPackage ../all-pkgs/s/smartmontools { };

snappy = callPackage ../all-pkgs/s/snappy { };

socket_wrapper = callPackage ../all-pkgs/s/socket_wrapper { };

sord = callPackage ../all-pkgs/s/sord { };

sox = callPackage ../all-pkgs/s/sox {
  amrnb = null;
  amrwb = null;
};

soxr = callPackage ../all-pkgs/s/soxr { };

spectrwm = callPackage ../all-pkgs/s/spectrwm { };

speech-dispatcher = callPackage ../all-pkgs/s/speech-dispatcher { };

speex = callPackage ../all-pkgs/s/speex { };

speexdsp = callPackage ../all-pkgs/s/speexdsp { };

spice = callPackage ../all-pkgs/s/spice { };

spice-protocol = callPackage ../all-pkgs/s/spice-protocol { };

spidermonkey_45 = callPackage ../all-pkgs/s/spidermonkey {
  channel = "45";
};
spidermonkey_24 = callPackage ../all-pkgs/s/spidermonkey {
  channel = "24";
};
spidermonkey_17 = callPackage ../all-pkgs/s/spidermonkey {
  channel = "17";
};
spidermonkey = callPackageAlias "spidermonkey_45" { };

spl = callPackage ../all-pkgs/s/spl {
  channel = "stable";
  type = "user";
};
spl_dev = callPackage ../all-pkgs/s/spl {
  channel = "dev";
  type = "user";
};

split2flac = callPackage ../all-pkgs/s/split2flac { };

sqlite = callPackage ../all-pkgs/s/sqlite { };

squashfs-tools = callPackage ../all-pkgs/s/squashfs-tools { };

sratom = callPackage ../all-pkgs/s/sratom { };

sshfs = callPackage ../all-pkgs/s/sshfs { };

sslh = callPackage ../all-pkgs/s/sslh { };

sssd = callPackage ../all-pkgs/s/sssd { };

st = callPackage ../all-pkgs/s/st {
  config = config.st.config or null;
  configFile = config.st.configFile or null;
};

stalonetray = callPackage ../all-pkgs/s/stalonetray { };

#steamPackages = callPackage ../all-pkgs/s/steam { };
#steam = steamPackages.steam-chrootenv.override {
#  # DEPRECATED
#  withJava = config.steam.java or false;
#  withPrimus = config.steam.primus or false;
#};

strace = callPackage ../all-pkgs/s/strace { };

sublime-text = callPackage ../all-pkgs/s/sublime-text { };

subversion_1-9 = callPackage ../all-pkgs/s/subversion {
  channel = "1.9";
};
subversion_1-8 = callPackage ../all-pkgs/s/subversion {
  channel = "1.8";
};
subversion = callPackageAlias "subversion_1-9" { };

sudo = callPackage ../all-pkgs/s/sudo { };

sushi_3-22 = callPackage ../all-pkgs/s/sushi {
  channel = "3.21";
  atk = pkgs.atk_2-26;
  gjs = pkgs.gjs_1-46;
  gtksourceview = pkgs.gtksourceview_3-22;
};
sushi = callPackageAlias "sushi_3-22" { };

svrcore = callPackage ../all-pkgs/s/svrcore { };

sway = callPackage ../all-pkgs/s/sway { };

swig_2 = callPackage ../all-pkgs/s/swig {
  channel = "2";
};
swig_3 = callPackage ../all-pkgs/s/swig {
  channel = "3";
};
swig = callPackageAlias "swig_3" { };

sydent = pkgs.python2Packages.sydent;

synapse = pkgs.python2Packages.synapse;

syncthing = pkgs.goPackages.syncthing.bin // { outputs = [ "bin" ]; };

synergy = callPackage ../all-pkgs/s/synergy { };

syslinux = callPackage ../all-pkgs/s/syslinux { };

sysstat = callPackage ../all-pkgs/s/sysstat { };

# TODO: Rename back to systemd once depedencies are sorted
systemd_full = callPackage ../all-pkgs/s/systemd { };
systemd_lib = callPackageAlias "systemd_full" {
  type = "lib";
};

systemd_dist = callPackage ../all-pkgs/s/systemd/dist.nix { };

systemd-dummy = callPackage ../all-pkgs/s/systemd-dummy { };

taglib = callPackage ../all-pkgs/t/taglib { };

tahoe-lafs = pkgs.python2Packages.tahoe-lafs;

talloc = callPackage ../all-pkgs/t/talloc { };

task-spooler = callPackage ../all-pkgs/t/task-spooler { };

tcl_8-5 = callPackage ../all-pkgs/t/tcl {
  channel = "8.5";
};
tcl_8-6 = callPackage ../all-pkgs/t/tcl {
  channel = "8.6";
};
tcl = callPackageAlias "tcl_8-6" { };

tcpdump = callPackage ../all-pkgs/t/tcpdump { };

tcp-wrappers = callPackage ../all-pkgs/t/tcp-wrappers { };

tdb = callPackage ../all-pkgs/t/tdb { };

teamspeak_client = callPackage ../all-pkgs/t/teamspeak/client.nix { };
teamspeak_server = callPackage ../all-pkgs/t/teamspeak/server.nix { };

teleport = pkgs.goPackages.teleport.bin // { outputs = [ "bin" ]; };

tesseract = callPackage ../all-pkgs/t/tesseract { };

tevent = callPackage ../all-pkgs/t/tevent { };

texinfo = callPackage ../all-pkgs/t/texinfo { };

thermal_daemon = callPackage ../all-pkgs/t/thermal_daemon { };

thin-provisioning-tools = callPackage ../all-pkgs/t/thin-provisioning-tools { };

thrift = callPackage ../all-pkgs/t/thrift { };

time = callPackage ../all-pkgs/t/time { };

tinc_1-0 = callPackage ../all-pkgs/t/tinc { channel = "1.0"; };
tinc_1-1 = callPackage ../all-pkgs/t/tinc { channel = "1.1"; };

tk_8-5 = callPackage ../all-pkgs/t/tk {
  channel = "8.5";
};
tk_8-6 = callPackage ../all-pkgs/t/tk {
  channel = "8.6";
};
tk = callPackageAlias "tk_8-6" { };

tmux = callPackage ../all-pkgs/t/tmux { };

tor = callPackage ../all-pkgs/t/tor { };

totem_3-26 = callPackage ../all-pkgs/t/totem {
  channel = "3.26";
};
totem = callPackageAlias "totem_3-26" { };

totem-pl-parser_3-26 = callPackage ../all-pkgs/t/totem-pl-parser {
  channel = "3.26";
};
totem-pl-parser = callPackageAlias "totem-pl-parser_3-26" { };

tracker_2-0 = callPackage ../all-pkgs/t/tracker {
  channel = "2.0";
  #evolution
  evolution-data-server = pkgs.evolution-data-server_3-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
  gnome-themes-standard = pkgs.gnome-themes-standard_3-22;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-24;
};
tracker = callPackageAlias "tracker_2-0" { };

transmission_generic = overrides: callPackage ../all-pkgs/t/transmission ({
  # The following are disabled by default
  adwaita-icon-theme = null;
  dbus = null;
  gdk-pixbuf = null;
  glib = null;
  gtk_3 = null;
  qt5 = null;
} // overrides);
transmission_2 = pkgs.transmission_generic {
  channel = "2";
};
transmission_head = pkgs.transmission_generic {
  channel = "head";
};
transmission = callPackageAlias "transmission_2" { };

transmission-remote-gtk = callPackage ../all-pkgs/t/transmission-remote-gtk { };

trapproto = callPackage ../all-pkgs/t/trapproto { };

trousers = callPackage ../all-pkgs/t/trousers { };

tslib = callPackage ../all-pkgs/t/tslib { };

tzdata = callPackage ../all-pkgs/t/tzdata { };

udisks = callPackage ../all-pkgs/u/udisks { };

uefi-shell = callPackage ../all-pkgs/u/uefi-shell { };

ufraw = callPackage ../all-pkgs/u/ufraw { };

uhub = callPackage ../all-pkgs/u/uhub { };

uid_wrapper = callPackage ../all-pkgs/u/uid_wrapper { };

unbound = callPackage ../all-pkgs/u/unbound { };

unicode-character-database =
  callPackage ../all-pkgs/u/unicode-character-database { };

unifi = callPackage ../all-pkgs/u/unifi { };

unixODBC = callPackage ../all-pkgs/u/unixODBC { };

unrar = callPackage ../all-pkgs/u/unrar { };

unzip = callPackage ../all-pkgs/u/unzip { };

upower = callPackage ../all-pkgs/u/upower { };

usbmuxd = callPackage ../all-pkgs/u/usbmuxd { };

usbutils = callPackage ../all-pkgs/u/usbutils { };

utf8proc = callPackage ../all-pkgs/u/utf8proc { };

uthash = callPackage ../all-pkgs/u/uthash { };

util-linux_full = callPackage ../all-pkgs/u/util-linux { };
util-linux_lib = callPackageAlias "util-linux_full" {
  type = "lib";
};

util-macros = callPackage ../all-pkgs/u/util-macros { };

v4l-utils = callPackage ../all-pkgs/v/v4l-utils {
  channel = "utils";
};
v4l_lib = callPackageAlias "v4l-utils" {
  channel = "lib";
};

vala_0-34 = callPackage ../all-pkgs/v/vala {
  channel = "0.34";
};
vala_0-36 = callPackage ../all-pkgs/v/vala {
  channel = "0.36";
};
vala = callPackageAlias "vala_0-36" { };

vault = pkgs.goPackages.vault.bin // { outputs = [ "bin" ]; };

vcdimager = callPackage ../all-pkgs/v/vcdimager { };

vid-stab = callPackage ../all-pkgs/v/vid-stab { };

videoproto = callPackage ../all-pkgs/v/videoproto { };

vim = callPackage ../all-pkgs/v/vim { };

vino_3-22 = callPackage ../all-pkgs/v/vino {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  libsoup = pkgs.libsoup_2-60;
};
vino = callPackageAlias "vino_3-22" { };

vlc = callPackage ../all-pkgs/v/vlc { };

vobsub2srt = callPackage ../all-pkgs/v/vobsub2srt { };

volume_key = callPackage ../all-pkgs/v/volume_key { };

vorbis-tools = callPackage ../all-pkgs/v/vorbis-tools { };

vte_0-50 = callPackage ../all-pkgs/v/vte {
  channel = "0.50";
  atk = pkgs.atk_2-26;
  gdk-pixbuf_unwrapped = pkgs.gdk-pixbuf_unwrapped_2-36;
};
vte = callPackageAlias "vte_0-50" { };

vulkan-headers = callPackage ../all-pkgs/v/vulkan-headers { };

w3m = callPackage ../all-pkgs/w/w3m { };

waf = callPackage ../all-pkgs/w/waf { };

wavpack = callPackage ../all-pkgs/w/wavpack { };

wayland = callPackage ../all-pkgs/w/wayland { };

wayland-protocols = callPackage ../all-pkgs/w/wayland-protocols { };

webkitgtk = callPackage ../all-pkgs/w/webkitgtk { };

wget = callPackage ../all-pkgs/w/wget { };

which = callPackage ../all-pkgs/w/which { };

windowswmproto = callPackage ../all-pkgs/w/windowswmproto { };

winusb = callPackage ../all-pkgs/w/winusb { };

wiredtiger = callPackage ../all-pkgs/w/wiredtiger { };

wireguard = callPackage ../all-pkgs/w/wireguard {
  kernel = null;
};

wireless-tools = callPackage ../all-pkgs/w/wireless-tools { };

wlc = callPackage ../all-pkgs/w/wlc { };

wpa_supplicant = callPackage ../all-pkgs/w/wpa_supplicant { };

wxGTK = callPackage ../all-pkgs/w/wxGTK { };

x264 = callPackage ../all-pkgs/x/x264 { };

x265_stable = callPackage ../all-pkgs/x/x265 {
  channel = "stable";
};
x265_head = callPackage ../all-pkgs/x/x265 {
  channel = "head";
};
x265 = callPackageAlias "x265_stable" { };

xapian-core = callPackage ../all-pkgs/x/xapian-core { };

xavs = callPackage ../all-pkgs/x/xavs { };

xcmiscproto = callPackage ../all-pkgs/x/xcmiscproto { };

xdg-user-dirs = callPackage ../all-pkgs/x/xdg-user-dirs { };

xdg-utils = callPackage ../all-pkgs/x/xdg-utils { };

xextproto = callPackage ../all-pkgs/x/xextproto { };

xf86-input-mtrack = callPackage ../all-pkgs/x/xf86-input-mtrack { };

xf86-input-wacom = callPackage ../all-pkgs/x/xf86-input-wacom { };

xf86bigfontproto = callPackage ../all-pkgs/x/xf86bigfontproto { };

xf86dgaproto = callPackage ../all-pkgs/x/xf86dgaproto { };

xf86driproto = callPackage ../all-pkgs/x/xf86driproto { };

xf86miscproto = callPackage ../all-pkgs/x/xf86miscproto { };

xf86vidmodeproto = callPackage ../all-pkgs/x/xf86vidmodeproto { };

xfconf_4-12 = callPackage ../all-pkgs/x/xfconf {
  channel = "4.12";
};
xfconf = callPackageAlias "xfconf_4-12" { };

xfe = callPackage ../all-pkgs/x/xfe { };

xfsprogs = callPackage ../all-pkgs/x/xfsprogs { };

xfsprogs_lib = pkgs.xfsprogs.lib;

xine-lib = callPackage ../all-pkgs/x/xine-lib { };

xine-ui = callPackage ../all-pkgs/x/xine-ui { };

xineramaproto = callPackage ../all-pkgs/x/xineramaproto { };

xmlto = callPackage ../all-pkgs/x/xmlto { };

xmltoman = callPackage ../all-pkgs/x/xmltoman { };

xorg = recurseIntoAttrs (
  lib.callPackagesWith pkgs ../all-pkgs/x/xorg/default.nix {
    inherit (pkgs)
      asciidoc
      autoconf
      automake
      autoreconfHook
      bison
      dbus
      expat
      fetchurl
      fetchzip
      fetchpatch
      fetchTritonPatch
      flex
      fontconfig
      freetype
      gperf
      intltool
      libdrm
      libevdev
      libinput
      libpng
      libtool
      libunwind
      libxslt
      m4
      makeWrapper
      mcpp
      mtdev
      opengl-dummy
      openssl
      perl
      pkgconfig
      python
      spice-protocol
      stdenv
      systemd_lib
      tradcpp
      util-linux_lib
      xmlto
      zlib
      # Rewritten xorg packages
      bigreqsproto
      compositeproto
      damageproto
      dmxproto
      dri2proto
      dri3proto
      fixesproto
      fontcacheproto
      fontsproto
      glproto
      inputproto
      kbproto
      libdmx
      libfontenc
      libice
      libpthread-stubs
      libsm
      libx11
      libxau
      libxcb
      libxcomposite
      libxcursor
      libxdamage
      libxdmcp
      libxext
      libxfixes
      libxfont
      libxfont2
      libxft
      libxi
      libxinerama
      libxkbfile
      libxrandr
      libxrender
      libxres
      libxscrnsaver
      libxt
      libxtst
      libxv
      presentproto
      printproto
      randrproto
      recordproto
      renderproto
      resourceproto
      scrnsaverproto
      trapproto
      util-macros
      videoproto
      windowswmproto
      xcb-proto
      xcmiscproto
      xextproto
      xf86bigfontproto
      xf86dgaproto
      xf86driproto
      xf86miscproto
      xf86vidmodeproto
      xineramaproto
      xproto
      xrefresh
      xtrans
      xwininfo
      ;
  }
);

xproto = callPackage ../all-pkgs/x/xproto { };

xrefresh = callPackage ../all-pkgs/x/xrefresh { };

xtrans = callPackage ../all-pkgs/x/xtrans { };

xvidcore = callPackage ../all-pkgs/x/xvidcore { };

xwininfo = callPackage ../all-pkgs/x/xwininfo { };

xz = callPackage ../all-pkgs/x/xz { };

yajl = callPackage ../all-pkgs/y/yajl { };

yaml-cpp = callPackage ../all-pkgs/y/yaml-cpp { };

yara = callPackage ../all-pkgs/y/yara { };

yasm = callPackage ../all-pkgs/y/yasm { };

yelp-tools = callPackage ../all-pkgs/y/yelp-tools { };

yelp-xsl_3-20 = callPackage ../all-pkgs/y/yelp-xsl {
  channel = "3.20";
};
yelp-xsl = callPackageAlias "yelp-xsl_3-20" { };

zeitgeist = callPackage ../all-pkgs/z/zeitgeist { };

zenity_generics = overrides: callPackage ../all-pkgs/z/zenity ({
  webkitgtk = null;
} // overrides);
zenity_3-24 = pkgs.zenity_generics {
  channel = "3.24";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-26;
  at-spi2-core = pkgs.at-spi2-core_2-26;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-36;
};
zenity = callPackageAlias "zenity_3-24" { };

zeromq = callPackage ../all-pkgs/z/zeromq { };

zfs = callPackage ../all-pkgs/z/zfs {
  channel = "stable";
  type = "user";
  spl = null;
};
zfs_dev = callPackage ../all-pkgs/z/zfs {
  channel = "dev";
  type = "user";
  spl = null;
};

zip = callPackage ../all-pkgs/z/zip { };

zita-convolver = callPackage ../all-pkgs/z/zita-convolver { };

zita-resampler = callPackage ../all-pkgs/z/zita-resampler { };

zlib = callPackage ../all-pkgs/z/zlib { };

zookeeper = callPackage ../all-pkgs/z/zookeeper { };

zsh = callPackage ../all-pkgs/z/zsh { };

zstd = callPackage ../all-pkgs/z/zstd { };

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
############################### END ALL PKGS ###################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
#
  docbook2x = callPackage ../tools/typesetting/docbook2x { };
#
  liboauth = callPackage ../development/libraries/liboauth { };
#
  memtest86plus = callPackage ../tools/misc/memtest86+ { };
#
  netcat = callPackage ../tools/networking/netcat { };
#
  npapi_sdk = callPackage ../development/libraries/npapi-sdk { };
#
  opensp = callPackage ../tools/text/sgml/opensp { };

  spCompat = callPackage ../tools/text/sgml/opensp/compat.nix { };
#
  strongswan = callPackage ../tools/networking/strongswan { };
#
  vpnc = callPackage ../tools/networking/vpnc { };

  openconnect = callPackageAlias "openconnect_openssl" { };

  openconnect_openssl = callPackage ../tools/networking/openconnect.nix {
    gnutls = null;
  };
#
  xl2tpd = callPackage ../tools/networking/xl2tpd { };
#
  tre = callPackage ../development/libraries/tre { };

  systemd-cryptsetup-generator =
    callPackage ../os-specific/linux/systemd/cryptsetup-generator.nix { };
#
  gcc = callPackageAlias "gcc7" { };
#
  gcc48 = lowPrio (wrapCC (callPackage ../development/compilers/gcc/4.8 {
    noSysDirs = true;

    # PGO seems to speed up compilation by gcc by ~10%, see #445 discussion
    profiledCompiler = true;

    # When building `gcc.crossDrv' (a "Canadian cross", with host == target
    # and host != build), `cross' must be null but the cross-libc must still
    # be passed.
    cross = null;
    libcCross = null;

    isl = pkgs.isl_0_14;
  }));
#
  gcc5 = lowPrio (wrapCC (callPackage ../development/compilers/gcc/5 {
    noSysDirs = true;

    # PGO seems to speed up compilation by gcc by ~10%, see #445 discussion
    profiledCompiler = true;

    # When building `gcc.crossDrv' (a "Canadian cross", with host == target
    # and host != build), `cross' must be null but the cross-libc must still
    # be passed.
    cross = null;
    libcCross = null;
  }));

  gcc6 = lowPrio (wrapCC (callPackage ../development/compilers/gcc/6 {
    noSysDirs = true;

    # PGO seems to speed up compilation by gcc by ~10%, see #445 discussion
    profiledCompiler = true;

    # When building `gcc.crossDrv' (a "Canadian cross", with host == target
    # and host != build), `cross' must be null but the cross-libc must still
    # be passed.
    cross = null;
    libcCross = null;
  }));

  gcc7 = lowPrio (wrapCC (callPackage ../development/compilers/gcc/7 {
    noSysDirs = true;

    # PGO seems to speed up compilation by gcc by ~10%, see #445 discussion
    profiledCompiler = true;

    # When building `gcc.crossDrv' (a "Canadian cross", with host == target
    # and host != build), `cross' must be null but the cross-libc must still
    # be passed.
    cross = null;
    libcCross = null;
  }));
#
  haskell = callPackage ./haskell-packages.nix { };
#
  haskellPackages = pkgs.haskell.packages.ghc7103.override {
    overrides = config.haskellPackageOverrides or (self: super: {});
  };
#
#  icedtea7_web = callPackage ../development/compilers/icedtea-web {
#    jdk = jdk7;
#    xulrunner = firefox-unwrapped;
#  };
#
  icedtea8_web = callPackage ../development/compilers/icedtea-web {
    jdk = pkgs.jdk8;
    xulrunner = pkgs.firefox-unwrapped;
  };

  icedtea_web = pkgs.icedtea8_web;
#
#  openjdk7-bootstrap =
#    callPackage ../development/compilers/openjdk/bootstrap.nix {
#      version = "7";
#    };
  openjdk8-bootstrap =
    callPackage ../development/compilers/openjdk/bootstrap.nix {
      version = "8";
    };
#
#  openjdk7-make-bootstrap = callPackage ../development/compilers/openjdk/make-bootstrap.nix {
#    openjdk = openjdk7.override { minimal = true; };
#  };
  openjdk8-make-bootstrap =
    callPackage ../development/compilers/openjdk/make-bootstrap.nix {
      openjdk = pkgs.openjdk8.override { minimal = true; };
    };
#
#  openjdk7 = callPackage ../development/compilers/openjdk/7.nix {
#    bootjdk = openjdk7-bootstrap;
#  };
#  openjdk7_jdk = openjdk7 // { outputs = [ "out" ]; };
#  openjdk7_jre = openjdk7.jre // { outputs = [ "jre" ]; };
#
  openjdk8 = callPackage ../development/compilers/openjdk/8.nix {
    bootjdk = pkgs.openjdk8-bootstrap;
  };
  openjdk8_jdk = pkgs.openjdk8 // { outputs = [ "out" ]; };
  openjdk8_jre = pkgs.openjdk8.jre // { outputs = [ "jre" ]; };

  openjdk = callPackageAlias "openjdk8" { };
#
#  java7 = openjdk7;
#  jdk7 = java7 // { outputs = [ "out" ]; };
#  jre7 = java7.jre // { outputs = [ "jre" ]; };
#
  java8 = callPackageAlias "openjdk8" { };
  jdk8 = pkgs.java8 // { outputs = [ "out" ]; };
  jre8 = pkgs.java8.jre // { outputs = [ "jre" ]; };
#
  java = callPackageAlias "java8" { };
  jdk = pkgs.java // { outputs = [ "out" ]; };
  jre = pkgs.java.jre // { outputs = [ "jre" ]; };
#
#  mono = callPackage ../development/compilers/mono { };
#
#  lua5_2 = callPackage ../development/interpreters/lua-5/5.2.nix { };
#  lua5_2_compat = callPackage ../development/interpreters/lua-5/5.2.nix {
#    compat = true;
#  };
  lua5_3 = callPackage ../development/interpreters/lua-5/5.3.nix { };
  lua5_3_compat = callPackage ../development/interpreters/lua-5/5.3.nix {
    compat = true;
  };
  lua5 = callPackageAlias "lua5_3_compat" { };
  lua = callPackageAlias "lua5" { };
#
  php = pkgs.php71;
#
#  phpPackages = recurseIntoAttrs (callPackage ./php-packages.nix {});
#
  inherit (callPackages ../development/interpreters/php { })
    php71;
#
  ant = callPackageAlias "apacheAnt" { };

  apacheAnt = callPackage ../development/tools/build-managers/apache-ant { };
#
  automoc4 = callPackage ../development/tools/misc/automoc4 { };
#
  binutils = callPackage ../development/tools/misc/binutils { };
#
  doxygen = callPackage ../development/tools/documentation/doxygen {
    qt4 = null;
  };
#
  gnome_doc_utils =
    callPackage ../development/tools/documentation/gnome-doc-utils { };
#
  ltrace = callPackage ../development/tools/misc/ltrace { };
#
  valgrind = callPackage ../development/tools/analysis/valgrind { };
#
  a52dec = callPackage ../development/libraries/a52dec { };
#
  aalib = callPackage ../development/libraries/aalib { };
#
  celt = callPackage ../development/libraries/celt {};
  celt_0_7 = callPackage ../development/libraries/celt/0.7.nix {};
  celt_0_5_1 = callPackage ../development/libraries/celt/0.5.1.nix {};
#
  faad2 = callPackage ../development/libraries/faad2 { };
#
  fltk13 = callPackage ../development/libraries/fltk/fltk13.nix { };
#
cfitsio = callPackage ../development/libraries/cfitsio { };

  fontconfig-ultimate =
    callPackage ../development/libraries/fontconfig-ultimate { };
#
  makeFontsConf =
    let
      fontconfig_ = pkgs.fontconfig;
    in {
      fontconfig ? fontconfig_
      , fontDirectories
    }:
    callPackage ../development/libraries/fontconfig/make-fonts-conf.nix {
      inherit
        fontconfig
        fontDirectories;
    };
#
  makeFontsCache =
    let
      fontconfig_ = pkgs.fontconfig;
    in {
      fontconfig ? fontconfig_
      , fontDirectories
    }:
    callPackage ../development/libraries/fontconfig/make-fonts-cache.nix {
      inherit
        fontconfig
        fontDirectories;
    };

  fribidi = callPackage ../development/libraries/fribidi { };
#
  giblib = callPackage ../development/libraries/giblib { };
#
  glibc = callPackage ../development/libraries/glibc { };

  # Only supported on Linux
  glibcLocales = callPackage ../development/libraries/glibc/locales.nix { };
#
  gom = callPackage ../all-pkgs/g/gom { };
#
  gsl = callPackage ../development/libraries/gsl { };
#
  gts = callPackage ../development/libraries/gts { };
#
  ilmbase = callPackage ../development/libraries/ilmbase { };
#
  ijs = callPackage ../development/libraries/ijs { };
#
  jbigkit = callPackage ../development/libraries/jbigkit { };

  libasyncns = callPackage ../development/libraries/libasyncns { };
#
  libbdplus = callPackage ../development/libraries/libbdplus { };

  libbs2b = callPackage ../development/libraries/audio/libbs2b { };
#
  libcaca = callPackage ../development/libraries/libcaca { };
#
  libcdr = callPackage ../development/libraries/libcdr {
    lcms = callPackageAlias "lcms2" { };
  };
#
  libdiscid = callPackage ../development/libraries/libdiscid { };
#
  libdvbpsi = callPackage ../development/libraries/libdvbpsi { };
#
  libgtop = callPackage ../development/libraries/libgtop {};
#
  liblqr1 = callPackage ../development/libraries/liblqr-1 { };
#
  libnatspec = callPackage ../development/libraries/libnatspec { };
#
  libndp = callPackage ../development/libraries/libndp { };
#
  librevenge = callPackage ../development/libraries/librevenge {};

  libiec61883 = callPackage ../development/libraries/libiec61883 { };
#
  libmad = callPackage ../development/libraries/libmad { };
#
  libmikmod = callPackage ../development/libraries/libmikmod { };
#
  libmng = callPackage ../development/libraries/libmng { };
#
  liboggz = callPackage ../development/libraries/liboggz { };
#
  libpaper = callPackage ../development/libraries/libpaper { };
#
libstartup_notification =
  callPackage ../development/libraries/startup-notification { };
#
  libtxc_dxtn_s2tc = callPackage ../development/libraries/libtxc_dxtn_s2tc { };
#
  libupnp = callPackage ../development/libraries/pupnp { };

  libvisio = callPackage ../development/libraries/libvisio { };

  libvisual = callPackage ../development/libraries/libvisual { };
#
  libwmf = callPackage ../development/libraries/libwmf { };
#
  libwpd = callPackage ../development/libraries/libwpd { };
#
  libwpg = callPackage ../development/libraries/libwpg { };
#
  libxmlxx = callPackage ../development/libraries/libxmlxx { };
#
  libzen = callPackage ../development/libraries/libzen { };

  log4cplus = callPackage ../development/libraries/log4cplus { };
#
  neon = callPackage ../development/libraries/neon {
    compressionSupport = true;
    sslSupport = true;
  };
#
  newt = callPackage ../development/libraries/newt { };
#
  openexr = callPackage ../development/libraries/openexr { };
#
  phonon = callPackage ../development/libraries/phonon/qt4 {};
#
  portmidi = callPackage ../development/libraries/portmidi { };
#
  rubberband = callPackage ../development/libraries/rubberband { };
#
  slang = callPackage ../development/libraries/slang { };
#
  soundtouch = callPackage ../development/libraries/soundtouch {};

  spandsp = callPackage ../development/libraries/spandsp {};
#
  sqlite-interactive = pkgs.sqlite;
#
  t1lib = callPackage ../development/libraries/t1lib { };
#
  telepathy_glib = callPackage ../development/libraries/telepathy/glib { };
#
  vamp = callPackage ../development/libraries/audio/vamp { };
#
  webrtc-audio-processing =
    callPackage ../development/libraries/webrtc-audio-processing { };
#
  xmlrpc_c = callPackage ../development/libraries/xmlrpc-c { };
#
  zziplib = callPackage ../development/libraries/zziplib { };
#
  buildPerlPackage = callPackage ../development/perl-modules/generic { };

  perlPackages = recurseIntoAttrs (callPackage ./perl-packages.nix {
    overrides = (config.perlPackageOverrides or (p: {})) pkgs;
  });
#
  apache-httpd = callPackage ../all-pkgs/a/apache-httpd  { };

  apacheHttpdPackagesFor = apacheHttpd: self:
    let
      callPackage = pkgs.newScope self;
    in {
      inherit apacheHttpd;

      mod_dnssd = callPackage ../servers/http/apache-modules/mod_dnssd { };

      # mod_evasive =
      #   callPackage ../servers/http/apache-modules/mod_evasive { };
      #
      # mod_fastcgi =
      #   callPackage ../servers/http/apache-modules/mod_fastcgi { };
      #
      # mod_python = callPackage ../servers/http/apache-modules/mod_python { };
      #
      # mod_wsgi = callPackage ../servers/http/apache-modules/mod_wsgi { };
      #
      # php = pkgs.php.override { inherit apacheHttpd; };
      #
      # subversion = pkgs.subversion.override {
      #   httpServer = true; inherit apacheHttpd;
      # };
    };
#
  apacheHttpdPackages =
    pkgs.apacheHttpdPackagesFor pkgs.apacheHttpd pkgs.apacheHttpdPackages;
#
#  # Backwards compatibility.
  mod_dnssd = pkgs.apacheHttpdPackages.mod_dnssd;

  zookeeper_mt = callPackage ../development/libraries/zookeeper_mt { };
#
  alsa-oss = callPackage ../os-specific/linux/alsa-oss { };

  alsa-tools = callPackage ../os-specific/linux/alsa-tools { };

#  # -- Linux kernel expressions ------------------------------------------------
#

  kernelPatches = callPackage ../all-pkgs/l/linux/patches.nix { };

  linux_4-9 = callPackage ../all-pkgs/l/linux {
    channel = "4.9";
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };

  linux_4-13 = callPackage ../all-pkgs/l/linux {
    channel = "4.13";
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };

  linux_testing = callPackage ../all-pkgs/l/linux {
    channel = "testing";
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };

  linux_bcachefs = callPackage ../all-pkgs/l/linux {
    channel = "bcachefs";
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };

#
#  /* Linux kernel modules are inherently tied to a specific kernel.  So
#     rather than provide specific instances of those packages for a
#     specific kernel, we have a function that builds those packages
#     for a specific kernel.  This function can then be called for
#     whatever kernel you're using. */
#
  linuxPackagesFor = { kernel }: let
    kCallPackage = pkgs.newScope kPkgs;

    kPkgs = {
      inherit kernel;

      cryptodev = pkgs.cryptodev_headers.override {
        onlyHeaders = false;
        inherit kernel;  # We shouldn't need this
      };

      cpupower = kCallPackage ../os-specific/linux/cpupower { };

      e1000e = kCallPackage ../os-specific/linux/e1000e {};

      mft = kCallPackage ../all-pkgs/m/mft {
        inherit (kPkgs) kernel;
      };

      nvidia-drivers_tesla = kCallPackage ../all-pkgs/n/nvidia-drivers {
       channel = "tesla";
      };
      nvidia-drivers_long-lived = kCallPackage ../all-pkgs/n/nvidia-drivers {
        channel = "long-lived";
        buildConfig = "kernelspace";
      };
      nvidia-drivers_short-lived = kCallPackage ../all-pkgs/n/nvidia-drivers {
        channel = "short-lived";
        buildConfig = "kernelspace";
      };
      nvidia-drivers_beta = kCallPackage ../all-pkgs/n/nvidia-drivers {
        channel = "beta";
        buildConfig = "kernelspace";
      };
      nvidia-drivers_latest = kCallPackage ../all-pkgs/n/nvidia-drivers {
        channel = "latest";
        buildConfig = "kernelspace";
      };

      spl = kCallPackage ../all-pkgs/s/spl {
        channel = "stable";
        type = "kernel";
        inherit (kPkgs) kernel;  # We shouldn't need this
      };

      spl_dev = kCallPackage ../all-pkgs/s/spl {
        channel = "dev";
        type = "kernel";
        inherit (kPkgs) kernel;  # We shouldn't need this
      };

      wireguard = kCallPackage ../all-pkgs/w/wireguard {
        inherit (kPkgs) kernel;
      };

      zfs = kCallPackage ../all-pkgs/z/zfs {
        channel = "stable";
        type = "kernel";
        inherit (kPkgs) kernel spl;  # We shouldn't need this
      };

      zfs_dev = kCallPackage ../all-pkgs/z/zfs {
        channel = "dev";
        type = "kernel";
        inherit (kPkgs) kernel;  # We shouldn't need this
        spl = kPkgs.spl_dev;
      };

    };
  in kPkgs;
#
#  # The current default kernel / kernel modules.
  linuxPackages = pkgs.linuxPackages_4-9;
  linux = pkgs.linuxPackages.kernel;
#
#  # Update this when adding the newest kernel major version!
  linuxPackages_latest = pkgs.linuxPackages_4-13;
  linux_latest = pkgs.linuxPackages_latest.kernel;
#
#  # Build the kernel modules for the some of the kernels.
  linuxPackages_4-9 = recurseIntoAttrs (pkgs.linuxPackagesFor {
    kernel = pkgs.linux_4-9;
  });
  linuxPackages_4-13 = recurseIntoAttrs (pkgs.linuxPackagesFor {
    kernel = pkgs.linux_4-13;
  });
  linuxPackages_testing = recurseIntoAttrs (pkgs.linuxPackagesFor {
    kernel = pkgs.linux_testing;
  });
  linuxPackages_bcachefs = recurseIntoAttrs (pkgs.linuxPackagesFor {
    kernel = pkgs.linux_bcachefs;
  });
  linuxPackages_custom = { version, src, configfile }:
    let
      linuxPackages_self = (
        linuxPackagesFor (
          pkgs.linuxManualConfig {
            inherit version src configfile;
            allowImportFromDerivation=true;
          }
        ) linuxPackages_self);
    in
    recurseIntoAttrs linuxPackages_self;
#
#  # A function to build a manually-configured kernel
  linuxManualConfig = pkgs.buildLinux;
  buildLinux = callPackage ../all-pkgs/l/linux/manual-config.nix {};
#
  kmod-blacklist-ubuntu =
    callPackage ../os-specific/linux/kmod-blacklist-ubuntu { };

  kmod-debian-aliases =
    callPackage ../os-specific/linux/kmod-debian-aliases { };

  libcap = callPackage ../os-specific/linux/libcap { };
#
  aggregateModules = modules:
    callPackage ../all-pkgs/k/kmod/aggregator.nix {
      inherit modules;
    };
#
  procps-old = lowPrio (callPackage ../os-specific/linux/procps { });
#
  sysfsutils = callPackage ../os-specific/linux/sysfsutils { };

  # TODO(dezgeg): either refactor & use ubootTools directly, or
  # remove completely
  ubootChooser = name: ubootTools;

  # Upstream U-Boots:
  ubootTools = callPackage ../misc/uboot {
    toolsOnly = true;
    targetPlatforms = lib.platforms.linux;
    filesToInstall = ["tools/dumpimage" "tools/mkenvimage" "tools/mkimage"];
  };
#
  cantarell_fonts = callPackage ../data/fonts/cantarell-fonts { };
#
  docbook5 = callPackage ../data/sgml+xml/schemas/docbook-5.0 { };

  docbook_sgml_dtd_31 =
    callPackage ../data/sgml+xml/schemas/sgml-dtd/docbook/3.1.nix { };

  docbook_sgml_dtd_41 =
    callPackage ../data/sgml+xml/schemas/sgml-dtd/docbook/4.1.nix { };

  docbook_xml_dtd_412 =
    callPackage ../data/sgml+xml/schemas/xml-dtd/docbook/4.1.2.nix { };

  docbook_xml_dtd_42 =
    callPackage ../data/sgml+xml/schemas/xml-dtd/docbook/4.2.nix { };

  docbook_xml_dtd_43 =
    callPackage ../data/sgml+xml/schemas/xml-dtd/docbook/4.3.nix { };
#
  docbook_xml_dtd_44 =
    callPackage ../data/sgml+xml/schemas/xml-dtd/docbook/4.4.nix { };
#
  docbook_xml_dtd_45 =
    callPackage ../data/sgml+xml/schemas/xml-dtd/docbook/4.5.nix { };
#
  freefont_ttf = callPackage ../data/fonts/freefont-ttf { };
#
  meslo-lg = callPackage ../data/fonts/meslo-lg {};
#
  mobile_broadband_provider_info =
    callPackage ../data/misc/mobile-broadband-provider-info { };
#
  sound-theme-freedesktop =
    callPackage ../data/misc/sound-theme-freedesktop { };
#
  unifont = callPackage ../data/fonts/unifont { };
#
  djvulibre = callPackage ../applications/misc/djvulibre { };
#
  djview = callPackage ../applications/graphics/djview { };
  djview4 = pkgs.djview;
#
  fluidsynth = callPackage ../applications/audio/fluidsynth { };
#
google_talk_plugin =
  callPackage
    ../applications/networking/browsers/mozilla-plugins/google-talk-plugin { };
#
  mpg123 = callPackage ../applications/audio/mpg123 { };
#
  mujs = callPackage ../all-pkgs/m/mujs { };
#
  rsync = callPackage ../applications/networking/sync/rsync { };
#
#
  #spotify = callPackage ../applications/audio/spotify { };
#
  subunit = callPackage ../development/libraries/subunit { };
#
telepathy_logger =
  callPackage
    ../applications/networking/instant-messengers/telepathy/logger {};

telepathy_mission_control =
  callPackage
    ../applications/networking/instant-messengers/telepathy/mission-control { };
#
  #trezor-bridge =
  #  callPackage ../applications/networking/browsers/mozilla-plugins/trezor { };
#
  xpdf = callPackage ../applications/misc/xpdf {
    base14Fonts = "${ghostscript}/share/ghostscript/fonts";
  };

  cups_filters = callPackage ../misc/cups/filters.nix { };
#
  dblatex = callPackage ../tools/typesetting/tex/dblatex {
    enableAllFeatures = false;
  };
#
  jack2_full = callPackage ../misc/jackaudio { };
  jack2_lib = callPackageAlias "jack2_full" {
    prefix = "lib";
  };
#
# All the new TeX Live is inside. See description in default.nix.
texlive =
  recurseIntoAttrs (callPackage ../tools/typesetting/tex/texlive-new { });
texLive = callPackageAlias "texlive" { };
#
  #wine = callPackage ../misc/emulators/wine {
  #  wineRelease = config.wine.release or "stable";
  #  wineBuild = config.wine.build or "wine32";
  #  pulseaudioSupport = config.pulseaudio or true;
  #};
  #wineStable = wine.override { wineRelease = "stable"; };
  #wineUnstable = lowPrio (wine.override { wineRelease = "unstable"; });
  #wineStaging = lowPrio (wine.override { wineRelease = "staging"; });

  #winetricks = callPackage ../misc/emulators/wine/winetricks.nix { };
#
  myEnvFun = callPackage ../misc/my-env { };
#
};  # END helperFunctions merge

in  # END let/in 1
self;
in  # END let/in 2
pkgs
