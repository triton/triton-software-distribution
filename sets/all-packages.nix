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

  lib = import ../lib;

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
            recurseIntoAttrs;
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
    callPackage ../tools/nix-generate-from-cpan.nix { };

  nixpkgs-lint = callPackage ../tools/nixpkgs-lint.nix { };


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
        '${pkgs.findutils}/bin/find' "$srcRoot" \
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

  cmark = callPackage ../pkgs/c/cmark { };

  #dockerTools = callPackage ../build-support/docker { };

  fetchgit = callPackage ../build-support/fetchgit { };

  fetchgitPrivate = callPackage ../build-support/fetchgit/private.nix { };

  fetchpatch = callPackage ../build-support/fetchpatch { };

  fetchsvn = callPackage ../build-support/fetchsvn {
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
    , multihash ? ""
    , sha256 ? ""
    , hash ? ""
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit
        name
        multihash
        hash
        sha256
        version;
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    } // {
      inherit rev;
    };

  fetchFromBitbucket =
    { owner
    , repo
    , rev
    , multihash ? ""
    , sha256
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit
        name
        multihash
        sha256
        version;
      url = "https://bitbucket.org/${owner}/${repo}/get/${rev}.tar.gz";
      extraPostFetch = ''
        # impure file, see https://github.com/NixOS/nixpkgs/pull/12002
        find . -name .hg_archival.txt -delete
      '';
    };

  fetchFromGitLab =
    { host ? "https://gitlab.com"
    , owner
    , repo
    , id ? "${owner}/${repo}"
    , rev
    , multihash ? ""
    , sha256
    , version ? null
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit name multihash sha256 version;
      url = "${host}/api/v4/projects/${lib.replaceStrings ["/"] ["%2F"] id}/"
        + "repository/archive.tar.bz2?sha=${rev}";
    };

  fetchFromCgit =
    { host
    , repo
    , rev  # Can also be a tag.
    , multihash ? ""
    , sha256
    , archive ? "tar.gz"
    , version ? null
    , name ? "${lib.replaceStrings [".git"] [""] repo}-${rev}"
    }:
    # Requires the instance to have snapshot support enabled.
    pkgs.fetchzip {
      inherit name multihash sha256 version;
      url = "${host}/${repo}/snapshot/${rev}.${archive}";
    };
  # API is almost identical.
  fetchFromGitweb = pkgs.fetchFromCgit;

  fetchFromSourceforge =
    { repo
    , rev
    , multihash ? ""
    , sha256
    , name ? "${repo}-${rev}"
    }:
    pkgs.fetchzip {
      inherit name multihash sha256;
      url = "http://sourceforge.net/code-snapshots/git/"
        + "${lib.substring 0 1 repo}/"
        + "${lib.substring 0 2 repo}/"
        + "${repo}/code.git/"
        + "${repo}-code-${rev}.zip";
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

  substituteAll =
    callPackage ../build-support/substitute/substitute-all.nix { };

  replaceDependency = callPackage ../build-support/replace-dependency.nix { };

  nukeReferences = callPackage ../build-support/nuke-references/default.nix { };

  vmTools = callPackage ../build-support/vm/default.nix { };

  releaseTools = callPackage ../build-support/release/default.nix { };

  composableDerivation = callPackage ../lib/composable-derivation.nix { };

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

wrapCC = callPackage ../build-support/cc-wrapper { };

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

"389-ds-base" = callPackage ../pkgs/3/389-ds-base { };

a52dec = callPackage ../pkgs/a/a52dec { };

aalib = callPackage ../pkgs/a/aalib { };

accountsservice = callPackage ../pkgs/a/accountsservice { };

acl = callPackage ../pkgs/a/acl { };

acme-sh = callPackage ../pkgs/a/acme-sh { };

acpi = callPackage ../pkgs/a/acpi { };

acpid = callPackage ../pkgs/a/acpid { };

adns = callPackage ../pkgs/a/adns { };

adobe-flash-player_stable = callPackage ../pkgs/a/adobe-flash-player {
  channel = "stable";
};
adobe-flash-player_beta = callPackage ../pkgs/a/adobe-flash-player {
  channel = "beta";
};
adobe-flash-player = callPackageAlias "adobe-flash-player_stable" { };

adwaita-icon-theme_3-30 = callPackage ../pkgs/a/adwaita-icon-theme {
  channel = "3.30";
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
adwaita-icon-theme = callPackageAlias "adwaita-icon-theme_3-30" { };

adwaita-qt = callPackage ../pkgs/a/adwaita-qt { };

afflib = callPackage ../pkgs/a/afflib { };

alacritty = pkgs.rustPackages.alacritty;

alsa-firmware = callPackage ../pkgs/a/alsa-firmware { };

alsa-lib = callPackage ../pkgs/a/alsa-lib { };

alsa-oss = callPackage ../pkgs/a/alsa-oss { };

alsa-plugins = callPackage ../pkgs/a/alsa-plugins { };

alsa-tools = callPackage ../pkgs/a/alsa-tools { };

alsa-utils = callPackage ../pkgs/a/alsa-utils { };

amd-microcode = callPackage ../pkgs/a/amd-microcode { };

amrnb = callPackage ../pkgs/a/amrnb { };

amrwb = callPackage ../pkgs/a/amrwb { };

aomedia = callPackage ../pkgs/a/aomedia { };
aomedia_head = callPackage ../pkgs/a/aomedia {
  channel = "head";
};

ant = callPackageAlias "apacheAnt" { };
apacheAnt = callPackage ../pkgs/a/apache-ant { };

apache-httpd = callPackage ../pkgs/a/apache-httpd  { };
apacheHttpdPackagesFor = apacheHttpd: self:
  let
    callPackage = pkgs.newScope self;
  in {
    inherit apacheHttpd;
    mod_dnssd = callPackage ../pkgs/m/mod_dnssd { };
  };
apacheHttpdPackages =
  pkgs.apacheHttpdPackagesFor pkgs.apacheHttpd pkgs.apacheHttpdPackages;
mod_dnssd = pkgs.apacheHttpdPackages.mod_dnssd;

appstream-glib = callPackage ../pkgs/a/appstream-glib { };

apr = callPackage ../pkgs/a/apr { };

apr-util = callPackage ../pkgs/a/apr-util { };

apt = callPackage ../pkgs/a/apt { };

#ardour =  callPackage ../pkgs/a/ardour { };

argyllcms = callPackage ../pkgs/a/argyllcms { };

aria2 = callPackage ../pkgs/a/aria2 { };
aria = callPackageAlias "aria2" { };

arkive = callPackage ../pkgs/a/arkive { };

asciidoctor_1 = callPackage ../pkgs/a/asciidoctor {
  channel = "1";
};
asciidoctor_2 = callPackage ../pkgs/a/asciidoctor {
  channel = "2";
};
asciidoctor = callPackageAlias "asciidoctor_2" { };

asciinema = pkgs.python3Packages.asciinema;

asio = callPackage ../pkgs/a/asio { };

aspell = callPackage ../pkgs/a/aspell { };

at-spi2-atk_2-30 = callPackage ../pkgs/a/at-spi2-atk {
  channel = "2.30";
  at-spi2-core = pkgs.at-spi2-core_2-30;
  atk = pkgs.atk_2-30;
};
at-spi2-atk = callPackageAlias "at-spi2-atk_2-30" { };

at-spi2-core_2-30 = callPackage ../pkgs/a/at-spi2-core {
  channel = "2.30";
};
at-spi2-core = callPackageAlias "at-spi2-core_2-30" { };

atftp = callPackage ../pkgs/a/atftp { };

atk_2-30 = callPackage ../pkgs/a/atk {
  channel = "2.30";
};
atk = callPackageAlias "atk_2-30" { };

atkmm_2-24 = callPackage ../pkgs/a/atkmm {
  channel = "2.24";
  atk = pkgs.atk_2-30;
};
atkmm = callPackageAlias "atkmm_2-24" { };

atom_stable = callPackage ../pkgs/a/atom {
  channel = "stable";
};
atom_beta = callPackage ../pkgs/a/atom {
  channel = "beta";
};
atom = callPackageAlias "atom_stable" { };

atop = callPackage ../pkgs/a/atop { };

attr = callPackage ../pkgs/a/attr { };

aubio = callPackage ../pkgs/a/aubio { };

audiofile = callPackage ../pkgs/a/audiofile { };

audit_full = callPackage ../pkgs/a/audit { };
audit_lib = callPackage ../pkgs/a/audit/lib.nix { };

augeas = callPackage ../pkgs/a/augeas { };

autoconf = callPackage ../pkgs/a/autoconf { };

autoconf_21x = callPackageAlias "autoconf" {
  channel = "2.1x";
};

autoconf-archive = callPackage ../pkgs/a/autoconf-archive { };

autogen = callPackage ../pkgs/a/autogen { };

automake = callPackage ../pkgs/a/automake { };

avahi = callPackage ../pkgs/a/avahi { };

aws-sdk-cpp = callPackage ../pkgs/a/aws-sdk-cpp { };

babeltrace = callPackage ../pkgs/b/babeltrace { };

babl = callPackage ../pkgs/b/babl { };

bash = callPackage ../pkgs/b/bash { };

bash_small = callPackage ../pkgs/b/bash {
  type = "small";
  readline = null;
  ncurses = null;
};

bash-completion = callPackage ../pkgs/b/bash-completion { };

bc = callPackage ../pkgs/b/bc { };

bcache-tools = callPackage ../pkgs/b/bcache-tools { };

bcachefs-tools = callPackage ../pkgs/b/bcachefs-tools { };

bdftopcf = callPackage ../pkgs/b/bdftopcf { };

beecrypt = callPackage ../pkgs/b/beecrypt { };

bind = callPackage ../pkgs/b/bind { };

bind_tools = callPackageAlias "bind" {
  suffix = "tools";
};

binutils = callPackage ../pkgs/b/binutils { };

bison = callPackage ../pkgs/b/bison { };

bluez = callPackage ../pkgs/b/bluez { };

boehm-gc = callPackage ../pkgs/b/boehm-gc { };

boost_1-66 = callPackage ../pkgs/b/boost {
  channel = "1.66";
};
boost_1-71 = callPackage ../pkgs/b/boost {
  channel = "1.71";
};
boost = callPackageAlias "boost_1-71" { };

borgbackup = pkgs.python3Packages.borgbackup;

borgmatic = pkgs.python3Packages.borgmatic;

brotli_1-0-3 = callPackage ../pkgs/b/brotli {
  version = "1.0.3";
};
brotli_1-0-7 = callPackage ../pkgs/b/brotli {
  version = "1.0.7";
};
brotli = callPackageAlias "brotli_1-0-7" { };
brotli_dist = callPackage ../pkgs/b/brotli/dist.nix { };

bs1770gain = callPackage ../pkgs/b/bs1770gain { };

btrfs-progs = callPackage ../pkgs/b/btrfs-progs { };

bubblewrap = callPackage ../pkgs/b/bubblewrap { };

build-dir-check = callPackage ../pkgs/b/build-dir-check { };

buildPerlPackage = callPackage ../pkgs/p/build-perl-package { };

busybox = callPackage ../pkgs/b/busybox { };

busybox_shell = callPackageAlias "busybox" {
  minimal = true;
  stdenv = pkgs.stdenv.override { cc = pkgs.cc_gcc_musl; };
  extraConfig = ''
    CONFIG_STATIC y
    CONFIG_ASH y
    CONFIG_ASH_ECHO y
    CONFIG_ASH_PRINTF y
    CONFIG_ASH_TEST y
    CONFIG_ASH_GETOPTS y
    CONFIG_ASH_CMDCMD y
    CONFIG_FEATURE_SH_MATH y
    CONFIG_FEATURE_SH_MATH_BASE y
  '';
};

busybox_bootstrap = callPackageAlias "busybox" {
  minimal = true;
  stdenv = pkgs.stdenv.override { cc = pkgs.cc_gcc_musl; };
  extraConfig = ''
    CONFIG_STATIC y
    CONFIG_ASH y
    CONFIG_ASH_ECHO y
    CONFIG_ASH_TEST y
    CONFIG_ASH_OPTIMIZE_FOR_SIZE y
    CONFIG_MKDIR y
    CONFIG_TAR y
    CONFIG_UNXZ y
  '';
};

bzip2 = callPackage ../pkgs/b/bzip2 { };

cabextract = callPackage ../pkgs/c/cabextract { };

cacert = callPackage ../pkgs/c/cacert { };

c-ares = callPackage ../pkgs/c/c-ares { };

cairo = callPackage ../pkgs/c/cairo { };

cairomm = callPackage ../pkgs/c/cairomm { };

cantarell_fonts = callPackage ../pkgs/c/cantarell-fonts { };

caribou = callPackage ../pkgs/c/caribou { };

cc = null;
hostcc = null;

cc_relinker = callPackage ../build-support/cc-relinker { };

cc_clang_early = pkgs.wrapCCNew {
  compiler = pkgs.clang.bin;
  tools = [ pkgs.llvm.bin ];
  inputs = [
    pkgs.clang.cc_headers
    pkgs.linux-headers
  ];
};

cc_gcc_early = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc.cc_headers
    pkgs.linux-headers
  ];
};

cc_gcc_glibc_headers = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc.cc_headers
    pkgs.glibc_headers_gcc
    pkgs.linux-headers
  ];
};

cc_gcc_musl_headers = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc.cc_headers
    pkgs.musl_headers
    pkgs.linux-headers
  ];
};

cc_gcc_glibc_nolibc = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_lib_glibc_static
    pkgs.gcc.cc_headers
    pkgs.glibc_headers_gcc
    pkgs.linux-headers
  ];
};

cc_gcc_musl_nolibc = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_lib_musl_static
    pkgs.gcc.cc_headers
    pkgs.musl_headers
    pkgs.linux-headers
  ];
};

cc_gcc_glibc_nolibgcc = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_lib_glibc_static
    pkgs.gcc.cc_headers
    pkgs.glibc_lib_gcc
    pkgs.linux-headers
  ];
};

cc_gcc_musl_nolibgcc = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_lib_musl_static
    pkgs.gcc.cc_headers
    pkgs.musl_lib_gcc
    pkgs.linux-headers
  ];
};

cc_gcc_glibc_early = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_lib_glibc
    pkgs.gcc.cc_headers
    pkgs.glibc_lib_gcc
    pkgs.linux-headers
  ];
};

cc_gcc_musl_early = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_lib_musl
    pkgs.gcc.cc_headers
    pkgs.musl_lib_gcc
    pkgs.linux-headers
  ];
};

cc_gcc_glibc = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_runtime_glibc
    pkgs.gcc_lib_glibc
    pkgs.gcc.cc_headers
    pkgs.glibc_lib_gcc.cc_reqs
    pkgs.glibc_lib_gcc
    pkgs.linux-headers
  ];
};

cc_gcc_musl = pkgs.wrapCC {
  compiler = pkgs.gcc.bin;
  tools = [ pkgs.binutils.bin ];
  inputs = [
    pkgs.gcc_runtime_musl
    pkgs.gcc_lib_musl
    pkgs.gcc.cc_headers
    pkgs.musl_lib_gcc
    pkgs.linux-headers
  ];
};

cc-regression = callPackage ../pkgs/c/cc-regression { };

ccid = callPackage ../pkgs/c/ccid { };

cdparanoia = callPackage ../pkgs/c/cdparanoia { };

cdrtools = callPackage ../pkgs/c/cdrtools { };

celluloid = callPackage ../pkgs/c/celluloid { };

celt_0-5 = callPackage ../pkgs/c/celt {
  channel = "0.5";
};
celt_0-11 = callPackage ../pkgs/c/celt {
  channel = "0.11";
};
celt = callPackageAlias "celt_0-11" { };

# Only ever add ceph LTS releases
# The default channel should be the latest LTS
# Dev should always point to the latest versioned release
ceph_lib = pkgs.ceph.lib;
ceph = hiPrio pkgs.ceph_12;
ceph_10 = callPackage ../pkgs/c/ceph {
  channel = "10";
};
ceph_12 = callPackage ../pkgs/c/ceph/cmake.nix {
  channel = "12";
};
ceph_dev = callPackage ../pkgs/c/ceph/cmake.nix {
  channel = "dev";
};
ceph_git = callPackage ../pkgs/c/ceph/cmake.nix {
  channel = "git";
};

cfitsio = callPackage ../pkgs/c/cfitsio { };

cgit = callPackage ../pkgs/c/cgit { };

cgmanager = callPackage ../pkgs/c/cgmanager { };

chck = callPackage ../pkgs/c/chck { };

check = callPackage ../pkgs/c/check { };

chromaprint = callPackage ../pkgs/c/chromaprint { };

#chromium_old = callPackage ../pkgs/c/chromium_old {
#  channel = "stable";
#};
#chromium_old_beta = callPackageAlias "chromium_old" {
#  channel = "beta";
#};
#chromium_old_dev = callPackageAlias "chromium_old" {
#  channel = "dev";
#};

chrony = callPackage ../pkgs/c/chrony { };

cifs-utils = callPackage ../pkgs/c/cifs-utils { };

civetweb = callPackage ../pkgs/c/civetweb { };

cjdns = callPackage ../pkgs/c/cjdns { };

clang_9 = callPackage ../pkgs/c/clang {
  llvm = pkgs.llvm_9;
};
clang = callPackageAlias "clang_9" { };

clr-boot-manager = callPackage ../pkgs/c/clr-boot-manager { };

clutter_1-26 = callPackage ../pkgs/c/clutter {
  channel = "1.26";
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
clutter = callPackageAlias "clutter_1-26" { };

clutter-gst = callPackage ../pkgs/c/clutter-gst { };

clutter-gtk_1-8 = callPackage ../pkgs/c/clutter-gtk {
  channel = "1.8";
};
clutter-gtk = callPackageAlias "clutter-gtk_1-8" { };

cmake = callPackage ../pkgs/c/cmake {
  cmake = pkgs.cmake_bootstrap;
};
cmake_bootstrap = callPackage ../pkgs/c/cmake/bootstrap.nix { };

cmocka = callPackage ../pkgs/c/cmocka { };

cogl_1-22 = callPackage ../pkgs/c/cogl {
  channel = "1.22";
};
cogl = callPackageAlias "cogl_1-22" { };

collectd_lib = callPackageAlias "collectd" { };
collectd = callPackage ../pkgs/c/collectd {
  type = "base";
};
collectd_plugins = callPackage ../pkgs/c/collectd {
  type = "plugins";
};

colm_0-12 = callPackage ../pkgs/c/colm {
  channel = "0.12";
};
colm_0-13 = callPackage ../pkgs/c/colm {
  channel = "0.13";
};
colm = callPackageAlias "colm_0-12" { };

colord = callPackage ../pkgs/c/colord { };

colord-gtk = callPackage ../pkgs/c/colord-gtk { };

colorhug-client = callPackage ../pkgs/c/colorhug-client { };

combine-xml-catalogs = callPackage ../pkgs/c/combine-xml-catalogs { };

compiler-rt_9 = callPackage ../pkgs/c/compiler-rt {
  llvm = pkgs.llvm_9;
};
compiler-rt = callPackageAlias "compiler-rt_9" { };

conntrack-tools = callPackage ../pkgs/c/conntrack-tools { };

consul = pkgs.goPackages.consul;

consul-template = pkgs.goPackages.consul-template;

coreutils = callPackage ../pkgs/c/coreutils { };

coreutils_small = callPackage ../pkgs/c/coreutils {
  type = "small";
  acl = null;
  attr = null;
  gmp = null;
  libcap = null;
  libselinux = null;
  libsepol = null;
};

corosync = callPackage ../pkgs/c/corosync { };

cpio = callPackage ../pkgs/c/cpio { };

cpp-netlib = callPackage ../pkgs/c/cpp-netlib { };

cppunit = callPackage ../pkgs/c/cppunit { };

cracklib = callPackage ../pkgs/c/cracklib { };

cryptodev_headers = callPackage ../pkgs/c/cryptodev {
  onlyHeaders = true;
  kernel = null;
};

cryptopp = callPackage ../pkgs/c/cryptopp { };

cryptsetup = callPackage ../pkgs/c/cryptsetup { };

cscope = callPackage ../pkgs/c/cscope { };

cuetools = callPackage ../pkgs/c/cuetools { };

cunit = callPackage ../pkgs/c/cunit { };

cups = callPackage ../pkgs/c/cups { };

cups_filters = callPackage ../allpkgs/c/cups-filters { };

curl = callPackage ../pkgs/c/curl { };

curl_minimal = callPackage ../pkgs/c/curl {
  type = "minimal";
};

cyrus-sasl = callPackage ../pkgs/c/cyrus-sasl { };

dash = callPackage ../pkgs/d/dash { };

db_5 = callPackage ../pkgs/d/db {
  channel = "5";
};
db_6 = callPackage ../pkgs/d/db {
  channel = "6";
};
db = callPackageAlias "db_5" { };

dbus = callPackage ../pkgs/d/dbus { };

dbus-broker = callPackage ../pkgs/d/dbus-broker { };

dbus-dummy = callPackage ../pkgs/d/dbus-dummy { };

dbus-glib = callPackage ../pkgs/d/dbus-glib { };

dcadec = callPackage ../pkgs/d/dcadec { };

dconf_0-30 = callPackage ../pkgs/d/dconf {
  channel = "0.30";
};
dconf = callPackageAlias "dconf_0-30" { };

dconf-editor_3-26 = callPackage ../pkgs/d/dconf-editor {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
dconf-editor = callPackageAlias "dconf-editor_3-26" { };

ddrescue = callPackage ../pkgs/d/ddrescue { };

dejagnu = callPackage ../pkgs/d/dejagnu { };

dejavu-fonts = callPackage ../pkgs/d/dejavu-fonts { };

desktop-file-utils = callPackage ../pkgs/d/desktop-file-utils { };
# Deprecated alias
desktop_file_utils = callPackageAlias "desktop-file-utils" { };

deterministic-zip = callPackage ../pkgs/d/deterministic-zip { };

devil = callPackage ../pkgs/d/devil { };

dhcp = callPackage ../pkgs/d/dhcp { };

dhcpcd = callPackage ../pkgs/d/dhcpcd { };

dht = callPackage ../pkgs/d/dht { };

dialog = callPackage ../pkgs/d/dialog { };

diffoscope = pkgs.python3Packages.diffoscope;

diffutils = callPackage ../pkgs/d/diffutils { };

ding-libs = callPackage ../pkgs/d/ding-libs { };

discord = callPackage ../pkgs/d/discord { };
discord_ptb = callPackage ../pkgs/d/discord {
  channel = "ptb";
};
discord_canary = callPackage ../pkgs/d/discord {
  channel = "canary";
};

djvulibre = callPackage ../pkgs/d/djvulibre { };

dlm_full = callPackage ../pkgs/d/dlm {
  type = "full";
};

dlm_lib = callPackage ../pkgs/d/dlm {
  type = "lib";
};

dmenu = callPackage ../pkgs/d/dmenu { };

dmidecode = callPackage ../pkgs/d/dmidecode { };

dmraid = callPackage ../pkgs/d/dmraid { };

dnscrypt-proxy = pkgs.goPackages.dnscrypt-proxy;

dnscrypt-wrapper = callPackage ../pkgs/d/dnscrypt-wrapper { };

dnsdiag = pkgs.python3Packages.dnsdiag;

dnsmasq = callPackage ../pkgs/d/dnsmasq { };

dnstop = callPackage ../pkgs/d/dnstop { };

docbook2x = callPackage ../pkgs/d/docbook2x { };

docbook5 = callPackage ../pkgs/d/docbook/docbook-5.0 { };

docbook_sgml_dtd_31 =
  callPackage ../pkgs/d/docbook/sgml-dtd/docbook/3.1.nix { };

docbook_sgml_dtd_41 =
  callPackage ../pkgs/d/docbook/sgml-dtd/docbook/4.1.nix { };

docbook_xml_dtd_412 =
  callPackage ../pkgs/d/docbook/xml-dtd/docbook/4.1.2.nix { };

docbook_xml_dtd_42 =
  callPackage ../pkgs/d/docbook/xml-dtd/docbook/4.2.nix { };

docbook_xml_dtd_43 =
  callPackage ../pkgs/d/docbook/xml-dtd/docbook/4.3.nix { };

docbook_xml_dtd_44 =
  callPackage ../pkgs/d/docbook/xml-dtd/docbook/4.4.nix { };

docbook_xml_dtd_45 =
  callPackage ../pkgs/d/docbook/xml-dtd/docbook/4.5.nix { };

docbook-xsl = callPackage ../pkgs/d/docbook-xsl { };

docbook-xsl-ns = callPackageAlias "docbook-xsl" {
  type = "ns";
};

docutils = pkgs.python3Packages.docutils;

dosfstools = callPackage ../pkgs/d/dosfstools { };

dos2unix = callPackage ../pkgs/d/dos2unix { };

dotconf = callPackage ../pkgs/d/dotconf { };

double-conversion = callPackage ../pkgs/d/double-conversion { };

doxygen = callPackage ../pkgs/d/doxygen {
  qt4 = null;
};

dpdk = callPackage ../pkgs/d/dpdk { };

dpkg = callPackage ../pkgs/d/dpkg { };

#dropbox = callPackage ../pkgs/d/dropbox { };

dtc = callPackage ../pkgs/d/dtc { };

duperemove = callPackage ../pkgs/d/duperemove { };

duplicity = pkgs.pythonPackages.duplicity;

e2fsprogs = callPackage ../pkgs/e/e2fsprogs { };

ed = callPackage ../pkgs/e/ed { };

editline = callPackage ../pkgs/e/editline { };

edac-utils = callPackage ../pkgs/e/edac-utils { };

efibootmgr = callPackage ../pkgs/e/efibootmgr { };

efivar = callPackage ../pkgs/e/efivar { };

egl-headers = callPackage ../pkgs/e/egl-headers { };

egl-wayland = callPackage ../pkgs/e/egl-wayland { };

eglexternalplatform = callPackage ../pkgs/e/eglexternalplatform { };

eigen = callPackage ../pkgs/e/eigen { };

elasticsearch_5 = callPackage ../pkgs/e/elasticsearch {
  channel = "5";
};
elasticsearch_6 = callPackage ../pkgs/e/elasticsearch {
  channel = "6";
};
elasticsearch = callPackageAlias "elasticsearch_5" { };

elfutils = callPackage ../pkgs/e/elfutils { };

ell = callPackage ../pkgs/e/ell { };

elvish = pkgs.goPackages.elvish;

emacs = callPackage ../pkgs/e/emacs { };

enca = callPackage ../pkgs/e/enca { };

enchant = callPackage ../pkgs/e/enchant { };

eog_3-26 = callPackage ../pkgs/e/eog {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
eog = callPackageAlias "eog_3-26" { };

erlang = callPackage ../pkgs/e/erlang { };

erlang_graphical = callPackageAlias "erlang" {
  graphical = true;
};

etcd = pkgs.goPackages.etcd;

ethtool = callPackage ../pkgs/e/ethtool { };

evieext = callPackage ../pkgs/e/evieext { };

evince_3-32 = callPackage ../pkgs/e/evince {
  channel = "3.32";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
  nautilus = pkgs.nautilus_unwrapped_3-26;
};
evince = callPackageAlias "evince_3-32" { };

#evolution = callPackage ../pkgs/e/evolution { };

evolution-data-server_3-28 = callPackage ../pkgs/e/evolution-data-server {
  channel = "3.28";
  #gnome-online-accounts
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
  libsoup = pkgs.libsoup_2-64;
};
evolution-data-server = callPackageAlias "evolution-data-server_3-28" { };

exempi = callPackage ../pkgs/e/exempi { };

exfat-utils = callPackage ../pkgs/e/exfat-utils { };

exiv2 = callPackage ../pkgs/e/exiv2 { };

exo = callPackage ../pkgs/e/exo { };

expat = callPackage ../pkgs/e/expat { };

expect = callPackage ../pkgs/e/expect { };

extra-cmake-modules = callPackage ../pkgs/e/extra-cmake-modules { };

f2fs-tools = callPackage ../pkgs/f/f2fs-tools { };

faac = callPackage ../pkgs/f/faac { };

faad2 = callPackage ../pkgs/f/faad2 { };

factorio_0-15 = callPackage ../pkgs/f/factorio {
  channel = "0.15";
};
factorio_headless_0-15 = callPackage ../pkgs/f/factorio {
  type = "headless";
  channel = "0.15";
};
factorio_0-16 = callPackage ../pkgs/f/factorio {
  channel = "0.16";
};
factorio_headless_0-16 = callPackage ../pkgs/f/factorio {
  type = "headless";
  channel = "0.16";
};
factorio_experimental = callPackage ../pkgs/f/factorio {
  channel = "experimental";
};
factorio_headless_experimental = callPackage ../pkgs/f/factorio {
  type = "headless";
  channel = "experimental";
};
factorio = callPackageAlias "factorio_0-16" { };
factorio_headless = callPackageAlias "factorio_headless_0-16" { };

fbterm = callPackage ../pkgs/f/fbterm { };

fcgi = callPackage ../pkgs/f/fcgi { };

fdk-aac_stable = callPackage ../pkgs/f/fdk-aac {
  channel = "stable";
};
fdk-aac_head = callPackage ../pkgs/f/fdk-aac {
  channel = "head";
};
fdk-aac = callPackageAlias "fdk-aac_stable" { };

feh = callPackage ../pkgs/f/feh { };

ffado_full = callPackage ../pkgs/f/ffado { };
ffado_lib = callPackage ../pkgs/f/ffado {
  prefix = "lib";
};

ffmpeg_generic = overrides: callPackage ../pkgs/f/ffmpeg ({
  # The following are disabled by default
  aomedia = null;
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
  jack2_lib = null;
  jni = null;
  kvazaar = null;
  ladspa-sdk = null;
  #libavc1394 = null;
  libbluray = null;
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
  mfx-dispatcher = null;
  mmal = null;
  nv-codec-headers = null;
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
  zimg = null;
  #zvbi = null;
} // overrides);
ffmpeg_3-4 = pkgs.ffmpeg_generic {
  channel = "3.4";
};
ffmpeg_3 = callPackageAlias "ffmpeg_3-4" { };
ffmpeg_4-0 = pkgs.ffmpeg_generic {
  channel = "4.0";
};
ffmpeg_4-1 = pkgs.ffmpeg_generic {
  channel = "4.1";
};
ffmpeg_4 = callPackageAlias "ffmpeg_4-1" { };
ffmpeg_head = pkgs.ffmpeg_generic {
  channel = "9.9";
  # Use latest dependencies
  opus = pkgs.opus_head;
  libvpx = pkgs.libvpx_head;
  x265 = pkgs.x265_head;
};
ffmpeg = callPackageAlias "ffmpeg_4" { };

ffms = callPackage ../pkgs/f/ffms { };

fftw_double = callPackage ../pkgs/f/fftw {
  precision = "double";
};
fftw_long-double = callPackage ../pkgs/f/fftw {
  precision = "long-double";
};
fftw_quad = callPackage ../pkgs/f/fftw {
  precision = "quad-precision";
};
fftw_single = callPackage ../pkgs/f/fftw {
  precision = "single";
};

file = callPackage ../pkgs/f/file { };

file-roller_3-26 = callPackage ../pkgs/f/file-roller {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  nautilus = pkgs.nautilus_unwrapped_3-26;
};
file-roller = callPackageAlias "file-roller_3-26" { };

filezilla = callPackage ../pkgs/f/filezilla { };

findutils = callPackage ../pkgs/f/findutils { };

fio = callPackage ../pkgs/f/fio { };

firefox = pkgs.firefox_wrapper pkgs.firefox-unwrapped { };
firefox-esr = pkgs.firefox_wrapper pkgs.firefox-esr-unwrapped { };
firefox-unwrapped = callPackage ../pkgs/f/firefox { };
firefox-esr-unwrapped = callPackage ../pkgs/f/firefox {
  channel = "esr";
};
firefox_wrapper = callPackage ../pkgs/f/firefox/wrapper.nix { };

fish = callPackage ../pkgs/f/fish { };

flac = callPackage ../pkgs/f/flac { };

flashmap = callPackage ../pkgs/f/flashmap { };

flashrom = callPackage ../pkgs/f/flashrom { };

flashrom_chromium = callPackage ../pkgs/f/flashrom/chromium.nix { };

flatbuffers = callPackage ../pkgs/f/flatbuffers { };

flex = callPackage ../pkgs/f/flex { };

flite = callPackage ../pkgs/f/flite { };

fltk13 = callPackage ../pkgs/f/fltk/fltk13.nix { };

fluidsynth = callPackage ../pkgs/f/fluidsynth { };

fontcacheproto = callPackage ../pkgs/f/fontcacheproto { };

fontconfig = callPackage ../pkgs/f/fontconfig { };
makeFontsCache =
  let
    fontconfig_ = pkgs.fontconfig;
  in {
    fontconfig ? fontconfig_,
    fontDirectories
  }:
  callPackage ../pkgs/f/fontconfig/make-fonts-cache.nix {
    inherit
      fontconfig
      fontDirectories;
  };

fontforge = callPackage ../pkgs/f/fontforge { };

fox = callPackage ../pkgs/f/fox { };

freefont_ttf = callPackage ../pkgs/f/freefont-ttf { };

freeglut = callPackage ../pkgs/f/freeglut { };

freeipmi = callPackage ../pkgs/f/freeipmi { };

freetype_for-harfbuzz = callPackage ../pkgs/f/freetype {
  type = "harfbuzz";
};
freetype = callPackage ../pkgs/f/freetype {
  type = "full";
};

frei0r-plugins = callPackage ../pkgs/f/frei0r-plugins { };

fribidi = callPackage ../pkgs/f/fribidi { };

fstrm = callPackage ../pkgs/f/fstrm { };

fuse_2 = callPackage ../pkgs/f/fuse/2.nix { };
fuse_3 = callPackage ../pkgs/f/fuse/3.nix { };

fuse-exfat = callPackage ../pkgs/f/fuse-exfat { };

fwupd = callPackage ../pkgs/f/fwupd {
  fwupdate = null; # Broken until binutils update
};

fwupdate = callPackage ../pkgs/f/fwupdate { };

game-music-emu = callPackage ../pkgs/g/game-music-emu { };

gawk = callPackage ../pkgs/g/gawk { };

gawk_small = callPackage ../pkgs/g/gawk {
  type = "small";
  gmp = null;
  libsigsegv = null;
  mpfr = null;
  readline = null;
};

gcab = callPackage ../pkgs/g/gcab { };

gcc = callPackage ../pkgs/g/gcc { };

gcc_lib_glibc = callPackage ../pkgs/g/gcc/lib.nix {
  cc = pkgs.cc_gcc_glibc_nolibgcc;
};

gcc_lib_musl = callPackage ../pkgs/g/gcc/lib.nix {
  cc = pkgs.cc_gcc_musl_nolibgcc;
};

gcc_lib_glibc_static = callPackage ../pkgs/g/gcc/lib.nix {
  cc = pkgs.cc_gcc_glibc_headers;
  type = "nolibc";
};

gcc_lib_musl_static = callPackage ../pkgs/g/gcc/lib.nix {
  cc = pkgs.cc_gcc_musl_headers;
  type = "nolibc";
};

gcc_cxx_glibc = callPackage ../pkgs/g/gcc/cxx.nix {
  cc = pkgs.cc_gcc_glibc_early;
  gcc_lib = pkgs.gcc_lib_glibc;
};

gcc_runtime_glibc = callPackage ../pkgs/g/gcc/runtime.nix {
  cc = pkgs.cc_gcc_glibc_early;
  gcc_lib = pkgs.gcc_lib_glibc;
};

gcc_runtime_musl = callPackage ../pkgs/g/gcc/runtime.nix {
  cc = pkgs.cc_gcc_musl_early;
  gcc_lib = pkgs.gcc_lib_musl;
  libsan = false;
  preConfigure = ''
    # Needed for the libstdc++ configure script to pick the right headers
    # that don't use glibc macros
    export NIX_SYSTEM_BUILD="$(echo "$NIX_SYSTEM_BUILD" | sed 's,gnu,musl,')"
    export NIX_SYSTEM_HOST="$(echo "$NIX_SYSTEM_HOST" | sed 's,gnu,musl,')"
  '';
  failureHook = ''
    find . -name config.log -exec cat {} \;
  '';
};

gcc_runtime = null;

gconf = callPackage ../pkgs/g/gconf { };

gcr = callPackage ../pkgs/g/gcr { };

gdb = callPackage ../pkgs/g/gdb { };

gdbm = callPackage ../pkgs/g/gdbm { };

gdk-pixbuf_2-38 = callPackage ../pkgs/g/gdk-pixbuf {
  channel = "2.38";
  gdk-pixbuf-loaders-cache = callPackageAlias "gdk-pixbuf-loaders-cache" {
    gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  };
};
gdk-pixbuf = callPackageAlias "gdk-pixbuf_2-38" { };

gdk-pixbuf-loaders-cache = callPackage ../pkgs/g/gdk-pixbuf-loaders-cache { };

gdl = callPackage ../pkgs/g/gdl { };

gdm = callPackage ../pkgs/g/gdm { };

geoclue = callPackage ../pkgs/g/geoclue { };

gegl = callPackage ../pkgs/g/gegl { };

gengetopt = callPackage ../pkgs/g/gengetopt { };

geocode-glib = callPackage ../pkgs/g/geocode-glib { };

geoip = callPackage ../pkgs/g/geoip { };

getopt = callPackage ../pkgs/g/getopt { };

gettext = callPackage ../pkgs/g/gettext { };

gexiv2_0-10 = callPackage ../pkgs/g/gexiv2 {
  channel = "0.10";
};
gexiv2 = callPackageAlias "gexiv2_0-10" { };

gflags = callPackage ../pkgs/g/gflags { };

ghostscript = callPackage ../pkgs/g/ghostscript { };

giblib = callPackage ../pkgs/g/giblib { };

giflib = callPackage ../pkgs/g/giflib { };

gimp = callPackage ../pkgs/g/gimp { };

git = callPackage ../pkgs/g/git { };

gjs_1-46 = callPackage ../pkgs/g/gjs {
  channel = "1.46";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
gjs_1-48 = callPackage ../pkgs/g/gjs {
  channel = "1.48";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
gjs = callPackageAlias "gjs_1-46" { };

gksu = callPackage ../pkgs/g/gksu { };

glew = callPackage ../pkgs/g/glew { };

glfw = callPackage ../pkgs/g/glfw { };

glib = callPackage ../pkgs/g/glib { };

glibc_lib = null;

glibc_lib_gcc = callPackage ../pkgs/g/glibc {
  cc = pkgs.cc_gcc_glibc_nolibc;
};

glibc_headers_clang = callPackage ../pkgs/g/glibc/headers.nix {
  cc = pkgs.cc_clang_early;
};

glibc_headers_gcc = callPackage ../pkgs/g/glibc/headers.nix {
  cc = pkgs.cc_gcc_early;
};

glibc_progs = callPackage ../pkgs/g/glibc/progs.nix { };

glibc_locales = callPackage ../pkgs/g/glibc/locales.nix { };

glib-networking_2-54 = callPackage ../pkgs/g/glib-networking {
  channel = "2.54";
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
glib-networking = callPackageAlias "glib-networking_2-54" { };

glibmm_2-60 = callPackage ../pkgs/g/glibmm {
  channel = "2.60";
  libsigcxx = pkgs.libsigcxx_2-10;
};
glibmm = callPackageAlias "glibmm_2-60" { };

glog = callPackage ../pkgs/g/glog { };

glu = callPackage ../pkgs/g/glu { };

glusterfs = callPackage ../pkgs/g/glusterfs { };

gmime = callPackage ../pkgs/g/gmime { };

gmp = callPackage ../pkgs/g/gmp { };

gn = callPackage ../pkgs/g/gn { };

gnome-autoar = callPackage ../pkgs/g/gnome-autoar { };

gnome-backgrounds_3-30 = callPackage ../pkgs/g/gnome-backgrounds {
  channel = "3.30";
};
gnome-backgrounds = callPackageAlias "gnome-backgrounds_3-30" { };

gnome-bluetooth_3-32 = callPackage ../pkgs/g/gnome-bluetooth {
  channel = "3.31";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
gnome-bluetooth = callPackageAlias "gnome-bluetooth_3-32" { };

gnome-calculator_3-26 = callPackage ../pkgs/g/gnome-calculator {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gnome-themes-standard = pkgs.gnome-themes-standard_3-22;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
  gtksourceview = pkgs.gtksourceview_3-24;
  libsoup = pkgs.libsoup_2-64;
};
gnome-calculator = callPackageAlias "gnome-calculator_3-26" { };

gnome-clocks = callPackage ../pkgs/g/gnome-clocks { };

gnome-common = callPackage ../pkgs/g/gnome-common { };

gnome-control-center = callPackage ../pkgs/g/gnome-control-center { };

gnome-desktop_3-31 = callPackage ../pkgs/g/gnome-desktop {
  channel = "3.31";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
gnome-desktop = callPackageAlias "gnome-desktop_3-31" { };

gnome-doc-utils = callPackage ../pkgs/g/gnome-doc-utils { };

#gnome-documents_3-20 = callPackage ../pkgs/g/gnome-documents {
#  channel = "3.20";
#};
#gnome-documents = callPackageAlias "gnome-documents_3-20" { };

gnome-keyring = callPackage ../pkgs/g/gnome-keyring { };

gnome-menus_3-13 = callPackage ../pkgs/g/gnome-menus {
  channel = "3.13";
};
gnome-menus = callPackageAlias "gnome-menus_3-13" { };

#gnome-online-accounts_3-22 = callPackage ../pkgs/g/gnome-online-accounts {
#  channel = "3.22";
#};
#gnome-online-accounts = callPackageAlias "gnome-online-accounts_3-22" { };

#gnome-online-miners = callPackage ../pkgs/g/gnome-online-miners { };

gnome-raw-thumbnailer = callPackage ../pkgs/g/gnome-raw-thumbnailer { };

gnome-screenshot_3-26 = callPackage ../pkgs/g/gnome-screenshot {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
gnome-screenshot = callPackageAlias "gnome-screenshot_3-26" { };

gnome-session_3-26 = callPackage ../pkgs/g/gnome-session {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gnome-desktop = pkgs.gnome-desktop_3-31;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
gnome-session = callPackageAlias "gnome-session_3-26" { };

gnome-settings-daemon_3-26 =
  callPackage ../pkgs/g/gnome-settings-daemon {
    channel = "3.26";
    adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
    gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
    gnome-desktop = pkgs.gnome-desktop_3-31;
    gnome-themes-standard = pkgs.gnome-themes-standard_3-22;
    gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
  };
gnome-settings-daemon = callPackageAlias "gnome-settings-daemon_3-26" { };

gnome-shell = callPackage ../pkgs/g/gnome-shell { };

gnome-shell-extensions = callPackage ../pkgs/g/gnome-shell-extensions { };

gnome-terminal_3-26 = callPackage ../pkgs/g/gnome-terminal {
  channel = "3.26";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
  nautilus = pkgs.nautilus_unwrapped_3-26;
  vte = pkgs.vte_0-50;
};
gnome-terminal = callPackageAlias "gnome-terminal_3-26" { };

gnome-themes-standard_3-22 = callPackage ../pkgs/g/gnome-themes-standard {
  channel = "3.22";
};
gnome-themes-standard = callPackageAlias "gnome-themes-standard_3-22" { };

gnome-user-share = callPackage ../pkgs/g/gnome-user-share { };

gnu-efi = callPackage ../pkgs/g/gnu-efi { };

gnugrep = callPackage ../pkgs/g/gnugrep { };

gnulib = callPackage ../pkgs/g/gnulib { };

gnum4 = callPackage ../pkgs/g/gnum4 { };

gnumake = callPackage ../pkgs/g/gnumake { };

gnupatch = callPackage ../pkgs/g/gnupatch { };

gnupatch_small = callPackage ../pkgs/g/gnupatch {
  type = "small";
  attr = null;
};

gnupg = callPackage ../pkgs/g/gnupg { };

gnused = callPackage ../pkgs/g/gnused { };

gnused_small = callPackage ../pkgs/g/gnused {
  type = "small";
  perl = null;
  acl = null;
};

gnutar_1-30 = callPackage ../pkgs/g/gnutar {
  version = "1.30";
};
gnutar_1-32 = callPackage ../pkgs/g/gnutar {
  version = "1.32";
};
gnutar = callPackage ../pkgs/g/gnutar { };

gnutar_small = callPackage ../pkgs/g/gnutar {
  type = "small";
  acl = null;
};

gnutls = callPackage ../pkgs/g/gnutls { };

goPackages_1-12 = callPackage ./go-packages.nix {
  channel = "1.12";
};
goPackages_1-13 = callPackage ./go-packages.nix {
  channel = "1.13";
};
goPackages = callPackageAlias "goPackages_1-12" { };

gobject-introspection = callPackage ../pkgs/g/gobject-introspection { };

gom = callPackage ../pkgs/g/gom { };

google-chrome_stable = callPackage ../pkgs/g/google-chrome {
  channel = "stable";
};
google-chrome_beta = callPackage ../pkgs/g/google-chrome {
  channel = "beta";
};
google-chrome_unstable = callPackage ../pkgs/g/google-chrome {
  channel = "unstable";
};
google-chrome = callPackageAlias "google-chrome_stable" { };

googletest = callPackage ../pkgs/g/googletest { };

gperf = pkgs.gperf_3-1;
gperf_3-1 = callPackage ../pkgs/g/gperf {
  channel = "3.1";
};
gperf_3-0 = callPackage ../pkgs/g/gperf {
  channel = "3.0";
};

gperftools = callPackage ../pkgs/g/gperftools { };

gpgme = callPackage ../pkgs/g/gpgme { };

gpm = callPackage ../pkgs/g/gpm-ncurses { };

gpsd = callPackage ../pkgs/g/gpsd { };

gptfdisk = callPackage ../pkgs/g/gptfdisk { };

granite = callPackage ../pkgs/g/granite { };

graphite2 = callPackage ../pkgs/g/graphite2 { };

graphviz = callPackage ../pkgs/g/graphviz { };

grilo = callPackage ../pkgs/g/grilo { };

grilo-plugins = callPackage ../pkgs/g/grilo-plugins { };

groff = callPackage ../pkgs/g/groff { };

grub_bios-i386 = callPackage ../pkgs/g/grub {
  type = "bios-i386";
};

grub_efi-x86_64 = callPackage ../pkgs/g/grub {
  type = "efi-x86_64";
};

grub_efi-i386 = callPackage ../pkgs/g/grub {
  type = "efi-i386";
};

gsettings-desktop-schemas_3-28 =
  callPackage ../pkgs/g/gsettings-desktop-schemas {
    channel = "3.28";
    gnome-backgrounds = pkgs.gnome-backgrounds_3-30;
  };
gsettings-desktop-schemas =
  callPackageAlias "gsettings-desktop-schemas_3-28" { };

grpc = callPackage ../pkgs/g/grpc { };

gsl = callPackage ../pkgs/g/gsl { };

gsm = callPackage ../pkgs/g/gsm { };

gsound = callPackage ../pkgs/g/gsound { };

gssdp = callPackage ../pkgs/g/gssdp { };

gst-libav_1-14 = callPackage ../pkgs/g/gst-libav {
  channel = "1.14";
  gst-plugins-base = pkgs.gst-plugins-base_1-14;
  gstreamer = pkgs.gstreamer_1-14;
};
gst-libav = callPackageAlias "gst-libav_1-14" { };

gst-plugins-bad_generics = overrides:
  callPackage ../pkgs/g/gst-plugins-bad ({
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
gst-plugins-bad_1-14 = pkgs.gst-plugins-bad_generics {
  channel = "1.14";
  gst-plugins-base = pkgs.gst-plugins-base_1-14;
  gstreamer = pkgs.gstreamer_1-14;
};
gst-plugins-bad = callPackageAlias "gst-plugins-bad_1-14" { };

gst-plugins-base_1-14 = callPackage ../pkgs/g/gst-plugins-base {
  channel = "1.14";
  gstreamer = pkgs.gstreamer_1-14;
};
gst-plugins-base = callPackageAlias "gst-plugins-base_1-14" { };

gst-plugins-good_generics = overrides:
  callPackage ../pkgs/g/gst-plugins-good ({
    aalib = null;
    jack2_lib = null;
    libcaca = null;
    wavpack = null;
  } // overrides);
gst-plugins-good_1-14 = pkgs.gst-plugins-good_generics {
  channel = "1.14";
  gst-plugins-base = pkgs.gst-plugins-base_1-14;
  gstreamer = pkgs.gstreamer_1-14;
};
gst-plugins-good = callPackageAlias "gst-plugins-good_1-14" { };

gst-plugins-ugly_generics = overrides:
  callPackage ../pkgs/g/gst-plugins-ugly ({
    amrnb = null;
    amrwb = null;
  } // overrides);
gst-plugins-ugly_1-14 = pkgs.gst-plugins-ugly_generics {
  channel = "1.14";
  gst-plugins-base = pkgs.gst-plugins-base_1-14;
  gstreamer = pkgs.gstreamer_1-14;
};
gst-plugins-ugly = callPackageAlias "gst-plugins-ugly_1-14" { };

gst-validate_1-14 = callPackage ../pkgs/g/gst-validate {
  channel = "1.14";
  gst-plugins-base = pkgs.gst-plugins-base_1-14;
  gstreamer = pkgs.gstreamer_1-14;
};
gst-validate = callPackageAlias "gst-validate_1-14" { };

gstreamer_1-14 = callPackage ../pkgs/g/gstreamer {
  channel = "1.14";
};
gstreamer = callPackageAlias "gstreamer_1-14" { };

gstreamer-editing-services_1-14 =
  callPackage ../pkgs/g/gstreamer-editing-services {
    channel = "1.14";
    gst-plugins-base = pkgs.gst-plugins-base_1-14;
    gstreamer = pkgs.gstreamer_1-14;
  };
gstreamer-editing-services =
  callPackageAlias "gstreamer-editing-services_1-14" { };

gstreamer-vaapi_1-14 = callPackage ../pkgs/g/gstreamer-vaapi {
  channel = "1.14";
  gst-plugins-bad = pkgs.gst-plugins-bad_1-14;
  gst-plugins-base = pkgs.gst-plugins-base_1-14;
  gstreamer = pkgs.gstreamer_1-14;
};
gstreamer-vaapi = callPackageAlias "gstreamer-vaapi_1-14" { };

gtk_2 = callPackage ../pkgs/g/gtk/2.x.nix { };
# Deprecated alias
gtk2 = callPackageAlias "gtk_2" { };
gtk_3-24 = callPackage ../pkgs/g/gtk {
  channel = "3.24";
  atk = pkgs.atk_2-30;
  at-spi2-atk = pkgs.at-spi2-atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
gtk_3 = callPackageAlias "gtk_3-24" { };
# Deprecated alias
gtk3 = callPackageAlias "gtk_3" { };
gtk = callPackageAlias "gtk_3" { };

gtk-doc = callPackage ../pkgs/g/gtk-doc { };

gtkhtml = callPackage ../pkgs/g/gtkhtml { };

gtkimageview = callPackage ../pkgs/g/gtkimageview { };

gtkmm_2 = callPackage ../pkgs/g/gtkmm/2.x.nix { };
gtkmm_3-24 = callPackage ../pkgs/g/gtkmm {
  channel = "3.24";
  atkmm = pkgs.atkmm_2-24;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gtk = pkgs.gtk_3-24;
  pangomm = pkgs.pangomm_2-40;
};
gtkmm_3 = callPackageAlias "gtkmm_3-24" { };

gtksourceview_3-24 = callPackage ../pkgs/g/gtksourceview {
  channel = "3.24";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
gtksourceview = callPackageAlias "gtksourceview_3-24" { };

gtkspell_2 = callPackage ../pkgs/g/gtkspell/2.x.nix { };
gtkspell_3 = callPackage ../pkgs/g/gtkspell/3.x.nix { };
gtkspell = callPackageAlias "gtkspell_3" { };

gts = callPackage ../pkgs/g/gts { };

guile = callPackage ../pkgs/g/guile { };

guitarix = callPackage ../pkgs/g/guitarix {
  fftw = pkgs.fftw_single;
};

gupnp = callPackage ../pkgs/g/gupnp { };

gupnp-av = callPackage ../pkgs/g/gupnp-av { };

gupnp-igd = callPackage ../pkgs/g/gupnp-igd { };

gvfs = callPackage ../pkgs/g/gvfs {
  libsoup = pkgs.libsoup_2-64;
};

gyp = pkgs.python3Packages.gyp.dev;

gzip = callPackage ../pkgs/g/gzip { };

hadoop = callPackage ../pkgs/h/hadoop { };

haproxy = callPackage ../pkgs/h/haproxy { };

harfbuzz_lib = callPackage ../pkgs/h/harfbuzz {
  type = "lib";
};
harfbuzz_full = callPackage ../pkgs/h/harfbuzz {
  type = "full";
};

hdparm = callPackage ../pkgs/h/hdparm { };

help2man = callPackage ../pkgs/h/help2man { };

hexchat = callPackage ../pkgs/h/hexchat { };

hicolor-icon-theme = callPackage ../pkgs/h/hicolor-icon-theme { };

hidapi = callPackage ../pkgs/h/hidapi { };

highlight = callPackage ../pkgs/h/highlight { };

hiredis = callPackage ../pkgs/h/hiredis { };

hsts-list = callPackage ../pkgs/h/hsts-list { };

htop = callPackage ../pkgs/h/htop { };

http-parser = callPackage ../pkgs/h/http-parser { };

httping = callPackage ../pkgs/h/httping { };

hugo = pkgs.goPackages.hugo;

hunspell = callPackage ../pkgs/h/hunspell { };

hwdata = callPackage ../pkgs/h/hwdata { };

i2c-tools = callPackage ../pkgs/i/i2c-tools { };

iana-etc = callPackage ../pkgs/i/iana-etc { };

iasl = callPackage ../pkgs/i/iasl { };

ibus = callPackage ../pkgs/i/ibus { };

ice = callPackage ../pkgs/i/ice { };

iceauth = callPackage ../pkgs/i/iceauth { };

icedtea8_web = callPackage ../pkgs/i/icedtea-web {
  jdk = pkgs.jdk8;
  xulrunner = pkgs.firefox-unwrapped;
};
icedtea_web = pkgs.icedtea8_web;

icu = callPackage ../pkgs/i/icu { };

id3lib = callPackage ../pkgs/i/id3lib { };

id3v2 = callPackage ../pkgs/i/id3v2 { };

idnkit = callPackage ../pkgs/i/idnkit { };

iftop = callPackage ../pkgs/i/iftop { };

ijs = callPackage ../pkgs/i/ijs { };

ilmbase = callPackage ../pkgs/i/ilmbase { };

imagemagick = callPackage ../pkgs/i/imagemagick { };

imlib2 = callPackage ../pkgs/i/imlib2 { };

iniparser = callPackage ../pkgs/i/iniparser { };

inkscape = callPackage ../pkgs/i/inkscape { };

inotify-tools = callPackage ../pkgs/i/inotify-tools { };

intel-gpu-tools = callPackage ../pkgs/i/intel-gpu-tools { };

intel-microcode = callPackage ../pkgs/i/intel-microcode { };

intel-vaapi-driver = callPackage ../pkgs/i/intel-vaapi-driver { };

intltool = callPackage ../pkgs/i/intltool { };

iotop = pkgs.python3Packages.iotop;

iperf_2 = callPackage ../pkgs/i/iperf {
  channel = "2";
};
iperf_3 = callPackage ../pkgs/i/iperf {
  channel = "3";
};
iperf = callPackageAlias "iperf_3" { };

ipfs = pkgs.goPackages.ipfs;

ipfs-cluster = pkgs.goPackages.ipfs-cluster;

ipfs-ds-convert = pkgs.goPackages.ipfs-ds-convert;

ipfs-hasher = callPackage ../pkgs/i/ipfs-hasher { };

ipmitool = callPackage ../pkgs/i/ipmitool { };

iproute = callPackage ../pkgs/i/iproute { };

ipset = callPackage ../pkgs/i/ipset { };

iptables = callPackage ../pkgs/i/iptables { };

iputils = callPackage ../pkgs/i/iputils { };

irqbalance = callPackage ../pkgs/i/irqbalance { };

isl_0-22 = callPackage ../pkgs/i/isl {
  channel = "0.22";
};
isl = callPackageAlias "isl_0-22" { };

iso-codes = callPackage ../pkgs/i/iso-codes { };

itstool = pkgs.python3Packages.itstool;

iucode-tool = callPackage ../pkgs/i/iucode-tool { };

iw = callPackage ../pkgs/i/iw { };

iwd = callPackage ../pkgs/i/iwd { };

jack2_full = callPackage ../pkgs/j/jack2 { };
jack2_lib = callPackageAlias "jack2_full" {
  prefix = "lib";
};

jam = callPackage ../pkgs/j/jam { };

jansson = callPackage ../pkgs/j/jansson { };

jasper = callPackage ../pkgs/j/jasper { };

jbig2dec = callPackage ../pkgs/j/jbig2dec { };

jbigkit = callPackage ../pkgs/j/jbigkit { };

jemalloc = callPackage ../pkgs/j/jemalloc { };

jq = callPackage ../pkgs/j/jq { };

jshon = callPackage ../pkgs/j/jshon { };

json-c = callPackage ../pkgs/j/json-c { };

json-glib = callPackage ../pkgs/j/json-glib { };

jsoncpp = callPackage ../pkgs/j/jsoncpp { };

judy = callPackage ../pkgs/j/judy { };

kashmir = callPackage ../pkgs/k/kashmir { };

kbd = callPackage ../pkgs/k/kbd { };

kea = callPackage ../pkgs/k/kea { };

keepalived = callPackage ../pkgs/k/keepalived { };

keepassx = callPackage ../pkgs/k/keepassx { };

kelbt = callPackage ../pkgs/k/kelbt { };

kerberos = callPackageAlias "krb5_lib" { };

kexec-tools = callPackage ../pkgs/k/kexec-tools { };

keyutils = callPackage ../pkgs/k/keyutils { };

kid3 = callPackage ../pkgs/k/kid3 { };

kitty = callPackage ../pkgs/k/kitty { };

kmod = callPackage ../pkgs/k/kmod { };

kmscon = callPackage ../pkgs/k/kmscon { };

knot = callPackage ../pkgs/k/knot { };

knot-resolver = callPackage ../pkgs/k/knot-resolver { };

krb5_full = callPackage ../pkgs/k/krb5/full.nix { };

krb5_lib = callPackage ../pkgs/k/krb5/lib.nix { };

#kubernetes = callPackage ../pkgs/k/kubernetes { };

kyotocabinet = callPackage ../pkgs/k/kyotocabinet { };

kytea = callPackage ../pkgs/k/kytea { };

ladspa-sdk = callPackage ../pkgs/l/ladspa-sdk { };

lame = callPackage ../pkgs/l/lame {
  libsndfile = null;
};

lcms = callPackage ../pkgs/l/lcms { };
# Deprecated alias
lcms2 = callPackageAlias "lcms" { };

lcov = callPackage ../pkgs/l/lcov { };

ldb = callPackage ../pkgs/l/ldb { };

ldns = callPackage ../pkgs/l/ldns { };

lego = pkgs.goPackages.lego;

lensfun = callPackage ../pkgs/l/lensfun { };

leptonica = callPackage ../pkgs/l/leptonica { };

less = callPackage ../pkgs/l/less { };

leveldb = callPackage ../pkgs/l/leveldb { };

lftp = callPackage ../pkgs/l/lftp { };

lib-bash = callPackage ../pkgs/l/lib-bash { };

libaacs = callPackage ../pkgs/l/libaacs { };

libaccounts-glib = callPackage ../pkgs/l/libaccounts-glib { };

libaio = callPackage ../pkgs/l/libaio { };

libao = callPackage ../pkgs/l/libao { };

libarchive = callPackage ../pkgs/l/libarchive { };

libasr = callPackage ../pkgs/l/libasr { };

libass = callPackage ../pkgs/l/libass { };

libassuan = callPackage ../pkgs/l/libassuan { };

libargon2 = callPackage ../pkgs/l/libargon2 { };

libatasmart = callPackage ../pkgs/l/libatasmart { };

libatomic_ops = callPackage ../pkgs/l/libatomic_ops { };

libavc1394 = callPackage ../pkgs/l/libavc1394 { };

libb2 = callPackage ../pkgs/l/libb2 { };

libb64 = callPackage ../pkgs/l/libb64 { };

libbdplus = callPackage ../pkgs/l/libbdplus { };

libblockdev = callPackage ../pkgs/l/libblockdev { };

libbluray = callPackage ../pkgs/l/libbluray { };

libbsd = callPackage ../pkgs/l/libbsd { };

libburn = callPackage ../pkgs/l/libburn { };

libbytesize = callPackage ../pkgs/l/libbytesize { };

libc = null;

libcacard = callPackage ../pkgs/l/libcacard { };

libcanberra = callPackage ../pkgs/l/libcanberra { };

libcap = callPackage ../pkgs/l/libcap { };

libcap-ng = callPackage ../pkgs/l/libcap-ng { };

libcddb = callPackage ../pkgs/l/libcddb { };

libcdio = callPackage ../pkgs/l/libcdio { };

libcdio-paranoia = callPackage ../pkgs/l/libcdio-paranoia { };

libcdr = callPackage ../pkgs/l/libcdr { };

libclc = callPackage ../pkgs/l/libclc { };

libconfig = callPackage ../pkgs/l/libconfig { };

libconfuse = callPackage ../pkgs/l/libconfuse { };

libcroco = callPackage ../pkgs/l/libcroco { };

libcue = callPackage ../pkgs/l/libcue { };

libdaemon = callPackage ../pkgs/l/libdaemon { };

libdbi = callPackage ../pkgs/l/libdbi { };

libdc1394 = callPackage ../pkgs/l/libdc1394 { };

libdmx = callPackage ../pkgs/l/libdmx { };

libdrm = callPackage ../pkgs/l/libdrm { };

libdvbpsi = callPackage ../pkgs/l/libdvbpsi { };

libdvdcss = callPackage ../pkgs/l/libdvdcss { };

libdvdnav = callPackage ../pkgs/l/libdvdnav { };

libdvdread = callPackage ../pkgs/l/libdvdread { };

libebml = callPackage ../pkgs/l/libebml { };

libebur128 = callPackage ../pkgs/l/libebur128 { };

libedit = callPackage ../pkgs/l/libedit { };

libepoxy = callPackage ../pkgs/l/libepoxy { };

liberation-fonts = callPackage ../pkgs/l/liberation-fonts { };

libev = callPackage ../pkgs/l/libev { };

libevdev = callPackage ../pkgs/l/libevdev { };

libevent = callPackage ../pkgs/l/libevent { };

libexif = callPackage ../pkgs/l/libexif { };

libfaketime = callPackage ../pkgs/l/libfaketime { };

libffi = callPackage ../pkgs/l/libffi { };

libfilezilla = callPackage ../pkgs/l/libfilezilla { };

libfontenc = callPackage ../pkgs/l/libfontenc { };

libfpx = callPackage ../pkgs/l/libfpx { };

libftdi = callPackage ../pkgs/l/libftdi { };

libgcrypt = callPackage ../pkgs/l/libgcrypt { };

libgd = callPackage ../pkgs/l/libgd { };

libgda = callPackage ../pkgs/l/libgda { };

libgdata = callPackage ../pkgs/l/libgdata { };

libgdiplus = callPackage ../pkgs/l/libgdiplus { };

libgee_0-20 = callPackage ../pkgs/l/libgee {
  channel = "0.20";
};
libgee = callPackageAlias "libgee_0-20" { };

#libgfbgraph = callPackage ../pkgs/l/libgfbgraph { };

libgit2 = callPackage ../pkgs/l/libgit2 { };

libgksu = callPackage ../pkgs/l/libgksu { };

libglade = callPackage ../pkgs/l/libglade { };

libglvnd = callPackage ../pkgs/l/libglvnd { };

libgnome-keyring = callPackage ../pkgs/l/libgnome-keyring { };

libgnomekbd_3-22 = callPackage ../pkgs/l/libgnomekbd {
  channel = "3.22";
};
libgnomekbd = callPackageAlias "libgnomekbd_3-22" { };

libgpg-error = callPackage ../pkgs/l/libgpg-error { };

libgphoto2 = callPackage ../pkgs/l/libgphoto2 { };

libgpod = callPackage ../pkgs/l/libgpod {
  inherit (pkgs.pythonPackages) mutagen;
};

libgsf_1-14 = callPackage ../pkgs/l/libgsf {
  channel = "1.14";
};
libgsf = callPackageAlias "libgsf_1-14" { };

libgudev = callPackage ../pkgs/l/libgudev { };

libgusb = callPackage ../pkgs/l/libgusb { };

libgweather_3-28 = callPackage ../pkgs/l/libgweather {
  channel = "3.28";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  libsoup = pkgs.libsoup_2-64;
};
libgweather = callPackageAlias "libgweather_3-28" { };

libgxps_0-3 = callPackage ../pkgs/l/libgxps {
  channel = "0.3";
};
libgxps = callPackageAlias "libgxps_0-3" { };

libical = callPackage ../pkgs/l/libical { };

libice = callPackage ../pkgs/l/libice { };

libid3tag = callPackage ../pkgs/l/libid3tag { };

libidl = callPackage ../pkgs/l/libidl { };

libidn = callPackage ../pkgs/l/libidn { };

libidn2 = callPackage ../pkgs/l/libidn2 { };

libidn2_glibc = callPackage ../pkgs/l/libidn2 {
  cc = pkgs.cc_gcc_glibc_early;
  libunistring = pkgs.libunistring_glibc;
};

libimagequant = callPackage ../pkgs/l/libimagequant { };

libimobiledevice = callPackage ../pkgs/l/libimobiledevice { };

libiodbc = callPackage ../pkgs/l/libiodbc {
  gtk_2 = null;
};

libinput = callPackage ../pkgs/l/libinput { };

libiscsi = callPackage ../pkgs/l/libiscsi { };

libisoburn = callPackage ../pkgs/l/libisoburn { };

libisofs = callPackage ../pkgs/l/libisofs { };

libjpeg_original = callPackage ../pkgs/l/libjpeg { };

libjpeg-turbo = callPackage ../pkgs/l/libjpeg-turbo { };

libjpeg = callPackageAlias "libjpeg-turbo" { };

libkate = callPackage ../pkgs/l/libkate { };

libksba = callPackage ../pkgs/l/libksba { };

liblfds = callPackage ../pkgs/l/liblfds { };

liblinear = callPackage ../pkgs/l/liblinear { };

liblo = callPackage ../pkgs/l/liblo { };

liblogging = callPackage ../pkgs/l/liblogging { };

liblqr = callPackage ../pkgs/l/liblqr { };

libmatroska = callPackage ../pkgs/l/libmatroska { };

libmaxminddb = callPackage ../pkgs/l/libmaxminddb { };

libmbim = callPackage ../pkgs/l/libmbim { };

libmcrypt = callPackage ../pkgs/l/libmcrypt { };

libmediaart = callPackage ../pkgs/l/libmediaart { };

libmediainfo = callPackage ../pkgs/l/libmediainfo { };

libmetalink = callPackage ../pkgs/l/libmetalink { };

libmhash = callPackage ../pkgs/l/libmhash { };

libmicrohttpd = callPackage ../pkgs/l/libmicrohttpd { };

libmms = callPackage ../pkgs/l/libmms { };

libmnl = callPackage ../pkgs/l/libmnl { };

libmodplug = callPackage ../pkgs/l/libmodplug { };

libmpc = callPackage ../pkgs/l/libmpc { };

libmpdclient = callPackage ../pkgs/l/libmpdclient { };

libmpeg2 = callPackage ../pkgs/l/libmpeg2 { };

libmtp = callPackage ../pkgs/l/libmtp { };

libmusicbrainz = callPackage ../pkgs/l/libmusicbrainz { };

libmypaint = callPackage ../pkgs/l/libmypaint { };

libnatpmp = callPackage ../pkgs/l/libnatpmp { };

libnatspec = callPackage ../pkgs/l/libnatspec { };

libnetfilter_acct = callPackage ../pkgs/l/libnetfilter_acct { };

libnetfilter_conntrack = callPackage ../pkgs/l/libnetfilter_conntrack { };

libnetfilter_cthelper = callPackage ../pkgs/l/libnetfilter_cthelper { };

libnetfilter_cttimeout = callPackage ../pkgs/l/libnetfilter_cttimeout { };

libnetfilter_queue = callPackage ../pkgs/l/libnetfilter_queue { };

libnfnetlink = callPackage ../pkgs/l/libnfnetlink { };

libnfs = callPackage ../pkgs/l/libnfs { };

libnfsidmap = callPackage ../pkgs/l/libnfsidmap { };

libnftnl = callPackage ../pkgs/l/libnftnl { };

libnih = callPackage ../pkgs/l/libnih { };

libnl = callPackage ../pkgs/l/libnl { };

libnotify = callPackage ../pkgs/l/libnotify { };

liboath = callPackage ../pkgs/l/liboath { };

liboauth = callPackage ../pkgs/l/liboauth { };

libogg = callPackage ../pkgs/l/libogg { };

libomxil-bellagio = callPackage ../pkgs/l/libomxil-bellagio { };

libopenraw = callPackage ../pkgs/l/libopenraw { };

liboping = callPackage ../pkgs/l/liboping { };

libopusenc = callPackage ../pkgs/l/libopusenc { };

libosinfo = callPackage ../pkgs/l/libosinfo { };

libossp-uuid = callPackage ../pkgs/l/libossp-uuid { };

libpcap = callPackage ../pkgs/l/libpcap { };

libpciaccess = callPackage ../pkgs/l/libpciaccess { };

libpeas_1-22 = callPackage ../pkgs/l/libpeas {
  channel = "1.22";
};
libpeas = callPackageAlias "libpeas_1-22" { };

libpipeline = callPackage ../pkgs/l/libpipeline { };

libplist = callPackage ../pkgs/l/libplist { };

libpng = callPackage ../pkgs/l/libpng { };

libproxy = callPackage ../pkgs/l/libproxy { };

libpsl = callPackage ../pkgs/l/libpsl { };

libpthread-stubs = callPackage ../pkgs/l/libpthread-stubs { };

libpwquality = callPackage ../pkgs/l/libpwquality { };

libqb = callPackage ../pkgs/l/libqb { };

libqmi = callPackage ../pkgs/l/libqmi { };

libraw = callPackage ../pkgs/l/libraw { };

libraw1394 = callPackage ../pkgs/l/libraw1394 { };

librelp = callPackage ../pkgs/l/librelp { };

libressl = callPackage ../pkgs/l/libressl { };

librevenge = callPackage ../pkgs/l/librevenge {};

librsvg = callPackage ../pkgs/l/librsvg { };

librsync = callPackage ../pkgs/l/librsync { };

libs3 = callPackage ../pkgs/l/libs3 { };

libsamplerate = callPackage ../pkgs/l/libsamplerate { };

libsass = callPackage ../pkgs/l/libsass { };

libscrypt = callPackage ../pkgs/l/libscrypt { };

libseccomp = callPackage ../pkgs/l/libseccomp { };

libsecret = callPackage ../pkgs/l/libsecret { };

libselinux = callPackage ../pkgs/l/libselinux { };

libsepol = callPackage ../pkgs/l/libsepol { };

libshout = callPackage ../pkgs/l/libshout { };

libsigcxx_2-10 = callPackage ../pkgs/l/libsigcxx {
  channel = "2.10";
};
libsigcxx = callPackageAlias "libsigcxx_2-10" { };

libsigsegv = callPackage ../pkgs/l/libsigsegv { };

libsm = callPackage ../pkgs/l/libsm { };

libsmbios = callPackage ../pkgs/l/libsmbios { };

libsmi = callPackage ../pkgs/l/libsmi { };

libsndfile = callPackage ../pkgs/l/libsndfile { };

libsodium = callPackage ../pkgs/l/libsodium { };

libsoup_2-64 = callPackage ../pkgs/l/libsoup {
  channel = "2.64";
};
libsoup = callPackageAlias "libsoup_2-64" { };

libspectre = callPackage ../pkgs/l/libspectre { };

libspiro = callPackage ../pkgs/l/libspiro { };

libsquish = callPackage ../pkgs/l/libsquish { };

libssh = callPackage ../pkgs/l/libssh { };

libssh2 = callPackage ../pkgs/l/libssh2 { };

libstoragemgmt = callPackage ../pkgs/l/libstoragemgmt { };

libtasn1 = callPackage ../pkgs/l/libtasn1 { };

libtheora = callPackage ../pkgs/l/libtheora { };

libtiger = callPackage ../pkgs/l/libtiger { };

libtiff = callPackage ../pkgs/l/libtiff { };

libtirpc = callPackage ../pkgs/l/libtirpc { };

libtool = callPackage ../pkgs/l/libtool { };

libtorrent = callPackage ../pkgs/l/libtorrent { };

libtorrent-rasterbar_1-1 = callPackage ../pkgs/l/libtorrent-rasterbar {
  channel = "1.1";
};
libtorrent-rasterbar_1-1_head = callPackage ../pkgs/l/libtorrent-rasterbar {
  channel = "1.1-head";
};
libtorrent-rasterbar_head = callPackage ../pkgs/l/libtorrent-rasterbar {
  channel = "head";
};
libtorrent-rasterbar = callPackageAlias "libtorrent-rasterbar_1-1" { };

libtsm = callPackage ../pkgs/l/libtsm { };

libu2f-host = callPackage ../pkgs/l/libu2f-host { };

libungif = callPackage ../pkgs/l/libungif { };

libuninameslist = callPackage ../pkgs/l/libuninameslist { };

libunique = callPackage ../pkgs/l/libunique { };

libenistring = callPackage ../pkgs/l/libunistring { };

libunistring_glibc = callPackage ../pkgs/l/libunistring {
  cc = pkgs.cc_gcc_glibc_early;
};

libunwind = callPackage ../pkgs/l/libunwind { };

liburcu = callPackage ../pkgs/l/liburcu { };

libusb_0 = callPackageAlias "libusb-compat" { };
libusb_1 = callPackage ../pkgs/l/libusb { };
libusb = callPackageAlias "libusb_1" { };

libusb-compat = callPackage ../pkgs/l/libusb-compat { };

libusbmuxd = callPackage ../pkgs/l/libusbmuxd { };

libutempter = callPackage ../pkgs/l/libutempter { };

libutp = callPackage ../pkgs/l/libutp { };

libuv = callPackage ../pkgs/l/libuv { };

libva = callPackage ../pkgs/l/libva { };

libva-vdpau-driver = callPackage ../pkgs/l/libva-vdpau-driver { };

libvdpau = callPackage ../pkgs/l/libvdpau { };

libvdpau-va-gl = callPackage ../pkgs/l/libvdpau-va-gl { };

libverto = callPackage ../pkgs/l/libverto { };

libvisio = callPackage ../pkgs/l/libvisio { };

libvisual = callPackage ../pkgs/l/libvisual { };

libvorbis = callPackage ../pkgs/l/libvorbis { };

libvpx_1-6 = callPackage ../pkgs/l/libvpx {
  channel = "1.6";
};
libvpx_1-7 = callPackage ../pkgs/l/libvpx {
  channel = "1.7";
};
libvpx_1-8 = callPackage ../pkgs/l/libvpx {
  channel = "1.8";
};
libvpx_head = callPackage ../pkgs/l/libvpx {
  channel = "1.999";
};
libvpx = callPackageAlias "libvpx_1-7" { };

libwacom = callPackage ../pkgs/l/libwacom { };

libwebp = callPackage ../pkgs/l/libwebp { };

libwnck = callPackage ../pkgs/l/libwnck { };

libwpd = callPackage ../pkgs/l/libwpd { };

libwpg = callPackage ../pkgs/l/libwpg { };

libwps = callPackage ../pkgs/l/libwps { };

libx11 = callPackage ../pkgs/l/libx11 { };

libxau = callPackage ../pkgs/l/libxau { };

libxcb = callPackage ../pkgs/l/libxcb { };

libxcomposite = callPackage ../pkgs/l/libxcomposite { };

libxcursor = callPackage ../pkgs/l/libxcursor { };

libxdamage = callPackage ../pkgs/l/libxdamage { };

libxdmcp = callPackage ../pkgs/l/libxdmcp { };

libxext = callPackage ../pkgs/l/libxext { };

libxfce4ui_4-12 = callPackage ../pkgs/l/libxfce4ui {
  channel = "4.12";
};
libxfce4ui = callPackageAlias "libxfce4ui_4-12" { };

libxfce4util_4-12 = callPackage ../pkgs/l/libxfce4util {
  channel = "4.12";
};
libxfce4util = callPackageAlias "libxfce4util_4-12" { };

libxfixes = callPackage ../pkgs/l/libxfixes { };

libxfont = callPackage ../pkgs/l/libxfont {
  channel = "1";
};

libxfont2 = callPackage ../pkgs/l/libxfont {
  channel = "2";
};

libxft = callPackage ../pkgs/l/libxft { };

libxi = callPackage ../pkgs/l/libxi { };

libxinerama = callPackage ../pkgs/l/libxinerama { };

libxkbcommon = callPackage ../pkgs/l/libxkbcommon { };

libxkbfile = callPackage ../pkgs/l/libxkbfile { };

libxklavier = callPackage ../pkgs/l/libxklavier { };

libxml2 = callPackage ../pkgs/l/libxml2 { };

libxmu = callPackage ../pkgs/l/libxmu { };

libxrandr = callPackage ../pkgs/l/libxrandr { };

libxrender = callPackage ../pkgs/l/libxrender { };

libxres = callPackage ../pkgs/l/libxres { };

libxscrnsaver = callPackage ../pkgs/l/libxscrnsaver { };

libxshmfence = callPackage ../pkgs/l/libxshmfence { };

libxslt = callPackage ../pkgs/l/libxslt { };

libxt = callPackage ../pkgs/l/libxt { };

libxtst = callPackage ../pkgs/l/libxtst { };

libxv = callPackage ../pkgs/l/libxv { };

libyaml = callPackage ../pkgs/l/libyaml { };

#libzapojit = callPackage ../pkgs/l/libzapojit { };

libzip = callPackage ../pkgs/l/libzip { };

# FIXME:
################################################################################
libasyncns = callPackage ../pkgs/l/libasyncns { };
libbs2b = callPackage ../pkgs/l/libbs2b { };
libcaca = callPackage ../pkgs/l/libcaca { };
libdiscid = callPackage ../pkgs/l/libdiscid { };
libgtop = callPackage ../pkgs/l/libgtop {};
libndp = callPackage ../pkgs/l/libndp { };
libiec61883 = callPackage ../pkgs/l/libiec61883 { };
libmad = callPackage ../pkgs/l/libmad { };
libmikmod = callPackage ../pkgs/l/libmikmod { };
libmng = callPackage ../pkgs/l/libmng { };
liboggz = callPackage ../pkgs/l/liboggz { };
libpaper = callPackage ../pkgs/l/libpaper { };
libupnp = callPackage ../pkgs/l/libpupnp { };
libwmf = callPackage ../pkgs/l/libwmf { };
libxmlxx = callPackage ../pkgs/l/libxmlxx { };
libzen = callPackage ../pkgs/l/libzen { };
################################################################################

lightdm = callPackage ../pkgs/l/lightdm { };

lightdm-gtk-greeter = callPackage ../pkgs/l/lightdm-gtk-greeter { };

light-locker = callPackage ../pkgs/l/light-locker { };

lilv = callPackage ../pkgs/l/lilv { };

linenoise = callPackage ../pkgs/l/linenoise { };

linenoise-ng = callPackage ../pkgs/l/linenoise-ng { };

kernelPatches = callPackage ../pkgs/l/linux/patches.nix { };
linux_4-19 = callPackage ../pkgs/l/linux {
  channel = "4.19";
  kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
};
linux_5-2 = callPackage ../pkgs/l/linux {
  channel = "5.2";
  kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
};
linux_testing = callPackage ../pkgs/l/linux {
  channel = "testing";
  kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
};
linux_bcachefs = callPackage ../pkgs/l/linux {
  channel = "bcachefs";
  kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
};
# Linux kernel modules are inherently tied to a specific kernel.  So rather
# than provide specific instances of those packages for a specific kernel, we
# have a function that builds those packages for a specific kernel.  This
# function can then be called for whatever kernel you're using.
linuxPackagesFor = { kernel }: let
  kCallPackage = pkgs.newScope kPkgs;
  kPkgs = {
    inherit kernel;

    cryptodev = pkgs.cryptodev_headers.override {
      onlyHeaders = false;
      inherit kernel;  # We shouldn't need this
    };

    cpupower = kCallPackage ../pkgs/c/cpupower { };

    e1000e = kCallPackage ../pkgs/e/e1000e {};

    mft = kCallPackage ../pkgs/m/mft {
      inherit (kPkgs) kernel;
    };

    nvidia-drivers_tesla = kCallPackage ../pkgs/n/nvidia-drivers {
      channel = "tesla";
    };
    nvidia-drivers_long-lived = kCallPackage ../pkgs/n/nvidia-drivers {
      channel = "long-lived";
      buildConfig = "kernelspace";
    };
    nvidia-drivers_short-lived = kCallPackage ../pkgs/n/nvidia-drivers {
      channel = "short-lived";
      buildConfig = "kernelspace";
    };
    nvidia-drivers_beta = kCallPackage ../pkgs/n/nvidia-drivers {
      channel = "beta";
      buildConfig = "kernelspace";
    };
    nvidia-drivers_latest = kCallPackage ../pkgs/n/nvidia-drivers {
      channel = "latest";
      buildConfig = "kernelspace";
    };

    wireguard = kCallPackage ../pkgs/w/wireguard {
      inherit (kPkgs) kernel;
    };

    zfs = kCallPackage ../pkgs/z/zfs/kernel.nix {
      channel = "stable";
    };

    zfs_dev = kCallPackage ../pkgs/z/zfs/kernel.nix {
      channel = "dev";
      inherit (kPkgs) kernel;  # We shouldn't need this
    };
  };
in kPkgs;

# The current default kernel / kernel modules.
linuxPackages = pkgs.linuxPackages_4-19;
linux = pkgs.linuxPackages.kernel;

# Update this when adding the newest kernel major version!
linuxPackages_latest = pkgs.linuxPackages_5-2;
linux_latest = pkgs.linuxPackages_latest.kernel;

# Build the kernel modules for the some of the kernels.
linuxPackages_4-19 = recurseIntoAttrs (pkgs.linuxPackagesFor {
  kernel = pkgs.linux_4-19;
});
linuxPackages_5-2 = recurseIntoAttrs (pkgs.linuxPackagesFor {
  kernel = pkgs.linux_5-2;
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

# A function to build a manually-configured kernel
linuxManualConfig = pkgs.buildLinux;
buildLinux = callPackage ../pkgs/l/linux/manual-config.nix {};

# FIXME:
kmod-blacklist-ubuntu =
  callPackage ../pkgs/k/kmod-blacklist-ubuntu { };

# FIXME:
kmod-debian-aliases =
  callPackage ../pkgs/k/kmod-debian-aliases { };

# FIXME:
aggregateModules = modules:
  callPackage ../pkgs/k/kmod/aggregator.nix {
    inherit modules;
  };

linux-firmware = callPackage ../pkgs/l/linux-firmware { };

linux-headers_4-19 = callPackage ../pkgs/l/linux-headers {
  channel = "4.19";
};
linux-headers_5-4 = callPackage ../pkgs/l/linux-headers {
  channel = "5.4";
};
# Minimum version for external distros
linux-headers = callPackageAlias "linux-headers_4-19" { };
# Minimum version for triton
linux-headers_triton = callPackageAlias "linux-headers_5-4" { };

lirc = callPackage ../pkgs/l/lirc { };

live555 = callPackage ../pkgs/l/live555 { };

lld_9 = callPackage ../pkgs/l/lld {
  llvm = pkgs.llvm_9;
};
lld = callPackageAlias "lld_9" { };

llvm_9 = callPackage ../pkgs/l/llvm {
  channel = "9";
};
llvm = callPackageAlias "llvm_9" { };

lm-sensors = callPackage ../pkgs/l/lm-sensors { };

lmdb = callPackage ../pkgs/l/lmdb { };

log4cplus = callPackage ../pkgs/l/log4cplus { };

lrdf = callPackage ../pkgs/l/lrdf { };

lsof = callPackage ../pkgs/l/lsof { };

ltrace = callPackage ../pkgs/l/ltrace { };

luajit = callPackage ../pkgs/l/luajit { };

lua_5-2 = callPackage ../pkgs/l/lua {
  channel = "5.2";
};
lua_5-3 = callPackage ../pkgs/l/lua {
  channel = "5.3";
};
lua = callPackageAlias "lua_5-3" { };

lv2 = callPackage ../pkgs/l/lv2 { };

lvm2 = callPackage ../pkgs/l/lvm2 { };

lxc = callPackage ../pkgs/l/lxc { };

lz4 = callPackage ../pkgs/l/lz4 { };

lzip = callPackage ../pkgs/l/lzip { };

lzo = callPackage ../pkgs/l/lzo { };

mac = callPackage ../pkgs/m/mac { };

man = callPackage ../pkgs/m/man { };

man-db = callPackage ../pkgs/m/man-db { };

man-pages = callPackage ../pkgs/m/ean-pages { };

mariadb = callPackage ../pkgs/m/mariadb { };
mysql = callPackageAlias "mariadb" { };
mysql_lib = callPackageAlias "mysql" { };

mariadb-connector-c = callPackage ../pkgs/m/mariadb-connector-c { };

mc = pkgs.goPackages.mc;

mcelog = callPackage ../pkgs/m/mcelog { };

mcpp = callPackage ../pkgs/m/mcpp { };

mdadm = callPackage ../pkgs/m/mdadm { };

mediainfo = callPackage ../pkgs/m/mediainfo { };

memtest86plus = callPackage ../pkgs/m/memtest86plus { };

mercurial = pkgs.python2Packages.mercurial;

mesa = callPackage ../pkgs/m/mesa { };
mesa_drivers = pkgs.mesa.dri_drivers;

mesa-demos = callPackage ../pkgs/m/mesa-demos { };

mesa-headers = callPackage ../pkgs/m/mesa-headers { };

meson = pkgs.python3Packages.meson.dev;

meson_bootstrap = callPackage ../pkgs/m/meson/bootstrap.nix {
  python = pkgs.python_tiny;
};

#mesos = callPackage ../pkgs/m/mesos {
#  inherit (pythonPackages) python boto setuptools wrapPython;
#  pythonProtobuf = pythonPackages.protobuf2_5;
#  perf = linuxPackages.perf;
#};

mft = callPackage ../pkgs/m/mft {
  kernel = null;
};

mfx-dispatcher = callPackage ../pkgs/m/mfx-dispatcher { };

mg = callPackage ../pkgs/m/mg { };

mime-types = callPackage ../pkgs/m/mime-types { };

minicom = callPackage ../pkgs/m/minicom { };

minidlna = callPackage ../pkgs/m/minidlna { };

minio = pkgs.goPackages.minio;

minipro = callPackage ../pkgs/m/minipro { };

minisign = callPackage ../pkgs/m/minisign { };

miniupnpc = callPackage ../pkgs/m/miniupnpc { };

mixxx = callPackage ../pkgs/m/mixxx { };

mkvtoolnix = callPackage ../pkgs/m/mkvtoolnix { };

mm-common = callPackage ../pkgs/m/mm-common { };

mobile_broadband_provider_info =
  callPackage ../pkgs/m/mobile-broadband-provider-info { };

modemmanager = callPackage ../pkgs/m/modemmanager { };

mongo-c-driver = callPackage ../pkgs/m/mongo-c-driver { };

mongodb = callPackage ../pkgs/m/mongodb { };

mono = callPackage ../pkgs/m/mono { };

moolticute = callPackage ../pkgs/m/moolticute { };

mosh = callPackage ../pkgs/m/mosh { };

#motif = callPackage ../pkgs/m/motif { };

mp3val = callPackage ../pkgs/m/mp3val { };

mp4v2 = callPackage ../pkgs/m/mp4v2 { };

mpd = callPackage ../pkgs/m/mpd {
  audiofile = null;
  avahi = null;
  bzip2 = null;
  chromaprint = null;
  expat = null;
  fluidsynth = null;
  game-music-emu = null;
  jack2_lib = null;
  libao = null;
  libgcrypt = null;
  libmikmod = null;
  libmms = null;
  libmodplug = null;
  libnfs = null;
  libshout = null;
  libsndfile = null;
  libupnp = null;
  musepack = null;
  openal = null;
  pcre = null;
  samba_client = null;
  udisks = null;
  yajl = null;
  zziplib = null;
};

mpfr = callPackage ../pkgs/m/mpfr { };

mpg123 = callPackage ../pkgs/m/mpg123 { };

mpv_generics = overrides: callPackage ../pkgs/m/mpv ({
  jack2_lib = null;
  lcms2 = null;
  libarchive = null;
  libbluray = null;
  libbs2b = null;
  libcaca = null;
  libdrm = null;
  mujs = null;
  nvidia-cuda-toolkit = null;
  nvidia-drivers = null;
  openal = null;
  rubberband = null;
  samba_client = null;
  sdl = null;
} // overrides);
mpv_0-29 = pkgs.mpv_generics {
  channel = "0.29";
};
mpv_head = pkgs.mpv_generics {
  channel = "999";
  ffmpeg = pkgs.ffmpeg_head;  # Requires newer than latest release
};
mpv = callPackageAlias "mpv_0-29" { };

ms-sys = callPackage ../pkgs/m/ms-sys { };

msgpack-c = callPackage ../pkgs/m/msgpack-c { };

mtdev = callPackage ../pkgs/m/mtdev { };

mtd-utils = callPackage ../pkgs/m/mtd-utils { };

mtools = callPackage ../pkgs/m/mtools { };

mtr = callPackage ../pkgs/m/mtr { };

mumble_generics = overrides: callPackage ../pkgs/m/mumble ({
  portaudio = null;
  pulseaudio_lib = null;
  speech-dispatcher = null;
} // overrides);
mumble_git = pkgs.mumble_generics {
  channel = "git";
  config = "mumble";
};
mumble = callPackageAlias "mumble_git" { };

mupdf = callPackage ../pkgs/m/mupdf { };

murmur_git = pkgs.mumble_generics {
  channel = "git";
  config = "murmur";
};
murmur = callPackageAlias "murmur_git" { };

musepack = callPackage ../pkgs/m/musepack { };

musl_lib = null;

musl_lib_gcc = callPackage ../pkgs/m/musl {
  cc = pkgs.cc_gcc_musl_nolibc;
};

musl_headers = callPackage ../pkgs/m/musl/headers.nix { };

mutter_3-26 = callPackage ../pkgs/m/mutter {
  channel = "3.26";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gnome-desktop = pkgs.gnome-desktop_3-31;
  gnome-settings-daemon = pkgs.gnome-settings-daemon_3-26;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
mutter = callPackageAlias "mutter_3-26" { };

mxml = callPackage ../pkgs/m/mxml { };

mypaint-brushes = callPackage ../pkgs/m/mypaint-brushes { };

nano = callPackage ../pkgs/n/nano { };

nasm = callPackage ../pkgs/n/nasm { };

nautilus_unwrapped_3-26 = callPackage ../pkgs/n/nautilus/unwrapped.nix {
  channel = "3.26";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gnome-desktop = pkgs.gnome-desktop_3-31;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
  tracker = pkgs.tracker_2-0;
};
nautilus_3-26 = callPackage ../pkgs/n/nautilus {
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
nautilus_unwrapped = callPackageAlias "nautilus_unwrapped_3-26" { };
nautilus = callPackageAlias "nautilus_3-26" { };

nbd = callPackage ../pkgs/n/nbd { };

ncdc = callPackage ../pkgs/n/ncdc { };

ncdu = callPackage ../pkgs/n/ncdu { };

ncmpc = callPackage ../pkgs/n/ncmpc { };

ncmpcpp = callPackage ../pkgs/n/ncmpcpp { };

ncurses = callPackage ../pkgs/g/gpm-ncurses { };

ndctl = callPackage ../pkgs/n/ndctl { };

ndisc6 = callPackage ../pkgs/n/ndisc6 { };

neon = callPackage ../pkgs/n/neon {
  compressionSupport = true;
  sslSupport = true;
};

netperf = callPackage ../pkgs/n/netperf { };

net-snmp = callPackage ../pkgs/n/net-snmp { };

net-tools = callPackage ../pkgs/n/net-tools { };

netcat = callPackage ../pkgs/n/netcat { };

nettle = callPackage ../pkgs/n/nettle { };

networkmanager_1-10 = callPackage ../pkgs/n/networkmanager {
  channel = "1.10";
};
networkmanager = callPackageAlias "networkmanager_1-10" { };

networkmanager-applet_1-8 = callPackage ../pkgs/n/networkmanager-applet {
  channel = "1.8";
  networkmanager = pkgs.networkmanager_1-10;
};
networkmanager-applet = callPackageAlias "networkmanager-applet_1-8" { };

networkmanager-l2tp = callPackage ../pkgs/n/networkmanager-l2tp { };

networkmanager-openconnect_1-2 =
  callPackage ../pkgs/n/networkmanager-openconnect {
    channel = "1.2";
  };
networkmanager-openconnect =
  callPackageAlias "networkmanager-openconnect_1-2" { };

networkmanager-openvpn_1-8 = callPackage ../pkgs/n/networkmanager-openvpn {
  channel = "1.8";
};
networkmanager-openvpn = callPackageAlias "networkmanager-openvpn_1-8" { };

networkmanager-pptp_1-2 = callPackage ../pkgs/n/networkmanager-pptp {
  channel = "1.2";
};
networkmanager-pptp = callPackageAlias "networkmanager-pptp_1-2" { };

networkmanager-vpnc_1-2 = callPackage ../pkgs/n/networkmanager-vpnc {
  channel = "1.2";
};
networkmanager-vpnc = callPackageAlias "networkmanager-vpnc_1-2" { };

newt = callPackage ../pkgs/n/newt { };

nfacct = callPackage ../pkgs/n/nfacct { };

nfs-utils = callPackage ../pkgs/n/nfs-utils { };

nftables = callPackage ../pkgs/n/nftables { };

ngtcp2 = callPackage ../pkgs/n/ngtcp2 { };

nghttp2_full = callPackage ../pkgs/n/nghttp2 { };
nghttp2_lib = callPackage ../pkgs/n/nghttp2 {
  prefix = "lib";
};

nginx_stable = callPackage ../pkgs/n/nginx {
  channel = "stable";
};
nginx_unstable = callPackage ../pkgs/n/nginx {
  channel = "unstable";
};
nginx = callPackageAlias "nginx_stable" { };

ninja = callPackage ../pkgs/n/ninja { };

nix = callPackage ../pkgs/n/nix { };

nixos-utils = callPackage ../pkgs/n/nixos-utils { };

nmap = callPackage ../pkgs/n/nmap { };

nodejs_6 = callPackage ../pkgs/n/nodejs {
  channel = "6";
};
nodejs_8 = callPackage ../pkgs/n/nodejs {
  channel = "8";
};
nodejs_10 = callPackage ../pkgs/n/nodejs {
  channel = "10";
};
nodejs_11 = callPackage ../pkgs/n/nodejs {
  channel = "11";
};
nodejs = callPackageAlias "nodejs_11" { };

noise = callPackage ../pkgs/n/noise { };

nomad = pkgs.goPackages.nomad;

notmuch = callPackage ../pkgs/n/notmuch { };

npapi_sdk = callPackage ../pkgs/n/npapi-sdk { };

npth = callPackage ../pkgs/n/npth { };

nspr = callPackage ../pkgs/n/nspr { };

nss = callPackage ../pkgs/n/nss { };

nss_wrapper = callPackage ../pkgs/n/nss_wrapper { };

ntfs-3g = callPackage ../pkgs/n/ntfs-3g { };

ntp = callPackage ../pkgs/n/ntp { };

numactl = callPackage ../pkgs/n/numactl { };

nv-codec-headers = callPackage ../pkgs/n/nv-codec-headers { };

nvidia-cuda-toolkit_8-0 = callPackage ../pkgs/n/nvidia-cuda-toolkit {
 channel = "8.0";
};
nvidia-cuda-toolkit = callPackageAlias "nvidia-cuda-toolkit_8-0" { };

nvidia-drivers_tesla = callPackage ../pkgs/n/nvidia-drivers {
  channel = "tesla";
  buildConfig = "userspace";
};
nvidia-drivers_long-lived = callPackage ../pkgs/n/nvidia-drivers {
  channel = "long-lived";
  buildConfig = "userspace";
};
nvidia-drivers_short-lived = callPackage ../pkgs/n/nvidia-drivers {
  channel = "short-lived";
  buildConfig = "userspace";
};
nvidia-drivers_beta = callPackage ../pkgs/n/nvidia-drivers {
  channel = "beta";
  buildConfig = "userspace";
};
nvidia-drivers_latest = callPackage ../pkgs/n/nvidia-drivers {
  channel = "latest";
  buildConfig = "userspace";
};
nvidia-drivers = callPackageAlias "nvidia-drivers_long-lived" { };

nvidia-installer = callPackage ../pkgs/n/nvidia-installer { };

nvidia-gpu-deployment-kit =
  callPackage ../pkgs/n/nvidia-gpu-deployment-kit { };

nvidia-settings = callPackage ../pkgs/n/nvidia-settings { };

nvidia-video-codec-sdk = callPackage ../pkgs/n/nvidia-video-codec-sdk { };

nvme-cli = callPackage ../pkgs/n/nvme-cli { };

oath-toolkit = callPackage ../pkgs/o/oath-toolkit { };

obexftp = callPackage ../pkgs/o/obexftp { };

oniguruma = callPackage ../pkgs/o/oniguruma { };

open-iscsi = callPackage ../pkgs/o/open-iscsi { };

open-isns = callPackage ../pkgs/o/open-isns { };

openal-soft = callPackage ../pkgs/o/openal-soft { };
openal = callPackageAlias "openal-soft" { };

openconnect_openssl = callPackage ../pkgs/o/openconnect {
  gnutls = null;
};
openconnect = callPackageAlias "openconnect_openssl" { };

opencv_2 = callPackage ../pkgs/o/opencv {
  channel = "2";
  gtk_3 = null;
};
opencv_3 = callPackage ../pkgs/o/opencv {
  channel = "3";
  gtk_2 = null;
};
opencv = callPackageAlias "opencv_3" { };

opendht = callPackage ../pkgs/o/opendht { };

openexr = callPackage ../pkgs/o/openexr { };

opengl-dummy = pkgs.buildEnv {
  name = "opengl-dummy";
  paths = [
    pkgs.egl-headers
    pkgs.libglvnd
    pkgs.libglvnd.dummypc
    pkgs.mesa-headers
    pkgs.opengl-headers
  ];
  passthru = {
    # This is the default search path for DRI drivers.
    driverSearchPath = "/run/opengl-drivers/${pkgs.stdenv.targetSystem}";

    egl = true;
    egl-streams = true;
    gbm = true;
    glesv1 = true;
    glesv2 = true;
    glesv3 = true;
    glx = true;
  };
};

opengl-headers = callPackage ../pkgs/o/opengl-headers { };

openh264 = callPackage ../pkgs/o/openh264 { };

openjdk8-bootstrap =
  callPackage ../pkgs/o/openjdk/bootstrap.nix {
    version = "8";
  };
openjdk8-make-bootstrap =
  callPackage ../pkgs/o/openjdk/make-bootstrap.nix {
    openjdk = pkgs.openjdk8.override { minimal = true; };
  };
openjdk8 = callPackage ../pkgs/o/openjdk/8.nix {
  bootjdk = pkgs.openjdk8-bootstrap;
};
openjdk8_jdk = pkgs.openjdk8 // { outputs = [ "out" ]; };
openjdk8_jre = pkgs.openjdk8.jre // { outputs = [ "jre" ]; };

openjdk = callPackageAlias "openjdk8" { };
java8 = callPackageAlias "openjdk8" { };
jdk8 = pkgs.java8 // { outputs = [ "out" ]; };
jre8 = pkgs.java8.jre // { outputs = [ "jre" ]; };
java = callPackageAlias "java8" { };
jdk = pkgs.java // { outputs = [ "out" ]; };
jre = pkgs.java.jre // { outputs = [ "jre" ]; };

openjpeg = callPackage ../pkgs/o/openjpeg { };

openldap = callPackage ../pkgs/o/openldap { };

openntpd = callPackage ../pkgs/o/openntpd { };

openobex = callPackage ../pkgs/o/openobex { };

openpace = callPackage ../pkgs/o/openpace { };

openresolv = callPackage ../pkgs/o/openresolv { };

opensc = callPackage ../pkgs/o/opensc { };

opensmtpd = callPackage ../pkgs/o/opensmtpd { };

opensmtpd-extras = callPackage ../pkgs/o/opensmtpd-extras { };

opensp = callPackage ../pkgs/o/opensp { };

openssh = callPackage ../pkgs/o/openssh { };

openssl_1-0-2 = callPackage ../pkgs/o/openssl {
  channel = "1.0.2";
};
openssl_1-1-1 = callPackage ../pkgs/o/openssl {
  channel = "1.1.1";
};
openssl = callPackageAlias "openssl_1-1-1" { };

openvpn = callPackage ../pkgs/o/openvpn { };

opus_stable = callPackage ../pkgs/o/opus {
  channel = "stable";
};
opus_head = callPackage ../pkgs/o/opus {
  channel = "head";
};
opus = callPackageAlias "opus_stable" { };

opus-tools = callPackage ../pkgs/o/opus-tools { };

opusfile = callPackage ../pkgs/o/opusfile { };

orbit2 = callPackage ../pkgs/o/orbit2 { };

orc = callPackage ../pkgs/o/orc { };

osquery = callPackage ../pkgs/o/osquery { };

p11-kit = callPackage ../pkgs/p/p11-kit { };

p7zip = callPackage ../pkgs/p/p7zip { };

pacemaker = callPackage ../pkgs/p/pacemaker { };

pam = callPackage ../pkgs/p/pam { };

pam_wrapper = callPackage ../pkgs/p/pam_wrapper { };

pango = callPackage ../pkgs/p/pango { };

pangomm_2-40 = callPackage ../pkgs/p/pangomm {
  channel = "2.40";
};
pangomm = callPackageAlias "pangomm_2-40" { };

pangox-compat = callPackage ../pkgs/p/pangox-compat { };

parallel = callPackage ../pkgs/p/parallel { };

parted = callPackage ../pkgs/p/parted { };

patchelf = callPackageAlias "patchelf_0-9" { };
patchelf_0-9 = callPackage ../pkgs/p/patchelf/0.9.nix { };
patchelf_0-10 = callPackage ../pkgs/p/patchelf/0.10.nix { };

patchutils = callPackage ../pkgs/p/patchutils { };

pavucontrol = callPackage ../pkgs/p/pavucontrol { };

pciutils = callPackage ../pkgs/p/pciutils { };

pcre = callPackage ../pkgs/p/pcre { };

pcre2_full = callPackage ../pkgs/p/pcre2 { };

pcre2_lib = callPackage ../pkgs/p/pcre2/lib.nix { };

pcsc-lite_full = callPackage ../pkgs/p/pcsc-lite {
  libOnly = false;
};
pcsc-lite_lib = callPackageAlias "pcsc-lite_full" {
  libOnly = true;
};

peg = callPackage ../pkgs/p/peg { };

perl = callPackage ../pkgs/p/perl { };
perlPackages = recurseIntoAttrs (callPackage ./perl-packages.nix {
  overrides = (config.perlPackageOverrides or (p: {})) pkgs;
});

pf-ring = callPackage ../pkgs/p/pf-ring { };

pgbouncer = callPackage ../pkgs/p/pgbouncer { };

php_7-1 = callPackages ../pkgs/p/php { };
php = pkgs.php_7-1;

picocom = callPackage ../pkgs/p/picocom { };

pinentry_gtk = callPackageAlias "pinentry" {
  enableGtk = true;
};
pinentry_qt = callPackageAlias "pinentry" {
  enableQt = true;
};
pinentry = callPackage ../pkgs/p/pinentry { };

pipewire = callPackage ../pkgs/p/pipewire { };

pkcs11-helper = callPackage ../pkgs/p/pkcs11-helper { };

pkgconf-wrapper = callPackage ../pkgs/p/pkgconf-wrapper { };

pkg-config_unwrapped = callPackage ../pkgs/p/pkg-config { };
pkg-config = callPackage (a: pkgs.pkgconf-wrapper a) {
  pkg-config = pkgs.pkg-config_unwrapped;
};

pkgconf_unwrapped = callPackage ../pkgs/p/pkgconf { };
pkgconf = callPackage (a: pkgs.pkgconf-wrapper a) {
  pkg-config = pkgs.pkgconf_unwrapped;
};

pkgconfig = callPackageAlias "pkgconf" { };

plex-media-server = callPackage ../pkgs/p/plex-media-server { };

plymouth = callPackage ../pkgs/p/plymouth { };

pngcrush = callPackage ../pkgs/p/pngcrush { };

po4a = callPackage ../pkgs/p/po4a { };

polkit = callPackage ../pkgs/p/polkit { };

poppler_qt = callPackageAlias "poppler" {
  suffix = "qt5";
  qt5 = pkgs.qt5;
};
poppler_utils = callPackageAlias "poppler" {
  suffix = "utils";
  utils = true;
};
poppler = callPackage ../pkgs/p/poppler {
  qt5 = null;
};

poppler-data = callPackage ../pkgs/p/poppler-data { };

popt = callPackage ../pkgs/p/popt { };

portaudio = callPackage ../pkgs/p/portaudio { };

portmidi = callPackage ../pkgs/p/portmidi { };

postgresql_11 = callPackage ../pkgs/p/postgresql {
  channel = "11";
};
postgresql_10 = callPackage ../pkgs/p/postgresql {
  channel = "10";
};
postgresql_9-6 = callPackage ../pkgs/p/postgresql {
  channel = "9.6";
};
postgresql = callPackageAlias "postgresql_11" { };

potrace = callPackage ../pkgs/p/potrace { };

powertop = callPackage ../pkgs/p/powertop { };

ppp = callPackage ../pkgs/p/ppp { };

pptp = callPackage ../pkgs/p/pptp { };

processor-trace = callPackage ../pkgs/p/processor-trace { };

procps = callPackageAlias "procps-ng" { };

procps-ng = callPackage ../pkgs/p/procps-ng { };

progress = callPackage ../pkgs/p/progress { };

protobuf-c = callPackage ../pkgs/p/protobuf-c { };

protobuf-cpp = callPackage ../pkgs/p/protobuf-cpp { };

psmisc = callPackage ../pkgs/p/psmisc { };

pth = callPackage ../pkgs/p/pth { };

pugixml = callPackage ../pkgs/p/pugixml { };

pulseaudio_full = callPackage ../pkgs/p/pulseaudio { };
pulseaudio_lib = callPackageAlias "pulseaudio_full" {
  prefix = "lib";
};

python27 = callPackage ../pkgs/p/python {
  channel = "2.7";
  self = callPackageAlias "python27" { };
};
python37 = callPackage ../pkgs/p/python {
  channel = "3.7";
  self = callPackageAlias "python37" { };
};
python38 = hiPrio (callPackage ../pkgs/p/python {
  channel = "3.8";
  self = callPackageAlias "python38" { };
});
python2 = callPackageAlias "python27" { };
python3 = callPackageAlias "python38" { };
python = callPackageAlias "python2" { };

# Intended only for very early stage builds
# Don't use this package without a good reason
python_tiny = callPackage ../pkgs/p/python/tiny.nix {
  python = null;
};

python27Packages = hiPrioSet (
  recurseIntoAttrs (callPackage ../sets/python-packages.nix {
    python = callPackageAlias "python27" { };
    self = callPackageAlias "python27Packages" { };
  })
);
python37Packages =
  recurseIntoAttrs (callPackage ../sets/python-packages.nix {
    python = callPackageAlias "python37" { };
    self = callPackageAlias "python37Packages" { };
  });
python38Packages =
  recurseIntoAttrs (callPackage ../sets/python-packages.nix {
    python = callPackageAlias "python38" { };
    self = callPackageAlias "python38Packages" { };
  });
#pypyPackages =
#  recurseIntoAttrs (callPackage ../sets/python-packages.nix {
#    python = callPackageAlias "pypy" { };
#    self = callPackageAlias "pypyPackages" { };
#  });
python2Packages = callPackageAlias "python27Packages" { };
python3Packages = callPackageAlias "python38Packages" { };
pythonPackages = callPackageAlias "python2Packages" { };

qbittorrent = callPackage ../pkgs/q/qbittorrent { };
qbittorrent_head = callPackage ../pkgs/q/qbittorrent {
  channel = "head";
  libtorrent-rasterbar = pkgs.libtorrent-rasterbar_1-1_head;
};
qbittorrent_nox = callPackage ../pkgs/q/qbittorrent { };
qbittorrent_nox_head = callPackage ../pkgs/q/qbittorrent {
  channel = "head";
  guiSupport = false;
  libtorrent-rasterbar = pkgs.libtorrent-rasterbar_1-1_head;
};

qca = callPackage ../pkgs/q/qca { };

qemu = callPackage ../pkgs/q/qemu { };

qjackctl = callPackage ../pkgs/q/qjackctl { };

qpdf = callPackage ../pkgs/q/qpdf { };

qrencode = callPackage ../pkgs/q/qrencode { };

qt5 = callPackage ../pkgs/q/qt { };

quassel = callPackage ../pkgs/q/quassel rec {
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

quazip = callPackage ../pkgs/q/quazip { };

radvd = callPackage ../pkgs/r/radvd { };

ragel_6 = callPackage ../pkgs/r/ragel/6.nix { };
ragel_7 = callPackage ../pkgs/r/ragel/7.nix { };
ragel = callPackageAlias "ragel_6" { };

rapidjson = callPackage ../pkgs/r/rapidjson { };

raptor2 = callPackage ../pkgs/r/raptor2 { };

rclone = pkgs.goPackages.rclone;

rdma-core = callPackage ../pkgs/r/rdma-core { };

re2c = callPackage ../pkgs/r/re2c { };

readline = callPackage ../pkgs/r/readline { };

recode = callPackage ../pkgs/r/recode { };

redis = callPackage ../pkgs/r/redis { };

resilio = callPackage ../pkgs/r/resilio { };

resolv_wrapper = callPackage ../pkgs/r/resolv_wrapper { };

rest = callPackage ../pkgs/r/rest { };

restbed = callPackage ../pkgs/r/restbed { };

rfkill = callPackage ../pkgs/r/rfkill { };

rhash = callPackage ../pkgs/r/rhash { };

rnnoise = callPackage ../pkgs/r/rnnoise { };

ripgrep = pkgs.rustPackages.ripgrep;

riot = callPackage ../pkgs/r/riot { };

rocksdb = callPackage ../pkgs/r/rocksdb { };

root-nameservers = callPackage ../pkgs/r/root-nameservers { };

rpcsvc-proto = callPackage ../pkgs/r/rpcsvc-proto { };

rpm = callPackage ../pkgs/r/rpm { };

rrdtool = callPackage ../pkgs/r/rrdtool { };

rsync = callPackage ../pkgs/r/rsync { };

rtkit = callPackage ../pkgs/r/rtkit { };

rtmpdump = callPackage ../pkgs/r/rtmpdump { };

rtorrent = callPackage ../pkgs/r/rtorrent { };

rubberband = callPackage ../pkgs/r/rubberband { };

ruby = callPackage ../pkgs/r/ruby { };

rustPackages = callPackage ./rust-packages.nix {
  channel = "stable";
};

rustPackages_beta = callPackageAlias "rustPackages" {
  channel = "beta";
};

rustPackages_nightly = callPackageAlias "rustPackages" {
  channel = "nightly";
};

sakura = callPackage ../pkgs/s/sakura { };

samba_full = callPackage ../pkgs/s/samba { };
samba_client = callPackageAlias "samba_full" {
  type = "client";
};

sanlock = callPackage ../pkgs/s/sanlock { };

sas2flash = callPackage ../pkgs/s/sas2flash { };

sassc = callPackage ../pkgs/s/sassc { };

sbc = callPackage ../pkgs/s/sbc { };

scdoc = callPackage ../pkgs/s/scdoc { };

schroedinger = callPackage ../pkgs/s/schroedinger { };

scons = pkgs.python2Packages.scons;

screen = callPackage ../pkgs/s/screen { };

scrot = callPackage ../pkgs/s/scrot { };

sddm = callPackage ../pkgs/s/sddm { };

sdl_2 = callPackage ../pkgs/s/sdl { };
sdl = callPackageAlias "sdl_2" { };

sdl-image = callPackage ../pkgs/s/sdl-image { };
SDL_2_image = callPackageAlias "sdl-image" { };

sdparm = callPackage ../pkgs/s/sdparm { };

seabios_qemu = callPackage ../pkgs/s/seabios {
  type = "qemu";
};

seahorse = callPackage ../pkgs/s/seahorse { };

serd = callPackage ../pkgs/s/serd { };

serf = callPackage ../pkgs/s/serf { };

sg3-utils = callPackage ../pkgs/s/sg3-utils { };

shadow = callPackage ../pkgs/s/shadow { };

shared-mime-info = callPackage ../pkgs/s/shared-mime-info { };

sharutils = callPackage ../pkgs/s/sharutils { };

shntool = callPackage ../pkgs/s/shntool { };

signify = callPackage ../pkgs/s/signify { };

sl = callPackage ../pkgs/s/sl { };

slang = callPackage ../pkgs/s/slang { };

sleuthkit = callPackage ../pkgs/s/sleuthkit { };

slock = callPackage ../pkgs/s/slock { };

smartmontools = callPackage ../pkgs/s/smartmontools { };

snappy = callPackage ../pkgs/s/snappy { };

socat = callPackage ../pkgs/s/socat { };

socket_wrapper = callPackage ../pkgs/s/socket_wrapper { };

sord = callPackage ../pkgs/s/sord { };

sound-theme-freedesktop =
  callPackage ../pkgs/s/sound-theme-freedesktop { };

soundtouch = callPackage ../pkgs/s/soundtouch {};

sox = callPackage ../pkgs/s/sox {
  amrnb = null;
  amrwb = null;
};

soxr = callPackage ../pkgs/s/soxr { };

spandsp = callPackage ../pkgs/s/spandsp {};

spectrwm = callPackage ../pkgs/s/spectrwm { };

speech-dispatcher = callPackage ../pkgs/s/speech-dispatcher { };

speex = callPackage ../pkgs/s/speex { };

speexdsp = callPackage ../pkgs/s/speexdsp { };

spice = callPackage ../pkgs/s/spice { };

spice-protocol = callPackage ../pkgs/s/spice-protocol { };

spidermonkey_45 = callPackage ../pkgs/s/spidermonkey {
  channel = "45";
};
spidermonkey_52 = callPackage ../pkgs/s/spidermonkey {
  channel = "52";
};
spidermonkey = callPackageAlias "spidermonkey_52" { };

split2flac = callPackage ../pkgs/s/split2flac { };

sqlite = callPackage ../pkgs/s/sqlite { };

squashfs-tools = callPackage ../pkgs/s/squashfs-tools { };

sratom = callPackage ../pkgs/s/sratom { };

sshfs = callPackage ../pkgs/s/sshfs { };

sslh = callPackage ../pkgs/s/sslh { };

sssd = callPackage ../pkgs/s/sssd { };

st = callPackage ../pkgs/s/st {
  config = config.st.config or null;
  configFile = config.st.configFile or null;
};

stalonetray = callPackage ../pkgs/s/stalonetray { };

# FIXME: rename w/o lib
libstartup_notification = callPackage ../pkgs/s/startup-notification { };

#steamPackages = callPackage ../pkgs/s/steam { };
#steam = steamPackages.steam-chrootenv.override {
#  # DEPRECATED
#  withJava = config.steam.java or false;
#  withPrimus = config.steam.primus or false;
#};

strace = callPackage ../pkgs/s/strace { };

stress-ng = callPackage ../pkgs/s/stress-ng { };

strongswan = callPackage ../pkgs/s/strongswan { };

sublime-text = callPackage ../pkgs/s/sublime-text { };

subversion = callPackage ../pkgs/s/subversion { };

subunit = callPackage ../pkgs/s/subunit { };
subunit_lib = callPackageAlias "subunit" {
  type = "lib";
};

sudo = callPackage ../pkgs/s/sudo { };

suil = callPackage ../pkgs/s/suil { };

#sushi_3-24 = callPackage ../pkgs/s/sushi {
#  channel = "3.24";
#  atk = pkgs.atk_2-30;
#  gjs = pkgs.gjs_1-46;
#  gtksourceview = pkgs.gtksourceview_3-24;
#};
#sushi = callPackageAlias "sushi_3-24" { };

svrcore = callPackage ../pkgs/s/svrcore { };

sway = callPackage ../pkgs/s/sway { };

swig_2 = callPackage ../pkgs/s/swig {
  channel = "2";
};
swig_3 = callPackage ../pkgs/s/swig {
  channel = "3";
};
swig_4 = callPackage ../pkgs/s/swig {
  channel = "4";
};
swig = callPackageAlias "swig_4" { };

sxiv = callPackage ../pkgs/s/sxiv { };

sydent = pkgs.python2Packages.sydent;

synapse = pkgs.python2Packages.synapse;

syncthing = pkgs.goPackages.syncthing;

synergy = callPackage ../pkgs/s/synergy { };

sysfsutils = callPackage ../pkgs/s/sysfsutils { };

syslinux = callPackage ../pkgs/s/syslinux { };

sysstat = callPackage ../pkgs/s/sysstat { };

# TODO: Rename back to systemd once depedencies are sorted
systemd_full = callPackage ../pkgs/s/systemd { };
systemd_lib = callPackageAlias "systemd_full" {
  type = "lib";
};
systemd_dist = callPackage ../pkgs/s/systemd/dist.nix { };
systemd-cryptsetup-generator =
  callPackage ../pkgs/s/systemd/cryptsetup-generator.nix { };

systemd-dummy = callPackage ../pkgs/s/systemd-dummy { };

t1lib = callPackage ../pkgs/t/t1lib { };

taglib = callPackage ../pkgs/t/taglib { };

tahoe-lafs = pkgs.python2Packages.tahoe-lafs;

talloc = callPackage ../pkgs/t/talloc { };

task-spooler = callPackage ../pkgs/t/task-spooler { };

tcl_8-5 = callPackage ../pkgs/t/tcl {
  channel = "8.5";
};
tcl_8-6 = callPackage ../pkgs/t/tcl {
  channel = "8.6";
};
tcl = callPackageAlias "tcl_8-6" { };

tcpdump = callPackage ../pkgs/t/tcpdump { };

tcp-wrappers = callPackage ../pkgs/t/tcp-wrappers { };

tdb = callPackage ../pkgs/t/tdb { };

teamspeak_client = callPackage ../pkgs/t/teamspeak/client.nix { };
teamspeak_server = callPackage ../pkgs/t/teamspeak/server.nix { };

telepathy_glib = callPackage ../pkgs/t/telepathy-glib { };

telepathy_logger = callPackage ../pkgs/t/telepathy-logger {};

telepathy_mission_control =
  callPackage ../pkgs/t/telepathy-mission-control { };

teleport = pkgs.goPackages.teleport;

tesseract = callPackage ../pkgs/t/tesseract { };

tevent = callPackage ../pkgs/t/tevent { };

texinfo = callPackage ../pkgs/t/texinfo { };

textencode = callPackage ../pkgs/t/textencode { };

textencode_dist = callPackage ../pkgs/t/textencode/dist.nix { };

thermal_daemon = callPackage ../pkgs/t/thermal_daemon { };

thin-provisioning-tools = callPackage ../pkgs/t/thin-provisioning-tools { };

thrift = callPackage ../pkgs/t/thrift { };

time = callPackage ../pkgs/t/time { };

tinc_1-0 = callPackage ../pkgs/t/tinc { channel = "1.0"; };
tinc_1-1 = callPackage ../pkgs/t/tinc { channel = "1.1"; };

tk_8-5 = callPackage ../pkgs/t/tk {
  channel = "8.5";
};
tk_8-6 = callPackage ../pkgs/t/tk {
  channel = "8.6";
};
tk = callPackageAlias "tk_8-6" { };

tmux = callPackage ../pkgs/t/tmux { };

tor = callPackage ../pkgs/t/tor { };

totem_3-26 = callPackage ../pkgs/t/totem {
  channel = "3.26";
  nautilus = pkgs.nautilus_unwrapped_3-26;
};
totem = callPackageAlias "totem_3-26" { };

totem-pl-parser_3-26 = callPackage ../pkgs/t/totem-pl-parser {
  channel = "3.26";
};
totem-pl-parser = callPackageAlias "totem-pl-parser_3-26" { };

tracker_2-0 = callPackage ../pkgs/t/tracker {
  channel = "2.0";
  #evolution
  evolution-data-server = pkgs.evolution-data-server_3-28;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
  gnome-themes-standard = pkgs.gnome-themes-standard_3-22;
  gsettings-desktop-schemas = pkgs.gsettings-desktop-schemas_3-28;
};
tracker = callPackageAlias "tracker_2-0" { };

transmission_generic = overrides: callPackage ../pkgs/t/transmission ({
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

transmission-remote-gtk = callPackage ../pkgs/t/transmission-remote-gtk { };

tre = callPackage ../pkgs/t/tre { };

trousers = callPackage ../pkgs/t/trousers { };

tslib = callPackage ../pkgs/t/tslib { };

tzdata = callPackage ../pkgs/t/tzdata { };

# TODO(dezgeg): either refactor & use ubootTools directly, or remove completely
ubootChooser = name: ubootTools;

# Upstream U-Boots:
ubootTools = callPackage ../pkgs/u/uboot {
  toolsOnly = true;
  targetPlatforms = lib.platforms.linux;
  filesToInstall = ["tools/dumpimage" "tools/mkenvimage" "tools/mkimage"];
};

udisks = callPackage ../pkgs/u/udisks { };

uefi-shell = callPackage ../pkgs/u/uefi-shell { };

ufraw = callPackage ../pkgs/u/ufraw { };

uhub = callPackage ../pkgs/u/uhub { };

uid_wrapper = callPackage ../pkgs/u/uid_wrapper { };

umurmur = callPackage ../pkgs/u/umurmur { };

unbound = callPackage ../pkgs/u/unbound { };

unicode-character-database =
  callPackage ../pkgs/u/unicode-character-database { };

unifi = callPackage ../pkgs/u/unifi { };

unixODBC = callPackage ../pkgs/u/unixODBC { };

unrar = callPackage ../pkgs/u/unrar { };

unzip = callPackage ../pkgs/u/unzip { };

upower = callPackage ../pkgs/u/upower { };

usbmuxd = callPackage ../pkgs/u/usbmuxd { };

usbredir = callPackage ../pkgs/u/usbredir { };

usbutils = callPackage ../pkgs/u/usbutils { };

utf8proc = callPackage ../pkgs/u/utf8proc { };

uthash = callPackage ../pkgs/u/uthash { };

util-linux_full = callPackage ../pkgs/u/util-linux { };
util-linux_lib = callPackageAlias "util-linux_full" {
  type = "lib";
};

util-macros = callPackage ../pkgs/u/util-macros { };

v4l-utils = callPackage ../pkgs/v/v4l-utils {
  channel = "utils";
};
v4l_lib = callPackageAlias "v4l-utils" {
  channel = "lib";
};

vala = callPackage ../pkgs/v/vala { };

valgrind = callPackage ../pkgs/v/valgrind { };

vamp-plugin-sdk = callPackage ../pkgs/v/vamp-plugin-sdk { };

vault = pkgs.goPackages.vault;

vcdimager = callPackage ../pkgs/v/vcdimager { };

vde2 = callPackage ../pkgs/v/vde2 { };

vid-stab = callPackage ../pkgs/v/vid-stab { };

vim = callPackage ../pkgs/v/vim { };

vino_3-22 = callPackage ../pkgs/v/vino {
  channel = "3.22";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  libsoup = pkgs.libsoup_2-64;
};
vino = callPackageAlias "vino_3-22" { };

virglrenderer = callPackage ../pkgs/v/virglrenderer { };

#vlc = callPackage ../pkgs/v/vlc { };

vobsub2srt = callPackage ../pkgs/v/vobsub2srt { };

volume_key = callPackage ../pkgs/v/volume_key { };

vorbis-tools = callPackage ../pkgs/v/vorbis-tools { };

vpnc = callPackage ../pkgs/v/vpnc { };

vte_0-50 = callPackage ../pkgs/v/vte {
  channel = "0.50";
  atk = pkgs.atk_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
vte = callPackageAlias "vte_0-50" { };

vulkan-headers = callPackage ../pkgs/v/vulkan-headers { };

w3m = callPackage ../pkgs/w/w3m { };

waf = pkgs.python3Packages.waf.dev;

wavpack = callPackage ../pkgs/w/wavpack { };

wayland = callPackage ../pkgs/w/wayland { };

wayland-protocols = callPackage ../pkgs/w/wayland-protocols { };

webkitgtk = callPackage ../pkgs/w/webkitgtk { };

webrtc-audio-processing = callPackage ../pkgs/w/webrtc-audio-processing { };

wget = callPackage ../pkgs/w/wget { };

which = callPackage ../pkgs/w/which { };

wiredtiger = callPackage ../pkgs/w/wiredtiger { };

wireguard = callPackage ../pkgs/w/wireguard {
  kernel = null;
};

wireless-tools = callPackage ../pkgs/w/wireless-tools { };

wlroots = callPackage ../pkgs/w/wlroots { };

woeusb = callPackage ../pkgs/w/woeusb { };

wpa_supplicant = callPackage ../pkgs/w/wpa_supplicant { };

wxGTK = callPackage ../pkgs/w/wxGTK { };

x264 = callPackage ../pkgs/x/x264 { };

x265_stable = callPackage ../pkgs/x/x265 {
  channel = "stable";
};
x265_head = callPackage ../pkgs/x/x265 {
  channel = "head";
};
x265 = callPackageAlias "x265_stable" { };

xapian-core = callPackage ../pkgs/x/xapian-core { };

xavs = callPackage ../pkgs/x/xavs { };

xbitmaps = callPackage ../pkgs/x/xbitmaps { };

xdg-user-dirs = callPackage ../pkgs/x/xdg-user-dirs { };

xdg-utils = callPackage ../pkgs/x/xdg-utils { };

xf86-input-evdev = callPackage ../pkgs/x/xf86-input-evdev { };

xf86-input-mtrack = callPackage ../pkgs/x/xf86-input-mtrack { };

xf86-input-synaptics = callPackage ../pkgs/x/xf86-input-synaptics { };

xf86-input-wacom = callPackage ../pkgs/x/xf86-input-wacom { };

xf86-video-amdgpu = callPackage ../pkgs/x/xf86-video-amdgpu { };

xf86-video-intel = callPackage ../pkgs/x/xf86-video-intel { };

xfconf_4-12 = callPackage ../pkgs/x/xfconf {
  channel = "4.12";
};
xfconf = callPackageAlias "xfconf_4-12" { };

xfe = callPackage ../pkgs/x/xfe { };

xfs = callPackage ../pkgs/x/xfs { };

xfsprogs = callPackage ../pkgs/x/xfsprogs { };

xfsprogs_lib = pkgs.xfsprogs.lib;

xine-lib = callPackage ../pkgs/x/xine-lib { };

xine-ui = callPackage ../pkgs/x/xine-ui { };

xkbcomp = callPackage ../pkgs/x/xkbcomp { };

xkeyboard-config = callPackage ../pkgs/x/xkeyboard-config { };

xl2tpd = callPackage ../pkgs/x/xl2tpd { };

xlsclients = callPackage ../pkgs/x/xlsclients { };

xmlrpc_c = callPackage ../pkgs/x/xmlrpc-c { };

xmlto = callPackage ../pkgs/x/xmlto { };

xmltoman = callPackage ../pkgs/x/xmltoman { };

xorg = recurseIntoAttrs (
  lib.callPackagesWith pkgs ../pkgs/x/xorg/default.nix {
    inherit (pkgs)
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
      libpciaccess
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
      python3Packages
      spice-protocol
      stdenv
      systemd_lib
      tradcpp
      util-linux_lib
      xmlto
      zlib
      # Rewritten xorg packages
      fontcacheproto
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
      libxshmfence
      libxt
      libxtst
      libxv
      util-macros
      xf86-video-amdgpu
      xf86-video-intel
      xfs
      xkbcomp
      xkeyboard-config
      xorg-server
      xorgproto
      xrefresh
      xtrans
      xwininfo
      ;
  }
);

xorgproto = callPackage ../pkgs/x/xorgproto { };

xorg-server_1-20 = callPackage ../pkgs/x/xorg-server {
  channel = "1.20";
};
xorg-server = callPackageAlias "xorg-server_1-20" { };

xpdf = callPackage ../pkgs/x/xpdf {
  base14Fonts = "${ghostscript}/share/ghostscript/fonts";
};

xprop = callPackage ../pkgs/x/xprop { };

xrdb = callPackage ../pkgs/x/xrdb { };

xrefresh = callPackage ../pkgs/x/xrefresh { };

xsetroot = callPackage ../pkgs/x/xsetroot { };

xtrans = callPackage ../pkgs/x/xtrans { };

xvidcore = callPackage ../pkgs/x/xvidcore { };

xwininfo = callPackage ../pkgs/x/xwininfo { };

xz_5-2-4 = callPackage ../pkgs/x/xz {
  version = "5.2.4";
};
xz = callPackageAlias "xz_5-2-4" { };

yajl = callPackage ../pkgs/y/yajl { };

yaml-cpp = callPackage ../pkgs/y/yaml-cpp { };

yara = callPackage ../pkgs/y/yara { };

yasm = callPackage ../pkgs/y/yasm { };

yelp-tools = callPackage ../pkgs/y/yelp-tools { };

yelp-xsl_3-20 = callPackage ../pkgs/y/yelp-xsl {
  channel = "3.20";
};
yelp-xsl = callPackageAlias "yelp-xsl_3-20" { };

youtube-dl = pkgs.python3Packages.youtube-dl;

yubikey-manager = pkgs.python3Packages.yubikey-manager;

z3 = callPackage ../pkgs/z/z3 { };

zeitgeist = callPackage ../pkgs/z/zeitgeist { };

zenity_generics = overrides: callPackage ../pkgs/z/zenity ({
  webkitgtk = null;
} // overrides);
zenity_3-24 = pkgs.zenity_generics {
  channel = "3.24";
  adwaita-icon-theme = pkgs.adwaita-icon-theme_3-30;
  at-spi2-core = pkgs.at-spi2-core_2-30;
  gdk-pixbuf = pkgs.gdk-pixbuf_2-38;
};
zenity = callPackageAlias "zenity_3-24" { };

zeromq = callPackage ../pkgs/z/zeromq { };

zfs = callPackage ../pkgs/z/zfs {
  channel = "stable";
};
zfs_dev = callPackage ../pkgs/z/zfs {
  channel = "dev";
};

zimg = callPackage ../pkgs/z/zimg { };

zip = callPackage ../pkgs/z/zip { };

zita-convolver = callPackage ../pkgs/z/zita-convolver { };

zita-resampler = callPackage ../pkgs/z/zita-resampler { };

zlib = callPackage ../pkgs/z/zlib { };

zookeeper = callPackage ../pkgs/z/zookeeper { };

zookeeper_mt = callPackage ../pkgs/z/zookeeper_mt { };

zsh = callPackage ../pkgs/z/zsh { };

zstd_1-4-4 = callPackage ../pkgs/z/zstd {
  version = "1.4.4";
};
zstd = callPackageAlias "zstd_1-4-4" { };

zziplib = callPackage ../pkgs/z/zziplib { };

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
myEnvFun = callPackage ../misc/my-env { };
};  # END helperFunctions merge

in  # END let/in 1
self;
in  # END let/in 2
pkgs
