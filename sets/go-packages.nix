{ lib
, channel
, newScope
, pkgs
}:

let
  callPackage = newScope (self // {
    inherit pkgs;
    goPackages = self;
  });

  self = {

  # Core packages for building all of the rest
  go = callPackage ../pkgs/g/go {
    inherit channel;
  };
  buildGo = callPackage ../pkgs/g/go/build.nix { };
  fetchGo = callPackage ../pkgs/g/go/fetch.nix { };

  # Packages
  consul = callPackage ../pkgs/c/consul { };

  consul-template = callPackage ../pkgs/c/consul-template { };

  dnscrypt-proxy = callPackage ../pkgs/d/dnscrypt-proxy { };

  elvish = callPackage ../pkgs/e/elvish { };

  etcd = callPackage ../pkgs/e/etcd { };

  hugo = callPackage ../pkgs/h/hugo { };

  ipfs = callPackage ../pkgs/i/ipfs { };

  ipfs-cluster = callPackage ../pkgs/i/ipfs-cluster { };

  ipfs-ds-convert = callPackage ../pkgs/i/ipfs-ds-convert { };

  lego = callPackage ../pkgs/l/lego { };

  mc = callPackage ../pkgs/m/mc { };

  minio = callPackage ../pkgs/m/minio { };

  nomad = callPackage ../pkgs/n/nomad { };

  rclone = callPackage ../pkgs/r/rclone { };

  syncthing = callPackage ../pkgs/s/syncthing { };

  teleport = callPackage ../pkgs/t/teleport { };

  vault = callPackage ../pkgs/v/vault { };

  }; in self
