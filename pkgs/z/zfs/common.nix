{ stdenv
, fetchFromGitHub
, fetchTritonPatch
, fetchurl
}:

let
  fetcher = { fetchzipVersion ? null, version ? null, rev ? null, sha256 }:
    if fetchzipVersion != null then
      fetchFromGitHub {
        owner = "zfsonlinux";
        repo = "zfs";
        rev = if version != null then "zfs-${version}" else rev;
        inherit sha256;
        version = fetchzipVersion;
      }
    else
      fetchurl {
        url = "https://github.com/zfsonlinux/zfs/releases/download/zfs-${version}/zfs-${version}.tar.gz";
        inherit sha256;
      };
in
{
  "stable" = rec {
    version = "0.8.2";
    maxLinuxVersion = "5.3";
    src = fetcher {
      inherit version;
      sha256 = "47608e257c8ecebb918014ef1da6172c3a45d990885891af18e80f5cc28beab8";
    };
    patches = [
      (fetchTritonPatch {
        rev = "af81e3b365a91a63b44e468b2dc0c770686dfa6e";
        file = "z/zfs/0001-Fix-binary-paths.patch";
        sha256 = "8009b1df288109d4f386842210c39e9e1ba3f0734d719dc6eb56deb3d29d2963";
      })
    ];
  };
  "dev" = {
    date = "2019-12-23";
    maxLinuxVersion = "5.4";
    src = fetcher {
      fetchzipVersion = 6;
      rev = "c587b2c7d8d2f6d127fe4266eef017ab7d8b8972";
      sha256 = "afa5773260494529431919b48b7bfe48a0458b158cdddb2bff40ba96df7ef28b";
    };
    patches = [
      (fetchTritonPatch {
        rev = "0dbe87cf3492212d1cbddf9b24f579bf1cfbe2e5";
        file = "z/zfs/0001-Fix-binary-paths.patch";
        sha256 = "233d3449babd612625a2fdd2bfceb4356329af77db3c1aba76e5447ccd0f4973";
      })
    ];
  };
}
