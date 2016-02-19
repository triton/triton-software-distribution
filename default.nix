{ targetSystem ? builtins.currentSystem
, hostSystem ? builtins.currentSystem
, config ? { }
} @ args:
let
  requiredVersion = import ./lib/minver.nix;
in
  if ! builtins ? nixVersion || builtins.compareVersions requiredVersion builtins.nixVersion == 1 then
    abort "This version of Triton requires Nix >= ${requiredVersion}, please upgrade! See https://nixos.org/wiki/How_to_update_when_Nix_is_too_old_to_evaluate_Nixpkgs"
  else
    import ./pkgs/top-level/all-packages.nix {
      inherit targetSystem hostSystem config;
      stdenv = null;
    }
