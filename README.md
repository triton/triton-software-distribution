Triton Software Distribution
============================

Triton is a collection of packages for the [Nix](https://nixos.org/nix/) package
manager.

##### Discussion Channels
* [Matrix](https://matrix.org) Community: `+triton:matrix.org`

[Documentation](https://triton.github.io/triton/)

##### Legacy Documentation
* [Documentation (Nix Expression Language chapter)](https://nixos.org/nix/manual/#ch-expression-language)
* [Manual (How to write packages for Nix)](https://nixos.org/nixpkgs/manual/)
* [Nix Wiki](https://nixos.org/wiki/)

##### Supported Platforms `(not all platforms implemented)`
+ `ARM` requires: `NEON`, `VFPv3+` (aka. armv7+)
  * `armv7l-linux` WIP
  * `armv8l-linux` WIP
  * `aarch64-linux` WIP
+ `x86` requires: `MMX`,`SSE`,`SSE2`,`SSE3`,`SSSE3`,`SSE4`,`SSE4.1`,`SSE4.2`,`AES`
 (aka. at least Intel Westmere, AMD 15h, or VIA Eden x4)
  * `i686-linux` (libs only)
  * `x86_64-linux`
+ `POWER` requires: POWER8+
  * `powerpc64le-linux` Incomplete
