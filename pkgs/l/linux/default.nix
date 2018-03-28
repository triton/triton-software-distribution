{ stdenv
, bison
, buildLinux
, fetchFromGitHub
, fetchurl
, flex
, git
, lib
, perl

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
      version = "4.9.91";
      baseSha256 = "029098dcffab74875e086ae970e3828456838da6e0ba22ce3f64ef764f3d7f1a";
      patchSha256 = "8968b5fd020df4618f275b152cdefb477d3bcb5d1383c6e2115aaef1573c21fe";
    };
    "4.14" = {
      version = "4.14.31";
      baseSha256 = "f81d59477e90a130857ce18dc02f4fbe5725854911db1e7ba770c7cd350f96a7";
      patchSha256 = "fa05fc75fff3a07e9f642bcfc5b99e601e9c92e3c7543127509e2fa102c25a2c";
    };
    "4.15" = {
      version = "4.15.14";
      baseSha256 = "5a26478906d5005f4f809402e981518d2b8844949199f60c4b6e1f986ca2a769";
      patchSha256 = "6be2c185839d730769a8e6bcf46ca0962845732e25ed4801fe1ea995218b1133";
    };
    "testing" = {
      version = "4.16-rc7";
      baseSha256 = "5a26478906d5005f4f809402e981518d2b8844949199f60c4b6e1f986ca2a769";
      patchUrls = [
        "https://github.com/wkennington/linux/releases/download/v${version}/patch-${version}.xz"
      ];
      patchSha256 = "cf5aede86aef261769c053caa76998a1039f0a003c196593608d732b20b83079";
    };
    "bcachefs" =
      let
        date = "2018-03-26";
      in {
        version = "4.15.13";
        patchUrls = [
          "https://github.com/wkennington/linux/releases/download/bcachefs-${version}-${date}/patch-bcachefs-${version}-${date}.xz"
        ];
        baseSha256 = "5a26478906d5005f4f809402e981518d2b8844949199f60c4b6e1f986ca2a769";
        patchSha256 = "f3042fdf3c18cf54e3ead600c3b2f76c75725bdb97b4dbed11174df1e64da68c";
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

    platformName = "pc";
    kernelBaseConfig = "defconfig";
    kernelTarget = "bzImage";
    autoModules = true;
    arch = common.kernelArch;

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
