{ stdenv
, bison
, buildLinux
, fetchFromGitHub
, fetchurl
, flex
, git
, lib
, perl

, gmp
, mpfr
, libmpc

, # Overrides to the kernel config.
  extraConfig ? ""

, # A list of patches to apply to the kernel.  Each element of this list
  # should be an attribute set {name, patch} where `name' is a
  # symbolic name and `patch' is the actual patch.  The patch may
  # optionally be compressed with gzip or bzip2.
  kernelPatches ? []

, ignoreConfigErrors ? false
, extraMeta ? {}
, channel
, ...
}:

let

  sources = {
    "4.9" = {
      version = "4.9.121";
      baseSha256 = "029098dcffab74875e086ae970e3828456838da6e0ba22ce3f64ef764f3d7f1a";
      patchSha256 = "6719df0a05f0e668b0e2e06016bfb3a62eeb7242424c0674a249a0641ee4b903";
    };
    "4.14" = {
      version = "4.14.62";
      baseSha256 = "f81d59477e90a130857ce18dc02f4fbe5725854911db1e7ba770c7cd350f96a7";
      patchSha256 = "2595a071c6253fb579fa0401b3deb9a9d1ddb74dd1dcd1e668ed4d8726dc4b6c";
    };
    "4.17" = {
      version = "4.17.14";
      baseSha256 = "9faa1dd896eaea961dc6e886697c0b3301277102e5bc976b2758f9a62d3ccd13";
      patchSha256 = "bf4d95df98dc6197024bc2a7c8a8ef5fd3b21495298c7a7a5dbd63c159ea9f17";
    };
    "4.18" = {
      version = "4.18";
      baseSha256 = "19d8bcf49ef530cd4e364a45b4a22fa70714b70349c8100e7308488e26f1eaf1";
      patchSha256 = null;
    };
    "testing" = {
      version = "4.18-rc8";
      baseSha256 = "9faa1dd896eaea961dc6e886697c0b3301277102e5bc976b2758f9a62d3ccd13";
      patchUrls = [
        "https://github.com/wkennington/linux/releases/download/v${version}/patch-${version}.xz"
      ];
      patchSha256 = "752be8fe7cefc8eb8afbbfa18a387b85df9b43fe1422af360575c52de44a8769";
    };
    "bcachefs" =
      let
        date = "2018-08-13";
      in {
        version = "4.18";
        patchUrls = [
          "https://github.com/wkennington/linux/releases/download/bcachefs-${version}-${date}/patch-bcachefs-${version}-${date}.xz"
        ];
        baseSha256 = "19d8bcf49ef530cd4e364a45b4a22fa70714b70349c8100e7308488e26f1eaf1";
        patchSha256 = "957b228b93068e25ae12279fc12524c2c5b109f693eb767e3d19e1f39da508dc";
        features.bcachefs = true;
      };
  };

  source = sources."${channel}";

  inherit (source)
    version;

  inherit (import ./source.nix { inherit lib fetchurl fetchFromGitHub source; })
    src
    srcsVerification
    patch;

  inherit (builtins)
    substring;

  inherit (lib)
    addPassthru
    any
    concatStringsSep
    head
    length
    optionals
    splitString
    tail
    versionAtLeast
    versionOlder;

  needsGitPatch = source.needsGitPatch or false;

  modDirVersion = let
    rcSplit = splitString "-" version;
    vSplit = splitString "." (head rcSplit);
    vSplit' = if length vSplit == 2 then vSplit ++ [ "0" ] else vSplit;
    rcSplit' = [ (concatStringsSep "." vSplit') ] ++ tail rcSplit;
  in concatStringsSep "-" rcSplit';

  common = import ./common.nix { inherit stdenv; };

  kernelConfigFun = baseConfig:
    let
      configFromPatches =
        map ({extraConfig ? "", ...}: extraConfig) kernelPatches;
    in concatStringsSep "\n" ([baseConfig] ++ configFromPatches);

  configfile = stdenv.mkDerivation {
    inherit ignoreConfigErrors;
    name = "linux-config-${version}";

    generateConfig = ./generate-config.pl;

    kernelConfig = kernelConfigFun config;

    nativeBuildInputs = [ perl ]
      ++ optionals needsGitPatch [ git ]
      ++ optionals (versionAtLeast version "4.16") [ bison flex ];

    # Referenced by gcc internally for plugins
    buildInputs = optionals (versionAtLeast version "4.9") [ gmp mpfr libmpc ];

    platformName = "pc";
    kernelBaseConfig = "defconfig";
    kernelTarget = "bzImage";
    autoModules = true;
    arch = common.kernelArch;

    # We don't want these compiler security features / optimizations
    optFlags = false;
    pie = false;
    fpic = false;
    noStrictOverflow = false;
    fortifySource = false;
    stackProtector = false;
    optimize = false;

    postPatch = kernel.postPatch + ''
      # Patch kconfig to print "###" after every question so that
      # generate-config.pl from the generic builder can answer them.
      sed -e '/fflush(stdout);/i\printf("###");' -i scripts/kconfig/conf.c
    '';

    inherit (kernel) src patches preUnpack prePatch;

    buildPhase = ''
      cd $buildRoot

      # Get a basic config file for later refinement with $generateConfig.
      make -C ../$srcRoot O=$PWD $kernelBaseConfig ARCH=$arch

      # Create the config file.
      echo "generating kernel configuration..."
      echo "$kernelConfig" > kernel-config
      DEBUG=1 ARCH=$arch KERNEL_CONFIG=kernel-config AUTO_MODULES=$autoModules \
           SRC=../$srcRoot perl -w $generateConfig
    '';

    installPhase = "mv .config $out";
  };

  kernel = buildLinux {
    inherit version modDirVersion src needsGitPatch patch kernelPatches;

    configfile = configfile.nativeDrv or configfile;

    crossConfigfile = configfile.crossDrv or configfile;

    config = { CONFIG_MODULES = "y"; CONFIG_FW_LOADER = "m"; };

    crossConfig = { CONFIG_MODULES = "y"; CONFIG_FW_LOADER = "m"; };
  };

  passthru = rec {
    meta = kernel.meta // extraMeta;

    inherit channel srcsVerification;

    # Return Major.Minor version string.
    channelVersion =
      let
        kv = source.version;
      in
      if any (n: n == (substring 3 1 kv)) [ "." "-" "" ] then
        substring 0 3 kv
      else if any (n: n == (substring 4 1 kv)) [ "." "-" "" ] then
        substring 0 4 kv
      else
        throw "linux.channelVersion: Unsupported kernel version string `${kv}`";

    features = source.features or { };

    # Returns false if channelVerison is greater than maxv or lessthan minv.
    isCompatibleVersion = maxv: minv:
      let
        cv = channelVersion;
      in
      if cv == maxv || (versionOlder cv maxv && versionAtLeast cv minv) then
        true
      else
        false;

    passthru = kernel.passthru // (removeAttrs passthru [ "passthru" "meta" ]);
  };

  config = import ./common-config.nix
    { inherit stdenv version extraConfig; };

  nativeDrv = addPassthru kernel.nativeDrv passthru;

  crossDrv = addPassthru kernel.crossDrv passthru;
in if kernel ? crossDrv then nativeDrv // { inherit nativeDrv crossDrv; } else addPassthru kernel passthru
