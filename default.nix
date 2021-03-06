{ targetSystem ? builtins.currentSystem
, hostSystem ? builtins.currentSystem
, config ? null
} @ args:

let
  # Minimum required version for evaluating Nixpkgs
  requiredVersion = "1.10";
in
if ! builtins ? nixVersion || builtins.compareVersions requiredVersion builtins.nixVersion == 1 then
  abort "This version of Triton requires Nix >= ${requiredVersion}, please upgrade!"
else
  import ./sets/all-packages.nix {
    inherit
      config
      hostSystem
      targetSystem;
    stdenv = null;
  }
