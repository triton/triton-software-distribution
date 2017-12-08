/* This file defines the composition for Go packages. */

{ stdenv
, buildGoPackage
, fetchFromGitHub
, fetchTritonPatch
, fetchzip
, go
, lib
, overrides
, pkgs
}:

let
  self = _self // overrides; _self = with self; {

  inherit go buildGoPackage;

  fetchGxPackage = { src, sha256 }: stdenv.mkDerivation {
    name = "gx-src-${src.name}";

    impureEnvVars = [ "IPFS_API" ];

    buildCommand = ''
      if ! [ -f /etc/ssl/certs/ca-certificates.crt ]; then
        echo "Missing /etc/ssl/certs/ca-certificates.crt" >&2
        echo "Please update to a version of nix which supports ssl." >&2
        exit 1
      fi

      start="$(date -u '+%s')"

      unpackDir="$TMPDIR/src"
      mkdir "$unpackDir"
      cd "$unpackDir"
      unpackFile "${src}"
      cd *

      echo "Environment:" >&2
      echo "  IPFS_API: $IPFS_API" >&2

      mtime=$(find . -type f -print0 | xargs -0 -r stat -c '%Y' | sort -n | tail -n 1)
      if [ "$start" -lt "$mtime" ]; then
        str="The newest file is too close to the current date:\n"
        str+="  File: $(date -u -d "@$mtime")\n"
        str+="  Current: $(date -u)\n"
        echo -e "$str" >&2
        exit 1
      fi
      echo -n "Clamping to date: " >&2
      date -d "@$mtime" --utc >&2

      gx --verbose install --global

      echo "Building GX Archive" >&2
      cd "$unpackDir"
      ${src.tar}/bin/tar --sort=name --owner=0 --group=0 --numeric-owner \
        --no-acls --no-selinux --no-xattrs \
        --mode=go=rX,u+rw,a-s \
        --clamp-mtime --mtime=@$mtime \
        -c . | ${src.brotli}/bin/brotli --quality 6 --output "$out"
    '';

    buildInputs = [ gx.bin ];
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
    outputHash = sha256;
    preferLocalBuild = true;

    passthru = {
      inherit src;
    };
  };

  nameFunc =
    { rev
    , goPackagePath
    , name ? null
    , date ? null
    }:
    let
      name' =
        if name == null then
          baseNameOf goPackagePath
        else
          name;
      version =
        if date != null then
          date
        else if builtins.stringLength rev != 40 then
          rev
        else
          stdenv.lib.strings.substring 0 7 rev;
    in
      "${name'}-${version}";

  buildFromGitHub =
    lib.makeOverridable ({ rev
    , date ? null
    , owner
    , repo
    , sha256
    , version
    , gxSha256 ? null
    , goPackagePath ? "github.com/${owner}/${repo}"
    , name ? null
    , ...
    } @ args:
    buildGoPackage (args // (let
      name' = nameFunc {
        inherit
          rev
          goPackagePath
          name
          date;
      };
    in {
      inherit rev goPackagePath;
      name = name';
      src = let
        src' = fetchFromGitHub {
          name = name';
          inherit rev owner repo sha256 version;
        };
      in if gxSha256 == null then
        src'
      else
        fetchGxPackage { src = src'; sha256 = gxSha256; };
    })));

  ## OFFICIAL GO PACKAGES

  appengine = buildFromGitHub {
    version = 3;
    rev = "9d8544a6b2c7df9cff240fcf92d7b2f59bc13416";
    owner = "golang";
    repo = "appengine";
    sha256 = "17sfak28q88xqkzdhbw3bbr0damsdfbpiv6d08mx9xp19vrdncip";
    goPackagePath = "google.golang.org/appengine";
    excludedPackages = "aetest";
    propagatedBuildInputs = [
      protobuf
      net
    ];
    postPatch = ''
      find . -name \*_classic.go -delete
      rm internal/main.go
    '';
    date = "2017-10-31";
  };

  build = buildFromGitHub {
    version = 3;
    rev = "eb24d5cdd7582fa3779a6b69a5d29c65ecb21581";
    date = "2017-12-07";
    owner = "golang";
    repo = "build";
    sha256 = "0k74ach04xrywcm88ky6amvf5k79884i3hgni29bdn7bnchx4n5f";
    goPackagePath = "golang.org/x/build";
    subPackages = [
      "autocertcache"
    ];
    propagatedBuildInputs = [
      crypto
      google-cloud-go
    ];
  };

  crypto = buildFromGitHub {
    version = 3;
    rev = "94eea52f7b742c7cbe0b03b22f0c4c8631ece122";
    date = "2017-11-28";
    owner = "golang";
    repo = "crypto";
    sha256 = "18vnlbm6si9qbhk08qd46z64xg0bansdxy0382phzw0lbfwjnknf";
    goPackagePath = "golang.org/x/crypto";
    buildInputs = [
      net_crypto_lib
    ];
    propagatedBuildInputs = [
      sys
    ];
  };

  debug = buildFromGitHub {
    version = 3;
    rev = "f11d3bcfb62fc8e5d737acc91534fad5e188b8d4";
    date = "2017-09-05";
    owner = "golang";
    repo = "debug";
    sha256 = "13ysbr6lw4wnxp15kgja17jgdmh017843f4j56alyspfmknxr7q7";
    goPackagePath = "golang.org/x/debug";
    excludedPackages = "\\(testdata\\)";
  };

  exp = buildFromGitHub {
    version = 3;
    rev = "a05f2c1e93dc0743a12c519ef35f386b8c095d91";
    owner = "golang";
    repo = "exp";
    sha256 = "0nfwcsmm2v5ivms31qh6jarpybjp8dsl6j857rdhmvvlrqyh1qsb";
    date = "2017-11-26";
    goPackagePath = "golang.org/x/exp";
    subPackages = [
      "ebnf"
    ];
  };

  geo = buildFromGitHub {
    version = 3;
    rev = "f9610db2b871b54b17d36d4da6a4d6a2aab6018d";
    owner = "golang";
    repo = "geo";
    sha256 = "1jqbp89ic2a9qnzcl6xfi1gv2ckx9wwav27v8z21vx2ifzsla0lb";
    date = "2017-12-03";
  };

  glog = buildFromGitHub {
    version = 3;
    rev = "23def4e6c14b4da8ac2ed8007337bc5eb5007998";
    date = "2016-01-26";
    owner = "golang";
    repo = "glog";
    sha256 = "15jy6gcnn4cq6r56nbxja1yn662q7qaj6n6ykzsz3hykql5j8h11";
  };

  image = buildFromGitHub {
    version = 3;
    rev = "f7e31b4ea2e3413ab91b4e7d2dc83e5f8d19a44c";
    date = "2017-10-13";
    owner = "golang";
    repo = "image";
    sha256 = "0rfzp0npzlxclvs83xsvszywjfzxdys8vaf23rnc84imca60f613";
    goPackagePath = "golang.org/x/image";
    propagatedBuildInputs = [
      text
    ];
  };

  net = buildFromGitHub {
    version = 3;
    rev = "dc871a5d77e227f5bbf6545176ef3eeebf87e76e";
    date = "2017-12-07";
    owner = "golang";
    repo = "net";
    sha256 = "0r2vq4ax7qqrmmzs6qgixcxq8ywayvzihh2a29knz8laikl2x6xz";
    goPackagePath = "golang.org/x/net";
    goPackageAliases = [
      "github.com/hashicorp/go.net"
    ];
    excludedPackages = "h2demo";
    propagatedBuildInputs = [
      text
      crypto
    ];
  };

  net_crypto_lib = buildFromGitHub {
    inherit (net) rev date owner repo sha256 version goPackagePath;
    subPackages = [
      "context"
    ];
  };

  oauth2 = buildFromGitHub {
    version = 3;
    rev = "6a2004c8907a86949d71c664c81574897a4e55a6";
    date = "2017-12-06";
    owner = "golang";
    repo = "oauth2";
    sha256 = "0xl9fdnyjb0903sykvddszji3c5rwhmixp342vh3k7zsv511np25";
    goPackagePath = "golang.org/x/oauth2";
    propagatedBuildInputs = [
      appengine
      google-cloud-go-compute-metadata
      net
    ];
  };

  protobuf = buildFromGitHub {
    version = 3;
    rev = "1e59b77b52bf8e4b449a57e6f79f21226d571845";
    date = "2017-11-13";
    owner = "golang";
    repo = "protobuf";
    sha256 = "198v302xdsjr7x175n6baryz6r1rblfnjy77pi2nrs9q18jk7ld4";
    goPackagePath = "github.com/golang/protobuf";
    buildInputs = [
      genproto_protobuf
    ];
  };

  protobuf_genproto = buildFromGitHub {
    inherit (protobuf) version rev date owner repo goPackagePath sha256;
    subPackages = [
      "proto"
      "ptypes/any"
    ];
  };

  snappy = buildFromGitHub {
    version = 2;
    rev = "553a641470496b2327abcac10b36396bd98e45c9";
    date = "2017-02-16";
    owner  = "golang";
    repo   = "snappy";
    sha256 = "1p27dax5jy6isvxmhnssz99pz9mzwcr1wbvdp1m3s6ap0qq708gg";
  };

  sync = buildFromGitHub {
    version = 3;
    rev = "fd80eb99c8f653c847d294a001bdf2a3a6f768f5";
    date = "2017-11-01";
    owner  = "golang";
    repo   = "sync";
    sha256 = "1krwmyrx83d404qzsikfhrll5w1291a43ga8497sjig9rb7kj2bs";
    goPackagePath = "golang.org/x/sync";
    propagatedBuildInputs = [
      net
    ];
  };

  sys = buildFromGitHub {
    version = 3;
    rev = "a0f4589a76f1f83070cb9e5613809e1d07b97c13";
    date = "2017-12-07";
    owner  = "golang";
    repo   = "sys";
    sha256 = "0wp2wnrqrkck0z665phx78riff9zwq84zkcc89x2126ip1wxizhm";
    goPackagePath = "golang.org/x/sys";
  };

  text = buildFromGitHub {
    version = 3;
    rev = "be25de41fadfae372d6470bda81ca6beb55ef551";
    date = "2017-12-07";
    owner = "golang";
    repo = "text";
    sha256 = "1q3fc38a49z8h81hq89764q8877k8m4n2vfs4y99z00dhi0pnjnv";
    goPackagePath = "golang.org/x/text";
    excludedPackages = "\\(cmd\\|test\\)";
  };

  time = buildFromGitHub {
    version = 3;
    rev = "6dc17368e09b0e8634d71cac8168d853e869a0c7";
    date = "2017-09-27";
    owner  = "golang";
    repo   = "time";
    sha256 = "0n7jygbsq7zd61kl3rqgz9pmsif2vmlmkrfifar0c1rjcg5sdxda";
    goPackagePath = "golang.org/x/time";
    propagatedBuildInputs = [
      net
    ];
  };

  tools = buildFromGitHub {
    version = 3;
    rev = "a5ff95640e8c289d9c807a532e8110268036c0dd";
    date = "2017-12-07";
    owner = "golang";
    repo = "tools";
    sha256 = "1cs0h5nfgd5zzrr5x53vck2mqgzx8kwqdq5vh8m7kn1ls3mxwhmk";
    goPackagePath = "golang.org/x/tools";

    preConfigure = ''
      # Make the builtin tools available here
      mkdir -p $bin/bin
      eval $(go env | grep GOTOOLDIR)
      find $GOTOOLDIR -type f | while read x; do
        ln -sv "$x" "$bin/bin"
      done
      export GOTOOLDIR=$bin/bin
    '';

    excludedPackages = "\\("
      + stdenv.lib.concatStringsSep "\\|" ([ "testdata" ] ++ stdenv.lib.optionals (stdenv.lib.versionAtLeast go.meta.branch "1.5") [ "vet" "cover" ])
      + "\\)";

    buildInputs = [
      appengine
      build
      crypto
      google-cloud-go
      net
    ];

    # Do not copy this without a good reason for enabling
    # In this case tools is heavily coupled with go itself and embeds paths.
    allowGoReference = true;

    postPatch = ''
      grep -r '+build appengine' -l | xargs rm
    '';

    # Set GOTOOLDIR for derivations adding this to buildInputs
    postInstall = ''
      mkdir -p $bin/nix-support
      echo "export GOTOOLDIR=$bin/bin" >> $bin/nix-support/setup-hook
    '';
  };


  ## THIRD PARTY

  ace = buildFromGitHub {
    version = 2;
    owner = "yosssi";
    repo = "ace";
    rev = "v0.0.5";
    sha256 = "0i3jfkgwvaz5w1cgz7sqqa7pnpz6hd0dniw2j89yhq6qgb4ikjy0";
    buildInputs = [
      gohtml
    ];
  };

  aeshash = buildFromGitHub {
    version = 2;
    rev = "8ba92803f64b76c91b111633cc0edce13347f0d1";
    owner  = "tildeleb";
    repo   = "aeshash";
    sha256 = "0p1nbk5nx2xhl8kan4bd6lcpmjrh7c60lyy9nf4rafyv2j7qqhnk";
    goPackagePath = "leb.io/aeshash";
    date = "2016-11-30";
    subPackages = [
      "."
    ];
    propagatedBuildInputs = [
      hashland_for_aeshash
    ];
  };

  afero = buildFromGitHub {
    version = 3;
    owner = "spf13";
    repo = "afero";
    rev = "v1.0.0";
    sha256 = "11v3khswil0wmhdzw9p51r2vcca4snga3d28himfpqp7kgp45jsb";
    propagatedBuildInputs = [
      sftp
      text
    ];
  };

  aliyungo = buildFromGitHub {
    version = 3;
    owner = "denverdino";
    repo = "aliyungo";
    rev = "d7c7e038ca2b9ffd3c2b5525d9eae4a31b0704c7";
    date = "2017-12-07";
    sha256 = "025bsr786m5kahk56ya2cgrpaqagr5m4pd27zy7ygv5hzzq3w22z";
    propagatedBuildInputs = [
      protobuf
    ];
  };

  amber = buildFromGitHub {
    version = 3;
    owner = "eknkc";
    repo = "amber";
    rev = "cdade1c073850f4ffc70a829e31235ea6892853b";
    date = "2017-10-10";
    sha256 = "0mhwv2l4dmj384ly0kb4rnyksz33h0c8drqxbhzvmhxvbb2qrglc";
  };

  amqp = buildFromGitHub {
    version = 3;
    owner = "streadway";
    repo = "amqp";
    rev = "ff791c2d22d3f1588b4e2cc71a9fba5e1da90654";
    date = "2017-11-01";
    sha256 = "07xnpkq5l44f79h0mwskd547sc23cff70wrj8jj9d967z138dz47";
  };

  ansi = buildFromGitHub {
    version = 2;
    owner = "mgutz";
    repo = "ansi";
    rev = "9520e82c474b0a04dd04f8a40959027271bab992";
    date = "2017-02-06";
    sha256 = "1180ng6y5b1cnxschbswxaq2cp4yjchhwqjzimspnxj2mh16syhd";
    propagatedBuildInputs = [
      go-colorable
    ];
  };

  ansiterm = buildFromGitHub {
    version = 3;
    owner = "juju";
    repo = "ansiterm";
    rev = "35c59b9e0fe275705a71bf5d58ee293f27efbbc4";
    date = "2016-11-07";
    sha256 = "0azzkmmc8yv7fzv007nhwck5jk9fll8yqqdpa1blkl8lsd2zvnnv";
    propagatedBuildInputs = [
      go-colorable
      go-isatty
      vtclean
    ];
  };

  asn1-ber = buildFromGitHub {
    version = 3;
    rev = "v1.2";
    owner  = "go-asn1-ber";
    repo   = "asn1-ber";
    sha256 = "0xh0f4680jdkh6k3ksnwly5fk9y4a4z4jjwh31yz5crmcf07xzn0";
    goPackageAliases = [
      "github.com/nmcclain/asn1-ber"
      "github.com/vanackere/asn1-ber"
      "gopkg.in/asn1-ber.v1"
    ];
  };

  atomic = buildFromGitHub {
    version = 3;
    owner = "uber-go";
    repo = "atomic";
    rev = "v1.3.1";
    sha256 = "14gxdchkiizv0ncrj1fi4ylchhz3c2kvvri1vx11h06r4ydydq5n";
    goPackagePath = "go.uber.org/atomic";
    goPackageAliases = [
      "github.com/uber-go/atomic"
    ];
  };

  auroradnsclient = buildFromGitHub {
    version = 3;
    rev = "v1.0.2";
    owner  = "edeckers";
    repo   = "auroradnsclient";
    sha256 = "1x5vq95n3gb4jznbi2wmxc6fl5c8f8h7d30ppdkwll3gqqykzpvr";
    propagatedBuildInputs = [
      logrus
    ];
  };

  aws-sdk-go = buildFromGitHub {
    version = 3;
    rev = "v1.12.43";
    owner  = "aws";
    repo   = "aws-sdk-go";
    sha256 = "0f50vrnldr64g8dq35k6mz0495b46dfly17r27j2axli588j4rqp";
    excludedPackages = "\\(awstesting\\|example\\)";
    buildInputs = [
      tools
    ];
    propagatedBuildInputs = [
      ini
      go-jmespath
      net
    ];
    preBuild = ''
      pushd go/src/$goPackagePath
      make generate
      popd
    '';
  };

  azure-sdk-for-go = buildFromGitHub {
    version = 3;
    date = "2017-11-07";
    rev = "7692b0cef22674113fcf71cc17ac3ccc1a7fef48";
    owner  = "Azure";
    repo   = "azure-sdk-for-go";
    sha256 = "08wrzs6n00127ymf9n7yrqsc7vxlsyrn3zlhp7260q0qawvgxg4p";
    excludedPackages = "\\(Gododir\\|storageimportexport\\|tools\\)";
    subPackages = [
      "arm/dns"
    ];
    propagatedBuildInputs = [
      go-autorest
    ];
  };

  azure-storage-go = buildFromGitHub {
    version = 3;
    rev = "v0.1.0";
    owner  = "Azure";
    repo   = "azure-storage-go";
    sha256 = "0lwdn0q94k54qh0xn7qaqj191ah4gfv5fc9wfpnd6l4x1pa2m7vk";
    goPackageAliases = [
      "github.com/Azure/azure-sdk-for-go/storage"
    ];
    propagatedBuildInputs = [
      go-autorest
    ];
  };

  b = buildFromGitHub {
    version = 3;
    date = "2017-11-08";
    rev = "c0c71e655879a2848b5a0e0208b63f97325cbacd";
    owner  = "cznic";
    repo   = "b";
    sha256 = "0yvs18hg321ya5nl2cs59cs0f69f08swx4xska7bh6gbb33knq0w";
    excludedPackages = "example";
  };

  backoff = buildFromGitHub {
    version = 3;
    owner = "cenkalti";
    repo = "backoff";
    rev = "v1.1.0";
    sha256 = "1370w8zhgdgvmp0prbzmjc93b8di9cb4wgfsgjd5m3xm4jqghzn7";
    propagatedBuildInputs = [
      net
    ];
  };

  barcode = buildFromGitHub {
    version = 3;
    owner = "boombuler";
    repo = "barcode";
    rev = "v1.0.0";
    sha256 = "0qfyxzaigr4f7ngz5vfhqil395aghx1ywg0lbv909znvcx5c0sl1";
  };

  base32 = buildFromGitHub {
    version = 3;
    owner = "whyrusleeping";
    repo = "base32";
    rev = "c30ac30633ccdabefe87eb12465113f06f1bab75";
    sha256 = "1q1z4zqmdbrjy61vbc28k01acdyrg9r0i095yf7q07c9xb5jffg7";
    date = "2017-08-28";
  };

  bigfft = buildFromGitHub {
    version = 3;
    date = "2017-08-06";
    rev = "52369c62f4463a21c8ff8531194c5526322b8521";
    owner = "remyoudompheng";
    repo = "bigfft";
    sha256 = "0il8sc0fm5kvgf8b2kddrggfkda6l27rbyw13i9sh60jj9dgh2gz";
  };

  binary = buildFromGitHub {
    version = 3;
    owner = "alecthomas";
    repo = "binary";
    rev = "6e8df1b1fb9d591dfc8249e230e0a762524873f3";
    date = "2017-11-01";
    sha256 = "142c56kfyivib7z9bpfdh2qc2kmhwh03fypxxv60wz7l6idr6jrw";
  };

  binding = buildFromGitHub {
    version = 3;
    date = "2017-06-11";
    rev = "ac54ee249c27dca7e76fad851a4a04b73bd1b183";
    owner = "go-macaron";
    repo = "binding";
    sha256 = "08pi8c86vzwrwjid3n8ls88xwxksyfd22vhzy129zkj0vspvl6sy";
    buildInputs = [
      com
      compress
      macaron_v1
    ];
  };

  blackfriday = buildFromGitHub {
    version = 3;
    owner = "russross";
    repo = "blackfriday";
    rev = "6d1ef893fcb01b4f50cb6e57ed7df3e2e627b6b2";
    sha256 = "0wdsyblcch0yk0hzr57m6mapfjdifp7zs9lk2ivvi891rfznc9mi";
    propagatedBuildInputs = [
      sanitized-anchor-name
    ];
    meta.useUnstable = true;
    date = "2017-10-11";
  };

  blake2b-simd = buildFromGitHub {
    version = 2;
    owner = "minio";
    repo = "blake2b-simd";
    date = "2016-07-23";
    rev = "3f5f724cb5b182a5c278d6d3d55b40e7f8c2efb4";
    sha256 = "5ead55b23a24393a96cb6504b0a64c48812587c4af12527101c3a7c79c2d35e5";
  };

  bbolt = buildFromGitHub {
    version = 3;
    rev = "48ea1b39c25fc1bab3506fbc712ecbaa842c4d2d";
    owner  = "coreos";
    repo   = "bbolt";
    sha256 = "1iqyy7q9n8rrldx09jhrlh274m8ykyym79iyfynnzafjhwph451g";
    date = "2017-12-07";
    buildInputs = [
      sys
    ];
  };

  bolt = buildFromGitHub {
    version = 3;
    rev = "v1.3.1";
    owner  = "boltdb";
    repo   = "bolt";
    sha256 = "0j1dmlp9sh1v5kpxzvamyjdwlb0pndpy9a2qjhg2q93ri3dbfr58";
    buildInputs = [
      sys
    ];
  };

  btcd = buildFromGitHub {
    version = 3;
    owner = "btcsuite";
    repo = "btcd";
    date = "2017-11-28";
    rev = "2e60448ffcc6bf78332d1fe590260095f554dd78";
    sha256 = "1zi1wll64vgds06bkq0mvrgmirim9i0ddg49dvmiwsna8w0a55s5";
    subPackages = [
      "btcec"
    ];
  };

  btree = buildFromGitHub {
    version = 2;
    rev = "316fb6d3f031ae8f4d457c6c5186b9e3ded70435";
    owner  = "google";
    repo   = "btree";
    sha256 = "1wjicavprwxpa0rmvc8wz6k0gxl2q4rpsg7ci5hjvkb2j56r4rwk";
    date = "2016-12-17";
  };

  builder = buildFromGitHub {
    version = 3;
    rev = "a4a881a4e552fcb5473f39e8b9f7d9f3457a7fb0";
    owner  = "go-xorm";
    repo   = "builder";
    sha256 = "0snc34bmmbn7m6mxd76l195as61adb11c8iyjk61p75p1z7skb9m";
    date = "2017-10-30";
  };

  bufio_v1 = buildFromGitHub {
    version = 3;
    date = "2014-06-18";
    rev = "567b2bfa514e796916c4747494d6ff5132a1dfce";
    owner  = "go-bufio";
    repo   = "bufio";
    sha256 = "16brclx5znbfx7h9ny47j1d3dsxvq9w0g4qww8hdlig1hyarqy0n";
    goPackagePath = "gopkg.in/bufio.v1";
  };

  bytefmt = buildFromGitHub {
    version = 3;
    date = "2017-04-28";
    rev = "f4415fafc5619dd75599a54a7c91fb3948ad58bd";
    owner  = "cloudfoundry";
    repo   = "bytefmt";
    sha256 = "1kknlgs28zy2l05kz68r1zf39m5f2j1ah3yxd9jzp91bb9ifbzhf";
    goPackagePath = "code.cloudfoundry.org/bytefmt";
    goPackageAliases = [
      "github.com/cloudfoundry/bytefmt"
    ];
  };

  cachecontrol = buildFromGitHub {
    version = 3;
    owner = "pquerna";
    repo = "cachecontrol";
    rev = "0dec1b30a0215bb68605dfc568e8855066c9202d";
    date = "2017-10-18";
    sha256 = "06gd25llrp6jcn40bvc71kqjv8wgvafxv4kqqdpis74ary1n6bb7";
  };

  cascadia = buildFromGitHub {
    version = 2;
    date = "2016-12-24";
    rev = "349dd0209470eabd9514242c688c403c0926d266";
    owner  = "andybalholm";
    repo   = "cascadia";
    sha256 = "0xhdlrsvzsv3va4in3iw9v1nz2f6n8zca98mq4swl8zwfdly2jj8";
    propagatedBuildInputs = [
      net
    ];
  };

  cast = buildFromGitHub {
    version = 2;
    owner = "spf13";
    repo = "cast";
    rev = "v1.1.0";
    sha256 = "0b7i6dwk06w710cjcd0wnhgyrf15m344lmhm9jpfhfs678bg7va5";
    buildInputs = [
      jwalterweatherman
    ];
  };

  cbauth = buildFromGitHub {
    version = 3;
    date = "2016-06-09";
    rev = "ae8f8315ad044b86ced2e0be9e3598e9dd94f38a";
    owner = "couchbase";
    repo = "cbauth";
    sha256 = "185c10ab80cn4jxdp915h428lm0r9zf1cqrfsjs71im3w3ankvsn";
  };

  cbor = buildFromGitHub {
    version = 3;
    owner = "whyrusleeping";
    repo = "cbor";
    rev = "63513f603b11583741970c5045ea567130ddb492";
    sha256 = "1xx3k25pywx3rbijfx6lgm8spzralm619cl3pk1ijpz2s265y0ld";
    date = "2017-10-05";
  };

  ccache = buildFromGitHub {
    version = 3;
    rev = "b425c9ca005a2050ebe723f6a0cddcb907354ab7";
    owner = "karlseguin";
    repo = "ccache";
    sha256 = "1y5iszzyyk4jyzwwbg8nlibd4jr0cl7gj1vi2mvvm09sc7gcczl7";
    date = "2017-09-04";
  };

  certificate-transparency-go = buildFromGitHub {
    version = 3;
    owner = "google";
    repo = "certificate-transparency-go";
    rev = "96d0882a11ef3ac0b43ad09b078d4017c26e05e9";
    date = "2017-12-04";
    sha256 = "1d3ipc9adgflah2gxi0l0fgxykd76afvnh5wjjz9pf3nxy0xxb7k";
    subPackages = [
      "."
      "asn1"
      "client"
      "client/configpb"
      "jsonclient"
      "tls"
      "x509"
      "x509/pkix"
    ];
    propagatedBuildInputs = [
      net
      protobuf
      gogo_protobuf
    ];
  };

  cfssl = buildFromGitHub {
    version = 3;
    date = "2017-12-07";
    rev = "d2393674072314fda47d2c7c16cb7fd4cdc16821";
    owner  = "cloudflare";
    repo   = "cfssl";
    sha256 = "14p6gn75x1cxc75wfknxjyg1m7lbwfas6ihg7sk6xa00llkks0pz";
    subPackages = [
      "auth"
      "api"
      "certdb"
      "config"
      "csr"
      "crypto/pkcs7"
      "errors"
      "helpers"
      "helpers/derhelpers"
      "info"
      "initca"
      "log"
      "ocsp/config"
      "signer"
      "signer/local"
    ];
    propagatedBuildInputs = [
      crypto
      certificate-transparency-go
      net
    ];
  };

  cfssl_errors = cfssl.override {
    subPackages = [
      "errors"
    ];
    buildInputs = [
    ];
    propagatedBuildInputs = [
    ];
  };

  cgofuse = buildFromGitHub {
    version = 3;
    rev = "v1.0.4";
    owner  = "billziss-gh";
    repo   = "cgofuse";
    sha256 = "1s7hj5qglfvxn89zvh29zvi1qlv245dwyxmz64siwd4r5nzgaxk8";
    buildInputs = [
      pkgs.fuse_2
    ];
  };

  chalk = buildFromGitHub {
    version = 2;
    rev = "22c06c80ed312dcb6e1cf394f9634aa2c4676e22";
    owner  = "ttacon";
    repo   = "chalk";
    sha256 = "0s5ffh4cilfg77bfxabr5b07sllic4xhbnz5ck68phys5jq9xhfs";
    date = "2016-06-26";
  };

  check = buildFromGitHub {
    version = 2;
    date = "2016-12-08";
    rev = "20d25e2804050c1cd24a7eea1e7a6447dd0e74ec";
    owner = "go-check";
    repo = "check";
    goPackagePath = "gopkg.in/check.v1";
    goPackageAliases = [
      "github.com/go-check/check"
    ];
    sha256 = "003qj5rpr27923bjvgd3mbgack3blw0m4izrq9plpxkha1glylz3";
  };

  chroma = buildFromGitHub {
    version = 3;
    rev = "c6b01cb2a6799ec5c955ca684fd1bdc49cb67ce3";
    owner  = "alecthomas";
    repo   = "chroma";
    sha256 = "0pcslal91pywwabri4wcxchv4iz2v41qsxzalc92ddn60jdggba2";
    excludedPackages = "cmd";
    propagatedBuildInputs = [
      fnmatch
      regexp2
    ];
    meta.useUnstable = true;
    date = "2017-12-04";
  };

  circbuf = buildFromGitHub {
    version = 3;
    date = "2015-08-27";
    rev = "bbbad097214e2918d8543d5201d12bfd7bca254d";
    owner  = "armon";
    repo   = "circbuf";
    sha256 = "1g4rrgv936x8mfdqsdg3gzz79h763pyj03p76pranq9cpvzg3ws2";
  };

  circonus-gometrics = buildFromGitHub {
    version = 3;
    rev = "v2.1.0";
    owner  = "circonus-labs";
    repo   = "circonus-gometrics";
    sha256 = "1fg7pclsnyflf98hl1w4qdaz68dlvz7vs6qg50rp4nnawmn5wxfl";
    propagatedBuildInputs = [
      circonusllhist
      errors
      go-retryablehttp
      httpunix
    ];
  };

  circonusllhist = buildFromGitHub {
    version = 3;
    date = "2017-05-25";
    rev = "6e85b9352cf0c2bb969831347491388bb3ae9c69";
    owner  = "circonus-labs";
    repo   = "circonusllhist";
    sha256 = "0qpkipra8irp0mxcr0b8pssjbqjhcfdp1rd0blzgicx4z01zpcq2";
  };

  cli_minio = buildFromGitHub {
    version = 2;
    owner = "minio";
    repo = "cli";
    rev = "v1.3.0";
    sha256 = "08z1g5g3f07inpgyb93ip037f4y1cnhsm2wvg63qnnnry9chwy36";
    buildInputs = [
      toml
      urfave_cli
      yaml_v2
    ];
  };

  AudriusButkevicius_cli = buildFromGitHub {
    version = 2;
    rev = "7f561c78b5a4aad858d9fd550c92b5da6d55efbb";
    owner = "AudriusButkevicius";
    repo = "cli";
    sha256 = "0m9vi5cw611mddyxs7i7ss0j45xq2zmjdrf4mzi5d2khija7iirm";
    date = "2014-07-27";
  };

  docker_cli = buildFromGitHub {
    version = 3;
    date = "2017-12-07";
    rev = "ace5417954ec908d862d59e992c8d77685366eab";
    owner = "docker";
    repo = "cli";
    sha256 = "1x0qvnmn5hbmkj59cqnwl5vmf70cjx85asyz63ym9sbhid0bp4r6";
    subPackages = [
      "cli/config/configfile"
      "cli/config/credentials"
      "opts"
    ];
    propagatedBuildInputs = [
      docker-credential-helpers
      errors
      go-connections
      moby_lib
      go-units
    ];
  };

  mitchellh_cli = buildFromGitHub {
    version = 3;
    date = "2017-11-29";
    rev = "33edc47170b5df54d2588696d590c5e20ee583fe";
    owner = "mitchellh";
    repo = "cli";
    sha256 = "1rpriyp77sgycbxfwsmbci8112qki17gmsfaqhbfys1b10wxi0qs";
    propagatedBuildInputs = [
      complete
      crypto
      go-isatty
      go-radix
      speakeasy
    ];
  };

  urfave_cli = buildFromGitHub {
    version = 3;
    rev = "v1.20.0";
    owner = "urfave";
    repo = "cli";
    sha256 = "1fmmp302zgs19br94v8ppymid9m9dz3iwvwypg7182r3rlbnwp9s";
    goPackagePath = "gopkg.in/urfave/cli.v1";
    goPackageAliases = [
      "github.com/codegangsta/cli"
      "github.com/urfave/cli"
    ];
    buildInputs = [
      toml
      yaml_v2
    ];
  };

  clock = buildFromGitHub {
    version = 3;
    owner = "benbjohnson";
    repo = "clock";
    rev = "7dc76406b6d3c05b5f71a86293cbcf3c4ea03b19";
    date = "2016-12-15";
    sha256 = "14b21633wnja9rc8ygk17aqil0z3sda82ljwwvnikb48nhjy792a";
    goPackageAliases = [
      "github.com/facebookgo/clock"
    ];
  };

  clockwork = buildFromGitHub {
    version = 2;
    rev = "v0.1.0";
    owner = "jonboulle";
    repo = "clockwork";
    sha256 = "1hwdrck8k4nxdc0zpbd4hbxsyh8xhip9k7d71cv4ziwlh71sci5g";
  };

  cmux = buildFromGitHub {
    version = 3;
    rev = "v0.1.3";
    owner = "soheilhy";
    repo = "cmux";
    sha256 = "1vayyhn5jb243xrpgsb3q633vff8kwh09rif6r2sbgk5v52zhz9j";
    propagatedBuildInputs = [
      net
    ];
  };

  cni = buildFromGitHub {
    version = 3;
    rev = "cb4cd0e12ce960e860bebf9ac4a13b68908039e9";
    owner = "containernetworking";
    repo = "cni";
    sha256 = "c34627f605fd58904fcd56baeb05fb7170017475581cddabd2e3b0fe22dfccb9";
    subPackages = [
      "pkg/types"
    ];
    meta.autoUpdate = false;
  };

  cobra = buildFromGitHub {
    version = 3;
    owner = "spf13";
    repo = "cobra";
    rev = "ccaecb155a2177302cb56cae929251a256d0f646";
    sha256 = "09854bkc7j4d22pqwbvds587xcfvivp165pik1b3cg7lg2ird55i";
    propagatedBuildInputs = [
      go-homedir
      go-md2man
      mousetrap
      pflag
      viper
      yaml_v2
    ];
    meta.useUnstable = true;
    date = "2017-12-07";
  };

  cockroach-go = buildFromGitHub {
    version = 3;
    rev = "0d8b4682f140f0fe486ef7e3d2f70665f3066906";
    owner  = "cockroachdb";
    repo   = "cockroach-go";
    sha256 = "0wni2id5h83agv51lbnrn2anwc0yk9n4vy6nqx1n2xfvj6qpyqlh";
    date = "2017-10-23";
    propagatedBuildInputs = [
      pq
    ];
  };

  color = buildFromGitHub {
    version = 3;
    rev = "v1.5.0";
    owner  = "fatih";
    repo   = "color";
    sha256 = "1mss7grj2kv8nh31ib8kmsz63rj2iqkjs3f9z8r3zh4fnrm1i4ym";
    propagatedBuildInputs = [
      go-colorable
      go-isatty
    ];
  };

  colorstring = buildFromGitHub {
    version = 3;
    rev = "8631ce90f28644f54aeedcb3e389a85174e067d1";
    owner  = "mitchellh";
    repo   = "colorstring";
    sha256 = "1x6mlyhpxkl8r3h4nafnv0k9wxm9csqdgd8msmyz00ahpxwga3k7";
    date = "2015-09-17";
  };

  columnize = buildFromGitHub {
    version = 3;
    rev = "abc90934186a77966e2beeac62ed966aac0561d5";
    owner  = "ryanuber";
    repo   = "columnize";
    sha256 = "00nrx8yh3ydynjlqf4daj49niwyrrmdav0g2a7cdzbxpsz6j7x22";
    date = "2017-07-03";
  };

  com = buildFromGitHub {
    version = 3;
    rev = "7677a1d7c1137cd3dd5ba7a076d0c898a1ef4520";
    owner  = "Unknwon";
    repo   = "com";
    sha256 = "1badabjv94paviyr56cqj5g2gfylgyagjrhrh5ml7wr2zwncvm8y";
    date = "2017-08-19";
  };

  complete = buildFromGitHub {
    version = 3;
    rev = "v1.1";
    owner  = "posener";
    repo   = "complete";
    sha256 = "0n9w20mds2zkgbv5ci7d2wny28yi48hpbw63l4f3i90zdx642w4w";
    propagatedBuildInputs = [
      go-multierror
    ];
  };

  compress = buildFromGitHub {
    version = 3;
    rev = "ea08389e0dc46025380296f7dd04ab0e8de36adb";
    owner  = "klauspost";
    repo   = "compress";
    sha256 = "0brk3dk5vvgv1ga2ad30644w14g9jiv5d8v9zj4sia9gz09ia9am";
    propagatedBuildInputs = [
      cpuid
      crc32
    ];
    date = "2017-11-04";
  };

  configure = buildFromGitHub {
    version = 2;
    rev = "4e0f2df8846ee9557b5c88307a769ff2f85e89cd";
    owner = "gravitational";
    repo = "configure";
    sha256 = "04qdmaz5pyd6nn7r5mdc2chzsx1zr2q0wv245xzzahx5n9m2x34x";
    date = "2016-10-02";
    propagatedBuildInputs = [
      gojsonschema
      kingpin_v2
      trace
      yaml_v2
    ];
    excludedPackages = "test";
  };

  consul = buildFromGitHub rec {
    version = 3;
    rev = "v1.0.1";
    owner = "hashicorp";
    repo = "consul";
    sha256 = "1wx2lsyw5vd6fziwc54vkanjpym13bd18brr861044dgxb9cqy7z";

    buildInputs = [
      armon_go-metrics
      circbuf
      columnize
      copystructure
      dns
      errors
      go-bindata-assetfs
      go-checkpoint
      go-connections
      go-discover
      go-dockerclient
      go-memdb
      go-multierror
      go-radix
      go-rootcerts
      hashicorp_go-sockaddr
      go-syslog
      go-testing-interface
      go-version
      golang-lru
      golang-text
      google-api-go-client
      gopsutil
      hashicorp_go-uuid
      hcl
      hil
      logutils
      mapstructure
      memberlist
      mitchellh_cli
      net
      net-rpc-msgpackrpc
      oauth2
      raft-boltdb
      raft
      scada-client
      time
      ugorji_go
      hashicorp_yamux
    ];

    propagatedBuildInputs = [
      go-cleanhttp
      serf
    ];

    postPatch = let
      v = stdenv.lib.substring 1 (stdenv.lib.stringLength rev - 1) rev;
    in ''
      sed \
        -e 's,\(Version[ \t]*= "\)unknown,\1${v},g' \
        -e 's,\(VersionPrerelease[ \t]*= "\)unknown,\1,g' \
        -i version/version.go
    '';

    # Keep consul.ui for backward compatability
    passthru.ui = pkgs.consul-ui;
  };

  consul_api = buildFromGitHub {
    inherit (consul) rev owner repo sha256 version;
    propagatedBuildInputs = [
      go-cleanhttp
      go-rootcerts
      serf
      hashicorp_yamux
    ];
    subPackages = [
      "api"
      "lib"
      "tlsutil"
    ];
  };

  consulfs = buildFromGitHub {
    version = 3;
    rev = "v0.2";
    owner = "bwester";
    repo = "consulfs";
    sha256 = "1br7zs43lmbxydw2ywsr8vdb5r5xwdlxd7hi120a0a0i77076cik";
    buildInputs = [
      consul_api
      fuse
      logrus
      net
    ];
  };

  consul-replicate = buildFromGitHub {
    version = 3;
    rev = "675a2c291d06aa1d152f11a2ac64b7001b588816";
    owner = "hashicorp";
    repo = "consul-replicate";
    sha256 = "0cjrsibg0d7p7rkgp5plxgsxb920ljs0g7wbajjnhizmlnprx3zk";
    propagatedBuildInputs = [
      consul_api
      consul-template
      errors
      go-multierror
      hcl
      mapstructure
    ];
    meta.useUnstable = true;
    date = "2017-08-10";
  };

  consul-template = buildFromGitHub {
    version = 3;
    rev = "v0.19.4";
    owner = "hashicorp";
    repo = "consul-template";
    sha256 = "0n0d4hrpv5hspwalix30w219fv3ln1m6gnypp4r2l6yna8prfz45";

    propagatedBuildInputs = [
      consul_api
      errors
      go-homedir
      go-multierror
      go-rootcerts
      go-shellwords
      go-syslog
      hcl
      logutils
      mapstructure
      toml
      yaml_v2
      vault_api
    ];
  };

  context = buildFromGitHub {
    version = 3;
    rev = "v1.1";
    owner = "gorilla";
    repo = "context";
    sha256 = "17qagayvacgq3vwhslq7zn4qabdb12vlfymya0v6c87h4yb6yr8w";
  };

  continuity = buildFromGitHub {
    version = 3;
    rev = "0cf103d319cc2d7efe085224094f466d1f8b9640";
    owner = "containerd";
    repo = "continuity";
    sha256 = "02jyfqkcp7qhv8anj5vgjazwnawh5v19q7jkfnz3cr9lzlvfkr1f";
    date = "2017-11-21";
    subPackages = [
      "pathdriver"
    ];
  };

  copystructure = buildFromGitHub {
    version = 3;
    date = "2017-05-25";
    rev = "d23ffcb85de31694d6ccaa23ccb4a03e55c1303f";
    owner = "mitchellh";
    repo = "copystructure";
    sha256 = "1fg0jzz54d0xmkfh2gxk42bd3bcfci1h498bqf05rq576blbpcld";
    propagatedBuildInputs = [ reflectwalk ];
  };

  core = buildFromGitHub {
    version = 3;
    rev = "v0.5.7";
    owner = "go-xorm";
    repo = "core";
    sha256 = "05ryjv26lwbcj7lha936yhlqdm0nazy8rjmmnbnig3x97ba6lhvq";
  };

  cors = buildFromGitHub {
    version = 3;
    owner = "rs";
    repo = "cors";
    rev = "v1.2";
    sha256 = "0zgk21r48vwlhl7z9y3g6rckn8lhiz43x0kg4abb0id54z2jhmcb";
    propagatedBuildInputs = [
      net
      xhandler
    ];
  };

  cpufeat = buildFromGitHub {
    version = 3;
    rev = "3794dfbfb04749f896b521032f69383f24c3687e";
    owner  = "templexxx";
    repo   = "cpufeat";
    sha256 = "01i4kcfv81gxlglyvkdi4aajj0ivy7rhcsq4b9yind1smq3rfxs5";
    date = "2017-09-27";
  };

  cpuid = buildFromGitHub {
    version = 3;
    rev = "v1.1";
    owner  = "klauspost";
    repo   = "cpuid";
    sha256 = "1a4mcdvddiz9z7x6652z5qb81b0c5hdxfy9awrxzhcqs3dwnrgpa";
    excludedPackages = "testdata";
  };

  crc32 = buildFromGitHub {
    version = 3;
    rev = "bab58d77464aa9cf4e84200c3276da0831fe0c03";
    owner  = "klauspost";
    repo   = "crc32";
    sha256 = "1x40fs9im3hj56zzr6yfba8bd0vdg4dd434h52lfg1p2a5w8kh1w";
    date = "2017-06-28";
  };

  cronexpr = buildFromGitHub {
    version = 2;
    rev = "d520615e531a6bf3fb69406b9eba718261285ec8";
    owner  = "gorhill";
    repo   = "cronexpr";
    sha256 = "0cjnck67s18sdrlx8cv0yys5vaf1sknywbzd2dyq2l144cjrsj7h";
    date = "2016-12-05";
  };

  cuckoo = buildFromGitHub {
    version = 3;
    rev = "23d6a3a21bf6bee833d131ddeeab610c71915c30";
    owner  = "tildeleb";
    repo   = "cuckoo";
    sha256 = "0v1nv6laq4mssz13nz49h6fxynyghj0hh2v2a2p4k4mck3srjzki";
    date = "2017-09-28";
    goPackagePath = "leb.io/cuckoo";
    goPackageAliases = [
      "github.com/tildeleb/cuckoo"
    ];
    excludedPackages = "\\(example\\|dstest\\|primes/primes\\)";
    propagatedBuildInputs = [
      aeshash
      binary
    ];
  };

  crypt = buildFromGitHub {
    version = 3;
    owner = "xordataexchange";
    repo = "crypt";
    rev = "b2862e3d0a775f18c7cfe02273500ae307b61218";
    date = "2017-06-26";
    sha256 = "0jng0cymgbyl1mwiqr8cq2zkhycf0m2jwiwpqnps911faqdgk9fh";
    propagatedBuildInputs = [
      consul_api
      crypto
      etcd_client
    ];
    postPatch = ''
      sed -i backend/consul/consul.go \
        -e 's,"github.com/armon/consul-api",consulapi "github.com/hashicorp/consul/api",'
    '';
  };

  cssmin = buildFromGitHub {
    version = 3;
    owner = "dchest";
    repo = "cssmin";
    rev = "fb8d9b44afdc258bfff6052d3667521babcb2239";
    date = "2015-12-10";
    sha256 = "0nqngx6h1664kyw2iis87g2lv96jjiic1z2g74a187bm2p2wjsxq";
  };

  datadog-go = buildFromGitHub {
    version = 3;
    rev = "4d2e5696ebe914940bd7459d2266fb7d555ea1b7";
    owner = "DataDog";
    repo = "datadog-go";
    sha256 = "1d9710arxly7a18kk0hcw0pxqrf853yhkbp1fr63hcbfrlj7f6mv";
    date = "2017-11-22";
  };

  dbus = buildFromGitHub {
    version = 3;
    rev = "v4.1.0";
    owner = "godbus";
    repo = "dbus";
    sha256 = "1qbd10y52x2b0p6hjkd18f6jy8c6qmci0av6id7zxh331vnzx5a2";
  };

  decimal = buildFromGitHub {
    version = 3;
    rev = "9ca7f51822d222ae4e246f070f9aad863599bd1a";
    owner  = "shopspring";
    repo   = "decimal";
    sha256 = "15dpbzrvzmrw7dcpnx028jkr7if551arv6aianzc6l0sqmgl1hrg";
    date = "2017-11-08";
  };

  demangle = buildFromGitHub {
    version = 3;
    date = "2016-09-27";
    rev = "4883227f66371e02c4948937d3e2be1664d9be38";
    owner = "ianlancetaylor";
    repo = "demangle";
    sha256 = "1fx4lz9gwps99ck0iskdjm0l3pnqr306h4w7578x3ni2vimc0ahy";
  };

  diskv = buildFromGitHub {
    version = 3;
    rev = "v2.0.1";
    owner  = "peterbourgon";
    repo   = "diskv";
    sha256 = "0himh621lksnk8wq1j36b607a1nv5mpwbd7d06mq14bcnr68ljvy";
    propagatedBuildInputs = [
      btree
    ];
  };

  distribution = buildFromGitHub {
    version = 3;
    rev = "f4118485915abb8b163442717326597908eee6aa";
    owner = "docker";
    repo = "distribution";
    sha256 = "1lkx2kqj6h3qczdp2260rx7d2pbh7v2zgnb7zh1ppya1i6zc1y7x";
    meta.useUnstable = true;
    date = "2017-12-07";
  };

  distribution_for_moby = buildFromGitHub {
    inherit (distribution) date rev owner repo sha256 version meta;
    subPackages = [
      "."
      "digestset"
      "context"
      "manifest"
      "manifest/manifestlist"
      "reference"
      "registry/api/errcode"
      "registry/api/v2"
      "registry/client"
      "registry/client/auth"
      "registry/client/auth/challenge"
      "registry/client/transport"
      "registry/storage/cache"
      "registry/storage/cache/memory"
      "uuid"
    ];
    propagatedBuildInputs = [
      go-digest
      logrus
      mux
      net
    ];
  };

  dns = buildFromGitHub {
    version = 3;
    rev = "v1.0.0";
    owner  = "miekg";
    repo   = "dns";
    sha256 = "1yimsn8wrqj4dli8ji4hva2xy7ba7lk4x867nkrbr1swsj8lmr1g";
    propagatedBuildInputs = [
      crypto
      net
    ];
  };

  dnsimple-go = buildFromGitHub {
    version = 3;
    rev = "256aa39d0454e51be9f1461ee24252a66d69365a";
    owner  = "dnsimple";
    repo   = "dnsimple-go";
    sha256 = "1fxhx2408paw5m58dhrlgb8ybj3ncasc6smq8s9c1jjh315yhi94";
    propagatedBuildInputs = [
      go-querystring
    ];
    date = "2017-12-04";
  };

  dnspod-go = buildFromGitHub {
    version = 3;
    rev = "f33a2c6040fc2550a631de7b3a53bddccdcd73fb";
    owner = "decker502";
    repo = "dnspod-go";
    sha256 = "1dag0m8q3332b5dilml72bhrw9ixpv2r51p5rsfqcliag1ajc6zh";
    date = "2017-06-01";
  };

  docker-credential-helpers = buildFromGitHub {
    version = 3;
    rev = "v0.6.0";
    owner = "docker";
    repo = "docker-credential-helpers";
    sha256 = "1k0aym74a6f83nsqjb2avsypakh3i23wk6il9295hfjd8ljwilpm";
    postPatch = ''
      find . -name \*_windows.go -delete
    '';
    buildInputs = [
      pkgs.libsecret
    ];
  };

  docopt-go = buildFromGitHub {
    version = 3;
    rev = "0.6.2";
    owner  = "docopt";
    repo   = "docopt-go";
    sha256 = "1cxn2aimmkibzcph3m3zidq4mbllxkdsbr28zrvqb2krw9zdqhn9";
  };

  dropbox-sdk-go-unofficial = buildFromGitHub {
    version = 3;
    rev = "3620be11411ddb30351ae33ac2ac34c16e13e66b";
    owner  = "dropbox";
    repo   = "dropbox-sdk-go-unofficial";
    sha256 = "08s3d2r38p4mamn19wiz9p815irk45ickrsj7ip4694sqgzgcb8j";
    propagatedBuildInputs = [
      oauth2
    ];
    excludedPackages = "generator";
    meta.useUnstable = true;
    date = "2017-09-20";
  };

  dsync = buildFromGitHub {
    version = 3;
    owner = "minio";
    repo = "dsync";
    date = "2017-11-22";
    rev = "ed0989bc6c7b199f749fa6be0b7ee98d689b88c7";
    sha256 = "07izm9hghc6pilnvs32ag531c7q1cf6aw8h2457dn2sz8m8wzp5s";
  };

  du = buildFromGitHub {
    version = 2;
    rev = "v1.0.1";
    owner  = "calmh";
    repo   = "du";
    sha256 = "00l7y5f2si43pz9iqnfccfbx6z6wni00aqc6jgkj1kwpjq5q9ya4";
  };

  duo_api_golang = buildFromGitHub {
    version = 2;
    date = "2016-06-27";
    rev = "2b2d787eb38e28ce4fd906321d717af19fad26a6";
    owner = "duosecurity";
    repo = "duo_api_golang";
    sha256 = "17vi9qg1dd02pmqjajqkspvdl676f0jhfzh4vzr4rxrcwgnqxdwx";
  };

  easyjson = buildFromGitHub {
    version = 3;
    owner = "mailru";
    repo = "easyjson";
    rev = "32fa128f234d041f196a9f3e0fea5ac9772c08e1";
    date = "2017-11-20";
    sha256 = "0abmq0b0s2iq0f3jnijwg13qf9qjniwfzib340ic3hr1ynzj3jck";
    excludedPackages = "benchmark";
  };

  ed25519 = buildFromGitHub {
    version = 2;
    owner = "agl";
    repo = "ed25519";
    rev = "5312a61534124124185d41f09206b9fef1d88403";
    sha256 = "0kb8jidncc30cn3dwwczxl7wnzjl862vy6p3rcrcnbgpygz6jhjf";
    date = "2017-01-16";
  };

  egoscale = buildFromGitHub {
    version = 3;
    rev = "64750f2499de8d5d68203d456cc520098689a5fa";
    date = "2017-12-07";
    owner  = "exoscale";
    repo   = "egoscale";
    sha256 = "0h545w55m9b69324rflz4cig10mn7w536ha97yib7qnb0445ihz4";
  };

  elastic_v3 = buildFromGitHub {
    version = 3;
    owner = "olivere";
    repo = "elastic";
    rev = "v3.0.69";
    sha256 = "0a34zkk8jybw0nzprqc5b8hrmlwxfn1vbsb97932c5v57wrqpyqn";
    goPackagePath = "gopkg.in/olivere/elastic.v3";
    propagatedBuildInputs = [
      net
    ];
  };

  elastic_v5 = buildFromGitHub {
    version = 3;
    owner = "olivere";
    repo = "elastic";
    rev = "v5.0.58";
    sha256 = "1csc50d0s7v0a80g5fdsmfy5flagnaw2ljkgmh7jylk3ywa7j1f4";
    goPackagePath = "gopkg.in/olivere/elastic.v5";
    propagatedBuildInputs = [
      errors
      net
      sync
    ];
  };

  eme = buildFromGitHub {
    version = 3;
    owner = "rfjakob";
    repo = "eme";
    rev = "2222dbd4ba467ab3fc7e8af41562fcfe69c0d770";
    date = "2017-10-28";
    sha256 = "1saazrhj3jg4bkkyiy9l3z5r7b3gxmvdwxz0nhxc86czk93bdv8v";
    meta.useUnstable = true;
  };

  emoji = buildFromGitHub {
    version = 3;
    owner = "kyokomi";
    repo = "emoji";
    rev = "2e9a9507333f3ee28f3fab88c2c3aba34455d734";
    sha256 = "1x7h2yx4h4jkyw6hk74m60zy5yzkfd1qzjqbgmd5n60v81rj91kw";
    date = "2017-11-21";
  };

  encoding = buildFromGitHub {
    version = 2;
    owner = "jwilder";
    repo = "encoding";
    date = "2017-02-09";
    rev = "27894731927e49b0a9023f00312be26733744815";
    sha256 = "0sha9ghh6i9ca8bkw7qcjhppkb2dyyzh8zm760y4yi9i660r95h4";
  };

  environschema_v1 = buildFromGitHub {
    version = 3;
    owner = "juju";
    repo = "environschema";
    rev = "7359fc7857abe2b11b5b3e23811a9c64cb6b01e0";
    sha256 = "1z3527vn918hbqjbmx5ncpym3jb99pj4kf9fmx3yfd0q5pgp7byz";
    goPackagePath = "gopkg.in/juju/environschema.v1";
    date = "2015-11-04";
    propagatedBuildInputs = [
      crypto
      errgo_v1
      juju_errors
      schema
      utils
      yaml_v2
    ];
  };

  errgo_v1 = buildFromGitHub {
    version = 3;
    owner = "go-errgo";
    repo = "errgo";
    rev = "442357a80af5c6bf9b6d51ae791a39c3421004f3";
    sha256 = "11js1zci1wzagk2f6y53qg58x3y3iz3kcmi2044y94l37j6cbcni";
    date = "2016-12-22";
    goPackagePath = "gopkg.in/errgo.v1";
  };

  juju_errors = buildFromGitHub {
    version = 3;
    owner = "juju";
    repo = "errors";
    rev = "c7d06af17c68cd34c835053720b21f6549d9b0ee";
    sha256 = "0dxr8xkqd14zbvrbq9nz6zk0n2ki5s90gkgwhf47swgwr6107kn2";
    date = "2017-07-03";
  };

  errors = buildFromGitHub {
    version = 3;
    owner = "pkg";
    repo = "errors";
    rev = "f15c970de5b76fac0b59abb32d62c17cc7bed265";
    sha256 = "1mi0gkdz5kpyc72z49bsf1ziq9z4crak48r6ma7zzq8qj6631mkq";
    date = "2017-10-18";
  };

  errwrap = buildFromGitHub {
    version = 3;
    date = "2014-10-28";
    rev = "7554cd9344cec97297fa6649b055a8c98c2a1e55";
    owner  = "hashicorp";
    repo   = "errwrap";
    sha256 = "0b7wrwcy9w7im5dyzpwbl1bv3prk1lr5g54ws8lygvwrmzfi479h";
  };

  escaper = buildFromGitHub {
    version = 2;
    owner = "lucasem";
    repo = "escaper";
    rev = "17fe61c658dcbdcbf246c783f4f7dc97efde3a8b";
    sha256 = "1k0cbipikxxqc4im8dhkiq30ziakbld6h88vzr099c4x00qvpanf";
    goPackageAliases = [
      "github.com/10gen/escaper"
    ];
    date = "2016-08-02";
  };

  etcd = buildFromGitHub {
    version = 3;
    owner = "coreos";
    repo = "etcd";
    rev = "5b059acd653644c490563d071dfa6c148d49de69";
    sha256 = "0kcl22yv13iacvbndrs0a35crza77rd0zsph2arjjcibhlv0scrn";
    propagatedBuildInputs = [
      bbolt
      btree
      urfave_cli
      ccache
      clockwork
      cobra
      cmux
      crypto
      go-grpc-prometheus
      go-humanize
      go-semver
      go-systemd
      groupcache
      grpc
      grpc-gateway
      grpc-websocket-proxy
      jwt-go
      net
      pb_v1
      pflag
      pkg
      probing
      prometheus_client_golang
      protobuf
      gogo_protobuf
      pty
      speakeasy
      tablewriter
      time
      ugorji_go
      yaml

      pkgs.libpcap
    ];

    excludedPackages = "\\(test\\|benchmark\\|example\\|bridge\\)";
    meta.useUnstable = true;
    date = "2017-12-07";
  };

  etcd_client = etcd.override {
    subPackages = [
      "auth/authpb"
      "client"
      "clientv3"
      "clientv3/concurrency"
      "clientv3/naming"
      "etcdserver/api/v3rpc/rpctypes"
      "etcdserver/etcdserverpb"
      "mvcc/mvccpb"
      "pkg/fileutil"
      "pkg/pathutil"
      "pkg/srv"
      "pkg/tlsutil"
      "pkg/transport"
      "pkg/types"
      "version"
    ];
    buildInputs = [
      go-systemd
    ];
    propagatedBuildInputs = [
      go-semver
      grpc
      net
      pkg
      protobuf
      ugorji_go
    ];
  };

  etcd_for_swarmkit = etcd.override {
    subPackages = [
      "raft/raftpb"
    ];
    buildInputs = [
    ];
    propagatedBuildInputs = [
      protobuf
    ];
  };

  etree = buildFromGitHub {
    version = 3;
    owner = "beevik";
    repo = "etree";
    rev = "v1.0.0";
    sha256 = "0j56c7xqz8nm8nf4104b8y0gwqr2hg5y2fgp25w27h8b3xdmx8gd";
  };

  eventfd = buildFromGitHub {
    version = 3;
    owner = "gxed";
    repo = "eventfd";
    rev = "80a92cca79a8041496ccc9dd773fcb52a57ec6f9";
    date = "2016-09-16";
    sha256 = "0wqlyis4v3zfij34p4m6f0ji2jmpaby16qll17h2kp0372qsj6z3";
    propagatedBuildInputs = [
      goendian
    ];
  };

  ewma = buildFromGitHub {
    version = 3;
    owner = "VividCortex";
    repo = "ewma";
    rev = "43880d236f695d39c62cf7aa4ebd4508c258e6c0";
    date = "2017-08-04";
    sha256 = "0mdiahsdh61nbvdbzbf1p1rp13k08mcsw5xk75h8bn3smk3j8nrk";
    meta.useUnstable = true;
  };

  fastuuid = buildFromGitHub {
    version = 3;
    date = "2015-01-06";
    rev = "6724a57986aff9bff1a1770e9347036def7c89f6";
    owner  = "rogpeppe";
    repo   = "fastuuid";
    sha256 = "1q04xarwz0f2jlhz3d9myxx8ikrbynj5pyhhcsz25dc56kc2gpfz";
  };

  fileutil = buildFromGitHub {
    version = 3;
    date = "2017-11-07";
    rev = "2d566d841097e1297dfb576f809cf9eeecbdbc37";
    owner  = "cznic";
    repo   = "fileutil";
    sha256 = "014mkm63rjzmbsl3hpymsdm1bxxcrn3i6cjy5mnq0hs3c2fb3q8y";
    buildInputs = [
      mathutil
    ];
  };

  fileutils = buildFromGitHub {
    version = 3;
    date = "2017-11-03";
    rev = "7d4729fb36185a7c1719923406c9d40e54fb93c7";
    owner  = "mrunalp";
    repo   = "fileutils";
    sha256 = "0b2ba3bvx1pwbywq395nkgsvvc1rihiakk8nk6i6drsi6885wcdz";
  };

  flagfile = buildFromGitHub {
    version = 3;
    date = "2017-06-19";
    rev = "aec8f353c0832daeaeb6a1bd09a9bf6f8fc677ae";
    owner  = "spacemonkeygo";
    repo   = "flagfile";
    sha256 = "0vaqlmayva323hs7qyza1n7383d2ly2k0hv8p2j6jl4bid9w8jy0";
  };

  fnmatch = buildFromGitHub {
    version = 3;
    date = "2016-04-03";
    rev = "cbb64ac3d964b81592e64f957ad53df015803288";
    owner  = "danwakefield";
    repo   = "fnmatch";
    sha256 = "126zbs23kbv3zn5g60a2w6cdxjrhqplpn6h8rwvvhm8lss30bql6";
  };

  form = buildFromGitHub {
    version = 3;
    rev = "c4048f792f70d207e6d8b9c1bf52319247f202b8";
    date = "2015-11-09";
    owner = "gravitational";
    repo = "form";
    sha256 = "0800jqfkmy4h2pavi8lhjqca84kam9b1azgwvb6z4kpirbnchpy3";
  };

  fs = buildFromGitHub {
    version = 3;
    date = "2013-11-11";
    rev = "2788f0dbd16903de03cb8186e5c7d97b69ad387b";
    owner  = "kr";
    repo   = "fs";
    sha256 = "1pllnjm1q96fl3pp62c38jl97pvcrzmb8k641aqndik3794n9x71";
  };

  fsnotify = buildFromGitHub {
    version = 2;
    owner = "fsnotify";
    repo = "fsnotify";
    rev = "v1.4.2";
    sha256 = "1kbs526vl358dd9rrcdnniwnzhcxkbswkmkl80dl2sgi9x0w45g6";
    propagatedBuildInputs = [
      sys
    ];
  };

  fsnotify_v1 = buildFromGitHub {
    version = 2;
    owner = "fsnotify";
    repo = "fsnotify";
    rev = "v1.4.2";
    sha256 = "1f3zshxdd3kj08b87106gxj68fjljfb7b3r9i8xjrj0i79wy6phn";
    goPackagePath = "gopkg.in/fsnotify.v1";
    propagatedBuildInputs = [
      sys
    ];
  };

  fs-repo-migrations = buildFromGitHub {
    version = 3;
    owner = "ipfs";
    repo = "fs-repo-migrations";
    rev = "v1.3.0";
    sha256 = "1bnlj9hls8bhdcljn21y72g75p0qb768l4i51gib827ylhs9l0ww";
    propagatedBuildInputs = [
      goprocess
      go-homedir
      go-os-rename
      go-random
      go-random-files
      net
    ];
    postPatch = ''
      # Unvendor
      find . -name \*.go -exec sed -i 's,".*Godeps/_workspace/src/,",g' {} \;

      # Remove old, unused migrations
      sed -i 's,&mg[01234].Migration{},nil,g' main.go
      sed -i '/mg[01234]/d' main.go
    '';
    subPackages = [
      "."
      "go-migrate"
      "ipfs-1-to-2/lock"
      "ipfs-1-to-2/repolock"
      "ipfs-4-to-5/go-datastore"
      "ipfs-4-to-5/go-datastore/query"
      "ipfs-4-to-5/go-ds-flatfs"
      "ipfs-5-to-6/migration"
      "mfsr"
      "stump"
    ];
  };

  fsync = buildFromGitHub {
    version = 2;
    owner = "spf13";
    repo = "fsync";
    rev = "12a01e648f05a938100a26858d2d59a120307a18";
    date = "2017-03-20";
    sha256 = "1vn313i08byzsmzvq98xqb074iiz1fx7hi912gzbzwrzxk81bish";
    buildInputs = [
      afero
    ];
  };

  ftp = buildFromGitHub {
    version = 3;
    owner = "jlaffaye";
    repo = "ftp";
    rev = "299b7ff5b6096588cceca2edc1fc9f557002fb85";
    sha256 = "1mc57xlajkbsmgz7ccphnnb2jy53wlb09as6nqhhl4mm4nx0mhpx";
    date = "2017-09-27";
  };

  fuse = buildFromGitHub {
    version = 2;
    owner = "bazil";
    repo = "fuse";
    rev = "371fbbdaa8987b715bdd21d6adc4c9b20155f748";
    date = "2016-08-11";
    sha256 = "1f3cb9274f037e14c2437126fa17d39e6284f40f0ddb93b2dbb59d5bab6b97d0";
    goPackagePath = "bazil.org/fuse";
    propagatedBuildInputs = [
      net
      sys
    ];
  };

  fwd = buildFromGitHub {
    version = 3;
    date = "2017-09-05";
    rev = "bb6d471dc95d4fe11e432687f8b70ff496cf3136";
    owner  = "philhofer";
    repo   = "fwd";
    sha256 = "04q32rf415iv3lmjba19i1sb5lx8ji7453v0cxv35vcs3dxaxnzf";
  };

  gabs = buildFromGitHub {
    version = 3;
    owner = "Jeffail";
    repo = "gabs";
    rev = "44cbc27138518b15305cb3eef220d04f2d641b9b";
    sha256 = "0f1yqfk16xb11zliqclwjb24hg5jgr507awri21d3bzdi1ravlwp";
    date = "2017-10-15";
  };

  gateway = buildFromGitHub {
    version = 3;
    date = "2016-05-22";
    rev = "edad739645120eeb82866bc1901d3317b57909b1";
    owner  = "calmh";
    repo   = "gateway";
    sha256 = "0544gd2ic2fvq1jjxsz6wfh1xgb4x51my148h282xzmxd509d3jr";
    goPackageAliases = [
      "github.com/jackpal/gateway"
    ];
  };

  gax-go = buildFromGitHub {
    version = 3;
    rev = "v2.0.0";
    owner  = "googleapis";
    repo   = "gax-go";
    sha256 = "06b3nwksr80bmj83vf6m9mdm6q3555xjjjjhx0f8z0s92j6w0y64";
    propagatedBuildInputs = [
      grpc_for_gax-go
      net
    ];
  };

  genproto = buildFromGitHub {
    version = 3;
    date = "2017-11-23";
    rev = "7f0da29060c682909f650ad8ed4e515bd74fa12a";
    owner  = "google";
    repo   = "go-genproto";
    goPackagePath = "google.golang.org/genproto";
    sha256 = "01qay019n20qvg13f87frdv89awmxgwqx4sy8nx322wsvcarr78i";
    propagatedBuildInputs = [
      grpc
      net
      protobuf
    ];
  };

  genproto_protobuf = genproto.override {
    subPackages = [
      "protobuf"
    ];
    buildInputs = [
      protobuf_genproto
    ];
    propagatedBuildInputs = [
    ];
  };

  genproto_for_grpc = genproto.override {
    subPackages = [
      "googleapis/rpc/status"
    ];
    buildInputs = [
      protobuf
    ];
    propagatedBuildInputs = [
    ];
  };

  geoip2-golang = buildFromGitHub {
    version = 2;
    rev = "v1.1.0";
    owner = "oschwald";
    repo = "geoip2-golang";
    sha256 = "0qs7v3hbhih7a99nd9xqc5mz2bgdvhknlzv3hr15fd1w5w49yv1b";
    propagatedBuildInputs = [
      maxminddb-golang
    ];
  };

  gettext = buildFromGitHub {
    version = 2;
    rev = "v0.9";
    owner = "gosexy";
    repo = "gettext";
    sha256 = "1zrxfzwlv04gadxxyn8whmdin83ij735bbggxrnf3mcbxs8svs96";
    buildInputs = [
      go-flags
      go-runewidth
    ];
  };

  ginkgo = buildFromGitHub {
    version = 3;
    rev = "v1.4.0";
    owner = "onsi";
    repo = "ginkgo";
    sha256 = "1bbzwmy18lm2dj9javbn1blbiwz6jaqyz5g77g72i5ycd60my5kx";
    buildInputs = [
      sys
    ];
  };

  gitmap = buildFromGitHub {
    version = 3;
    rev = "de8030ebafb76c6e84d50ee6d143382637c00598";
    date = "2017-06-13";
    owner = "bep";
    repo = "gitmap";
    sha256 = "0r3h63lp98174p1d2qlnc3gc09hdc6gcj501sk85hlh3zr6iws6l";
  };

  gjson = buildFromGitHub {
    version = 3;
    owner = "tidwall";
    repo = "gjson";
    rev = "v1.0.3";
    sha256 = "0g63py8ryjlydannxbjxilvq08qxg84pplfsfw5xy50b1arfqbq3";
    propagatedBuildInputs = [
      match
    ];
  };

  glob = buildFromGitHub {
    version = 2;
    rev = "v0.2.2";
    owner = "gobwas";
    repo = "glob";
    sha256 = "1mzn45p24qn7qdagfb9mlj96jlmwk3kgk637kxnb4qaqnl8bkkh1";
  };

  gmsm = buildFromGitHub {
    version = 3;
    rev = "v1.1";
    owner = "tjfoc";
    repo = "gmsm";
    sha256 = "10pygy31wfcfq2gxi3r3zmqybaw4agmch8r3siiyyps92bhjzzrx";
    propagatedBuildInputs = [
      crypto
    ];
  };

  gnostic = buildFromGitHub {
    version = 3;
    rev = "v0.1.0";
    owner = "googleapis";
    repo = "gnostic";
    sha256 = "0maql4kfc6q303lxz7pldjbh3k65pkw9yczxsg7285srmf7yp5s6";
    excludedPackages = "tools";
    propagatedBuildInputs = [
      docopt-go
      protobuf
      yaml_v2
    ];
  };

  json-iterator_go = buildFromGitHub {
    version = 3;
    rev = "1.0.4";
    owner = "json-iterator";
    repo = "go";
    sha256 = "04k5bcdrrpff1vcl9h03l0wlkwd51za5sw2iwbq43ds0xkw4qdaj";
    excludedPackages = "test";
  };

  siddontang_go = buildFromGitHub {
    version = 3;
    date = "2017-05-17";
    rev = "cb568a3e5cc06256f91a2da5a87455f717eb33f4";
    owner = "siddontang";
    repo = "go";
    sha256 = "0g5k8gv7fmviyxpbxa6y05r5hfhchs8gas5idgcf8ahfgkv4x9i5";
  };

  ugorji_go = buildFromGitHub {
    version = 3;
    date = "2017-12-03";
    rev = "f0aa215a7d653544d39d0e27dfa10fa4b183f397";
    owner = "ugorji";
    repo = "go";
    sha256 = "0iyfkihkqqxm89q3c0bj5j9a9zs0kn4h20vijicg1m33iy5szbh6";
    goPackageAliases = [
      "github.com/hashicorp/go-msgpack"
    ];
  };

  go-acd = buildFromGitHub {
    version = 3;
    owner = "ncw";
    repo = "go-acd";
    rev = "887eb06ab6a255fbf5744b5812788e884078620a";
    date = "2017-11-20";
    sha256 = "14b1fsxnkxf70sli2lg613qx1mfsl093ddwshyczr6fx8j6j084y";
    propagatedBuildInputs = [
      go-querystring
    ];
  };

  go-addr-util = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-addr-util";
    rev = "41df61455dd66ee92799dcc2652543bc89632f3c";
    date = "2017-12-06";
    sha256 = "0wzzbvn10gxa730iaz9nwa0wyy33p81lag38f3x936dsd8jbyixz";
    propagatedBuildInputs = [
      go-log
      go-ws-transport
      go-multiaddr
      go-multiaddr-net
      mafmt
    ];
  };

  go-ansiterm = buildFromGitHub {
    version = 3;
    owner = "Azure";
    repo = "go-ansiterm";
    rev = "d6e3b3328b783f23731bc4d058875b0371ff8109";
    date = "2017-09-29";
    sha256 = "1ckr3942pr6xlw9na5ndzs2vlsi412g7vk5bcf6nsr021k0mq0wb";
    buildInputs = [
      logrus
    ];
  };

  go-httpclient = buildFromGitHub {
    version = 2;
    owner = "mreiferson";
    repo = "go-httpclient";
    rev = "31f0106b4474f14bc441575c19d3a5fa21aa1f6c";
    date = "2016-06-30";
    sha256 = "e9fb80be94f61a8df23ee201be2988688cceba4d1c7339b60b955a66daebd3e3";
  };

  go4 = buildFromGitHub {
    version = 3;
    date = "2017-05-25";
    rev = "034d17a462f7b2dcd1a4a73553ec5357ff6e6c6e";
    owner = "camlistore";
    repo = "go4";
    sha256 = "0pfa73nh0gznyljipflnyzaimvrznarx5fmkjajnj3r3vf2gnwj4";
    goPackagePath = "go4.org";
    goPackageAliases = [
      "github.com/camlistore/go4"
      "github.com/juju/go4"
    ];
    buildInputs = [
      google-api-go-client
      google-cloud-go
      oauth2
      net
      sys
    ];
  };

  gocapability = buildFromGitHub {
    version = 3;
    rev = "db04d3cc01c8b54962a58ec7e491717d06cfcc16";
    owner = "syndtr";
    repo = "gocapability";
    sha256 = "1nv9lnriwgnwqh2pd5cg884w1v9vmj8vzxfv4p4pilvzlz3aid6x";
    date = "2017-07-04";
  };

  gocql = buildFromGitHub {
    version = 3;
    rev = "9ce8b08dfa5559eb86592129986654503cf40cf7";
    owner  = "gocql";
    repo   = "gocql";
    sha256 = "0hz3vyz0264vr8f137bhs47rns2jzshx9mf6yac4a81iv9pz8nkd";
    propagatedBuildInputs = [
      inf_v0
      snappy
      hailocab_go-hostpool
      net
    ];
    date = "2017-12-07";
  };

  godo = buildFromGitHub {
    version = 3;
    rev = "v1.1.1";
    owner  = "digitalocean";
    repo   = "godo";
    sha256 = "1b9jbp6ynw9jwhg8v7qpxf3hh8akfisc12ags1ac9mriaq38icz5";
    propagatedBuildInputs = [
      go-querystring
      http-link-go
      net
    ];
  };

  goendian = buildFromGitHub {
    version = 3;
    rev = "0f5c6873267e5abf306ffcdfcfa4bf77517ef4a7";
    owner  = "gxed";
    repo   = "GoEndian";
    sha256 = "1h05p9xlfayfjj00yjkggbwhsb3m52l5jdgsffs518p9fsddwbfy";
    date = "2016-09-16";
  };

  gofuzz = buildFromGitHub {
    version = 3;
    rev = "24818f796faf91cd76ec7bddd72458fbced7a6c1";
    owner  = "google";
    repo   = "gofuzz";
    sha256 = "1ghcx5q9vsgmknl9954cp4ilgayfkg937c1z4m3lqr41fkma9zgi";
    date = "2017-06-12";
  };

  gohistogram = buildFromGitHub {
    version = 3;
    rev = "v1.0.0";
    owner  = "VividCortex";
    repo   = "gohistogram";
    sha256 = "02bikhfr47gp4ww9mmz9pz6q4g6293z0fn8kd83kn0i12x0s8b2l";
  };

  goid = buildFromGitHub {
    version = 3;
    rev = "3db12ebb2a599ba4a96bea1c17b61c2f78a40e02";
    owner  = "petermattis";
    repo   = "goid";
    sha256 = "1ylv8w0sa8bc7w5sf1sd8i7dsiba2zm1fp0mjlcg0g0jlbhqgqg9";
    date = "2017-08-16";
  };

  gojsondiff = buildFromGitHub {
    version = 3;
    rev = "e21612694bdd50975f93cd5eaccb457477128e28";
    owner  = "yudai";
    repo   = "gojsondiff";
    sha256 = "0q42kycm8mkchg78j8rlwjd8qb5d6cb0v3iv204vd6wiidyh76a6";
    date = "2017-11-26";
    propagatedBuildInputs = [
      urfave_cli
      go-diff
      golcs
    ];
    excludedPackages = "test";
  };

  gojsonpointer = buildFromGitHub {
    version = 2;
    rev = "6fe8760cad3569743d51ddbb243b26f8456742dc";
    owner  = "xeipuuv";
    repo   = "gojsonpointer";
    sha256 = "0gfg90ibq0f6smmysj5svn1b04a39sc4w7xw38rgr4kyszhv4zj5";
    date = "2017-02-25";
  };

  gojsonreference = buildFromGitHub {
    version = 3;
    rev = "e02fc20de94c78484cd5ffb007f8af96be030a45";
    owner  = "xeipuuv";
    repo   = "gojsonreference";
    sha256 = "1m3cg70vdn5vmwpxpgb85igsm60vaxdh52agmx899ig9ir9k9xb7";
    date = "2015-08-08";
    propagatedBuildInputs = [ gojsonpointer ];
  };

  gojsonschema = buildFromGitHub {
    version = 3;
    rev = "212d8a0df7acfab8bdd190a7a69f0ab7376edcc8";
    owner  = "xeipuuv";
    repo   = "gojsonschema";
    sha256 = "06jn9zbx1f9mabf1axk78l70h15wdzm39qbqlm29f9bc30hfiykz";
    date = "2017-10-25";
    propagatedBuildInputs = [ gojsonreference ];
  };

  gomail_v2 = buildFromGitHub {
    version = 3;
    rev = "81ebce5c23dfd25c6c67194b37d3dd3f338c98b1";
    date = "2016-04-11";
    owner = "go-gomail";
    repo = "gomail";
    sha256 = "0akjvnrwqipl67rjg0aab0wiqn904d4rszpscgkjw23i1h2h9v3y";
    goPackagePath = "gopkg.in/gomail.v2";
    propagatedBuildInputs = [
      quotedprintable_v3
    ];
  };

  gomemcache = buildFromGitHub {
    version = 2;
    rev = "1952afaa557dc08e8e0d89eafab110fb501c1a2b";
    date = "2017-02-08";
    owner = "bradfitz";
    repo = "gomemcache";
    sha256 = "1h1sjgjv4ay6y26g25vg2q0iawmw8fnlam7r66qiq0hclzb72fcn";
  };

  gomemcached = buildFromGitHub {
    version = 3;
    rev = "56481a09982ccef7e3e408a3b97dd818821f42f2";
    date = "2017-11-20";
    owner = "couchbase";
    repo = "gomemcached";
    sha256 = "11xw7s9szxlcdwmn8m3fix1q3fbr4kjw3j0gcrhn9157xih7mfkl";
    excludedPackages = "mocks";
    propagatedBuildInputs = [
      crypto
      goutils_logging
    ];
  };

  gopacket = buildFromGitHub {
    version = 3;
    rev = "v1.1.14";
    owner = "google";
    repo = "gopacket";
    sha256 = "0z68x9isjd4l7rxdb6zwq0qf52b5k1vc48v23j9gws3rgvq046wv";
    buildInputs = [
      pkgs.libpcap
      pkgs.pf-ring
    ];
    propagatedBuildInputs = [
      net
      sys
    ];
  };

  gophercloud = buildFromGitHub {
    version = 3;
    rev = "b63d2fd36f5dae9723e73696248abca95d6b8dc6";
    owner = "gophercloud";
    repo = "gophercloud";
    sha256 = "0dhvjv0r2jgcp6l9zkxpj2i3lxd3bc2gndcqlbhhx7m1dlva6kmk";
    date = "2017-12-07";
    excludedPackages = "test";
    propagatedBuildInputs = [
      crypto
      yaml_v2
    ];
  };

  google-cloud-go = buildFromGitHub {
    version = 3;
    date = "2017-12-07";
    rev = "9cfa4d03ec0eb9e3ee4ac57c10654e23195fe7cc";
    owner = "GoogleCloudPlatform";
    repo = "google-cloud-go";
    sha256 = "1h6bqsbwyryb9lky87639wvw0k5c347m00qhn1975wnbqncbm4fr";
    goPackagePath = "cloud.google.com/go";
    goPackageAliases = [
      "google.golang.org/cloud"
    ];
    propagatedBuildInputs = [
      debug
      gax-go
      genproto
      geo
      glog
      go-cmp
      google-api-go-client
      grpc
      net
      oauth2
      opencensus
      pprof
      protobuf
      sync
      text
      time
    ];
    postPatch = ''
      sed -i 's,bundler.Close,bundler.Stop,g' logging/logging.go
    '';
    excludedPackages = "\\(oauth2\\|readme\\|mocks\\)";
    meta.useUnstable = true;
  };

  google-cloud-go-compute-metadata = buildFromGitHub {
    inherit (google-cloud-go) rev date owner repo sha256 version goPackagePath goPackageAliases meta;
    subPackages = [
      "compute/metadata"
    ];
    propagatedBuildInputs = [
      net
    ];
  };

  gopcap = buildFromGitHub {
    version = 2;
    rev = "00e11033259acb75598ba416495bb708d864a010";
    date = "2015-07-28";
    owner = "akrennmair";
    repo = "gopcap";
    sha256 = "189skp51bd7aqpqs63z20xqm0pj5dra23g51m993rbq81zsvp0yq";
    buildInputs = [
      pkgs.libpcap
    ];
  };

  goprocess = buildFromGitHub {
    version = 2;
    rev = "b497e2f366b8624394fb2e89c10ab607bebdde0b";
    date = "2016-08-25";
    owner = "jbenet";
    repo = "goprocess";
    sha256 = "1i4spw84hlka1l8xxizpiqklsqyc3hxxjz3wbpn3i2ql68raylbx";
  };

  gops = buildFromGitHub {
    version = 3;
    rev = "f4d96179f364c59b5d8feea7256072857f61d501";
    owner = "google";
    repo = "gops";
    sha256 = "00hjz7r12sskz9y2521a08z0xvbnki2smzwd24s0w7yqaw6nzsgy";
    propagatedBuildInputs = [
      keybase_go-ps
      goversion
      osext
    ];
    meta.useUnstable = true;
    date = "2017-12-03";
  };

  goredis = buildFromGitHub {
    version = 3;
    rev = "760763f78400635ed7b9b115511b8ed06035e908";
    date = "2015-03-24";
    owner = "siddontang";
    repo = "goredis";
    sha256 = "0aqjid0i649s1h4wi704hvf6yfyzjp8c06vng43pp0r4vyi27b5z";
  };

  gorelic = buildFromGitHub {
    version = 2;
    rev = "ae09aa139a2b7f638e2412baceaceebd41eff115";
    date = "2016-06-16";
    owner = "yvasiyarov";
    repo = "gorelic";
    sha256 = "1x9hd2hlq796lf87h1jipqrf7vj7c1qxmg49f3qk5s4cvs5gzb5m";
  };

  goreq = buildFromGitHub {
    version = 3;
    rev = "bcd34c9993f899273c74baaa95e15386cd97b6e7";
    date = "2017-12-04";
    owner = "franela";
    repo = "goreq";
    sha256 = "1j2283fmx3d870kgffnr7gjkbzxaf57a58whv4aar7hs10sj9hx5";
  };

  goterm = buildFromGitHub {
    version = 3;
    rev = "ef0fa5b75d0fa2b31323463783a6e90353771116";
    date = "2017-11-30";
    owner = "buger";
    repo = "goterm";
    sha256 = "12mm3nzlspl4r130xw6d1lb7ywwvr8p55d5s4zh98v2dbh8p6i8l";
  };

  gotty = buildFromGitHub {
    version = 2;
    rev = "cd527374f1e5bff4938207604a14f2e38a9cf512";
    date = "2012-06-04";
    owner = "Nvveen";
    repo = "Gotty";
    sha256 = "16slr2a0mzv2bi90s5pzmb6is6h2dagfr477y7g1s89ag1dcayp8";
  };

  goutils = buildFromGitHub {
    version = 3;
    rev = "7a02f3df0ea980574216f469c192985a2083b957";
    date = "2017-07-06";
    owner = "couchbase";
    repo = "goutils";
    sha256 = "0hyy5clkj4rdad4s3prpdwks602p7ss0ag30kxaqvn31hppm9szl";
    buildInputs = [
      cbauth
      go-couchbase
      gomemcached
    ];
  };

  goutils_logging = buildFromGitHub {
    inherit (goutils) rev date owner repo sha256 version;
    subPackages = [
      "logging"
    ];
  };

  golang-lru = buildFromGitHub {
    version = 3;
    date = "2016-08-13";
    rev = "0a025b7e63adc15a622f29b0b2c4c3848243bbf6";
    owner  = "hashicorp";
    repo   = "golang-lru";
    sha256 = "0gpksyhyrjhms5q4xsknnihjbadikrbhw809lhsxrkh41vklgy68";
  };

  golang-petname = buildFromGitHub {
    version = 3;
    rev = "d3c2ba80e75eeef10c5cf2fc76d2c809637376b3";
    owner  = "dustinkirkland";
    repo   = "golang-petname";
    sha256 = "00vrvfmrx3d20q029iaimi1qk5iwv68cmqm740pi0qzklxv0007f";
    date = "2017-09-21";
  };

  golang-text = buildFromGitHub {
    version = 2;
    rev = "048ed3d792f7104850acbc8cfc01e5a6070f4c04";
    owner  = "tonnerre";
    repo   = "golang-text";
    sha256 = "188nzg7dcr3xl8ipgdiks6h3wxi51391y4jza4jcbvw1z1mi7iig";
    date = "2013-09-25";
    propagatedBuildInputs = [
      pty
      kr_text
    ];
    meta.useUnstable = true;
  };

  golang_protobuf_extensions = buildFromGitHub {
    version = 3;
    rev = "v1.0.0";
    owner  = "matttproud";
    repo   = "golang_protobuf_extensions";
    sha256 = "10gbh8lfcsvfs0a5fbr8rfl3s375bb4l2890h2v4qm3yf5d7mz6x";
    buildInputs = [ protobuf ];
  };

  golcs = buildFromGitHub {
    version = 3;
    rev = "ecda9a501e8220fae3b4b600c3db4b0ba22cfc68";
    date = "2017-03-16";
    owner = "yudai";
    repo = "golcs";
    sha256 = "183cdzwfi0wif082j6w09zr7446sa2kgg6bc7lrhdnh5nvlj3ly0";
  };

  goleveldb = buildFromGitHub {
    version = 3;
    rev = "adf24ef3f94bd13ec4163060b21a5678f22b429b";
    date = "2017-11-20";
    owner = "syndtr";
    repo = "goleveldb";
    sha256 = "1l1jpjdziai4i9lqsrnxz6vfyv3w4apm5z4gnh5myns3kdjwya6l";
    propagatedBuildInputs = [
      ginkgo
      gomega
      snappy
    ];
  };

  golex = buildFromGitHub {
    version = 3;
    rev = "4ab7c5e190e49208c823ce8ec803aa39e6a4b31a";
    date = "2017-08-03";
    owner = "cznic";
    repo = "golex";
    sha256 = "02hk6gqr5559v7iz88p14l61h11a111kab391as61xwjhr1pplxa";
    propagatedBuildInputs = [
      lex
      lexer
    ];
  };

  gomega = buildFromGitHub {
    version = 3;
    rev = "v1.2.0";
    owner  = "onsi";
    repo   = "gomega";
    sha256 = "114sz7v0cbdal40jhp8zrzqggws4hnlwrcfbix7hcc9811h8nmp1";
    propagatedBuildInputs = [
      net
      protobuf
      yaml_v2
    ];
  };

  google-api-go-client = buildGoPackage rec {
    name = nameFunc {
      inherit
        goPackagePath
        rev;
      date = "2017-12-08";
    };
    rev = "fb1d4474b70b485b7facc09bff19c312dec8b7be";
    goPackagePath = "google.golang.org/api";
    src = fetchzip {
      version = 3;
      stripRoot = false;
      purgeTimestamps = true;
      inherit name;
      url = "https://code.googlesource.com/google-api-go-client/+archive/${rev}.tar.gz";
      sha256 = "1hgd3dmi51v4kbvp2v0wlgrwqcs0mj6ihxv2ksbqf2dih6lfzyk2";
    };
    buildInputs = [
      appengine
      genproto
      grpc
      net
      oauth2
      sync
    ];
  };

  goorgeous = buildFromGitHub {
    version = 3;
    rev = "dcf1ef873b8987bf12596fe6951c48347986eb2f";
    owner = "chaseadamsio";
    repo = "goorgeous";
    sha256 = "012d2j1gxzw4d1vkmbf85gy66v1ynd7mvagfick5h6b32c8mgsz1";
    propagatedBuildInputs = [
      blackfriday
      sanitized-anchor-name
    ];
    meta.useUnstable = true;
    date = "2017-11-26";
  };

  gopass = buildFromGitHub {
    version = 2;
    date = "2017-01-09";
    rev = "bf9dde6d0d2c004a008c27aaee91170c786f6db8";
    owner = "howeyc";
    repo = "gopass";
    sha256 = "0chij9mja3pwgmyvjcbp86xh9h9v1ljgpvscph6jxa1k1pp9dfah";
    propagatedBuildInputs = [
      crypto
      sys
    ];
  };

  gopsutil = buildFromGitHub {
    version = 3;
    rev = "v2.17.11";
    owner  = "shirou";
    repo   = "gopsutil";
    sha256 = "1x5wa25zxgmphq8615wly6sx3b97gl53wni366v5g1zh67vkbk53";
    buildInputs = [
      sys
      w32
      wmi
    ];
  };

  goquery = buildFromGitHub {
    version = 3;
    rev = "bc4e06eb0792d1a14661d19dd7822163c25bb6bd";
    owner  = "PuerkitoBio";
    repo   = "goquery";
    sha256 = "07p7xvz9626hrzm37j5r2r2jzdr2nqvz4m9ihhbkw2svmr0x37dm";
    propagatedBuildInputs = [
      cascadia
      net
    ];
    date = "2017-12-06";
  };

  gosaml2 = buildFromGitHub {
    version = 3;
    rev = "8908227c114abe0b63b1f0606abae72d11bf632a";
    owner  = "russellhaering";
    repo   = "gosaml2";
    sha256 = "ebc793728bfb3f10c7aecedaf1831d4ea77c9c6f9572d374b02ca683ec531633";
    date = "2017-05-15";
    excludedPackages = "test";
    propagatedBuildInputs = [
      etree
      goxmldsig
      satori_go-uuid
    ];
    meta.autoUpdate = false;
  };

  goskiplist = buildFromGitHub {
    version = 3;
    rev = "2dfbae5fcf46374f166f8969cb07e167f1be6273";
    owner  = "ryszard";
    repo   = "goskiplist";
    sha256 = "1znb1ldiffvvlakisi9k24xj2rlglyd696gc3zpys6dbl906ywvs";
    date = "2015-03-12";
  };

  gotask = buildFromGitHub {
    version = 3;
    rev = "104f8017a5972e8175597652dcf5a730d686b6aa";
    owner  = "jingweno";
    repo   = "gotask";
    sha256 = "0anv7mxsihy9y8g0fin93afs380b0j9hjsay6y9y0f72cmry68ql";
    date = "2014-01-12";
    propagatedBuildInputs = [
      urfave_cli
      go-shellquote
    ];
  };

  goupnp = buildFromGitHub {
    version = 3;
    rev = "dceda08e705b2acee36aab47d765ed801f64cfc7";
    owner  = "huin";
    repo   = "goupnp";
    sha256 = "0d69r7pn3yr8khdsyy4ax00vf7dpbb96fdndbj5z97mmwliz6dmn";
    date = "2017-11-09";
    propagatedBuildInputs = [
      goutil
      gotask
      net
    ];
  };

  goutil = buildFromGitHub {
    version = 3;
    rev = "1ca381bf315033e89af3286fdec0109ce8d86126";
    owner  = "huin";
    repo   = "goutil";
    sha256 = "0f3p0aigiappv130zvy94ia3j8qinz4di7akxsm09f0k1cblb82f";
    date = "2017-08-03";
  };

  govalidator = buildFromGitHub {
    version = 3;
    rev = "852d82c746b23d9b357b210ea470d99f4e023b72";
    owner = "asaskevich";
    repo = "govalidator";
    sha256 = "19rxfhld9jicymzbx3jbb9scxr5v6hzqib0cnjddy15izklwa551";
    date = "2017-11-28";
  };

  goversion = buildFromGitHub {
    version = 3;
    rev = "v1.0.0";
    owner = "rsc";
    repo = "goversion";
    sha256 = "1f9himpsm4w4m4zngzhs055accri8144rdhixx13mrv72w771vbr";
    goPackagePath = "rsc.io/goversion";
  };

  goxmldsig = buildFromGitHub {
    version = 3;
    rev = "b7efc6231e45b10bfd779852831c8bb59b350ec5";
    owner  = "russellhaering";
    repo   = "goxmldsig";
    sha256 = "1dz7rzxwk47hifdng3g7jc5cvy2sslaqa2rxnwc7d6kdid71li8c";
    date = "2017-09-11";
    propagatedBuildInputs = [
      clockwork
      etree
    ];
  };

  go-autorest = buildFromGitHub {
    version = 3;
    rev = "v9.5.0";
    owner  = "Azure";
    repo   = "go-autorest";
    sha256 = "1g1ikbkg0v3axxcfrvq8a1xk74ay4xdrlk9772ra47qn1rxh1vc1";
    propagatedBuildInputs = [
      jwt-go
      utfbom
    ];
    excludedPackages = "\\(cli\\|cmd\\|example\\)";
  };

  go-base58 = buildFromGitHub {
    version = 3;
    rev = "1.0.0";
    owner  = "jbenet";
    repo   = "go-base58";
    sha256 = "0isr59slw0q9byms6v404ylv2d0im30iicxg0hbkvh3badmk15br";
  };

  go-bindata-assetfs = buildFromGitHub {
    version = 2;
    rev = "30f82fa23fd844bd5bb1e5f216db87fd77b5eb43";
    owner   = "elazarl";
    repo    = "go-bindata-assetfs";
    sha256 = "0pval4z7k1bbcdx1hqd4cw9x5l01pikkya0n61c4wrfi0ghx25ln";
    date = "2017-02-27";
  };

  go-bits = buildFromGitHub {
    version = 2;
    owner = "dgryski";
    repo = "go-bits";
    date = "2016-06-01";
    rev = "2ad8d707cc05b1815ce6ff2543bb5e8d8f9298ef";
    sha256 = "d77d906fb806bb9bd9af7f54f0c3277d6b86d84015e198cb367f1d7788c8b938";
  };

  go-bitstream = buildFromGitHub {
    version = 2;
    owner = "dgryski";
    repo = "go-bitstream";
    date = "2016-07-01";
    rev = "7d46cd22db7004f0cceb6f7975824b560cf0e486";
    sha256 = "32a82d1220c6d2ec05cf2d6150ed8f2a3ce6c544f626cc7574acaa57e31bbd9c";
  };

  go-buffruneio = buildFromGitHub {
    version = 2;
    owner = "pelletier";
    repo = "go-buffruneio";
    rev = "v0.2.0";
    sha256 = "080mjg20yp2h04pk5g2ls3jg7z2h80wjj0qv254k2hga63xkk3k6";
  };

  go-cache = buildFromGitHub {
    version = 3;
    rev = "v2.1.0";
    owner = "patrickmn";
    repo = "go-cache";
    sha256 = "16kdcibb8z4bnjr27nlv2y8piz3yri2q9srn872q50ny0f1yj8ib";
  };

  go-checkpoint = buildFromGitHub {
    version = 3;
    date = "2017-10-09";
    rev = "1545e56e46dec3bba264e41fde2c1e2aa65b5dd4";
    owner  = "hashicorp";
    repo   = "go-checkpoint";
    sha256 = "0gq3z0fqwff36bf60vs5yjrcnp57w4h72ap5wgfkmlg7m0y3pn3m";
    propagatedBuildInputs = [
      go-cleanhttp
      hashicorp_go-uuid
    ];
  };

  go-cid = buildFromGitHub {
    version = 3;
    date = "2017-12-05";
    rev = "1805dd530f03dcdf288e47db67f5dd556736f677";
    owner = "ipfs";
    repo = "go-cid";
    sha256 = "1q9v5lh7v6qd4j6sf0szcxhzplscikb80s6d9lmc7j73havx8s0s";
    propagatedBuildInputs = [
      go-multibase
      go-multihash
    ];
  };

  go-cleanhttp = buildFromGitHub {
    version = 3;
    date = "2017-11-30";
    rev = "06c9ea3a335b7443026f8124b22619524420291b";
    owner = "hashicorp";
    repo = "go-cleanhttp";
    sha256 = "0gwcgyzdqimzpbvdj78zmrr9npmggzw8m2qri3r1qa6w7lg3bdlm";
  };

  go-cmp = buildFromGitHub {
    version = 3;
    rev = "v0.1.0";
    owner  = "google";
    repo   = "go-cmp";
    sha256 = "1z9kypq5yj9asmxmnk9rlsr4f7ghqbgvs7vljf0pg5fac4kbqdjp";
  };

  go-collectd = buildFromGitHub {
    version = 2;
    owner = "collectd";
    repo = "go-collectd";
    rev = "bf0e31aeedfea7fb13f821e0831cfe2b5974d1e9";
    sha256 = "1zz7l4cz9pasnnj3gjc43skw481rxncflsyvyw7n0k4aawklr14b";
    goPackagePath = "collectd.org";
    buildInputs = [
      grpc
      net
      pkgs.collectd
      protobuf
    ];
    preBuild = ''
      # Regerate protos
      srcDir="$(pwd)"/go/src
      pushd go/src/$goPackagePath >/dev/null
      find . -name \*pb.go -delete
      for file in $(find . -name \*.proto | sort | uniq); do
        pushd "$(dirname "$file")" > /dev/null
        echo "Regenerating protobuf: $file" >&2
        protoc -I "$srcDir" -I "$srcDir/$goPackagePath" -I . --go_out=plugins=grpc:. "$(basename "$file")"
        popd >/dev/null
      done
      popd >/dev/null

      # Create a config.h and proper headers
      export COLLECTD_SRC="$(pwd)/collectd-src"
      mkdir -pv "$COLLECTD_SRC"
      pushd "$COLLECTD_SRC" >/dev/null
        unpackFile "${pkgs.collectd.src}"
      popd >/dev/null
      srcdir="$(echo "$COLLECTD_SRC"/collectd-*)"
      # Run configure to generate config.h
      pushd "$srcdir" >/dev/null
        ./configure
      popd >/dev/null
      export CGO_CPPFLAGS="-I$srcdir/src/daemon -I$srcdir/src"
    '';
    date = "2017-04-11";
  };

  go-colorable = buildFromGitHub {
    version = 3;
    rev = "v0.0.9";
    owner  = "mattn";
    repo   = "go-colorable";
    sha256 = "18izn70blaqxynn8448g05brw3qf98fgp9i5p1mqmwfxnsp9zal1";
    propagatedBuildInputs = [
      go-isatty
    ];
  };

  go-connections = buildFromGitHub {
    version = 3;
    rev = "v0.3.0";
    owner  = "docker";
    repo   = "go-connections";
    sha256 = "0lvkfmkah8yjjq582lxdb6ghpcfc8j2yw8iz19l9v98i6csgcamy";
    propagatedBuildInputs = [
      errors
      go-winio
      logrus
      net
      runc
    ];
  };

  go-couchbase = buildFromGitHub {
    version = 3;
    rev = "b2479ad629a58de79501b021497525f0ea27e226";
    owner  = "couchbase";
    repo   = "go-couchbase";
    sha256 = "15pdxiwhwl8j21f2gzgzrrbi77x7mz2kf1cr8rq584z4iwfgb16k";
    date = "2017-10-09";
    goPackageAliases = [
      "github.com/couchbaselabs/go-couchbase"
    ];
    propagatedBuildInputs = [
      gomemcached
      goutils_logging
    ];
    excludedPackages = "\\(perf\\|example\\)";
  };

  davidlazar_go-crypto = buildFromGitHub {
    version = 3;
    rev = "dcfb0a7ac018a248366f96bcd8a2f8c805d7b268";
    owner  = "davidlazar";
    repo   = "go-crypto";
    sha256 = "1hza8ikvhqp74qhydi7fndcn4j1049g698cbm1jv4xg2gz0mlcdx";
    date = "2017-07-01";
    propagatedBuildInputs = [
      crypto
    ];
  };

  keybase_go-crypto = buildFromGitHub {
    version = 3;
    rev = "80dd18f19f35c6b2e3b56254e397c36d07d9d285";
    owner  = "keybase";
    repo   = "go-crypto";
    sha256 = "1q80drcygnyl7qg4p75l3k7mhwarwn41rr2f1l7vd8lyms138a78";
    date = "2017-11-30";
    propagatedBuildInputs = [
      ed25519
    ];
  };

  go-deadlock = buildFromGitHub {
    version = 3;
    rev = "03d40e5dbd5488667a13b3c2600b2f7c2886f02f";
    owner  = "sasha-s";
    repo   = "go-deadlock";
    sha256 = "0blwxc33mwz44l3w10ljv6p0793pj27spii4nisaxvqydy7irzmi";
    date = "2017-11-30";
    propagatedBuildInputs = [
      goid
    ];
  };

  go-diff = buildFromGitHub {
    version = 3;
    rev = "1744e2970ca51c86172c8190fadad617561ed6e7";
    owner  = "sergi";
    repo   = "go-diff";
    sha256 = "1c4i9qk6z3882v96d7pp3vqvxgh51p7z4h3w8cgrpf6lz5zw91qv";
    date = "2017-11-10";
  };

  go-discover = buildFromGitHub {
    version = 3;
    rev = "ec0cf28946abe5acceeaaf29be7c64a6a4d529cb";
    owner  = "hashicorp";
    repo   = "go-discover";
    sha256 = "0kcx9axbdl6n4sisqqkhs7915nni3wvj6w6dq1xa7gvh41g7vzhi";
    date = "2017-11-15";
    propagatedBuildInputs = [
      aliyungo
      aws-sdk-go
      #azure-sdk-for-go
      #go-autorest
      godo
      google-api-go-client
      gophercloud
      oauth2
      scaleway-sdk
      softlayer-go
    ];
    postPatch = ''
      rm -r provider/azure
      sed -i '/azure"/d' discover.go
    '';
  };

  go-difflib = buildFromGitHub {
    version = 3;
    rev = "v1.0.0";
    owner  = "pmezard";
    repo   = "go-difflib";
    sha256 = "1ypgp0akc22spz4j87cx9pih5wbvbsrk31sli3crjzfgbll5hx4i";
  };

  go-digest = buildFromGitHub {
    version = 3;
    rev = "279bed98673dd5bef374d3b6e4b09e2af76183bf";
    owner  = "opencontainers";
    repo   = "go-digest";
    sha256 = "10fbcg0fj2fawbv25gldj4xwjy14qz0dkrzkhbgmrc0za9k6qwv8";
    date = "2017-06-07";
    goPackageAliases = [
      "github.com/docker/distribution/digest"
    ];
  };

  go-dockerclient = buildFromGitHub {
    version = 3;
    date = "2017-12-07";
    rev = "df0587029c84fb4b7dc88444ea63deb665cfedef";
    owner = "fsouza";
    repo = "go-dockerclient";
    sha256 = "09h525gg6dqam7hnyw90ym1iv0xqnr78p5h08z21rdaiib3x8273";
    propagatedBuildInputs = [
      go-cleanhttp
      go-units
      go-winio
      moby_lib
      mux
      net
    ];
  };

  go-envparse = buildFromGitHub {
    version = 3;
    rev = "7af148db102f1bb91eb8c7c459f1e388688a4426";
    owner  = "hashicorp";
    repo   = "go-envparse";
    sha256 = "04l934fxwa95zdx5mb1xhqzhrszw86lb8h235xhyb5gd6v98n9gf";
    date = "2017-06-02";
  };

  go-errors = buildFromGitHub {
    version = 3;
    date = "2017-11-01";
    rev = "3afebba5a48dbc89b574d890b6b34d9ee10b4785";
    owner  = "go-errors";
    repo   = "errors";
    sha256 = "13n1vz7i43621h59836f1lw545kkhm5ddhycabq4ld76n0jll90l";
  };

  go-etcd = buildFromGitHub {
    version = 2;
    date = "2015-10-26";
    rev = "003851be7bb0694fe3cc457a49529a19388ee7cf";
    owner  = "coreos";
    repo   = "go-etcd";
    sha256 = "1cijiw77cy4z6p4zhagm0q7ydyn8kk24v1611arx6wmvzgi7lyc3";
    propagatedBuildInputs = [
      ugorji_go
    ];
  };

  go-ethereum = buildFromGitHub {
    version = 3;
    rev = "v1.7.3";
    owner  = "ethereum";
    repo   = "go-ethereum";
    sha256 = "03a52n47gacc1z9f9z6lpvcs00bqz5iy2h6lhmw5zcbdlgm164vs";
    subPackages = [
      "crypto/sha3"
    ];
  };

  go-events = buildFromGitHub {
    version = 3;
    owner = "docker";
    repo = "go-events";
    rev = "9461782956ad83b30282bf90e31fa6a70c255ba9";
    date = "2017-07-21";
    sha256 = "1x902my10kmp3d24jcd9pxpbhma95jyqdd1k4ndjmcc6z4ygxxz1";
    propagatedBuildInputs = [
      logrus
    ];
  };

  go-farm = buildFromGitHub {
    version = 3;
    rev = "ac7624ea8da311f2fbbd94401d8c1cf66089f9fb";
    owner  = "dgryski";
    repo   = "go-farm";
    sha256 = "1s0di55iz53fclac6z2z8lby0qi3dl7ca2bfhcf0ddwdghp6p5kv";
    date = "2017-11-19";
  };

  go-flags = buildFromGitHub {
    version = 3;
    rev = "v1.3.0";
    owner  = "jessevdk";
    repo   = "go-flags";
    sha256 = "09gljnkkm39lsjzdrbch4i5s5xyvs7n6bwxbrm4rqiglsz33l9fy";
  };

  go-floodsub = buildFromGitHub {
    version = 3;
    rev = "385670512401b598ae5ab6c559eed9a0c3fc323e";
    owner  = "libp2p";
    repo   = "go-floodsub";
    sha256 = "1f4sb5kscpdn0ggfmvwkh9z8zhh0zffsalgpwg0jqg8bbfdnmnmg";
    date = "2017-12-05";
    propagatedBuildInputs = [
      gogo_protobuf
      go-libp2p-host
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-protocol
      go-log
      go-multiaddr
      timecache
    ];
  };

  go-flowrate = buildFromGitHub {
    version = 3;
    rev = "cca7078d478f8520f85629ad7c68962d31ed7682";
    owner  = "mxk";
    repo   = "go-flowrate";
    sha256 = "0xypq6z657pxqj5h2mlq22lvr8g6wvpqza1a1fvlq85i7i5nlkx9";
    date = "2014-04-19";
  };

  go-getter = buildFromGitHub {
    version = 3;
    rev = "994f50a6f071b07cfbea9eca9618c9674091ca51";
    date = "2017-12-04";
    owner = "hashicorp";
    repo = "go-getter";
    sha256 = "1lgbz7drmjqrbxzvnbpb1ifh6miawba5j4m0ka8h8bmbqqxcwsbi";
    propagatedBuildInputs = [
      aws-sdk-go
      go-cleanhttp
      go-homedir
      go-netrc
      go-testing-interface
      go-version
      xz
    ];
  };

  go-git-ignore = buildFromGitHub {
    version = 3;
    rev = "362f9845770f1606d61ba3ddf9cfb1f0780d2ffe";
    date = "2017-10-17";
    owner = "sabhiram";
    repo = "go-git-ignore";
    sha256 = "0zd6amnaj8r7573bh4ciq3dyngcbi3canr7g6cwjcbvmsg3yb42j";
  };

  go-github = buildFromGitHub {
    version = 3;
    date = "2017-12-02";
    rev = "fbfee053c26dab3772adfc7799d995eed379133e";
    owner = "google";
    repo = "go-github";
    sha256 = "1gaffxj4y4di88d7mqpl9k54ddpr10nai6iv2p9gi16yskr1m04r";
    buildInputs = [
      appengine
      oauth2
    ];
    propagatedBuildInputs = [
      go-querystring
    ];
    excludedPackages = "example";
  };

  go-glob = buildFromGitHub {
    version = 3;
    date = "2017-01-28";
    rev = "256dc444b735e061061cf46c809487313d5b0065";
    owner = "ryanuber";
    repo = "go-glob";
    sha256 = "0qchs17kd5hs8c3al4nba385qn562hhf1ag4fpk5j2qfgpyw1zc8";
  };

  go-grpc-prometheus = buildFromGitHub {
    version = 3;
    rev = "0dafe0d496ea71181bf2dd039e7e3f44b6bd11a7";
    owner = "grpc-ecosystem";
    repo = "go-grpc-prometheus";
    sha256 = "1n2lrbdic3z1sf5jil7r0p61x3gvk58m2pyfgfj9fc0fk3kycd34";
    propagatedBuildInputs = [
      grpc
      net
      prometheus_client_golang
    ];
    date = "2017-08-26";
  };

  go-hclog = buildFromGitHub {
    version = 3;
    date = "2017-10-05";
    rev = "ca137eb4b4389c9bc6f1a6d887f056bf16c00510";
    owner  = "hashicorp";
    repo   = "go-hclog";
    sha256 = "0ckx3m5bbmwc7g73d8nh56jg0zbh4544qp3g1yjjjv0dzvz8s852";
  };

  go-hdb = buildFromGitHub {
    version = 3;
    rev = "v0.9.5";
    owner  = "SAP";
    repo   = "go-hdb";
    sha256 = "0hzxm32b7r50sjpd1x33xk24gjqqk6q67j8b7kyw0hlnk6pw1lki";
    propagatedBuildInputs = [
      text
    ];
  };

  go-homedir = buildFromGitHub {
    version = 2;
    date = "2016-12-03";
    rev = "b8bc1bf767474819792c23f32d8286a45736f1c6";
    owner  = "mitchellh";
    repo   = "go-homedir";
    sha256 = "18j4j5zpxlpqqbdcl7d7cl69gcj747wq3z2m58lb99376w4a5xm6";
  };

  go-homedir_minio = buildFromGitHub {
    version = 3;
    owner = "minio";
    repo = "go-homedir";
    date = "2017-12-04";
    rev = "4d76aabb80b22bad8695d3904e943f1fb5e6199f";
    sha256 = "1n4l57jggf8a8lyq76swhn7064ydkw0na8yrwch0sl9vgxq8nafg";
  };

  hailocab_go-hostpool = buildFromGitHub {
    version = 3;
    rev = "e80d13ce29ede4452c43dea11e79b9bc8a15b478";
    date = "2016-01-25";
    owner  = "hailocab";
    repo   = "go-hostpool";
    sha256 = "1faz9sjnffkd7jsklnk5c7xq799928ff4gcb98sy6c69fmykhwc7";
  };

  gohtml = buildFromGitHub {
    version = 3;
    owner = "yosssi";
    repo = "gohtml";
    rev = "0cb98725f71a637e7bb967a8e87a1bab7ebaa6b0";
    date = "2017-05-01";
    sha256 = "0pmm57d5iz75pqjn3rkq6dmz37yha97j25awczlldwyh0kssrrlj";
    propagatedBuildInputs = [
      net
    ];
  };

  go-humanize = buildFromGitHub {
    version = 3;
    rev = "bb3d318650d48840a39aa21a027c6630e198e626";
    owner = "dustin";
    repo = "go-humanize";
    sha256 = "1apy3hdqlk1ix6r3xaqrj5y7zpq3081lnij13jk7kcd32mskhx4p";
    date = "2017-11-11";
  };

  go-i18n = buildFromGitHub {
    version = 3;
    rev = "v1.10.0";
    owner  = "nicksnyder";
    repo   = "go-i18n";
    sha256 = "031l584ilgvv7mvi4pn7lcc7wlb2lz2wia2gl0l6r4baxsraj3j3";
    buildInputs = [
      go-toml
      yaml_v2
    ];
  };

  go-immutable-radix = buildFromGitHub {
    version = 3;
    date = "2017-07-25";
    rev = "8aac2701530899b64bdea735a1de8da899815220";
    owner = "hashicorp";
    repo = "go-immutable-radix";
    sha256 = "1j7347idaa3qk4sn1gzg0hcch3qvf0lvhqbihmj4ca3bw05zqxpn";
    propagatedBuildInputs = [ golang-lru ];
  };

  go-ipfs-api = buildFromGitHub {
    version = 3;
    rev = "4e18c90494642212ec8f4a64e9328e6a4306a204";
    owner  = "ipfs";
    repo   = "go-ipfs-api";
    sha256 = "0jgywn4yr6irhhadr1wn1vf0fck35mb1rq4gawg845s0k6nn76iq";
    excludedPackages = "tests";
    propagatedBuildInputs = [
      go-floodsub
      go-homedir
      go-ipfs-cmdkit
      go-libp2p-peer
      go-libp2p-pubsub
      go-multiaddr
      go-multiaddr-net
      go-multipart-files
      tar-utils
    ];
    meta.useUnstable = true;
    date = "2017-11-23";
  };

  go-ipfs-cmdkit = buildFromGitHub {
    version = 3;
    rev = "af14cdf0a1833dd9a3cda2a7d3095b7a10f5b8bd";
    owner  = "ipfs";
    repo   = "go-ipfs-cmdkit";
    sha256 = "10zmqig8g97d9mhp0jzzagzjk5dhflx900n8ci4ijzjcjar2pzl2";
    date = "2017-12-05";
    propagatedBuildInputs = [
      go-ipfs-util
      sys
    ];
  };

  go-ipfs-util = buildFromGitHub {
    version = 3;
    rev = "ecb455b230ce7cb40510186fa723aa19af133aaf";
    owner  = "ipfs";
    repo   = "go-ipfs-util";
    sha256 = "10ziajr94j4k3zpi8lzqllbhdv4lgkfjk670ws49q6sgsik5g5d8";
    date = "2017-12-04";
    propagatedBuildInputs = [
      go-base58
      go-multihash
    ];
  };

  go-isatty = buildFromGitHub {
    version = 3;
    rev = "v0.0.3";
    owner  = "mattn";
    repo   = "go-isatty";
    sha256 = "1ds5jqxjzzvlxzr3f94iwz0vsci11i7qshqg8mx1gr64dm8r8vsh";
    buildInputs = [
      sys
    ];
  };

  go-jmespath = buildFromGitHub {
    version = 3;
    rev = "dd801d4f4ce7ac746e7e7b4489d2fa600b3b096b";
    owner = "jmespath";
    repo = "go-jmespath";
    sha256 = "1cnqhi93x24pg3vmd9b8k0rr13pbjlj5xrnnn673ngjwqj321h73";
    date = "2017-11-20";
  };

  go-jose_v1 = buildFromGitHub {
    version = 2;
    rev = "v1.1.0";
    owner = "square";
    repo = "go-jose";
    sha256 = "b2dac3e4693bbf2ef11c8afd6aec838479acb789c1d156084776e68488bbd64e";
    goPackagePath = "gopkg.in/square/go-jose.v1";
    buildInputs = [
      urfave_cli
      kingpin_v2
    ];
  };

  go-jose_v2 = buildFromGitHub {
    version = 3;
    rev = "v2.1.3";
    owner = "square";
    repo = "go-jose";
    sha256 = "1gdygy4xx8zxyb8lwck9v1x4ldkigabdcnj68gvgvmb50fhr0y8m";
    goPackagePath = "gopkg.in/square/go-jose.v2";
    buildInputs = [
      crypto
      urfave_cli
      kingpin_v2
    ];
  };

  go-keyspace = buildFromGitHub {
    version = 2;
    rev = "5b898ac5add1da7178a4a98e69cb7b9205c085ee";
    owner = "whyrusleeping";
    repo = "go-keyspace";
    sha256 = "1kf9gyrhfjhqckziaag8qg5kyyy2zmkfz33wmf9c6p6xqypg0bx7";
    date = "2016-03-22";
  };

  go-libp2p = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p";
    date = "2017-12-05";
    rev = "8850e513e161d895e2980980435eb5ff7f5c0146";
    sha256 = "1siyys7xajaaldq36xyvx6mwlw9l3s4kn8qzy8spphv01jnd1fci";
    excludedPackages = "mock";
    propagatedBuildInputs = [
      goprocess
      go-ipfs-util
      go-log
      go-libp2p-circuit
      go-libp2p-crypto
      go-libp2p-host
      go-libp2p-interface-connmgr
      go-libp2p-loggables
      go-libp2p-metrics
      go-libp2p-nat
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-peerstore
      go-libp2p-protocol
      go-multiaddr
      go-multiaddr-dns
      go-multiaddr-net
      go-multistream
      go-semver
      whyrusleeping_mdns
      gogo_protobuf
    ];
  };

  go-libp2p-circuit = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-circuit";
    date = "2017-12-05";
    rev = "1c353b5ced417ae5044e4883300e9453b79e7a47";
    sha256 = "04l324srqm490jhmqp0l86747kgx2bm2xpac70gsw7qg7kyqcgyj";
    propagatedBuildInputs = [
      go-addr-util
      go-log
      go-libp2p-crypto
      go-libp2p-host
      go-libp2p-interface-conn
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-peerstore
      go-libp2p-swarm
      go-libp2p-transport
      go-maddr-filter
      go-multiaddr
      go-multiaddr-net
      go-multihash
      gogo_protobuf
    ];
  };

  go-libp2p-conn = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-conn";
    date = "2017-12-05";
    rev = "41874667f01e78e255b5c1a313f472bb017b771b";
    sha256 = "1wcrg5aj1nwmnch6zi3clz7az85jj2hgzgrxwdc2hjhhch2pwry6";
    propagatedBuildInputs = [
      go-log
      go-temp-err-catcher
      goprocess
      go-addr-util
      go-libp2p-crypto
      go-libp2p-interface-conn
      go-libp2p-interface-pnet
      go-libp2p-loggables
      go-libp2p-peer
      go-libp2p-secio
      go-libp2p-transport
      go-maddr-filter
      go-msgio
      go-multiaddr
      go-multiaddr-net
      go-multistream
    ];
  };

  go-libp2p-connmgr = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-connmgr";
    date = "2017-10-08";
    rev = "ea96e1a2edfffd630a0ec7af5380eed3b13bfeeb";
    sha256 = "0j1d1r8r1x8v2fm2hqnrrfn3m2a745f4f7z6ccikxa3ysy2gw6bb";
    propagatedBuildInputs = [
      go-libp2p-interface-connmgr
      go-libp2p-net
      go-libp2p-peer
      go-log
      go-multiaddr
    ];
  };

  go-libp2p-consensus = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-consensus";
    rev = "v0.0.1";
    sha256 = "0ylz4zwpan2nkhyq9ckdclrxhsf86nmwwp8kcwi334v0491963fh";
  };

  go-libp2p-crypto = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-crypto";
    date = "2017-07-06";
    rev = "e89e1de117dd65c6129d99d1d853f48bc847cf17";
    sha256 = "0zcy9457502ramr17qyck3wgl233bv39hzlmmdhc758liyq1xgrf";
    propagatedBuildInputs = [
      btcd
      ed25519
      go-base58
      go-ipfs-util
      go-multihash
      gogo_protobuf
    ];
  };

  go-libp2p-gorpc = buildFromGitHub {
    version = 3;
    owner = "hsanjuan";
    repo = "go-libp2p-gorpc";
    date = "2017-10-23";
    rev = "ec73b5da99d77e01d2a140899855fb803650d1e0";
    sha256 = "1zjyij9830ryki6l3cr9vv280qy1z2a3hq94ak4ahi9whpms3z3v";
    propagatedBuildInputs = [
      go-log
      go-libp2p-host
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-protocol
      go-multicodec
    ];
  };

  go-libp2p-gostream = buildFromGitHub {
    version = 3;
    owner = "hsanjuan";
    repo = "go-libp2p-gostream";
    date = "2017-10-23";
    rev = "c75991eb05a4915abc8184d27df230858e07d600";
    sha256 = "0j1hg8l6yrcxb5hh57qy6nb35fhakpglazlby909bqwc6yanw76b";
    propagatedBuildInputs = [
      go-libp2p-host
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-protocol
    ];
  };

  go-libp2p-host = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-host";
    date = "2017-12-05";
    rev = "bb2f9de697e574146834c22a81abf67fe2deb7b2";
    sha256 = "19azqvf0639b2gp2m1yz3ji2rwpz4bajswc16sc2nx53fzb5q0b8";
    propagatedBuildInputs = [
      go-libp2p-interface-connmgr
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-peerstore
      go-libp2p-protocol
      go-multiaddr
      go-multistream
      go-semver
    ];
  };

  go-libp2p-interface-conn = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-interface-conn";
    date = "2017-12-05";
    rev = "e2364b1915e2e3fd59cbd9e16355b2eb6d5493ba";
    sha256 = "11cy4fsv9lp5a416hlvr8gib8289z4n583mfw85j6ac7p5b4b5b9";
    propagatedBuildInputs = [
      go-ipfs-util
      go-libp2p-crypto
      go-libp2p-peer
      go-libp2p-transport
      go-maddr-filter
      go-multiaddr
    ];
  };

  go-libp2p-interface-connmgr = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-interface-connmgr";
    date = "2017-12-05";
    rev = "43bac92c9f2ff6625c9a2b22d557e12a26232fdc";
    sha256 = "0yhkafbp7jdaxf70xcm3wymbcqgg1g6db5c4bvcyxaqbkc2lgb85";
    propagatedBuildInputs = [
      go-libp2p-net
      go-libp2p-peer
      go-multiaddr
    ];
  };

  go-libp2p-interface-pnet = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-interface-pnet";
    date = "2017-12-05";
    rev = "79aee70dc632f4b4b2b9b52391f544fe0bfbdfba";
    sha256 = "0vb669iwajqmhbarkgpsmffnfwl76j4mvgg9lln0r67mc0yd0rv8";
    propagatedBuildInputs = [
      go-libp2p-transport
    ];
  };

  go-libp2p-loggables = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-loggables";
    date = "2017-12-04";
    rev = "879a962c30d53c320ce9aea9dc002c04f3e8a3ca";
    sha256 = "1zfld6ggz84jp68g45p3wa7czmnvknalfmpigxwx0q7lcw9vvmvh";
    propagatedBuildInputs = [
      go-log
      go-libp2p-peer
      go-multiaddr
      satori_go-uuid
    ];
  };

  go-libp2p-metrics = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-metrics";
    date = "2017-12-05";
    rev = "4036f82f1a5bb574b54e091729005defd18439e9";
    sha256 = "1581rh3fr1r2cdvzpvjbiz8yb2cpn53qpfgfpb8fzr1vmkfzswj5";
    propagatedBuildInputs = [
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-protocol
      go-libp2p-transport
      whyrusleeping_go-metrics
    ];
  };

  go-libp2p-nat = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-nat";
    date = "2017-12-05";
    rev = "b0b12516ee323d3e00e2b7d9bd8b4e89f8f677e3";
    sha256 = "0gbbv81dayz1j091kv476y146vfvkax84lnmn0bf0093q5pr50lm";
    propagatedBuildInputs = [
      goprocess
      go-log
      go-multiaddr
      go-multiaddr-net
      go-nat
      go-notifier
    ];
  };

  go-libp2p-net = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-net";
    date = "2017-12-05";
    rev = "7376e443db870a50994a68b1c8f8aa3a63ab686b";
    sha256 = "0fcpf5p37dqnnj7ksp1njram0kvgi5hp5lk2fig4qq14wax6alk2";
    propagatedBuildInputs = [
      goprocess
      go-libp2p-interface-conn
      go-libp2p-peer
      go-libp2p-peerstore
      go-libp2p-protocol
      go-multiaddr
      go-stream-muxer
    ];
  };

  go-libp2p-peer = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-peer";
    date = "2017-12-04";
    rev = "2ca71036eb522f8904cc9c0f1f3eebe6617fdec9";
    sha256 = "08zgksp4bhfzsl3s9p9m6ncz9s3b6y71qqp7qqwkf4gnb5p2qsq7";
    propagatedBuildInputs = [
      go-base58
      go-ipfs-util
      go-libp2p-crypto
      go-log
      go-multicodec-packed
      go-multihash
    ];
  };

  go-libp2p-peerstore = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-peerstore";
    date = "2017-12-07";
    rev = "8b5c1b16c0f471fdee2a70fa77ed180b8d7a0c01";
    sha256 = "0w3qaj1mas11fkmx56y2diq3xpvkkkis6vp50p4rj2y6g0pxai6a";
    excludedPackages = "test";
    propagatedBuildInputs = [
      go-libp2p-crypto
      go-libp2p-peer
      go-log
      go-keyspace
      go-multiaddr
      go-multiaddr-net
      mafmt
    ];
  };

  go-libp2p-pnet = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-pnet";
    date = "2017-12-05";
    rev = "b7f37767c33c233ecbbd601005c4fe787e7d9811";
    sha256 = "10k5fm80y4nl5kaz55j0ydyw2fljdwshnch8v8kk1ikc5y1i08mf";
    propagatedBuildInputs = [
      crypto
      davidlazar_go-crypto
      go-libp2p-interface-pnet
      go-libp2p-transport
      go-msgio
      go-multicodec
    ];
  };

  go-libp2p-protocol = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-protocol";
    date = "2017-08-24";
    rev = "86bfc440c3e51ec65a4629219623cc5c7e31f16a";
    sha256 = "01slk2wspdjrdffyn1fr8pvgh9k822j776fdx0ddhww3bj1s3v00";
  };

  go-libp2p-pubsub = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-pubsub";
    date = "2017-11-18";
    rev = "a031ab4d1b8142714eec946acb7033abafade3d7";
    sha256 = "037y9pfjjzjv5psrhjd9j3nlqqigsfm8xgz6c57i27p799hisifq";
    propagatedBuildInputs = [
      gogo_protobuf
    ];
  };

  go-libp2p-raft = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-raft";
    date = "2017-11-21";
    rev = "fcdb9131fb269477cb87235eaa29d59ed3c7a13a";
    sha256 = "0al5dyqh7i7k53pb858njr3n5cy4wmkjp35wkzc9f7z46jy998a8";
    propagatedBuildInputs = [
      go-libp2p-consensus
      go-libp2p-gostream
      go-libp2p-host
      go-libp2p-peer
      go-libp2p-protocol
      go-log
      go-multicodec
      raft
    ];
  };

  go-libp2p-secio = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-secio";
    date = "2017-12-04";
    rev = "255efc8d10b46865d6f1471b0223b5b4026e7cb7";
    sha256 = "0l9hi5rlsnn6lmlirczlsn1pvbncarbsix38gxjnixrdr9psjvfw";
    propagatedBuildInputs = [
      crypto
      gogo_protobuf
      go-log
      go-libp2p-crypto
      go-libp2p-peer
      go-msgio
      go-multihash
    ];
  };

  go-libp2p-swarm = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-swarm";
    date = "2017-12-06";
    rev = "4986ec896a17e361065630452b09566584248708";
    sha256 = "14dzknkprhjparsijlphil5qfv4qlmhhy081f31qy30rxk9aad66";
    propagatedBuildInputs = [
      go-log
      goprocess
      go-addr-util
      go-libp2p-conn
      go-libp2p-crypto
      go-libp2p-interface-conn
      go-libp2p-interface-pnet
      go-libp2p-loggables
      go-libp2p-metrics
      go-libp2p-net
      go-libp2p-peer
      go-libp2p-peerstore
      go-libp2p-protocol
      go-libp2p-transport
      go-maddr-filter
      go-peerstream
      go-stream-muxer
      go-tcp-transport
      go-ws-transport
      go-multiaddr
      go-smux-multistream
      go-smux-spdystream
      go-smux-yamux
      multiaddr-filter
    ];
  };

  go-libp2p-transport = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-libp2p-transport";
    date = "2017-12-04";
    rev = "6ab1c8a1eaa770e840dfc81050c0dd5199ed8103";
    sha256 = "1wyisd2qg57kha51hcabjhqwsqwvn34z7sgr6gx4wvlzb4x0l2a0";
    propagatedBuildInputs = [
      go-log
      go-multiaddr
      go-multiaddr-net
      go-stream-muxer
      mafmt
    ];
  };

  go-log = buildFromGitHub {
    version = 2;
    owner = "ipfs";
    repo = "go-log";
    date = "2017-03-16";
    rev = "48d644b006ba26f1793bffc46396e981801078e3";
    sha256 = "1s2kjgrg12r1lpickn8qxvi3642rf34i17gda3jwzwn2gp9jyyvr";
    propagatedBuildInputs = [
      whyrusleeping_go-logging
    ];
  };

  whyrusleeping_go-logging = buildFromGitHub {
    version = 3;
    owner = "whyrusleeping";
    repo = "go-logging";
    date = "2017-05-15";
    rev = "0457bb6b88fc1973573aaf6b5145d8d3ae972390";
    sha256 = "0fmz7xcsk2k8dr9nmj4fgs7d1l10d85hn1qjc8f68wa0ax83yfjl";
  };

  go-logging = buildFromGitHub {
    version = 2;
    owner = "op";
    repo = "go-logging";
    date = "2016-03-15";
    rev = "970db520ece77730c7e4724c61121037378659d9";
    sha256 = "8087016a076abb7ab630f22c6e2b0ae8ce310350aad9792123c7842b299f87a7";
  };

  go-lxc_v2 = buildFromGitHub {
    version = 3;
    rev = "1f07259d85a5d2c42d506ae8a081db88f27c1252";
    owner  = "lxc";
    repo   = "go-lxc";
    sha256 = "0cwjkddbasklld2gh2y221kgrq42y2i9w7cyi4mgn29kaq81wh48";
    goPackagePath = "gopkg.in/lxc/go-lxc.v2";
    buildInputs = [
      pkgs.lxc
    ];
    date = "2017-12-07";
  };

  go-lz4 = buildFromGitHub {
    version = 2;
    rev = "7224d8d8f27ef618c0a95f1ae69dbb0488abc33a";
    owner  = "bkaradzic";
    repo   = "go-lz4";
    sha256 = "1hbbagvmq7kxrlwqkn0i4mz66i3n37ch7y6bm9yncnjgd97kldms";
    date = "2016-09-24";
  };

  go-maddr-filter = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-maddr-filter";
    date = "2017-12-04";
    rev = "5844eae20bf7647c1a31847db4bd7e39fd7fa6ea";
    sha256 = "1h1mskahdhbds1zh30hh2ivhj22g7yi8bmx1qqgazd10q6v8z1x2";
    propagatedBuildInputs = [
      go-multiaddr
      go-multiaddr-net
    ];
  };

  go-md2man = buildFromGitHub {
    version = 3;
    owner = "cpuguy83";
    repo = "go-md2man";
    rev = "1d903dcb749992f3741d744c0f8376b4bd7eb3e1";
    sha256 = "0l5fl6c8g5dnwklp8q6qp2n2s8r1zj7ssbw5h9k809nl82irbssi";
    propagatedBuildInputs = [
      blackfriday
    ];
    meta.useUnstable = true;
    date = "2017-08-27";
  };

  go-memdb = buildFromGitHub {
    version = 3;
    date = "2017-10-05";
    rev = "75ff99613d288868d8888ec87594525906815dbc";
    owner = "hashicorp";
    repo = "go-memdb";
    sha256 = "17fbbl0bpk14j3kjbhhrw5fxjjjnhx7w2w5lyxvckr7n7n3v3zy5";
    propagatedBuildInputs = [
      go-immutable-radix
    ];
  };

  armon_go-metrics = buildFromGitHub {
    version = 3;
    date = "2017-11-17";
    rev = "7aa49fde808223f8dadfdbfd3a20ff6c19e5f9ec";
    owner = "armon";
    repo = "go-metrics";
    sha256 = "14cd5ml22clwi69n6762w3hncic1sd93nw0pjkjbb4frgzmja57v";
    propagatedBuildInputs = [
      circonus-gometrics
      datadog-go
      go-immutable-radix
      prometheus_client_golang
    ];
  };

  docker_go-metrics = buildFromGitHub {
    version = 3;
    date = "2017-10-09";
    rev = "b8fbfd8f51b86cbfefb5f00fd998df220a234337";
    owner = "docker";
    repo = "go-metrics";
    sha256 = "1iavha8zjgknnfibf1annr8a8wmnpccy70dnha49vhidsrs5pbjq";
    propagatedBuildInputs = [
      prometheus_client_golang
    ];
    postPatch = ''
      grep -q 'lt.m.WithLabelValues(labels...)}' timer.go
      sed -i '/WithLabelValues/s,)},).(prometheus.Histogram)},' timer.go
    '';
  };

  rcrowley_go-metrics = buildFromGitHub {
    version = 3;
    rev = "e181e095bae94582363434144c61a9653aff6e50";
    date = "2017-11-28";
    owner = "rcrowley";
    repo = "go-metrics";
    sha256 = "1n53lx7yayahawh3mcqi3l0n6agraikgv3ij3hwd0q3262v6z06q";
    propagatedBuildInputs = [
      stathat
    ];
  };

  whyrusleeping_go-metrics = buildFromGitHub {
    version = 3;
    rev = "1ca5caed0cfa95a47fd65a79762286ae626c865c";
    date = "2015-11-19";
    owner = "whyrusleeping";
    repo = "go-metrics";
    sha256 = "0za9fr3y5fw7gv4s2m694ryd1gkip48fsi4662kmc2s9shcwj7cm";
  };

  go-metro = buildFromGitHub {
    version = 2;
    date = "2015-06-07";
    rev = "d5cb643948fbb1a699e6da1426f0dba75fe3bb8e";
    owner = "dgryski";
    repo = "go-metro";
    sha256 = "5d271cba19ad6aa9b0aaca7e7de6d5473eb4a9e4b682bbb1b7a4b37cca9bb706";
    meta.autoUpdate = false;
  };

  go-msgio = buildFromGitHub {
    version = 3;
    rev = "709299bfffa0871d77f796b0cd1e857b64201f86";
    owner = "libp2p";
    repo = "go-msgio";
    sha256 = "0cmjgnx8plhglmhkn9ywmkf494j19axnh7zc34ldw6l1kl54jxih";
    date = "2017-12-05";
  };

  go-mssqldb = buildFromGitHub {
    version = 3;
    rev = "8a15d1bb0c8eaa4b870c016b312de5b50b493b4e";
    owner = "denisenkom";
    repo = "go-mssqldb";
    sha256 = "0mvwrr136fm43jkj8bb7pyvdcblnhzn6g5xih26ai6qjcf7pzcd5";
    date = "2017-12-04";
    buildInputs = [
      crypto
      net
    ];
  };

  go-multiaddr = buildFromGitHub {
    version = 3;
    rev = "781e075f3dd7ccaa80da7dd542267030fdfedb20";
    date = "2017-12-04";
    owner  = "multiformats";
    repo   = "go-multiaddr";
    sha256 = "0qyfr8qidigfjw9b4ss36yq1jznnxcp118h054f0y46agjwi2n5f";
    goPackageAliases = [ "github.com/jbenet/go-multiaddr" ];
    propagatedBuildInputs = [
      go-multihash
    ];
  };

  go-multiaddr-dns = buildFromGitHub {
    version = 3;
    rev = "87ed7a0467713ec4204e073168e6e5adbed936de";
    date = "2017-12-05";
    owner  = "multiformats";
    repo   = "go-multiaddr-dns";
    sha256 = "0k0acm2gv16lnvh1w4wy6kvj1bjp1piiq962zim8wp2jm7nx41m1";
    propagatedBuildInputs = [
      go-multiaddr
    ];
  };

  go-multiaddr-net = buildFromGitHub {
    version = 3;
    rev = "4ce984eed7a8f77535ce5d267d0a21bd5a3d8363";
    owner  = "multiformats";
    repo   = "go-multiaddr-net";
    sha256 = "0zds61mxxdxdj7dpm5ngkirmh8kqn9y0f993s1z71j5vl3d1r5a8";
    date = "2017-12-04";
    goPackageAliases = [ "github.com/jbenet/go-multiaddr-net" ];
    propagatedBuildInputs = [
      go-multiaddr
    ];
  };

  go-multibase = buildFromGitHub {
    version = 3;
    rev = "54686aabd40b185e9d1a81c0b5de4f6d7c6c628c";
    date = "2017-08-29";
    owner  = "multiformats";
    repo   = "go-multibase";
    sha256 = "0h61a3rhissqqp8vx0jdd7xcs7nhrfy3krj1b0g00q9fy3axxdv0";
    propagatedBuildInputs = [
      go-base58
      base32
    ];
  };

  go-multicodec = buildFromGitHub {
    version = 3;
    rev = "fd289ac41fba9e574f214ab2a808a1678ef8810c";
    date = "2017-11-20";
    owner  = "multiformats";
    repo   = "go-multicodec";
    sha256 = "0alx6yagjmg3q3srzd4l8m07310xn1nqf03d0f0afqf86f3vp620";
    propagatedBuildInputs = [
      cbor
      ugorji_go
      go-msgio
      gogo_protobuf
    ];
  };

  go-multicodec-packed = buildFromGitHub {
    version = 3;
    owner = "multiformats";
    repo = "go-multicodec-packed";
    date = "2017-06-28";
    rev = "0ee69486dc1c9087aacfcc575e333f305009997e";
    sha256 = "00f0dly4q5zic84gk7p513y08xgy7xqwsw6n5wv7mc89wj397s9w";
  };

  go-multierror = buildFromGitHub {
    version = 3;
    date = "2017-12-04";
    rev = "b7773ae218740a7be65057fc60b366a49b538a44";
    owner  = "hashicorp";
    repo   = "go-multierror";
    sha256 = "1imymwg4z8ba59d7846s1n4w1jba72k5yppv8qdwylq4bpd48nfd";
    propagatedBuildInputs = [
      errwrap
    ];
  };

  go-multihash = buildFromGitHub {
    version = 3;
    rev = "v1.0.6";
    owner  = "multiformats";
    repo   = "go-multihash";
    sha256 = "0k4xg9lrrd0hawm0l67hwzi6r1y94jg1vv109n1rxrk65gwrn811";
    goPackageAliases = [ "github.com/jbenet/go-multihash" ];
    propagatedBuildInputs = [
      crypto
      go-base58
      go-ethereum
      hashland
      murmur3
    ];
  };

  go-multipart-files = buildFromGitHub {
    version = 3;
    rev = "3be93d9f6b618f2b8564bfb1d22f1e744eabbae2";
    owner  = "whyrusleeping";
    repo   = "go-multipart-files";
    sha256 = "1b3zd8338dzda7vrval6wirs7cn5klfw1i2sq5a8qxvrb6rlvb3w";
    date = "2015-09-04";
  };

  go-multistream = buildFromGitHub {
    version = 2;
    rev = "b8f1996688ab586031517919b49b1967fca8d5d9";
    date = "2017-03-17";
    owner  = "multiformats";
    repo   = "go-multistream";
    sha256 = "0110p4bk3m9xri96bn65kfibi5ir0ima6xbfsv7m8drijgzjyx3a";
  };

  go-nat = buildFromGitHub {
    version = 3;
    rev = "dcaf50131e4810440bed2cbb6f7f32c4f4cc95dd";
    owner  = "fd";
    repo   = "go-nat";
    sha256 = "1zv8h4s7rqvkd78q4j2fvg2zr94x5gf964q8hq9vh7cj0zrjb150";
    date = "2015-05-08";
    propagatedBuildInputs = [
      gateway
      goupnp
      jackpal_go-nat-pmp
    ];
  };

  AudriusButkevicius_go-nat-pmp = buildFromGitHub {
    version = 3;
    rev = "452c97607362b2ab5a7839b8d1704f0396b640ca";
    owner  = "AudriusButkevicius";
    repo   = "go-nat-pmp";
    sha256 = "1bz6lhl9h2nv5vvcb5i53zhd4w17aq5pmxi40krps2lhazsgcmba";
    date = "2016-05-22";
  };

  jackpal_go-nat-pmp = buildFromGitHub {
    version = 3;
    rev = "28a68d0c24adce1da43f8df6a57340909ecd7fdd";
    owner  = "jackpal";
    repo   = "go-nat-pmp";
    sha256 = "173kd4l52rmd4d4j6mnf69s6gpmdx7b9npkmkgxlzpiad62vaq20";
    date = "2017-04-05";
  };

  go-nats = buildFromGitHub {
    version = 3;
    rev = "v1.3.0";
    owner = "nats-io";
    repo = "go-nats";
    sha256 = "13066sdbwp2r5zwljb5096q87q52i21k3p4aj6dypgclrnl072vi";
    excludedPackages = "test";
    propagatedBuildInputs = [
      nuid
      protobuf
    ];
    goPackageAliases = [
      "github.com/nats-io/nats"
    ];
  };

  go-nats-streaming = buildFromGitHub {
    version = 3;
    rev = "43723aa09c43cec839e43583df07b1940c9f7651";
    owner = "nats-io";
    repo = "go-nats-streaming";
    sha256 = "10q6m9hj8xqw4ajvka3rggsq0adsa4ip9bnvgdqsml2fh9i7kg0f";
    propagatedBuildInputs = [
      go-nats
      nuid
      gogo_protobuf
    ];
    date = "2017-12-07";
  };

  go-netrc = buildFromGitHub {
    version = 2;
    owner = "bgentry";
    repo = "go-netrc";
    date = "2014-05-22";
    rev = "9fd32a8b3d3d3f9d43c341bfe098430e07609480";
    sha256 = "68984543a73f4d7ad4b58708207a483bd74fc9388ac582eac532434b11361a9e";
  };

  go-notifier = buildFromGitHub {
    version = 3;
    owner = "whyrusleeping";
    repo = "go-notifier";
    date = "2017-08-27";
    rev = "097c5d47330ff6a823f67e3515faa13566a62c6f";
    sha256 = "1rnnc8nngvpbkzqrsls3q8jzb0nrc8c8qi0z89cw0lzp36l00dy6";
    propagatedBuildInputs = [
      goprocess
    ];
  };

  go-oidc = buildFromGitHub {
    version = 3;
    date = "2017-10-26";
    rev = "a93f71fdfe73d2c0f5413c0565eea0af6523a6df";
    owner  = "coreos";
    repo   = "go-oidc";
    sha256 = "e0370707f20d97f6e8a447de6a6b29564a75cb8a6bd3d8cc992d9996e8b9c78e";
    propagatedBuildInputs = [
      cachecontrol
      clockwork
      go-jose_v2
      oauth2
      pkg
    ];
    meta.autoUpdate = false;
    excludedPackages = "example";
  };

  go-okta = buildFromGitHub {
    version = 3;
    rev = "053fd73f6d35ad82d5eee3481cbf76b10f61dee6";
    owner = "sstarcher";
    repo = "go-okta";
    sha256 = "1g9d4y5c8cqschi4r2jsd8dw2f5drrykgpav13dlad2y1ps3nj8q";
    date = "2017-12-05";
  };

  go-ole = buildFromGitHub {
    version = 3;
    date = "2017-11-10";
    rev = "a41e3c4b706f6ae8dfbff342b06e40fa4d2d0506";
    owner  = "go-ole";
    repo   = "go-ole";
    sha256 = "1krqmh5va8hxbf0bdd6vlmnxpw5zclj343qfb8yqgibklr15k9s8";
    excludedPackages = "example";
  };

  go-os-rename = buildFromGitHub {
    version = 3;
    rev = "3ac97f61ef67a6b87b95c1282f6c317ed0e693c2";
    owner  = "jbenet";
    repo   = "go-os-rename";
    sha256 = "0dqddk6l49jq35hd1x6nls0wdcy3j9dvlcbakxvibdxiw3k4y50f";
    date = "2015-04-28";
  };

  go-ovh = buildFromGitHub {
    version = 3;
    rev = "4b1fea467323b74c5f462f0947f402b428ca0626";
    owner = "ovh";
    repo = "go-ovh";
    sha256 = "0983hsivji86dpmn63r3dfxdgxrk2hk1lgn3xy6bnvclskl8rm2p";
    date = "2017-09-06";
    propagatedBuildInputs = [
      ini_v1
    ];
  };

  go-peerstream = buildFromGitHub {
    version = 3;
    rev = "897bba6345df97eef1861f5ec4226f9c62697ac6";
    date = "2017-12-04";
    owner  = "libp2p";
    repo   = "go-peerstream";
    sha256 = "0m33w6lvm327x0h9shvg470bvlyg3jihbbjncf719nirvjxr0xgg";
    excludedPackages = "\\(example\\|test\\)";
    propagatedBuildInputs = [
      go-temp-err-catcher
      go-libp2p-protocol
      go-libp2p-transport
      go-stream-muxer
    ];
  };

  go-plugin = buildFromGitHub {
    version = 3;
    rev = "e2fbc6864d18d3c37b6cde4297ec9fca266d28f1";
    date = "2017-10-29";
    owner  = "hashicorp";
    repo   = "go-plugin";
    sha256 = "0r67n6vrbidk7h5p1j25y3ymdr95iq9m1cc08j3ij4jj5hqmfr2v";
    propagatedBuildInputs = [
      go-hclog
      go-testing-interface
      grpc
      net
      protobuf
      hashicorp_yamux
    ];
  };

  go-proxyproto = buildFromGitHub {
    version = 3;
    date = "2017-06-20";
    rev = "48572f11356f1843b694f21a290d4f1006bc5e47";
    owner  = "armon";
    repo   = "go-proxyproto";
    sha256 = "1csy3srrl28zfpf3nfaliqzkz5miclygydq8cwdggksivs471jac";
  };

  go-ps = buildFromGitHub {
    version = 2;
    rev = "4fdf99ab29366514c69ccccddab5dc58b8d84062";
    date = "2017-03-09";
    owner  = "mitchellh";
    repo   = "go-ps";
    sha256 = "1x70gc6y9licdi6qww1lkwx1wkwwkqylzhkfl0wpnizl8m7vpdmp";
  };

  keybase_go-ps = buildFromGitHub {
    version = 3;
    rev = "668c8856d9992f97248b3177d45743d2cc1068db";
    date = "2016-10-05";
    owner  = "keybase";
    repo   = "go-ps";
    sha256 = "04f1qw4h19907d6x8lg4r1gkzl3i7z120bqsmrpl6lwb5irfy065";
  };

  go-python = buildFromGitHub {
    version = 3;
    owner = "sbinet";
    repo = "go-python";
    date = "2017-09-01";
    rev = "6d13f941744b9332d6ed00dc2cd2722acd79a47e";
    sha256 = "1jvwgavfwlhz73wsrnfya8s2whvbwn63j10gp6qyyycj67snsayy";
    propagatedBuildInputs = [
      pkgs.python2Packages.python
    ];
  };

  go-querystring = buildFromGitHub {
    version = 2;
    date = "2017-01-11";
    rev = "53e6ce116135b80d037921a7fdd5138cf32d7a8a";
    owner  = "google";
    repo   = "go-querystring";
    sha256 = "1ibpx1hpqjkvcmn4gsz54k9p62sl1iac2kgb97spcl630nn4p0yj";
  };

  go-radix = buildFromGitHub {
    version = 3;
    rev = "1fca145dffbcaa8fe914309b1ec0cfc67500fe61";
    owner  = "armon";
    repo   = "go-radix";
    sha256 = "1lwh7qfsn0nk20jprdfa79ibnz9vw8yljhcvw7c2sqhss4lwyvkz";
    date = "2017-07-27";
  };

  go-random = buildFromGitHub {
    version = 3;
    rev = "384f606e91f542a98e779e652eed88051618f0f7";
    owner  = "jbenet";
    repo   = "go-random";
    sha256 = "0dsp9g972y0i93fdb9kn3vvjk7px8z1gx4yikw9al1y7mdx37pbp";
    date = "2015-08-29";
    propagatedBuildInputs = [
      go-humanize
    ];
  };

  go-random-files = buildFromGitHub {
    version = 3;
    rev = "737479700b40b4b50e914e963ce8d9d44603e3c8";
    owner  = "jbenet";
    repo   = "go-random-files";
    sha256 = "12dm4bhj0v67w7a3g9rxhdnw8r927dz4z9dpx1pglisw58dc3kci";
    date = "2015-06-09";
    propagatedBuildInputs = [
      go-random
    ];
  };

  go-resiliency = buildFromGitHub {
    version = 3;
    rev = "b1fe83b5b03f624450823b751b662259ffc6af70";
    owner  = "eapache";
    repo   = "go-resiliency";
    sha256 = "0iyn9ssm02ila0n8lm44awgsdpvzv833y0zwk9pgnm7s089slm8g";
    date = "2017-06-07";
  };

  go-restful = buildFromGitHub {
    version = 3;
    rev = "v2.4.0";
    owner = "emicklei";
    repo = "go-restful";
    sha256 = "1z3b0mc0ldq4nvrz6fgc9arqf2pm4fnixd0ldn226k77s8l1v1kj";
  };

  go-restful-swagger12 = buildFromGitHub {
    version = 3;
    rev = "7524189396c68dc4b04d53852f9edc00f816b123";
    owner = "emicklei";
    repo = "go-restful-swagger12";
    sha256 = "0jvcbd2635c2p85gbinsah4jgi9hjgnphn9ji072wrwlx4i3ghxg";
    goPackageAliases = [
      "github.com/emicklei/go-restful/swagger"
    ];
    propagatedBuildInputs = [
      go-restful
    ];
    date = "2017-09-26";
  };

  go-retryablehttp = buildFromGitHub {
    version = 3;
    rev = "794af36148bf63c118d6db80eb902a136b907e71";
    owner = "hashicorp";
    repo = "go-retryablehttp";
    sha256 = "177h5fzmasq79i9sj7wxv7n7qw9ng4yx13f2bwbid71msf41wf1d";
    date = "2017-08-24";
    propagatedBuildInputs = [
      go-cleanhttp
    ];
  };

  go-reuseport = buildFromGitHub {
    version = 3;
    rev = "2833484e679e6b120d5fce650775d22f4d4db127";
    owner = "libp2p";
    repo = "go-reuseport";
    sha256 = "05q3033wx4lr6n7zc7mhxammzx1shd54m253b1wj6s6lhkgfqi3r";
    date = "2017-11-20";
    excludedPackages = "test";
    propagatedBuildInputs = [
      eventfd
      go-log
      libp2p_go-sockaddr
      sys
    ];
  };

  go-rootcerts = buildFromGitHub {
    version = 3;
    rev = "6bb64b370b90e7ef1fa532be9e591a81c3493e00";
    owner = "hashicorp";
    repo = "go-rootcerts";
    sha256 = "1nxfy0j98s2c3sljga8n1r0l1xcz2pp3i9rzk8iy0xid5dh3mv3q";
    date = "2016-05-03";
    buildInputs = [
      go-homedir
    ];
  };

  go-runewidth = buildFromGitHub {
    version = 2;
    rev = "v0.0.2";
    owner = "mattn";
    repo = "go-runewidth";
    sha256 = "1j99da81h9s528g3lmhgy1pvmzhhcxl8g3p9dzg8byxdsvjadxia";
  };

  go-semver = buildFromGitHub {
    version = 3;
    rev = "1817cd4bea52af76542157eeabd74b057d1a199e";
    owner  = "coreos";
    repo   = "go-semver";
    sha256 = "0fkf0myxfwwwcngk7wl3yr593xyvx905ag1s4hfbxx0mzgn7zy9n";
    date = "2017-06-13";
  };

  go-shared = buildFromGitHub {
    version = 3;
    rev = "v0.1.1";
    owner  = "pengsrc";
    repo   = "go-shared";
    sha256 = "038w697lqiz83qxjrvnvfdj0jdr588sy0wggzshmwgry2lpzdsh2";
    propagatedBuildInputs = [
      gabs
      logrus
      yaml_v2
    ];
  };

  go-shellquote = buildFromGitHub {
    version = 3;
    rev = "cd60e84ee657ff3dc51de0b4f55dd299a3e136f2";
    owner  = "kballard";
    repo   = "go-shellquote";
    sha256 = "1mihgvq5vmj0z3fp1kp5ap8bl46inb8np2andw97fabcck86qvyy";
    date = "2017-06-19";
  };

  go-shellwords = buildFromGitHub {
    version = 2;
    rev = "v1.0.3";
    owner  = "mattn";
    repo   = "go-shellwords";
    sha256 = "11prxlsk3kwgq6v5ikdsjv5vjv4hfihvw55qc27jip1ia2grcxvz";
  };

  go-shuffle = buildFromGitHub {
    version = 3;
    owner = "shogo82148";
    repo = "go-shuffle";
    date = "2017-08-08";
    rev = "59829097ff3b062427a69e2c461ef60523e37280";
    sha256 = "0bmad1aljj4afl6r1h1wqaiw9f2gxn1xb3kwsg0d2rn15497a2k2";
  };

  go-simplejson = buildFromGitHub {
    version = 2;
    rev = "da1a8928f709389522c8023062a3739f3b4af419";
    owner  = "bitly";
    repo   = "go-simplejson";
    sha256 = "0qrqmhi7wng3nb42ch4pp7xly2yia8grg3mkifqnra5d9pr7q91j";
    date = "2017-02-06";
  };

  go-smux-multistream = buildFromGitHub {
    version = 3;
    rev = "afa6825376c14a0462fd420a7d4b4d157c937a42";
    owner  = "whyrusleeping";
    repo   = "go-smux-multistream";
    sha256 = "1ckx5y4kqfwfvs9qf4zb1cc699kqsr91i6wnr69zxdsjaxkhqq0n";
    date = "2017-09-12";
    propagatedBuildInputs = [
      go-stream-muxer
      go-multistream
    ];
  };

  go-smux-spdystream = buildFromGitHub {
    version = 3;
    rev = "a6182ff2a058b177f3dc7513fe198e6002f7be78";
    owner  = "whyrusleeping";
    repo   = "go-smux-spdystream";
    sha256 = "1kifzd34j5pcigl47ly5m0jzgl5z0kjk7sa5jfcd4jpx2h3anf2c";
    date = "2017-09-12";
    propagatedBuildInputs = [
      go-stream-muxer
      spdystream
    ];
  };

  go-smux-yamux = buildFromGitHub {
    version = 3;
    rev = "4b90b786fa86d970c5db5a3b61088de8c8c0c14c";
    owner  = "whyrusleeping";
    repo   = "go-smux-yamux";
    sha256 = "07cllzg90iav1qykc1hczg9ir9fy948gvfkyis1n7s56xn4r6kmj";
    date = "2017-09-16";
    propagatedBuildInputs = [
      go-stream-muxer
      whyrusleeping_yamux
    ];
  };

  go-snappy = buildFromGitHub {
    version = 3;
    rev = "d8f7bb82a96d89c1254e5a6c967134e1433c9ee2";
    owner  = "siddontang";
    repo   = "go-snappy";
    sha256 = "16kr17w2hp91hilncavr4kv06xw6c85vgzzsn330ww5gfvda4x7c";
    date = "2014-07-04";
  };

  hashicorp_go-sockaddr = buildFromGitHub {
    version = 3;
    rev = "9b4c5fa5b10a683339a270d664474b9f4aee62fc";
    owner  = "hashicorp";
    repo   = "go-sockaddr";
    sha256 = "1b1jnaacx2dpmj5bk4909kalzmyak6a1xxcbd78kbcdlwmlds55v";
    date = "2017-10-30";
    propagatedBuildInputs = [
      mitchellh_cli
      columnize
      errwrap
      go-wordwrap
    ];
  };

  libp2p_go-sockaddr = buildFromGitHub {
    version = 3;
    rev = "9ad2a49ab6a4f3e1ac08dffb3aa1f110dc062807";
    owner  = "libp2p";
    repo   = "go-sockaddr";
    sha256 = "1dhigl279lf6izgjkn628h9xaq35q8xr50c6lglmm3p5nskbkdlq";
    date = "2017-11-09";
    propagatedBuildInputs = [
      sys
    ];
  };

  go-spew = buildFromGitHub {
    version = 3;
    rev = "ecdeabc65495df2dec95d7c4a4c3e021903035e5";
    owner  = "davecgh";
    repo   = "go-spew";
    sha256 = "07d5jx3yisrapyy7wlppxxnikcw84g2yzajddzsx3y4c4v1bbxak";
    date = "2017-10-05";
  };

  go-sqlite3 = buildFromGitHub {
    version = 3;
    rev = "v1.4.0";
    owner  = "mattn";
    repo   = "go-sqlite3";
    sha256 = "1s7sm39n1i6dgj98dgzgw697zv0qx4mpgw0hhlgwz9n4y9c66z3i";
    excludedPackages = "test";
    buildInputs = [
      goquery
    ];
    propagatedBuildInputs = [
      net
    ];
  };

  go-statsd-client = buildFromGitHub {
    version = 3;
    rev = "ce77ca9ecdee1c3ffd097e32f9bb832825ccb203";
    owner  = "cactus";
    repo   = "go-statsd-client";
    sha256 = "01k99bprg2x6zd29v4cpva0pzk7v6p0rrvs0n2ggg5k1cilnvxz0";
    date = "2017-08-31";
    excludedPackages = "test";
  };

  go-stdlib = buildFromGitHub {
    version = 3;
    rev = "b1a47cfbdd7543e70e9ef3e73d0802ad306cc1cc";
    owner  = "opentracing-contrib";
    repo   = "go-stdlib";
    sha256 = "020qjzwm37jbd34nb37qjvcgn3d922k28q44ycfgc8i4phv0gnbv";
    date = "2017-10-29";
    propagatedBuildInputs = [
      opentracing-go
    ];
  };

  go-stream-muxer = buildFromGitHub {
    version = 3;
    rev = "6ebe3f58af097068454b167a89442050b023b571";
    owner  = "libp2p";
    repo   = "go-stream-muxer";
    sha256 = "0isz6ab308sdd7a1jsp82db6fx36nb2wxbag15494rv8rwmhwnsg";
    date = "2017-09-11";
  };

  go-stun = buildFromGitHub {
    version = 3;
    rev = "d9bbe8f8fa7bf7ed03e6cfc6a2796bb36139e1f4";
    owner  = "ccding";
    repo   = "go-stun";
    sha256 = "0ylnb9z4kb7x58c1h7mzq1m3kg85fipzc51hdafwwgs08r6g0477";
    date = "2017-12-06";
  };

  go-syslog = buildFromGitHub {
    version = 3;
    date = "2017-08-29";
    rev = "326bf4a7f709d263f964a6a96558676b103f3534";
    owner  = "hashicorp";
    repo   = "go-syslog";
    sha256 = "07z5anbqzgvcd59isahgvisdsq55asqn2d21292zm3xgacpghm4g";
  };

  go-systemd = buildFromGitHub {
    version = 3;
    rev = "c966a8af8422394b2e370d90e2101adba21c14be";
    owner = "coreos";
    repo = "go-systemd";
    sha256 = "08rk040k22ymd5z7bm9l534yyfsgza0dp41vivj826ch6dzndrb2";
    propagatedBuildInputs = [
      dbus
      pkg
      pkgs.systemd_lib
    ];
    date = "2017-11-30";
  };

  go-systemd_journal = buildFromGitHub {
    inherit (go-systemd) rev owner repo sha256 version date;
    subPackages = [
      "journal"
    ];
  };

  go-tcp-transport = buildFromGitHub {
    version = 3;
    owner = "libp2p";
    repo = "go-tcp-transport";
    rev = "7596c75059d4416cec6a8e21f62f327889517920";
    sha256 = "09fcg6wj9gyyjbpsllw6gww824hwkdnl88dfyshpwibgrb7bskrw";
    date = "2017-12-04";
    propagatedBuildInputs = [
      go-log
      go-libp2p-transport
      go-multiaddr
      go-multiaddr-net
      go-reuseport
      mafmt
    ];
  };

  go-temp-err-catcher = buildFromGitHub {
    version = 3;
    owner = "jbenet";
    repo = "go-temp-err-catcher";
    rev = "aac704a3f4f27190b4ccc05f303a4931fd1241ff";
    sha256 = "19ivkcjl34avnzv5jilpiygv2ikzbnnd43axvdisc4cwdkrcwd11";
    date = "2015-01-20";
  };

  go-testing-interface = buildFromGitHub {
    version = 3;
    owner = "mitchellh";
    repo = "go-testing-interface";
    rev = "a61a99592b77c9ba629d254a693acffaeb4b7e28";
    sha256 = "1ml2xzp6lzbf9vzvvsjgfw667md6dnbjh8830s8a29l2flwsa5jd";
    date = "2017-10-04";
  };

  go-toml = buildFromGitHub {
    version = 3;
    owner = "pelletier";
    repo = "go-toml";
    rev = "4e9e0ee19b60b13eb79915933f44d8ed5f268bdd";
    sha256 = "16qb7xfivagj5lrdc23icicchpg1fskdsc3pm5dp5064m88jw9c5";
    propagatedBuildInputs = [
      go-buffruneio
    ];
    meta.useUnstable = true;
    date = "2017-10-24";
  };

  go-units = buildFromGitHub {
    version = 3;
    rev = "v0.3.2";
    owner = "docker";
    repo = "go-units";
    sha256 = "1xdhpf14y3fx9gnf7fwz31rkj2md1bk9vi2mjiwi7fxsp8dbl4zr";
  };

  go-unsnap-stream = buildFromGitHub {
    version = 3;
    rev = "62a9a9eb44fd8932157b1a8ace2149eff5971af6";
    owner = "glycerine";
    repo = "go-unsnap-stream";
    sha256 = "0ds4l7c9cnlmp2bl4vfx2filcd9fac47piganbd00q3js5aw3sjv";
    date = "2017-11-27";
    propagatedBuildInputs = [
      snappy
    ];
  };

  hashicorp_go-uuid = buildFromGitHub {
    version = 3;
    rev = "64130c7a86d732268a38cb04cfbaf0cc987fda98";
    date = "2016-07-17";
    owner  = "hashicorp";
    repo   = "go-uuid";
    sha256 = "143w0jiz5vbn5khy3zyqf05lvlipmr843q0wdm5zdf2iqlxf6hgk";
  };

  satori_go-uuid = buildFromGitHub {
    version = 3;
    rev = "5bf94b69c6b68ee1b541973bb8e1144db23a194b";
    date = "2017-03-21";
    owner  = "satori";
    repo   = "go.uuid";
    sha256 = "0xdavv3zghc00xa8in1427yksbx1lzk2x2fzq8y82vhdj3majrr7";
  };

  go-version = buildFromGitHub {
    version = 3;
    rev = "4fe82ae3040f80a03d04d2cccb5606a626b8e1ee";
    owner  = "hashicorp";
    repo   = "go-version";
    sha256 = "1mfvihzxhdamarf5jkmim0ac6wid85n2scybab58x9qyalkpdig8";
    date = "2017-11-29";
  };

  go-winio = buildFromGitHub {
    version = 3;
    rev = "v0.4.5";
    owner  = "Microsoft";
    repo   = "go-winio";
    sha256 = "1jb47ynakszf0yrgx31m1shgkqngih7ck61p2w47rhwpr4415cyr";
    buildInputs = [
      sys
    ];
    # Doesn't build on non-windows machines
    postPatch = ''
      rm vhd/zvhd.go
    '';
  };

  go-wordwrap = buildFromGitHub {
    version = 2;
    rev = "ad45545899c7b13c020ea92b2072220eefad42b8";
    owner  = "mitchellh";
    repo   = "go-wordwrap";
    sha256 = "0yj17x3c1mr9l3q4dwvy8y2xgndn833rbzsjf10y48yvr12zqjd0";
    date = "2015-03-14";
  };

  go-ws-transport = buildFromGitHub {
    version = 3;
    rev = "de6160a1d0a6c2df87ed00dd607353fb33932e48";
    owner  = "libp2p";
    repo   = "go-ws-transport";
    sha256 = "0fksbz00cml6bfv5m99xpm7dkyrli88pfyir09548h0zyp8psh2c";
    date = "2017-12-05";
    propagatedBuildInputs = [
      go-libp2p-transport
      go-multiaddr
      go-multiaddr-net
      mafmt
      websocket
    ];
  };

  go-xerial-snappy = buildFromGitHub {
    version = 3;
    rev = "bb955e01b9346ac19dc29eb16586c90ded99a98c";
    owner  = "eapache";
    repo   = "go-xerial-snappy";
    sha256 = "055fdp516prfb61sl4gww6mkj0wd909n3m80l5mvhbyngsh67h8i";
    date = "2016-06-09";
    propagatedBuildInputs = [
      snappy
    ];
  };

  go-zookeeper = buildFromGitHub {
    version = 3;
    rev = "471cd4e61d7a78ece1791fa5faa0345dc8c7d5a5";
    date = "2017-11-17";
    owner  = "samuel";
    repo   = "go-zookeeper";
    sha256 = "0wlvvczq9053ccr8ccbpss90zfqdiznfl2dqmzc8h4lj52mwcarb";
  };

  goconfig = buildFromGitHub {
    version = 2;
    owner = "Unknwon";
    repo = "goconfig";
    rev = "87a46d97951ee1ea20ed3b24c25646a79e87ba5d";
    date = "2016-11-21";
    sha256 = "4b1e8153d3bcaa0e5f929b1cd09e4fb780a4753d4aaf8df12b4915c6a65eb70a";
  };

  gorequest = buildFromGitHub {
    version = 3;
    owner = "parnurzeal";
    repo = "gorequest";
    rev = "8e3aed27fe49f7fdc765dad067845f600fc984e8";
    sha256 = "12jgbq5nz9p0bc3d2xld9201hq62vrg1q7f948wrbcvgx33fq6fl";
    propagatedBuildInputs = [
      errors
      http2curl
      net
    ];
    date = "2017-10-15";
  };

  grafana = buildFromGitHub {
    version = 3;
    owner = "grafana";
    repo = "grafana";
    rev = "v4.6.2";
    sha256 = "1yvqhj9nnjlplpp70xi9b1vjybrc2bnrmvn53nnzix2ii3ccyl3l";
    buildInputs = [
      amqp
      aws-sdk-go
      binding
      urfave_cli
      clock
      color
      com
      core
      gojsondiff
      gomail_v2
      go-cache
      go-spew
      go-sqlite3
      go-version
      gzip
      ini_v1
      jaeger-client-go
      ldap
      log15
      macaron_v1
      mysql
      net
      oauth2
      opentracing-go
      pq
      prometheus_client_golang
      prometheus_client_model
      prometheus_common
      session
      slug
      stack
      sync
      toml
      websocket
      xorm
    ];
  };

  graphite-golang = buildFromGitHub {
    version = 2;
    owner = "marpaia";
    repo = "graphite-golang";
    date = "2016-11-29";
    rev = "c474c9b821b4d0a4574edc6412b0003fbce233c4";
    sha256 = "0gvm8x29y4y2cv358hr1cs6sr8p6snbcmnmag6pa0a2sjwahj7i0";
  };

  groupcache = buildFromGitHub {
    version = 3;
    date = "2017-11-01";
    rev = "84a468cf14b4376def5d68c722b139b881c450a4";
    owner  = "golang";
    repo   = "groupcache";
    sha256 = "0lvpbd5qn8r0mkpsizs30d2zbgfr86s9xa4ka2zm7h0ms1a8l182";
    buildInputs = [ protobuf ];
  };

  grpc = buildFromGitHub {
    version = 3;
    rev = "v1.8.1";
    owner = "grpc";
    repo = "grpc-go";
    sha256 = "0wipwslbms0831bnsnv2iz92sq802q2rgvrka1qczdczfww8w09j";
    goPackagePath = "google.golang.org/grpc";
    goPackageAliases = [
      "github.com/grpc/grpc-go"
    ];
    excludedPackages = "\\(test\\|benchmark\\)";
    propagatedBuildInputs = [
      genproto_for_grpc
      glog
      net
      oauth2
      protobuf
    ];
  };

  grpc_for_gax-go = grpc.override {
    propagatedBuildInputs = [
      genproto_for_grpc
      net
      protobuf
    ];
    subPackages = [
      "."
      "balancer"
      "balancer/roundrobin"
      "codes"
      "connectivity"
      "credentials"
      "encoding"
      "grpclb/grpc_lb_v1"
      "grpclb/grpc_lb_v1/messages"
      "grpclog"
      "internal"
      "keepalive"
      "metadata"
      "naming"
      "peer"
      "resolver"
      "resolver/dns"
      "resolver/manual"
      "resolver/passthrough"
      "stats"
      "status"
      "tap"
      "transport"
    ];
  };

  grpc-gateway = buildFromGitHub {
    version = 3;
    rev = "v1.3.0";
    owner = "grpc-ecosystem";
    repo = "grpc-gateway";
    sha256 = "1iqcrp9nnnamnqm9xbw05sx8lhw37z7riyffff0y3ypfayqkshg8";
    propagatedBuildInputs = [
      genproto
      glog
      grpc
      net
      protobuf
    ];
  };

  grpc-websocket-proxy = buildFromGitHub {
    version = 3;
    rev = "830351dc03c6f07d625727d5f993a463babb20e1";
    owner = "tmc";
    repo = "grpc-websocket-proxy";
    sha256 = "03b6066zj7pjrd6j44rzqm47067niaqhjzmvhmmjpcz00fm83qy4";
    date = "2017-10-17";
    propagatedBuildInputs = [
      logrus
      net
      websocket
    ];
  };

  grumpy = buildFromGitHub {
    version = 3;
    owner = "google";
    repo = "grumpy";
    rev = "f1446cd91c750b2439a1eb9a1e92f736a9fbb551";
    sha256 = "6ad8e8b05e189d7c288963c1f1eeed433c6b333ad51c89ec788ae2b1f52b4c03";

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.which
    ];

    buildInputs = [
      pkgs.python2
    ];

    postPatch = ''
      # FIXME: fix executables not installing to $bin correctly
      sed -i Makefile \
        -e "s,[^@]/usr/bin,\)$out/bin,g" \
        -e "s,/usr/lib,$out/lib,g"
    '';

    preBuild = ''
      cd go/src/github.com/google/grumpy
    '';

    buildPhase = ''
      runHook preBuild
      make
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      make install "PY_INSTALL_DIR=$out/${pkgs.python2.sitePackages}"
      runHook postInstall
    '';

    preFixup = ''
      for i in $out/bin/grump{c,run}; do
        wrapProgram  "$i" \
          --set 'GOPATH' : "$out" \
          --prefix 'PYTHONPATH' : "$out/${pkgs.python2.sitePackages}"
      done
      # FIXME: prevent failures
      mkdir -p $bin
    '';

    buildDirCheck = false;

    meta = with lib; {
      description = "Python to Go source code transcompiler and runtime";
      homepage = https://github.com/google/grumpy;
      license = licenses.asl20;
      maintainers = with maintainers; [
        codyopel
      ];
      platforms = with platforms;
        x86_64-linux;
    };
  };

  gx = buildFromGitHub {
    version = 3;
    rev = "v0.12.1";
    owner = "whyrusleeping";
    repo = "gx";
    sha256 = "1x4j3vmv6x1b2hvqfxsy95imv2kcc1g53nq90c0n3q3bzd2fgddf";
    propagatedBuildInputs = [
      go-git-ignore
      go-homedir
      go-multiaddr
      go-multihash
      go-multiaddr-net
      go-os-rename
      json-filter
      progmeter
      semver
      stump
      urfave_cli
      go-ipfs-api
    ];
    excludedPackages = [
      "tests"
    ];
  };

  gx-go = buildFromGitHub {
    version = 3;
    rev = "v1.6.0";
    owner = "whyrusleeping";
    repo = "gx-go";
    sha256 = "1b9dwacxz9h3i5ba5wig3qg737xssk7lyp1c3sj03nhsyz5fb32y";
    buildInputs = [
      urfave_cli
      fs
      go-homedir
      gx
      stump
    ];
  };

  gzip = buildFromGitHub {
    version = 3;
    date = "2016-02-22";
    rev = "cad1c6580a07c56f5f6bc52d66002a05985c5854";
    owner = "go-macaron";
    repo = "gzip";
    sha256 = "0pcm617hb06yaypffmmn8pwm9mwqszhm8bx2bkbfgbjvbnjzqg7g";
    propagatedBuildInputs = [
      compress
      macaron_v1
    ];
  };

  gziphandler = buildFromGitHub {
    version = 3;
    date = "2017-11-20";
    rev = "d6f46609c7629af3a02d791a4666866eed3cbd3e";
    owner = "NYTimes";
    repo = "gziphandler";
    sha256 = "1ycckfi8b5hw7iswp34why0jmx3lrw2pxlbrny6ypld6qkccjnpg";
  };

  hashland = buildFromGitHub {
    version = 3;
    rev = "07375b562deaa8d6891f9618a04e94a0b98e2ee7";
    owner  = "tildeleb";
    repo   = "hashland";
    sha256 = "1rs71c9pi9apwh59m42hdyvi0ax9a59rv12s5wmsq8013c3m2wnj";
    goPackagePath = "leb.io/hashland";
    date = "2017-10-03";
    excludedPackages = "example";
    propagatedBuildInputs = [
      aeshash
      blake2b-simd
      cuckoo
      go-farm
      go-metro
      hrff
      whirlpool
    ];
  };

  hashland_for_aeshash = buildFromGitHub {
    version = 3;
    rev = "07375b562deaa8d6891f9618a04e94a0b98e2ee7";
    owner  = "tildeleb";
    repo   = "hashland";
    sha256 = "1rs71c9pi9apwh59m42hdyvi0ax9a59rv12s5wmsq8013c3m2wnj";
    goPackagePath = "leb.io/hashland";
    date = "2017-10-03";
    subPackages = [
      "nhash"
    ];
  };

  handlers = buildFromGitHub {
    version = 3;
    owner = "gorilla";
    repo = "handlers";
    rev = "v1.3.0";
    sha256 = "18df12yrv4z6kj1c6kjgcmpj2syr8maqdbjm0q2gxv00vpbgxlkn";
  };

  hashstructure = buildFromGitHub {
    version = 3;
    date = "2017-06-09";
    rev = "2bca23e0e452137f789efbc8610126fd8b94f73b";
    owner  = "mitchellh";
    repo   = "hashstructure";
    sha256 = "12z3vcxbdgkn1hfisj3m23kgq9lkl1rby5cik7878sbdy9zkl0bw";
  };

  hcl = buildFromGitHub {
    version = 3;
    date = "2017-10-17";
    rev = "23c074d0eceb2b8a5bfdbb271ab780cde70f05a8";
    owner  = "hashicorp";
    repo   = "hcl";
    sha256 = "1ri7hdbsq574j8ii81rn92l3fyqg7f5i6xxqmdzxs6iclmydf1zm";
  };

  hdrhistogram = buildFromGitHub {
    version = 2;
    date = "2016-10-09";
    rev = "3a0bb77429bd3a61596f5e8a3172445844342120";
    owner  = "codahale";
    repo   = "hdrhistogram";
    sha256 = "0xnsf0yzh4z1iyl0vcbj97cyl19zq37hvjfz533zq91xglgpghmc";
    propagatedBuildInputs = [
      mgo_v2
    ];
  };

  hil = buildFromGitHub {
    version = 3;
    date = "2017-06-27";
    rev = "fa9f258a92500514cc8e9c67020487709df92432";
    owner  = "hashicorp";
    repo   = "hil";
    sha256 = "1m0gzss7vgq9jdc4sx4cjlid1r1zahf0mi0mc4q6b7hz25zkmkwk";
    propagatedBuildInputs = [
      mapstructure
      reflectwalk
    ];
    meta.useUnstable = true;
  };

  hllpp = buildFromGitHub {
    version = 2;
    owner = "retailnext";
    repo = "hllpp";
    date = "2017-03-17";
    rev = "9fdfea05b3e55bebe7beb22d16c7db15d46cd518";
    sha256 = "0b36yn9si929b2z8p13rz8qf74fmkrkmj4igp6slzc8hniv1606r";
  };

  holster = buildFromGitHub {
    version = 3;
    rev = "v1.5.2";
    owner = "mailgun";
    repo = "holster";
    sha256 = "0gjdy0dkaj4w35929bzm3zigi8g23apvdvphx3z84szxpnm71b65";
    subPackages = [
      "."
    ];
    propagatedBuildInputs = [
      errors
      logrus
      structs
    ];
  };

  hotp = buildFromGitHub {
    version = 2;
    rev = "c180d57d286b385101c999a60087a40d7f48fc77";
    owner  = "gokyle";
    repo   = "hotp";
    sha256 = "1sv6fq7nw7crnqn7ycg3f5j3x4g0rahxynjprwh8md3cfj1161xr";
    date = "2016-02-17";
    propagatedBuildInputs = [
      rsc
    ];
  };

  hrff = buildFromGitHub {
    version = 3;
    rev = "757f8bd43e20ae62b376efce979d8e7082c16362";
    owner  = "tildeleb";
    repo   = "hrff";
    sha256 = "0qg0y313a4bb01ki35hrzvf8ad2s616gc9ndnia0a936pwwgvml9";
    goPackagePath = "leb.io/hrff";
    date = "2017-09-27";
  };

  http2curl = buildFromGitHub {
    version = 3;
    owner = "moul";
    repo = "http2curl";
    date = "2017-09-19";
    rev = "9ac6cf4d929b2fa8fd2d2e6dec5bb0feb4f4911d";
    sha256 = "1v2sjbgcnip3j1fx05wp73xcw0j8h6p6nwwy5mbc297yklyycvi7";
  };

  httpcache = buildFromGitHub {
    version = 3;
    rev = "2bcd89a1743fd4b373f7370ce8ddc14dfbd18229";
    owner  = "gregjones";
    repo   = "httpcache";
    sha256 = "15z3qll4513askvy7vrzi7wvw60yj4922aa11vm2mhy9sjp41r9r";
    date = "2017-11-19";
    propagatedBuildInputs = [
      diskv
      goleveldb
      gomemcache
      redigo
    ];
    postPatch = ''
      grep -r '+build appengine' -l | xargs rm
    '';
  };

  http-link-go = buildFromGitHub {
    version = 3;
    rev = "ac974c61c2f990f4115b119354b5e0b47550e888";
    owner  = "tent";
    repo   = "http-link-go";
    sha256 = "05zir2mh47n1mlrnxgahxplxnaib0248xijd26mfs4ws88507bv3";
    date = "2013-07-02";
  };

  httprequest_v1 = buildFromGitHub {
    version = 3;
    rev = "35158f716c228fdf58b5a5b80cf331302d10160a";
    owner  = "go-httprequest";
    repo   = "httprequest";
    sha256 = "1sfhjqm5fqzyd3ni8ywrdjv1z1pzg64lq347l7n8w3a79g1wic25";
    date = "2017-11-03";
    goPackagePath = "gopkg.in/httprequest.v1";
    goPackageAliases = [
      "github.com/juju/httprequest"
    ];
    propagatedBuildInputs = [
      errgo_v1
      httprouter
      net
      tools
    ];
  };

  httprouter = buildFromGitHub {
    version = 3;
    rev = "e1b9828bc9e5904baec057a154c09ca40fe7fae0";
    owner  = "julienschmidt";
    repo   = "httprouter";
    sha256 = "1jvj04b26nq955ixbkkqwagmarxqzln962vzdywc05s26y97ri41";
    date = "2017-10-27";
  };

  httpunix = buildFromGitHub {
    version = 3;
    rev = "b75d8614f926c077e48d85f1f8f7885b758c6225";
    owner  = "tv42";
    repo   = "httpunix";
    sha256 = "03pz7s57v5hmy1hlsannj48zxy1rl8d4rymdlvqh3qisz7705izw";
    date = "2015-04-27";
  };

  hugo = buildFromGitHub {
    version = 3;
    owner = "gohugoio";
    repo = "hugo";
    rev = "v0.31.1";
    sha256 = "16gc3si23s51529rrh43ld2y9r0qilhl6nv8581sq03jvh9l307d";
    buildInputs = [
      ace
      afero
      amber
      blackfriday
      cast
      chroma
      cobra
      cssmin
      emoji
      fsnotify
      fsync
      gitmap
      go-i18n
      go-immutable-radix
      go-toml
      goorgeous
      image
      inflect
      jwalterweatherman
      mage
      mapstructure
      mmark
      nitro
      osext
      pflag
      prose
      purell
      text
      toml
      viper
      websocket
      yaml_v2
    ];
  };

  idmclient = buildFromGitHub {
    version = 3;
    rev = "15392b0e99abe5983297959c737b8d000e43b34c";
    owner  = "juju";
    repo   = "idmclient";
    sha256 = "1z91hpkd0panc0qgprr9dlky0ib39x4vphxz0jb1la9y8azi7w7g";
    date = "2017-11-10";
    excludedPackages = "test";
    propagatedBuildInputs = [
      environschema_v1
      errgo_v1
      httprequest_v1
      macaroon_v2
      macaroon-bakery_v2
      names_v2
      net
      usso
      utils
    ];
  };

  image-spec = buildFromGitHub {
    version = 3;
    rev = "v1.0.1";
    owner  = "opencontainers";
    repo   = "image-spec";
    sha256 = "1ar8vvah76z4nv7wygamkz0dyzkgikg5px3rd7g6ymyfc1vjpsl1";
    propagatedBuildInputs = [
      errors
      go4
      go-digest
      gojsonschema
    ];
  };

  inf_v0 = buildFromGitHub {
    version = 3;
    rev = "v0.9.0";
    owner  = "go-inf";
    repo   = "inf";
    sha256 = "0wc22yz8wmysdbsh4z1nmfa8465knhacxjfpfqy1ifqjffw3nqxd";
    goPackagePath = "gopkg.in/inf.v0";
  };

  inflect = buildFromGitHub {
    version = 3;
    owner = "markbates";
    repo = "inflect";
    rev = "8656ca7f45f5ed737dbe42c370dc31d1f583b7f5";
    date = "2017-11-29";
    sha256 = "0blhkyg4afgpy1y1iq9qyp72k0wm0yx18r8ha8hca7x7b285iiy5";
  };

  influxdb = buildFromGitHub {
    version = 3;
    owner = "influxdata";
    repo = "influxdb";
    rev = "v1.4.2";
    sha256 = "1vwb5vzw40v0fjg2yn1b6dq7cag3skz5cd51svl6wlvz6c4aifyy";
    propagatedBuildInputs = [
      bolt
      crypto
      encoding
      go-bits
      go-bitstream
      go-collectd
      hllpp
      jwt-go
      liner
      murmur3
      pat
      gogo_protobuf
      ratecounter
      snappy
      statik
      sys
      toml
      usage-client
      xxhash
      zap
    ];
    goPackageAliases = [
      "github.com/influxdb/influxdb"
    ];
    postPatch = /* Remove broken tests */ ''
      rm -rf services/collectd/test_client
    '';
  };

  influxdb_client = buildFromGitHub {
    inherit (influxdb) owner repo rev sha256 version;
    goPackageAliases = [
      "github.com/influxdb/influxdb"
    ];
    subPackages = [
      "client"
      "client/v2"
      "models"
      "pkg/escape"
    ];
  };

  ini = buildFromGitHub {
    version = 3;
    rev = "v1.32.0";
    owner  = "go-ini";
    repo   = "ini";
    sha256 = "044q7hslpni3jpb0v0g411xn2fi8fzyp79zyjxzb7y23nfsqywjy";
  };

  ini_v1 = buildFromGitHub {
    version = 3;
    rev = "v1.32.0";
    owner  = "go-ini";
    repo   = "ini";
    goPackagePath = "gopkg.in/ini.v1";
    sha256 = "0jm4l7libijis9nqx1wwcddsac78f5z1dp6fxf2yzkjbnzh8y3zy";
  };

  inject = buildFromGitHub {
    version = 3;
    date = "2016-06-27";
    rev = "d8a0b8677191f4380287cfebd08e462217bac7ad";
    owner = "go-macaron";
    repo = "inject";
    sha256 = "1q8ma0266zims9cxkar908dln67m2awdfvrnxrv16p5grka5jixi";
  };

  internal = buildFromGitHub {
    version = 3;
    rev = "4747030f7cf2f4c0a01512b00cd68734b167ac3b";
    owner  = "cznic";
    repo   = "internal";
    sha256 = "0kmsbgr8qjqxbzymnb0hyk7xickqddzlmffpl7rjw88jmpafks0a";
    date = "2017-09-05";
    buildInputs = [
      fileutil
      mathutil
      mmap-go
    ];
  };

  ipfs = buildFromGitHub {
    version = 3;
    rev = "v0.4.13";
    owner = "ipfs";
    repo = "go-ipfs";
    sha256 = "6e763deafa9fb3d1c28ea4c7a9d12a1e65813636890025676dbabe1e71b35282";
    gxSha256 = "0z6if76il0nqfqzw5vbxi5ngd3d79cjq42x4sd60m6sdlrgzrkm5";
    nativeBuildInputs = [
      gx-go.bin
    ];
    allowVendoredSources = true;
    excludedPackages = "test";
    meta.autoUpdate = false;
    postInstall = ''
      find "$bin"/bin -not -name ipfs\* -mindepth 1 -maxdepth 1 -delete
    '';
  };

  ipfs-cluster = buildFromGitHub {
    version = 3;
    rev = "34c815b0eee078f2157889062e5e7589c8943da3";
    owner = "ipfs";
    repo = "ipfs-cluster";
    sha256 = "07g8k5i7kij3c6agp9rrc1ch6zlf50i5mmwkd65x621q3l7x7v64";
    meta.useUnstable = true;
    date = "2017-12-07";
    excludedPackages = "test";
    propagatedBuildInputs = [
      urfave_cli
      go4
      go-cid
      go-libp2p
      go-libp2p-crypto
      go-libp2p-consensus
      go-libp2p-host
      go-libp2p-interface-pnet
      go-libp2p-gorpc
      go-libp2p-peerstore
      go-libp2p-pnet
      go-libp2p-protocol
      go-libp2p-peer
      go-libp2p-raft
      go-libp2p-swarm
      go-log
      go-multiaddr
      go-multiaddr-dns
      go-multiaddr-net
      go-multicodec
      mux
      raft
      raft-boltdb
    ];
  };

  jaeger-client-go = buildFromGitHub {
    version = 3;
    owner = "jaegertracing";
    repo = "jaeger-client-go";
    rev = "v2.11.0";
    sha256 = "1rd81s1q902hdzr2zby9bycg2vgfnhr9g5l8bwwc3vfvx9g1kgm2";
    goPackagePath = "github.com/uber/jaeger-client-go";
    excludedPackages = "crossdock";
    propagatedBuildInputs = [
      jaeger-lib
      net
      opentracing-go
      thrift
      zap
    ];
  };

  jaeger-lib = buildFromGitHub {
    version = 3;
    owner = "jaegertracing";
    repo = "jaeger-lib";
    rev = "v1.2.1";
    sha256 = "0xwai5gslgjxfxpmk2jvy2di9aws30s18vnk2ymb19br3ar3an4m";
    goPackagePath = "github.com/uber/jaeger-lib";
    excludedPackages = "test";
    propagatedBuildInputs = [
      hdrhistogram
      kit
      prometheus_client_golang
      tally
    ];
    postPatch = ''
      grep -q 'hv.WithLabelValues' metrics/prometheus/factory.go
      sed -i '/hv.WithLabelValues/s#),#).(prometheus.Histogram),#g' metrics/prometheus/factory.go
    '';
  };

  jose = buildFromGitHub {
    version = 3;
    owner = "SermoDigital";
    repo = "jose";
    rev = "1.1";
    sha256 = "1m2b6y8y0nvg6g7w9a38gambajfx9m1a6a3p1r6n88fyr9j2l434";
  };

  json-filter = buildFromGitHub {
    version = 3;
    owner = "whyrusleeping";
    repo = "json-filter";
    rev = "ff25329a9528f01c5175414f16cc0a6a162a5b8b";
    date = "2016-06-15";
    sha256 = "0slxjrhnh55jdhhlp4np6fr133pv3wlqgi37bjxgy6jwcm29iidq";
  };

  json-patch = buildFromGitHub {
    version = 3;
    owner = "evanphx";
    repo = "json-patch";
    rev = "944e07253867aacae43c04b2e6a239005443f33a";
    date = "2017-07-19";
    sha256 = "0q7zag1ng95a07xrwdw48bqw7dh7ky8frwadbpd85nxwl6fc7z61";
    propagatedBuildInputs = [
      go-flags
    ];
  };

  jsonpointer = buildFromGitHub {
    version = 2;
    owner = "go-openapi";
    repo = "jsonpointer";
    rev = "779f45308c19820f1a69e9a4cd965f496e0da10f";
    date = "2017-01-02";
    sha256 = "1kdgq87bns9xzvyyybcdk3hj09l8ic8s758dxldj91jjlbd2cc2x";
    propagatedBuildInputs = [
      swag
    ];
  };

  jsonreference = buildFromGitHub {
    version = 2;
    owner = "go-openapi";
    repo = "jsonreference";
    rev = "36d33bfe519efae5632669801b180bf1a245da3b";
    date = "2016-11-05";
    sha256 = "0xqaz9kwlwj205ma9z7dm3j5ad2cl2cs0mvs3xqw3mvd6p0dmg7h";
    propagatedBuildInputs = [
      jsonpointer
      purell
    ];
  };

  jsonx = buildFromGitHub {
    version = 2;
    owner = "jefferai";
    repo = "jsonx";
    rev = "9cc31c3135eef39b8e72585f37efa92b6ca314d0";
    date = "2016-07-21";
    sha256 = "0s5zani868a70hpacqxl1qzzwc8hdappb99qixmbfkf7wdyyzfic";
    propagatedBuildInputs = [
      gabs
    ];
  };

  jwalterweatherman = buildFromGitHub {
    version = 3;
    owner = "spf13";
    repo = "jWalterWeatherman";
    rev = "12bd96e66386c1960ab0f74ced1362f66f552f7b";
    date = "2017-09-01";
    sha256 = "1hl1qzgxm3f5abpa2ic1gna7x5kjlikfgqar7dg2nbvlvxrwbg7l";
    goPackageAliases = [
      "github.com/spf13/jwalterweatherman"
    ];
  };

  jwt-go = buildFromGitHub {
    version = 3;
    owner = "dgrijalva";
    repo = "jwt-go";
    rev = "v3.1.0";
    sha256 = "1rlpcz2riqhlzr5rz1jhy7d6xkkrm5x4669x2pav00dvpgaj77cx";
  };

  kcp-go = buildFromGitHub {
    version = 3;
    owner = "AudriusButkevicius";
    repo = "kcp-go";
    rev = "8ae5f528469c6ab76110f41eb7a51341b7efb946";
    sha256 = "0aw5y8fcg92x21acndqz1qnbp7j8xngazp30g53nbld2806nca8b";
    propagatedBuildInputs = [
      crypto
      errors
      gmsm
      net
      templexxx_reedsolomon
      xor
    ];
    date = "2017-10-25";
  };

  gravitational_kingpin = buildFromGitHub {
    version = 3;
    rev = "52bc17adf63c0807b5e5b5d91350703630f621c7";
    owner = "gravitational";
    repo = "kingpin";
    sha256 = "1jrlcdblk8vpb544jk4m3rdkzvdmd6qp3ykwspwagy909dpjgwmc";
    propagatedBuildInputs = [
      template
      units
    ];
    meta.useUnstable = true;
    date = "2017-09-06";
  };

  kingpin_v2 = buildFromGitHub {
    version = 3;
    rev = "v2.2.5";
    owner = "alecthomas";
    repo = "kingpin";
    sha256 = "0sysp3c9i1vim5w9hbjaklnwskyyddxdfmlx0qcxw4csb5iacppv";
    goPackagePath = "gopkg.in/alecthomas/kingpin.v2";
    propagatedBuildInputs = [
      template
      units
    ];
  };

  kit = buildFromGitHub {
    version = 3;
    rev = "v0.6.0";
    owner = "go-kit";
    repo = "kit";
    sha256 = "1v28lsb4n921zylska4ca8cz11sgs2jzcgcyr8ciap5mv5i1xj01";
    subPackages = [
      "log"
      "log/level"
      "metrics"
      "metrics/expvar"
      "metrics/generic"
      "metrics/influx"
      "metrics/internal/lv"
      "metrics/prometheus"
    ];
    propagatedBuildInputs = [
      gohistogram
      influxdb_client
      logfmt
      prometheus_client_golang
      stack
    ];
  };

  kit_for_prometheus = kit.override {
    subPackages = [
      "log"
      "log/level"
    ];
    propagatedBuildInputs = [
      logfmt
      stack
    ];
  };

  kubernetes-api = buildFromGitHub {
    version = 3;
    rev = "218912509d74a117d05a718bb926d0948e531c20";
    owner  = "kubernetes";
    repo   = "api";
    sha256 = "1wcnm61kqclpg940jbkyfl5yf6aha9887kk8agc9fv28b2v74pw8";
    goPackagePath = "k8s.io/api";
    goPackageAliases = [
      "k8s.io/client-go/pkg/apis"
    ];
    propagatedBuildInputs = [
      gogo_protobuf
      kubernetes-apimachinery
    ];
    meta.useUnstable = true;
    date = "2017-10-27";
  };

  kubernetes-apimachinery = buildFromGitHub {
    version = 3;
    rev = "18a564baac720819100827c16fdebcadb05b2d0d";
    owner  = "kubernetes";
    repo   = "apimachinery";
    sha256 = "1p23kkmmaqnc99qggjqy6nf6iswqfaij8h0qk3d2laxv2gnckaq8";
    goPackagePath = "k8s.io/apimachinery";
    excludedPackages = "\\(testing\\|fuzzer\\)";
    propagatedBuildInputs = [
      glog
      gofuzz
      go-flowrate
      go-spew
      gogo_protobuf
      golang-lru
      kubernetes-kube-openapi
      inf_v0
      json-iterator_go
      json-patch
      net
      pborman_uuid
      pflag
      spdystream
      spec_openapi
      yaml
    ];
    meta.useUnstable = true;
    date = "2017-10-27";
  };

  kubernetes-kube-openapi = buildFromGitHub {
    version = 3;
    rev = "c4fd2f0a5bff91647fd75e77ea52a8722264b0ce";
    date = "2017-12-05";
    owner  = "kubernetes";
    repo   = "kube-openapi";
    sha256 = "0vnq5y1wqa0zrkgfq5mamxcn0hdqh000m2dn9j6wjsyw3rgq0j1n";
    goPackagePath = "k8s.io/kube-openapi";
    subPackages = [
      "pkg/common"
    ];
    propagatedBuildInputs = [
      go-restful
      spec_openapi
    ];
  };

  kubernetes-client-go = buildFromGitHub {
    version = 3;
    rev = "72e1c2a1ef30b3f8da039e92d4a6a1f079f374e8";
    owner  = "kubernetes";
    repo   = "client-go";
    sha256 = "1mcxpg38vamq6dii625aib0k8cakzy3j46jh9s5pw2zwyw1g6fzp";
    goPackagePath = "k8s.io/client-go";
    propagatedBuildInputs = [
      diskv
      glog
      gnostic
      gopass
      gophercloud
      go-autorest
      go-oidc
      go-restful-swagger12
      groupcache
      httpcache
      kubernetes-api
      kubernetes-apimachinery
      mergo
      net
      oauth2
      pflag
      protobuf
      ratelimit
    ];
    meta.useUnstable = true;
    date = "2017-11-01";
  };

  ldap = buildFromGitHub {
    version = 3;
    rev = "v2.5.1";
    owner  = "go-ldap";
    repo   = "ldap";
    sha256 = "0csrsr88k66yfd95lwznikh1iij6zsr45mcbxaswz5l12fsm7l9w";
    goPackageAliases = [
      "github.com/nmcclain/ldap"
      "github.com/vanackere/ldap"
    ];
    propagatedBuildInputs = [
      asn1-ber
    ];
  };

  ledisdb = buildFromGitHub {
    version = 3;
    rev = "v0.6";
    owner  = "siddontang";
    repo   = "ledisdb";
    sha256 = "1bzqlmna1l59dlhx53gnb75ncg76sp299g2vzwayz4159n875gk8";
    prePatch = ''
      dirs=($(find . -type d -name vendor | sort))
      echo "''${dirs[@]}" | xargs -n 1 rm -r
    '';
    subPackages = [
      "config"
      "ledis"
      "rpl"
      "store"
      "store/driver"
      "store/goleveldb"
      "store/leveldb"
      "store/rocksdb"
    ];
    propagatedBuildInputs = [
      siddontang_go
      go-toml
      net
      goleveldb
      mmap-go
      siddontang_rdb
    ];
  };

  lego = buildFromGitHub {
    version = 3;
    rev = "v0.4.1";
    owner = "xenolf";
    repo = "lego";
    sha256 = "0nwqwvjq2yp2shycn8ipr3cb8wij00kgkaybgd7147cspbzfmnrq";
    buildInputs = [
      auroradnsclient
      aws-sdk-go
      azure-sdk-for-go
      urfave_cli
      crypto
      dns
      dnspod-go
      dnsimple-go
      egoscale
      go-autorest
      go-jose_v1
      go-ovh
      google-api-go-client
      linode
      memcache
      ns1-go_v2
      oauth2
      net
      testify
      vultr
    ];
  };

  lemma = buildFromGitHub {
    version = 3;
    rev = "4214099fb348c416514bc2c93087fde56216d7b5";
    owner = "mailgun";
    repo = "lemma";
    sha256 = "1xm2bz2z3v4fwv53qzb6ayxqmjjhalp0kq1gr49sq2xmslhcl83q";
    date = "2017-06-19";
    propagatedBuildInputs = [
      crypto
      metrics
      timetools
      mailgun_ttlmap
    ];
  };

  lex = buildFromGitHub {
    version = 3;
    rev = "68050f59b71a42ca5b94e7b832e5bc2cdb48af66";
    date = "2017-01-12";
    owner = "cznic";
    repo = "lex";
    sha256 = "1gx2rp0169aznsnv924q80777mzncb0w9vb2vppszpg30kh5w8zv";
    propagatedBuildInputs = [
      fileutil
      lexer
    ];
  };

  lexer = buildFromGitHub {
    version = 3;
    rev = "52ae7862082bd9649e03c1c4013a104b37811bfa";
    date = "2014-12-11";
    owner = "cznic";
    repo = "lexer";
    sha256 = "1sdwxgdx26lzaiprwkc5h8fxnxiq5qaihpqggsmw6205b5rb1yad";
    propagatedBuildInputs = [
      exp
      fileutil
    ];
  };

  libkv = buildFromGitHub {
    version = 3;
    rev = "93ab0e6c056d325dfbb11e1d58a3b4f5f62e7f3c";
    owner = "docker";
    repo = "libkv";
    sha256 = "14qw4rmhw5biq5mpiqyrlvzp0vhy2ilgxvgbxflp6114l5w0vkki";
    date = "2017-07-01";
    excludedPackages = "\\(mock\\|testutils\\)";
    propagatedBuildInputs = [
      bolt
      consul_api
      etcd_client
      go-zookeeper
      net
    ];
  };

  libnetwork = buildFromGitHub {
    version = 3;
    rev = "ea0db4f8a82d7216072d889a6da141906c277ec5";
    owner = "docker";
    repo = "libnetwork";
    sha256 = "17xggvjxrf4bc8flbsrkpfxjf6mia013jx7lsj0kn63xqn3y9qxy";
    date = "2017-12-07";
    subPackages = [
      "datastore"
      "discoverapi"
      "types"
    ];
    propagatedBuildInputs = [
      libkv
    ];
  };

  libseccomp-golang = buildFromGitHub {
    version = 2;
    rev = "v0.9.0";
    owner = "seccomp";
    repo = "libseccomp-golang";
    sha256 = "0kvrysdhq8yqcv4cvf1bmc38f6fwj2cwvw2zd004gka0qdmwhxx3";
    buildInputs = [
      pkgs.libseccomp
    ];
  };

  libtrust = buildFromGitHub {
    version = 2;
    rev = "aabc10ec26b754e797f9028f4589c5b7bd90dc20";
    owner = "docker";
    repo = "libtrust";
    sha256 = "40837c2420436be95f8098bf3a9c1b2820b72ec2b43fd0983a00c006d66ba1e8";
    date = "2016-07-08";
    postPatch = /* Demo uses same package namespace as actual library */ ''
      rm -rfv tlsdemo
    '';
  };

  liner = buildFromGitHub {
    version = 3;
    rev = "3681c2a912330352991ecdd642f257efe5b85518";
    owner = "peterh";
    repo = "liner";
    sha256 = "110j0y6iqljydwh1w2y396bzn9w68lkly177slawkmzl7vp4yfkp";
    date = "2017-11-22";
  };

  linode = buildFromGitHub {
    version = 2;
    rev = "37e84520dcf74488f67654f9c775b9752c232dc1";
    owner = "timewasted";
    repo = "linode";
    sha256 = "13ypkib9nmm8pc2z8yqa97gh3karvrhwas0i4ck88pqhxwi85liw";
    date = "2016-08-29";
  };

  lldb = buildFromGitHub {
    version = 2;
    rev = "bea8611dd5c407f3c5eab9f9c68e887a27dc6f0e";
    owner  = "cznic";
    repo   = "lldb";
    sha256 = "1a3zd71vkvz1c319ihpmrky4zy84lazhsy3gwmnac71f6r8schii";
    propagatedBuildInputs = [
      fileutil
      mathutil
      mmap-go
      sortutil
    ];
    extraSrcs = [
      internal
      zappy
    ];
    meta.useUnstable = true;
    date = "2016-11-02";
  };

  log15 = buildFromGitHub {
    version = 3;
    rev = "0decfc6c20d9ca0ad143b0e89dcaa20f810b4fb3";
    owner  = "inconshreveable";
    repo   = "log15";
    sha256 = "1d5i3yv6571lbdpwag711v34m4psp49is63zqrk3lpfkrwyasf71";
    goPackageAliases = [
      "gopkg.in/inconshreveable/log15.v2"
    ];
    propagatedBuildInputs = [
      go-colorable
      go-isatty
      stack
      sys
    ];
    date = "2017-10-19";
  };

  kr_logfmt = buildFromGitHub {
    version = 3;
    rev = "b84e30acd515aadc4b783ad4ff83aff3299bdfe0";
    owner  = "kr";
    repo   = "logfmt";
    sha256 = "1p9z8ni7ijg0qxqyhkqr2aq80ll0mxkq0fk5mgsd8ly9l9f73mjc";
    date = "2014-02-26";
  };

  logfmt = buildFromGitHub {
    version = 3;
    rev = "v0.3.0";
    owner  = "go-logfmt";
    repo   = "logfmt";
    sha256 = "104vw0802vk9rmwdzqfqdl616q2g8xmzbwmqcl35snl2dggg5sia";
    propagatedBuildInputs = [
      kr_logfmt
    ];
  };

  lunny_log = buildFromGitHub {
    version = 2;
    rev = "7887c61bf0de75586961948b286be6f7d05d9f58";
    owner = "lunny";
    repo = "log";
    sha256 = "0jsk5yc7lqlh9zicadbhxh6as3vlhln08f2wxrbnpcw0b1jncnp1";
    date = "2016-09-21";
  };

  mailgun_log = buildFromGitHub {
    version = 2;
    rev = "2f35a4607f1abf71f97f77f99b0de8493ef6f4ef";
    owner = "mailgun";
    repo = "log";
    sha256 = "1akyw7r5as06b6inn16wh9gg16zx3729nxmrgg0c46sgy23xmh9m";
    date = "2015-09-25";
  };

  loggo = buildFromGitHub {
    version = 3;
    rev = "8232ab8918d91c72af1a9fb94d3edbe31d88b790";
    owner = "juju";
    repo = "loggo";
    sha256 = "0scrnv3kmqilcc06j5d00sdqsiqx42p95n4q72ar7ynvkgngzxzf";
    date = "2017-06-05";
    propagatedBuildInputs = [
      ansiterm
    ];
  };

  loghisto = buildFromGitHub {
    version = 2;
    rev = "9d1d8c1fd2a4ac852bf2e312f2379f553345fda7";
    owner = "spacejam";
    repo = "loghisto";
    sha256 = "0dpfgzlf4n0vvppffxk5qwdb72iq6x320srkd1rzys0fd7xyvyz1";
    date = "2016-03-02";
    propagatedBuildInputs = [
      glog
    ];
  };

  logrus = buildFromGitHub {
    version = 3;
    rev = "v1.0.4";
    owner = "sirupsen";
    repo = "logrus";
    sha256 = "1z2vw438lmva6khkmys1fprfk8a62mxd1klqbaws3lvvw74ys41j";
    goPackageAliases = [
      "github.com/Sirupsen/logrus"
    ];
    propagatedBuildInputs = [
      crypto
      sys
    ];
  };

  logutils = buildFromGitHub {
    version = 3;
    date = "2015-06-09";
    rev = "0dc08b1671f34c4250ce212759ebd880f743d883";
    owner  = "hashicorp";
    repo   = "logutils";
    sha256 = "1g005p42a22ag4qvkb2jx50z638r21vrvvgpwpd3c1d3qazjg7ha";
  };

  logxi = buildFromGitHub {
    version = 2;
    date = "2016-10-27";
    rev = "aebf8a7d67ab4625e0fd4a665766fef9a709161b";
    owner  = "mgutz";
    repo   = "logxi";
    sha256 = "10rvbxihgkwbdbb6pc7pn4jhgjxmq7gvxc8r5hckfi7qmc3z0ahk";
    excludedPackages = "Gododir";
    propagatedBuildInputs = [
      ansi
      go-colorable
      go-isatty
    ];
  };

  lsync = buildFromGitHub {
    version = 3;
    rev = "2d7c40f41402df6f0713a749a011cddc12d1b2f3";
    owner = "minio";
    repo = "lsync";
    sha256 = "1n7kaqly6jgbvp48fznyv94yg9yc6c99pdb3iw3c0kc0ycw9xn4h";
    date = "2017-08-09";
  };

  luhn = buildFromGitHub {
    version = 3;
    rev = "v2.0.0";
    owner  = "calmh";
    repo   = "luhn";
    sha256 = "179qp1rkn185d2xj7djg193y3ia0cdlxw5spp8k7ads4k9yg0xh0";
  };

  lxd = buildFromGitHub {
    version = 3;
    rev = "lxd-2.20";
    owner  = "lxc";
    repo   = "lxd";
    sha256 = "0icffdkc3d7ynap6i2r8cg91bc3iga1c7llv8k95x2w69mmhi0jh";
    excludedPackages = "\\(test\\|benchmark\\)"; # Don't build the binary called test which causes conflicts
    buildInputs = [
      pkgs.acl
      pkgs.lxc
    ];
    propagatedBuildInputs = [
      crypto
      environschema_v1
      gettext
      gocapability
      golang-petname
      go-colorable
      go-lxc_v2
      go-sqlite3
      idmclient
      macaroon-bakery_v2
      mux
      net
      pborman_uuid
      persistent-cookiejar
      pongo2-v3
      protobuf
      testify
      tablewriter
      tomb_v2
      yaml_v2
      websocket
    ];
  };

  lz4 = buildFromGitHub {
    version = 3;
    rev = "v1.0.1";
    owner  = "pierrec";
    repo   = "lz4";
    sha256 = "0l0ww1lf7chx408f1d2wvwniigqpqcsbqvr8f4x1zqwjmgx3rah7";
    propagatedBuildInputs = [
      pierrec_xxhash
    ];
  };

  macaroon-bakery_v2 = buildFromGitHub {
    version = 3;
    rev = "ec9d2ad6796100720c154f614b6dea8798ec1181";
    owner  = "go-macaroon-bakery";
    repo   = "macaroon-bakery";
    sha256 = "0g8kvkb5rvx7jnsqp6fzq7spr7p20kqqwn7yl9icixvpkw3bajjw";
    goPackagePath = "gopkg.in/macaroon-bakery.v2";
    date = "2017-11-03";
    excludedPackages = "\\(test\\|example\\)";
    propagatedBuildInputs = [
      crypto
      environschema_v1
      errgo_v1
      fastuuid
      httprequest_v1
      httprouter
      loggo
      macaroon_v2
      mgo_v2
      net
      protobuf
      webbrowser
    ];
  };

  macaroon_v2 = buildFromGitHub {
    version = 3;
    rev = "bed2a428da6e56d950bed5b41fcbae3141e5b0d0";
    owner  = "go-macaroon";
    repo   = "macaroon";
    sha256 = "1dqpx3zpfddbhwd4nbrz7nb14xqmpr27czxd092vp0l58pcrk5rn";
    goPackagePath = "gopkg.in/macaroon.v2";
    date = "2017-10-17";
    propagatedBuildInputs = [
      crypto
    ];
  };

  macaron_v1 = buildFromGitHub {
    version = 3;
    rev = "v1.2.4";
    owner  = "go-macaron";
    repo   = "macaron";
    sha256 = "03a08lcfgzl1x4yyrsahiqpv7qrk8am19gqg6mrk17hiazipr7ay";
    goPackagePath = "gopkg.in/macaron.v1";
    propagatedBuildInputs = [
      com
      crypto
      ini_v1
      inject
    ];
  };

  mafmt = buildFromGitHub {
    version = 3;
    date = "2017-12-04";
    rev = "75e85e871bd7b78bce1596d18fb59bf9209556a0";
    owner = "whyrusleeping";
    repo = "mafmt";
    sha256 = "050ca55d4z75pw29yldny01y18xf13gmf6ch81ksz8ni668w5vxy";
    propagatedBuildInputs = [
      go-multiaddr
    ];
  };

  mage = buildFromGitHub {
    version = 3;
    rev = "v2.0.1";
    owner = "magefile";
    repo = "mage";
    sha256 = "07b1kyaa08fadacypyhvjxywaxw4fd2impdrncvva7vrji5xlzrv";
    excludedPackages = "testdata";
  };

  mapstructure = buildFromGitHub {
    version = 3;
    date = "2017-10-17";
    rev = "06020f85339e21b2478f756a78e295255ffa4d6a";
    owner  = "mitchellh";
    repo   = "mapstructure";
    sha256 = "0p0wq20ha2ksb5k9zplr7xgg8hg2dak0wakc6wasjv5mamka3h5m";
  };

  match = buildFromGitHub {
    version = 3;
    owner = "tidwall";
    repo = "match";
    date = "2017-10-02";
    rev = "1731857f09b1f38450e2c12409748407822dc6be";
    sha256 = "0z94spvy3k99ybj7mk5wppbxw3m059ir8k22hdskc2wy11m763ki";
  };

  mathutil = buildFromGitHub {
    version = 3;
    date = "2017-10-15";
    rev = "09cde8d5df5fd3e1944897ce6d00d83dd5ed3a91";
    owner = "cznic";
    repo = "mathutil";
    sha256 = "1c7zvq89hiis3513kbpzqycsg2pxzqcn4ggkaadkxp9i0452qy9h";
    excludedPackages = "example";
    buildInputs = [
      bigfft
    ];
  };

  maxminddb-golang = buildFromGitHub {
    version = 3;
    rev = "v1.2.0";
    owner  = "oschwald";
    repo   = "maxminddb-golang";
    sha256 = "14qm66rnfkf5d4hajh2cglal3v09x4mmjxjsx5n9d44n4qwq5277";
    propagatedBuildInputs = [
      sys
    ];
  };

  mc = buildFromGitHub {
    version = 3;
    owner = "minio";
    repo = "mc";
    rev = "RELEASE.2017-10-14T00-51-16Z";
    sha256 = "0gvyckadfc2rcw72kg6nh236gd6bdhyg1a5bdkfcd8k4ycacqlsm";
    propagatedBuildInputs = [
      cli_minio
      color
      go-colorable
      go-homedir_minio
      go-humanize
      go-isatty
      go-version
      minio_pkg
      minio-go
      notify
      pb
      profile
      structs
      text
    ];
    postPatch = ''
      # Hack to workaround no longer provided `pkg/probe`
      mv vendor/github.com/minio/minio/pkg/probe pkg/probe
      find cmd -type f | xargs sed -i 's,github.com/minio/minio/pkg/probe,github.com/minio/mc/pkg/probe,g'
    '';
  };

  mc_pkg = mc.override {
    subPackages = [
      "pkg/console"
    ];
    propagatedBuildInputs = [
      color
      go-colorable
      go-isatty
    ];
  };

  hashicorp_mdns = buildFromGitHub {
    version = 2;
    date = "2017-02-21";
    rev = "4e527d9d808175f132f949523e640c699e4253bb";
    owner = "hashicorp";
    repo = "mdns";
    sha256 = "0d7hknw06jsk3w7cvy5hrwg3y4dhzc5d2176vr0g624ww5jdzh64";
    propagatedBuildInputs = [
      dns
      net
    ];
  };

  whyrusleeping_mdns = buildFromGitHub {
    version = 3;
    date = "2017-02-03";
    rev = "348bb87e5cd39b33dba9a33cb20802111e5ee029";
    owner = "whyrusleeping";
    repo = "mdns";
    sha256 = "1vr6p0qjbwq5mk7zsxf40zzhxmik6sb2mnqdggz7r6lp3i7z736l";
    propagatedBuildInputs = [
      dns
      net
    ];
  };

  memberlist = buildFromGitHub {
    version = 3;
    rev = "3d8438da9589e7b608a83ffac1ef8211486bcb7c";
    owner = "hashicorp";
    repo = "memberlist";
    sha256 = "1svng3dy8pkhbz0hankcbridr47r4g7cb3g3c4vrb1v2g0n6cxml";
    propagatedBuildInputs = [
      dns
      ugorji_go
      armon_go-metrics
      go-multierror
      hashicorp_go-sockaddr
      seed
    ];
    meta.useUnstable = true;
    date = "2017-12-01";
  };

  memcache = buildFromGitHub {
    version = 2;
    date = "2015-06-22";
    rev = "1031fa0ce2f20c1c0e1e1b51951d8ea02c84fa05";
    owner = "rainycape";
    repo = "memcache";
    sha256 = "0585b0rblaxn4b2p5q80x3ynlcbhvf43p18yxxhlnm0yf0w3hjl9";
  };

  mergo = buildFromGitHub {
    version = 3;
    rev = "0.2.4";
    owner = "imdario";
    repo = "mergo";
    sha256 = "0fydzwb8s8gslx31pgccapyyxqgp74fh4ngbg9zspnycsvv0p9xc";
  };

  metrics = buildFromGitHub {
    version = 3;
    date = "2017-07-14";
    rev = "fd99b46995bd989df0d163e320e18ea7285f211f";
    owner = "mailgun";
    repo = "metrics";
    sha256 = "00c7x0sq3zx9cx8cd93mjz241mqpn4fsnakcsv6q9rwzm7ig9002";
    propagatedBuildInputs = [
      holster
      timetools
    ];
  };

  mgo_v2 = buildFromGitHub {
    version = 3;
    rev = "r2016.08.01";
    owner = "go-mgo";
    repo = "mgo";
    sha256 = "04yl8rdzpwbnxad6dxsxjh0m9ksmzi8pqr24nc9rxn8xg61jfg99";
    goPackagePath = "gopkg.in/mgo.v2";
    goPackageAliases = [
      "github.com/10gen/llmgo"
    ];
    excludedPackages = "dbtest";
    buildInputs = [
      pkgs.cyrus-sasl
    ];
  };

  minheap = buildFromGitHub {
    version = 3;
    rev = "3dbe6c6bf55f94c5efcf460dc7f86830c21a90b2";
    owner = "mailgun";
    repo = "minheap";
    sha256 = "1d0j7vzvqizq56dxb8kcp0krlnm18qsykkd064hkiafwapc3lbyd";
    date = "2017-06-19";
  };

  minio = buildFromGitHub {
    version = 3;
    owner = "minio";
    repo = "minio";
    rev = "1672c73988844f7e9417e671cde606887d580f68";
    sha256 = "0pab4kv1dppkld8xar8x4gdrixgva0qg2qxyy1n4mpwf6abb3394";
    propagatedBuildInputs = [
      amqp
      atomic
      cli_minio
      color
      cors
      crypto
      dsync
      elastic_v5
      gjson
      go-bindata-assetfs
      go-homedir_minio
      go-humanize
      go-nats
      go-nats-streaming
      go-version
      google-api-go-client
      google-cloud-go
      handlers
      jwt-go
      logrus
      lsync
      mc_pkg
      minio-go
      mux
      mysql
      oauth2
      paho-mqtt-golang
      pb
      pq
      profile
      redigo
      klauspost_reedsolomon
      rpc
      sarama_v1
      sha256-simd
      skyring-common
      structs
      yaml_v2
    ];
    meta.useUnstable = true;
    date = "2017-12-07";
    postPatch = ''
      rm cmd/gateway-{azure,s3}*.go
      sed -i 's,return newAzureLayer.*,break,' cmd/gateway-main.go
    '';
  };

  # The pkg package from minio, for bootstrapping minio
  minio_pkg = minio.override {
    propagatedBuildInputs = [
      minio-go
      pb
      structs
      yaml_v2
    ];
    subPackages = [
      "pkg/madmin"
      "pkg/quick"
      "pkg/safe"
      "pkg/trie"
      "pkg/words"
      "pkg/x/os"
    ];
  };

  minio-go = buildFromGitHub {
    version = 3;
    owner = "minio";
    repo = "minio-go";
    rev = "v2.1.0";
    sha256 = "bc7a0e5dd0a4a0668ee313fd02cdbe6ddd6924395836abb8c5b914d27a96bc66";
    propagatedBuildInputs = [
      go-homedir_minio
      ini
    ];
    meta.autoUpdate = false;
  };

  mmap-go = buildFromGitHub {
    version = 2;
    owner = "edsrzf";
    repo = "mmap-go";
    rev = "0bce6a6887123b67a60366d2c9fe2dfb74289d2e";
    sha256 = "0svsbzhh9wb800x1gwgnmbi62jvmq269cak78dajpnpjyw2m9a73";
    date = "2017-03-20";
  };

  mmark = buildFromGitHub {
    version = 3;
    owner = "miekg";
    repo = "mmark";
    rev = "v1.3.6";
    sha256 = "1ji3c0klclp13810ymjihhnlsjxpv8bif1xx4brjs4ip9l7lbdpj";
    propagatedBuildInputs = [
      toml
    ];
  };

  moby = buildFromGitHub {
    version = 3;
    owner = "moby";
    repo = "moby";
    rev = "8fe0a759f72442d7582c4453e6306822c53224bf";
    date = "2017-12-07";
    sha256 = "0a5ns5pzh0g0vkkryh747d4nzsargvlpfjqbz1avgpw9hlaigf8z";
    goPackageAliases = [
      "github.com/docker/docker"
    ];
    postPatch = ''
      find . -name \*.go -exec sed -i 's,github.com/docker/docker,github.com/moby/moby,g' {} \;
    '';
    meta.useUnstable = true;
  };

  moby_for_runc = moby.override {
    subPackages = [
      "pkg/longpath"
      "pkg/mount"
      "pkg/symlink"
      "pkg/system"
      "pkg/term"
      "pkg/term/windows"
    ];
    propagatedBuildInputs = [
      continuity
      errors
      go-ansiterm
      go-units
      go-winio
      image-spec
      logrus
      sys
    ];
  };

  moby_lib = moby.override {
    subPackages = [
      "api/types"
      "api/types/blkiodev"
      "api/types/container"
      "api/types/filters"
      "api/types/mount"
      "api/types/network"
      "api/types/registry"
      "api/types/strslice"
      "api/types/swarm"
      "api/types/swarm/runtime"
      "api/types/versions"
      "daemon/cluster/convert"
      "opts"
      "pkg/archive"
      "pkg/fileutils"
      "pkg/homedir"
      "pkg/idtools"
      "pkg/ioutils"
      "pkg/jsonmessage"
      "pkg/longpath"
      "pkg/mount"
      "pkg/namesgenerator"
      "pkg/pools"
      "pkg/stdcopy"
      "pkg/stringid"
      "pkg/system"
      "pkg/tarsum"
      "pkg/term"
      "pkg/term/windows"
      "reference"
      "registry"
      "registry/resumable"
    ];
    propagatedBuildInputs = [
      continuity
      distribution_for_moby
      errors
      go-ansiterm
      go-connections
      go-digest
      go-units
      go-winio
      gogo_protobuf
      gotty
      image-spec
      libnetwork
      logrus
      net
      pflag
      runc
      swarmkit
      sys
    ];
  };

  mock = buildFromGitHub {
    version = 3;
    owner = "golang";
    repo = "mock";
    rev = "v1.0.0";
    sha256 = "00c9g4cqwm3j19mfzdrxdsdpn1bcnb11g7i72ajf68a78z71pvjn";
  };

  mongo-tools = buildFromGitHub {
    version = 3;
    rev = "r3.6.0";
    owner  = "mongodb";
    repo   = "mongo-tools";
    sha256 = "0vr5mp9q16w474f1sn5pv54abpdzpsxxkfb3lai1ivzaahklqxg0";
    buildInputs = [
      crypto
      escaper
      go-cache
      go-flags
      gopacket
      gopass
      mgo_v2
      openssl
      termbox-go
      tomb_v2
    ];

    # Mongodb incorrectly names all of their binaries main
    # Let's work around this with our own installer
    preInstall = ''
      mkdir -p $bin/bin
      while read b; do
        rm -f go/bin/main
        go install $goPackagePath/$b/main
        cp go/bin/main $bin/bin/$b
      done < <(find go/src/$goPackagePath -name main | xargs dirname | xargs basename -a)
      rm -r go/bin
    '';
  };

  mousetrap = buildFromGitHub {
    version = 3;
    rev = "v1.0";
    owner = "inconshreveable";
    repo = "mousetrap";
    sha256 = "0a5rc2jmgcdbp28qp5di2znps95gwz2fmv1j0b4xi5k6jrbsyib8";
  };

  mow-cli = buildFromGitHub {
    version = 3;
    rev = "v1.0.3";
    owner  = "jawher";
    repo   = "mow.cli";
    sha256 = "0wff94c1436hrlrb7mwi8s6if49pkfs67cpmy1m5p15f6wycqlhf";
  };

  ns1-go_v2 = buildFromGitHub {
    version = 3;
    rev = "c563826f4cbef9c11bebeb9f20a3f7afe9c1e2f4";
    owner  = "ns1";
    repo   = "ns1-go";
    sha256 = "0i1xmx6aw69749m5dy1i97xhhga7zp3sfk4wiflkmdkah2670in2";
    goPackagePath = "gopkg.in/ns1/ns1-go.v2";
    date = "2017-05-02";
  };

  msgp = buildFromGitHub {
    version = 3;
    rev = "v1.0.2";
    owner  = "tinylib";
    repo   = "msgp";
    sha256 = "1pd18yp2ja8r137x5g8qrf7i9a7zzvb1lp0g43kzcl03r0v06zgh";
    propagatedBuildInputs = [
      fwd
      chalk
      tools
    ];
  };

  multiaddr-filter = buildFromGitHub {
    version = 3;
    rev = "e903e4adabd70b78bc9293b6ee4f359afb3f9f59";
    owner  = "whyrusleeping";
    repo   = "multiaddr-filter";
    sha256 = "0p8d06rm2zazq14ri9890q9n62nli0jsfyy15cpfy7wxryql84n7";
    date = "2016-05-16";
  };

  multibuf = buildFromGitHub {
    version = 2;
    rev = "565402cd71fbd9c12aa7e295324ea357e970a61e";
    owner  = "mailgun";
    repo   = "multibuf";
    sha256 = "1csjfl3bcbya7dq3xm1nqb5rwrpw5migrqa4ajki242fa5i66mdr";
    date = "2015-07-14";
  };

  multierr = buildFromGitHub {
    version = 3;
    rev = "v1.1.0";
    owner  = "uber-go";
    repo   = "multierr";
    sha256 = "0yd7ydwhdfaxn6gyq6z9qb4s1y0ijsa9qya3g4zcg9az4vya19bg";
    goPackagePath = "go.uber.org/multierr";
    propagatedBuildInputs = [
      atomic
    ];
  };

  murmur3 = buildFromGitHub {
    version = 3;
    rev = "9f5d223c60793748f04a9d5b4b4eacddfc1f755d";
    owner  = "spaolacci";
    repo   = "murmur3";
    sha256 = "0r7qnzhbw0lmhaypgrg78q99qaff873v9ygjqnja946iw1dh3x5b";
    date = "2017-08-19";
  };

  mux = buildFromGitHub {
    version = 3;
    rev = "v1.6.0";
    owner = "gorilla";
    repo = "mux";
    sha256 = "08bjv9clrwqrm1vnk0aj1kipaia09f87rhcd5miyms1xi02m5fm5";
    propagatedBuildInputs = [
      context
    ];
  };

  mysql = buildFromGitHub {
    version = 3;
    rev = "9181e3a86a19bacd63e68d43ae8b7b36320d8092";
    owner  = "go-sql-driver";
    repo   = "mysql";
    sha256 = "1sbrxpikvc0426vwnvqj3ylcddrkps3lqivhfshplh50qs4q7azp";
    postPatch = ''
      grep -r '+build appengine' -l | xargs rm
    '';
    date = "2017-12-04";
  };

  names_v2 = buildFromGitHub {
    version = 3;
    date = "2017-11-13";
    rev = "54f00845ae470a362430a966fe17f35f8784ac92";
    owner = "juju";
    repo = "names";
    sha256 = "08qd8wbaasz9pj0kjhbalaj1hxq0qmgg80ch8ljypry0324cqxn4";
    goPackagePath = "gopkg.in/juju/names.v2";
    propagatedBuildInputs = [
      juju_errors
      utils
    ];
  };

  net-rpc-msgpackrpc = buildFromGitHub {
    version = 3;
    date = "2015-11-16";
    rev = "a14192a58a694c123d8fe5481d4a4727d6ae82f3";
    owner = "hashicorp";
    repo = "net-rpc-msgpackrpc";
    sha256 = "0dlpb20x8c6a6s6crzf2z7dmgb66p9d9zbnb0ipsgd613gaz7ha5";
    propagatedBuildInputs = [
      ugorji_go
      go-multierror
    ];
  };

  netlink = buildFromGitHub {
    version = 3;
    rev = "f67b75edbf5e3bb7dfe70bb788610693a71be3d1";
    owner  = "vishvananda";
    repo   = "netlink";
    sha256 = "161sp9f10dic64sjvkwl0hq6vhll2lw7qfwsbb7f2sas19shhfqq";
    date = "2017-11-28";
    propagatedBuildInputs = [
      netns
      sys
    ];
  };

  netns = buildFromGitHub {
    version = 3;
    rev = "be1fbeda19366dea804f00efff2dd73a1642fdcc";
    owner  = "vishvananda";
    repo   = "netns";
    sha256 = "1v0azn8ndn1cdx254rs5v9agwqkiwn7bgfrshvx6gxhpghxk1x26";
    date = "2017-11-11";
  };

  nitro = buildFromGitHub {
    version = 3;
    owner = "spf13";
    repo = "nitro";
    rev = "24d7ef30a12da0bdc5e2eb370a79c659ddccf0e8";
    date = "2013-10-03";
    sha256 = "1sbiyzxwca05n06xvfshz19n30qybq8gcyy00hv7hwpflqrjl0ii";
  };

  nodb = buildFromGitHub {
    version = 3;
    owner = "lunny";
    repo = "nodb";
    rev = "fc1ef06ad4af0da31cdb87e3fa5ec084c67e6597";
    date = "2016-06-21";
    sha256 = "116cqkn4yh0n5qrx04kf2rvnb0kplsaps0adarwzci0wnnwgc4gd";
    propagatedBuildInputs = [
      goleveldb
      lunny_log
      go-snappy
      toml
    ];
  };

  nomad = buildFromGitHub {
    version = 3;
    rev = "v0.7.0";
    owner = "hashicorp";
    repo = "nomad";
    sha256 = "0azf1iq65g2n99ky934j23q8sr1w9y4q59xkzqa2annl7825zjmr";

    nativeBuildInputs = [
      ugorji_go.bin
    ];

    buildInputs = [
      armon_go-metrics
      bolt
      circbuf
      colorstring
      columnize
      complete
      consul-template
      consul_api
      copystructure
      cors
      cronexpr
      crypto
      distribution_for_moby
      docker_cli
      go-checkpoint
      go-cleanhttp
      go-bindata-assetfs
      go-dockerclient
      go-envparse
      go-getter
      go-humanize
      go-immutable-radix
      go-lxc_v2
      go-memdb
      go-multierror
      go-plugin
      go-ps
      go-rootcerts
      hashicorp_go-sockaddr
      go-syslog
      go-testing-interface
      go-version
      golang-lru
      gopsutil
      gziphandler
      hashstructure
      hcl
      logutils
      mapstructure
      memberlist
      mitchellh_cli
      moby_lib
      net-rpc-msgpackrpc
      open-golang
      osext
      prometheus_client_golang
      raft-boltdb
      raft
      rkt
      runc
      scada-client
      seed
      serf
      snappy
      spec_appc
      srslog
      sync
      sys
      tail
      time
      tomb_v1
      tomb_v2
      ugorji_go
      vault_api
      hashicorp_yamux
    ];

    excludedPackages = "\\(test\\|mock\\)";

    postPatch = ''
      # Rename deprecated ParseNamed to ParseNormalizedNamed
      #  -e 's,.ParseNamed,.ParseNormalizedNamed,g' \
      #  -e 's,"github.com/docker/docker/reference","github.com/docker/distribution/reference",g' \
      find . -type f -exec sed -i {} \
        -e 's,"github.com/docker/docker/cli,"github.com/docker/cli/cli,g' \
        \;

      # Remove test junk
      find . \( -name testutil -or -name testagent.go \) -prune -exec rm -r {} \;
    '';

    preBuild = ''
      pushd go/src/$goPackagePath
      go list ./... | xargs go generate
      popd
    '';

    postInstall = ''
      rm "$bin"/bin/app
    '';
  };

  notify = buildFromGitHub {
    version = 3;
    owner = "zillode";
    repo = "notify";
    date = "2017-10-04";
    rev = "54e3093eb7377fd139c4605f475cc78e83610b9d";
    sha256 = "0zlqs3pvdwndip60idf42zfr5cv12lmx4d0swgy1wgi00887xhpx";
    goPackageAliases = [
      "github.com/rjeczalik/notify"
    ];
    propagatedBuildInputs = [
      sys
    ];
  };

  nuid = buildFromGitHub {
    version = 3;
    rev = "33c603157d6fd1b0ac2599bcc4a286b36479a06d";
    owner = "nats-io";
    repo = "nuid";
    sha256 = "1ympbdk16hik281q1y60c0rwzm3hqfvy0j0pym505k301z51vmiw";
    date = "2017-10-25";
  };

  objecthash = buildFromGitHub {
    version = 3;
    date = "2016-08-01";
    rev = "770874ca6c9e9967c6ee7adae3de0f680c922b43";
    owner  = "benlaurie";
    repo   = "objecthash";
    sha256 = "0si2wixfz6nbxrav76iii4lgjh66kfj9i1prdniin9f4r7idiak5";
    subPackages = [
      "go/objecthash"
    ];
  };

  objx = buildFromGitHub {
    version = 3;
    date = "2015-09-28";
    rev = "1a9d0bb9f541897e62256577b352fdbc1fb4fd94";
    owner  = "stretchr";
    repo   = "objx";
    sha256 = "0lqsr7jwb57bph7l3dr58i5f0xpss31km0158fizrsj6pq87z7s0";
  };

  oktasdk-go = buildFromGitHub {
    version = 3;
    owner = "chrismalek";
    repo = "oktasdk-go";
    rev = "ae553c909ca06a4c34eb41ee435e83871a7c2496";
    date = "2017-09-11";
    sha256 = "0jcqdiczz94xkw0xcq97adfc9nk3wgy67l419811q8j7caqim7jv";
    propagatedBuildInputs = [
      go-querystring
    ];
  };

  opencensus = buildFromGitHub {
    version = 3;
    owner = "census-instrumentation";
    repo = "opencensus-go";
    rev = "c5e712e5a7e283aa08017f727210068ed421f97d";
    date = "2017-12-07";
    sha256 = "05yhqq5p0adp56a8gcikq3h2qsx5njnvyjf2z6716rjnisyn3jxi";
    goPackagePath = "go.opencensus.io";
    subPackages = [
      "internal/tagencoding"
      "plugin/grpc"
      "plugin/grpc/grpcstats"
      "plugin/grpc/grpctrace"
      "stats"
      "tag"
      "trace"
      "trace/propagation"
    ];
    propagatedBuildInputs = [
      grpc
      net
    ];
  };

  open-golang = buildFromGitHub {
    version = 2;
    owner = "skratchdot";
    repo = "open-golang";
    rev = "75fb7ed4208cf72d323d7d02fd1a5964a7a9073c";
    date = "2016-03-02";
    sha256 = "da900f012522dd61cc0504a16bbb137e3ed2173d0715fbf709046a1e0d923ca3";
  };

  openid-go = buildFromGitHub {
    version = 3;
    owner = "yohcop";
    repo = "openid-go";
    rev = "cfc72ed89575fe6b1b7b880d537ba0c5e37f7391";
    date = "2017-09-01";
    sha256 = "0ai04iinihpzxcj1mz8zkx048b5djqc7cyfr34mfibkvzx238jjd";
    propagatedBuildInputs = [
      net
    ];
  };

  openssl = buildFromGitHub {
    version = 3;
    date = "2017-07-21";
    rev = "2692b9f6fa95e72c75f8d9ba76e49c5dfd2cf8e4";
    owner = "10gen";
    repo = "openssl";
    sha256 = "0zsp8m5gxhiilvlhpgdbyzaw7k0hdch7q5f13cdhjlkb22zk8ps0";
    goPackageAliases = [
      "github.com/spacemonkeygo/openssl"
    ];
    buildInputs = [
      pkgs.openssl
    ];
    propagatedBuildInputs = [
      spacelog
    ];

    preBuild = ''
      find go/src/$goPackagePath -name \*.go | xargs sed -i 's,spacemonkeygo/openssl,10gen/openssl,g'
    '';
  };

  opentracing-go = buildFromGitHub {
    version = 3;
    owner = "opentracing";
    repo = "opentracing-go";
    rev = "v1.0.2";
    sha256 = "0g9h4slaiik7fa0rx04jxdjrn9i9w597ws95hmip125jbjafvqc6";
    propagatedBuildInputs = [
      net
    ];
  };

  osext = buildFromGitHub {
    version = 3;
    date = "2017-05-10";
    rev = "ae77be60afb1dcacde03767a8c37337fad28ac14";
    owner = "kardianos";
    repo = "osext";
    sha256 = "0xbz5vjmgv6gf9f2xrhz48kcfmx5623fbcsw5x22s4hzwmvnb588";
    goPackageAliases = [
      "github.com/bugsnag/osext"
      "bitbucket.org/kardianos/osext"
    ];
  };

  otp = buildFromGitHub {
    version = 3;
    rev = "v1.0.0";
    owner = "pquerna";
    repo = "otp";
    sha256 = "0qx6g6kbm6l6snflz9c624b8wi8yghwp0r2117j73viq5q5n5zjc";
    propagatedBuildInputs = [
      barcode
    ];
  };

  oxy = buildFromGitHub {
    version = 2;
    owner = "vulcand";
    repo = "oxy";
    date = "2016-07-23";
    rev = "db85f00cac5466def1f6f2667063e6e38c1fe606";
    sha256 = "3c32677900a6399eecd80fc47798e998f47f8df502727574052d6ddc654d4a61";
    goPackageAliases = [ "github.com/mailgun/oxy" ];
    propagatedBuildInputs = [
      hdrhistogram
      mailgun_log
      multibuf
      predicate
      timetools
      mailgun_ttlmap
    ];
    meta.autoUpdate = false;
  };

  paho-mqtt-golang = buildFromGitHub {
    version = 3;
    owner = "eclipse";
    repo = "paho.mqtt.golang";
    rev = "v1.1.0";
    sha256 = "1ikh7xkxwysk910zw3yv7kyc9g2na095s3hhs8hsp1mgdxf50n49";
    propagatedBuildInputs = [
      net
    ];
  };

  pat = buildFromGitHub {
    version = 2;
    owner = "bmizerany";
    repo = "pat";
    date = "2016-02-17";
    rev = "c068ca2f0aacee5ac3681d68e4d0a003b7d1fd2c";
    sha256 = "aad2d84661ea918168e60ed7bab467d4e0fce28fe9372e786c2714c10f6490a7";
  };

  pb = buildFromGitHub {
    version = 3;
    owner = "cheggaaa";
    repo = "pb";
    date = "2017-08-24";
    rev = "657164d0228d6bebe316fdf725c69f131a50fb10";
    sha256 = "02dw9zj0dqd195nbvw360vvza92mxpbngd9gr12b0d7cihg4bcdz";
    propagatedBuildInputs = [
      go-runewidth
    ];
    meta.useUnstable = true;
  };

  pb_v1 = buildFromGitHub {
    version = 3;
    owner = "cheggaaa";
    repo = "pb";
    rev = "v1.0.18";
    sha256 = "03xjvv2falvaq0h2zrc1w34zq3fczs0k8c4066fmxpqpc6p26yq5";
    goPackagePath = "gopkg.in/cheggaaa/pb.v1";
    propagatedBuildInputs = [
      go-runewidth
    ];
  };

  perks = buildFromGitHub {
    version = 3;
    date = "2016-08-04";
    owner  = "beorn7";
    repo   = "perks";
    rev = "4c0e84591b9aa9e6dcfdf3e020114cd81f89d5f9";
    sha256 = "1nrw7xp2i4whgr91ffl9j9fm5r8icgxxvny3xilkap8zsmfhbkqh";
  };

  persistent-cookiejar = buildFromGitHub {
    version = 3;
    date = "2017-10-26";
    owner  = "juju";
    repo   = "persistent-cookiejar";
    rev = "d5e5a8405ef9633c84af42fbcc734ec8dd73c198";
    sha256 = "1knkwj44wq85wkxb69v3yh5v9ddix63a2saq49077yd7l13j6rmd";
    excludedPackages = "test";
    propagatedBuildInputs = [
      errgo_v1
      go4
      net
      retry_v1
    ];
  };

  pester = buildFromGitHub {
    version = 3;
    owner = "sethgrid";
    repo = "pester";
    rev = "760f8913c0483b776294e1bee43f1d687527127b";
    date = "2017-11-27";
    sha256 = "1fz699331d3h65y68lj1w9f7lsqbkrwygxaw6m1pfbjdrd1krs5f";
  };

  pfilter = buildFromGitHub {
    version = 3;
    owner = "AudriusButkevicius";
    repo = "pfilter";
    rev = "0.0.3";
    sha256 = "0r3isyy0vnsam0ycr6kf3748gaz1d5r3rd45zi2xg4pa4q17lwaf";
  };

  pflag = buildFromGitHub {
    version = 3;
    owner = "spf13";
    repo = "pflag";
    rev = "4c012f6dcd9546820e378d0bdda4d8fc772cdfea";
    sha256 = "032yn6ss4cm102msjs6qb5j2mwj96vh26xygg6rzck461vdsbwhh";
    date = "2017-11-06";
  };

  pkcs7 = buildFromGitHub {
    version = 3;
    owner = "fullsailor";
    repo = "pkcs7";
    rev = "a009d8d7de53d9503c797cb8ec66fa3b21eed209";
    date = "2017-06-13";
    sha256 = "13xipw188r9lh6hxcd5mlsv941y21a76cv50dagy12mlmrs9m293";
  };

  pkcs11 = buildFromGitHub {
    version = 3;
    owner = "miekg";
    repo = "pkcs11";
    rev = "7283ca79f35edb89bc1b4ecae7f86a3680ce737f";
    sha256 = "1zl6dv4imi1amc3jvfav6i5v9jjqwfs3ahacbfp3k4gkf5gw79jq";
    date = "2017-02-20";
    propagatedBuildInputs = [
      pkgs.libtool
    ];
  };

  pkcs11key = buildFromGitHub {
    version = 3;
    owner = "letsencrypt";
    repo = "pkcs11key";
    rev = "v2.0.0";
    sha256 = "06307qc44967zf7i9r92vhhrm9ziz68nfhdsxy3ynh6940dhxcd4";
    propagatedBuildInputs = [
      cfssl_errors
      pkcs11
    ];
  };

  pkg = buildFromGitHub {
    version = 3;
    date = "2017-09-01";
    owner  = "coreos";
    repo   = "pkg";
    rev = "459346e834d8e97be707cd0ea1236acaaa159ffc";
    sha256 = "0fhj5mw2r1pq8yqifnal8yg1wvfsqmrpa35ig9g9npsgajd8hib7";
    buildInputs = [
      crypto
      yaml_v1
    ];
    propagatedBuildInputs = [
      go-systemd_journal
    ];
  };

  pongo2-v3 = buildFromGitHub {
    version = 3;
    rev = "v3.0";
    owner  = "flosch";
    repo   = "pongo2";
    sha256 = "0l9w18sslszkc4f6ghfa0jixy8lziswjdxccsvp1j9m2gqpi16jz";
    goPackagePath = "gopkg.in/flosch/pongo2.v3";
  };

  pprof = buildFromGitHub {
    version = 3;
    rev = "b8f425e98f1c7237a1440a8f6921c5633d54270c";
    owner  = "google";
    repo   = "pprof";
    sha256 = "1v6g5njvh267pz5h6qbkgr12lzf1fh8sf1396yjipnmpdf76ybnf";
    date = "2017-12-08";
    propagatedBuildInputs = [
      demangle
    ];
  };

  pq = buildFromGitHub {
    version = 3;
    rev = "83612a56d3dd153a94a629cd64925371c9adad78";
    owner  = "lib";
    repo   = "pq";
    sha256 = "0c07m91yf0y3bij7q0zm7spbvv7nai66c0i3rwpkk66sjbf9gwjw";
    date = "2017-11-26";
  };

  predicate = buildFromGitHub {
    version = 3;
    rev = "v1.0.0";
    owner  = "vulcand";
    repo   = "predicate";
    sha256 = "1mx35iwn4y2qw396j2qdr0q72xchp3qq826p6wvcyzgsja3yml8r";
    propagatedBuildInputs = [
      trace
    ];
  };

  probing = buildFromGitHub {
    version = 3;
    rev = "0.0.1";
    owner  = "xiang90";
    repo   = "probing";
    sha256 = "0wjjml1dg64lfq4s1b6kqabz35pm02yfgc0nc8cp8y4aw2ip49vr";
  };

  procfs = buildFromGitHub {
    version = 3;
    rev = "a6e9df898b1336106c743392c48ee0b71f5c4efa";
    date = "2017-10-17";
    owner  = "prometheus";
    repo   = "procfs";
    sha256 = "147c4rxgijj1k67jyj6pmsgflnh6m2719c2hc3fxmmj7i4ypmpmi";
  };

  profile = buildFromGitHub {
    version = 3;
    owner = "pkg";
    repo = "profile";
    rev = "v1.2.1";
    sha256 = "0j8xam3hkcl265fdqlkmlxf9ri8ynx5iq5dkghbsal85h8jm7mf8";
  };

  progmeter = buildFromGitHub {
    version = 3;
    owner = "whyrusleeping";
    repo = "progmeter";
    rev = "30d42a105341e640d284d9920da2078029764980";
    sha256 = "162rlxy065dq1acdwcr9y9lc6zx2pjqdqvngrq6bnrargw15avid";
    date = "2017-11-15";
  };

  prometheus = buildFromGitHub {
    version = 3;
    rev = "v2.0.0";
    owner  = "prometheus";
    repo   = "prometheus";
    sha256 = "04a5rlrgigfknlb6qfvjcsr7scyxiqdykmkg6w9asw3myix0khyn";
    buildInputs = [
      aws-sdk-go
      #azure-sdk-for-go
      consul_api
      dns
      fsnotify_v1
      go-autorest
      goleveldb
      gophercloud
      go-stdlib
      govalidator
      go-zookeeper
      google-api-go-client
      kubernetes-apimachinery
      kubernetes-client-go
      net
      oauth2
      opentracing-go
      prometheus_client_golang
      prometheus_client_model
      prometheus_common
      protobuf
      snappy
      time
      yaml_v2
    ];
  };

  prometheus_client_golang = buildFromGitHub {
    version = 3;
    rev = "661e31bf844dfca9aeba15f27ea8aa0d485ad212";
    owner = "prometheus";
    repo = "client_golang";
    sha256 = "13nm63v0fr8wqb3mvqlkbrc81fcydvmwfr9685jsgrc3h7z3x0hv";
    propagatedBuildInputs = [
      net
      protobuf
      prometheus_client_model
      prometheus_common_for_client
      procfs
      perks
    ];
    date = "2017-12-01";
  };

  prometheus_client_model = buildFromGitHub {
    version = 3;
    rev = "99fa1f4be8e564e8a6b613da7fa6f46c9edafc6c";
    date = "2017-11-17";
    owner  = "prometheus";
    repo   = "client_model";
    sha256 = "0axllq8fkndw91p52cg9bq1r812r2sfy7a3vy5sbmw1iyifbic1c";
    buildInputs = [
      protobuf
    ];
  };

  prometheus_common = buildFromGitHub {
    version = 3;
    date = "2017-11-17";
    rev = "2e54d0b93cba2fd133edc32211dcc32c06ef72ca";
    owner = "prometheus";
    repo = "common";
    sha256 = "0qsrllh5w8qxslvwgb8pd9n35jv2p2wscnsqjbqwn77b2lnw78i4";
    buildInputs = [
      errors
      kit_for_prometheus
      kingpin_v2
      net
      prometheus_client_model
      protobuf
      sys
      yaml_v2
    ];
    propagatedBuildInputs = [
      golang_protobuf_extensions
      httprouter
      logrus
      prometheus_client_golang
    ];
  };

  prometheus_common_for_client = prometheus_common.override {
    subPackages = [
      "expfmt"
      "model"
      "internal/bitbucket.org/ww/goautoneg"
    ];
    propagatedBuildInputs = [
      golang_protobuf_extensions
      prometheus_client_model
      protobuf
    ];
  };

  properties = buildFromGitHub {
    version = 3;
    owner = "magiconair";
    repo = "properties";
    rev = "v1.7.3";
    sha256 = "1gbi6n1c1v686q2l4vs3az1gm6hvyzvhg7qganvvc7skr8s2v8z1";
  };

  prose = buildFromGitHub {
    version = 3;
    owner = "jdkato";
    repo = "prose";
    rev = "v1.1.0";
    sha256 = "08daklyimc51cxmv72hfnhsdaq9k5ps5d73am53kz7dsl838zrki";
    propagatedBuildInputs = [
      urfave_cli
      go-shuffle
      sentences_v1
      stats
    ];
  };

  gogo_protobuf = buildFromGitHub {
    version = 3;
    owner = "gogo";
    repo = "protobuf";
    rev = "v0.5";
    sha256 = "1fhi1yfq2i37nm4flwnfqrbkl0ijxj8nq1jwdd2h186l812xkxvs";
    excludedPackages = "test";
  };

  protobuild = buildFromGitHub {
    version = 3;
    rev = "dd989eff46b904de37a40c429288f7f2e5256ac5";
    date = "2017-09-06";
    owner = "stevvooe";
    repo = "protobuild";
    sha256 = "09jw4n6jlp11h7pjirvmwv38kjxxgl5wmlg7lhvgiahh57wz42yb";
    propagatedBuildInputs = [
      protobuf
      gogo_protobuf
      toml
    ];
    postPatch = ''
      sed -i "s,/usr/local,${pkgs.protobuf-cpp},g" descriptors.go
    '';
  };

  pty = buildFromGitHub {
    version = 3;
    owner = "kr";
    repo = "pty";
    rev = "v1.0.1";
    sha256 = "1iwjj83vb39h2f39hlf1vll644hqkhwbfyhm9iy0bkhhdqxf38hm";
  };

  purell = buildFromGitHub {
    version = 3;
    owner = "PuerkitoBio";
    repo = "purell";
    rev = "1c4bec281e4bbc75b4f4a1bd923bdf1bd989a969";
    sha256 = "187sc4qm9wms3c6wc2gy7svbvh248qdjf6c63qxlhy6v6hbnsr6k";
    propagatedBuildInputs = [
      net
      text
      urlesc
    ];
    date = "2017-11-17";
  };

  qart = buildFromGitHub {
    version = 3;
    rev = "0.1";
    owner  = "vitrun";
    repo   = "qart";
    sha256 = "0iba8lcrc79p5pzc35bnkphn6lnccnz0d2da6ypzv9xn6phyja3z";
  };

  qingstor-sdk-go = buildFromGitHub {
    version = 3;
    rev = "v2.2.9";
    owner  = "yunify";
    repo   = "qingstor-sdk-go";
    sha256 = "0smpnq1ryln6rcb3f063shj50cpw36pw4hdccrvg9mhg330xfa8a";
    excludedPackages = "test";
    propagatedBuildInputs = [
      go-shared
      logrus
      yaml_v2
    ];
  };

  ql = buildFromGitHub {
    version = 3;
    rev = "3f53e147d722f949b627631bc771623ab9bdb396";
    owner  = "cznic";
    repo   = "ql";
    sha256 = "178pz237myik12x8fzdw09vs89hb7gjbwabpk2bb1mwsd2xsg0az";
    propagatedBuildInputs = [
      b
      exp
      go4
      golex
      lldb
      mathutil
      strutil
    ];
    date = "2017-11-22";
  };

  queue = buildFromGitHub {
    version = 3;
    rev = "v1.1.0";
    owner  = "eapache";
    repo   = "queue";
    sha256 = "1zbgf7pdi934ryh129yf1m6f6cxwwclmi0n2myqi8rg3lz28j2kz";
  };

  quotedprintable_v3 = buildFromGitHub {
    version = 3;
    rev = "2caba252f4dc53eaf6b553000885530023f54623";
    owner  = "alexcesaro";
    repo   = "quotedprintable";
    sha256 = "1vxbp1n7439gb3vwynqaxdqcv0xlkzzxv88mpcvhsshzbiqhb1cs";
    goPackagePath = "gopkg.in/alexcesaro/quotedprintable.v3";
    date = "2015-07-16";
  };

  rabbit-hole = buildFromGitHub {
    version = 3;
    rev = "v1.4.0";
    owner  = "michaelklishin";
    repo   = "rabbit-hole";
    sha256 = "07944wgvj6shjzcj04zlmldkcxc892zx03lcv55kc7igi77lnmyi";
  };

  radius = buildFromGitHub {
    version = 3;
    rev = "eebc3671c1699b29d5ff236cf4a8c5519384dcb5";
    date = "2017-09-03";
    owner  = "layeh";
    repo   = "radius";
    sha256 = "1x0zaqhznilqqmvl9qnbn7ymxjwmrjp5bcj3yxbgmbgrvjhsqrr8";
    goPackagePath = "layeh.com/radius";
  };

  raft = buildFromGitHub {
    version = 3;
    date = "2017-12-04";
    rev = "0919aa6a43618e19335d2ac609d4ff079ce75ed8";
    owner  = "hashicorp";
    repo   = "raft";
    sha256 = "002ggqn72bmbzhmq88iwmy9jc5h1qr4znq36m72jaagbyk782b40";
    meta.useUnstable = true;
    propagatedBuildInputs = [
      armon_go-metrics
      ugorji_go
    ];
    subPackages = [
      "."
    ];
  };

  raft-boltdb = buildFromGitHub {
    version = 3;
    date = "2017-10-10";
    rev = "6e5ba93211eaf8d9a2ad7e41ffad8c6f160f9fe3";
    owner  = "hashicorp";
    repo   = "raft-boltdb";
    sha256 = "08k5ax1iwpwxhb7rmjmgbdb4ywlqpgdj4yj95f0ppyw0jcskv3dc";
    propagatedBuildInputs = [
      bolt
      ugorji_go
      raft
    ];
  };

  ratecounter = buildFromGitHub {
    version = 3;
    owner = "paulbellamy";
    repo = "ratecounter";
    rev = "f965c2b56662c5bbb5e6b93cc760d43f8698aab8";
    sha256 = "1190lmnglmc0ayq82wyhqh5hnin7xh71wkpfr97ym7z8ahqx96mf";
    date = "2017-06-20";
  };

  ratelimit = buildFromGitHub {
    version = 3;
    rev = "59fac5042749a5afb9af70e813da1dd5474f0167";
    date = "2017-10-26";
    owner  = "juju";
    repo   = "ratelimit";
    sha256 = "0sb6gx92bkv0qznj5gpqhfpfdi3vw5bbj7bxh3c4djh1vydhmlh6";
  };

  raw = buildFromGitHub {
    version = 2;
    rev = "4ad22e6f1008c9f1100cb970699da776b45be83c";
    owner  = "feyeleanor";
    repo   = "raw";
    sha256 = "0zb5qwrm7x7p79wzi4lbr4px9q6qm5zz9xwjakf2wb1cnyxim93w";
    date = "2016-12-30";
  };

  rclone = buildFromGitHub {
    version = 3;
    owner = "ncw";
    repo = "rclone";
    date = "2017-12-07";
    rev = "5061aaaf4673e8ab9199b6282ec11cbb5773556a";
    sha256 = "00s86cbfg20wgxjz3gfb2pvwngj1f3rkcci6qzf1bkprnr3aksjv";
    propagatedBuildInputs = [
      appengine
      aws-sdk-go
      #azure-sdk-for-go
      bbolt
      cgofuse
      cobra
      crypto
      #dropbox-sdk-go-unofficial
      eme
      errors
      ewma
      fs
      ftp
      fuse
      go-acd
      go-cache
      goconfig
      google-api-go-client
      net
      oauth2
      open-golang
      pflag
      qingstor-sdk-go
      sdnotify
      sftp
      ssh-agent
      swift
      sys
      tb
      termbox-go
      testify
      text
      time
      times
      tree
    ];
    postPatch = ''
      # Azure-sdk-for-go does not provide a stable apit status:
      rm -r azureblob/
      sed -i fs/all/all.go \
        -e '/azureblob/d'

      # Dropbox doesn't build easily
      rm -r dropbox/
      sed -i fs/all/all.go \
        -e '/dropbox/d'
      sed -i fs/hash.go \
        -e '/dbhash/d'
    '';
    meta.useUnstable = true;
  };

  cupcake_rdb = buildFromGitHub {
    version = 2;
    date = "2016-08-25";
    rev = "43ba34106c765f2111c0dc7b74cdf8ee437411e0";
    owner = "cupcake";
    repo = "rdb";
    sha256 = "0sqs6l4i5f2pd4i719aijbyjhdss8zqvk3b9195d0ljx2di9y84i";
  };

  siddontang_rdb = buildFromGitHub {
    version = 3;
    date = "2015-03-07";
    rev = "fc89ed2e418d27e3ea76e708e54276d2b44ae9cf";
    owner = "siddontang";
    repo = "rdb";
    sha256 = "0q2jpnjyr1gqjl50m3xwa3mqwryn14i9jcl7nwxw0yvxh6vlvnhh";
    propagatedBuildInputs = [
      cupcake_rdb
    ];
  };

  redigo = buildFromGitHub {
    version = 3;
    owner = "garyburd";
    repo = "redigo";
    date = "2017-11-27";
    rev = "b389d5392e340092642eec4e36754e0280ad1f8e";
    sha256 = "1xwrv1cb4m8lwhqwf849334sx2dp6bqcp3qwli674ql3xwj5b7n8";
    meta.useUnstable = true;
  };

  redis_v2 = buildFromGitHub {
    version = 3;
    rev = "v2.3.2";
    owner  = "go-redis";
    repo   = "redis";
    sha256 = "1svhq879d7r2paj2q9h8qy3h2lf90dmkncb7a87na86z2dikhll2";
    goPackagePath = "gopkg.in/redis.v2";
    propagatedBuildInputs = [
      bufio_v1
    ];
  };

  klauspost_reedsolomon = buildFromGitHub {
    version = 3;
    owner = "klauspost";
    repo = "reedsolomon";
    date = "2017-11-18";
    rev = "e52c150f961e65ab9538bf1276b33bf469f919d8";
    sha256 = "1wakikkl02s9yzp1f1fdakx2byxxcva7ic9jhx7d5aa1yp5l246x";
    propagatedBuildInputs = [
      cpuid
    ];
    meta.useUnstable = true;
  };

  templexxx_reedsolomon = buildFromGitHub {
    version = 3;
    owner = "templexxx";
    repo = "reedsolomon";
    rev = "0.1.1";
    sha256 = "1v2p99ggw94kj1mg89h6dqnmc4806vqica0rjj2i50p8j40zpq86";
    subPackages = [
      "."
    ];
    propagatedBuildInputs = [
      cpufeat
    ];
  };

  reflectwalk = buildFromGitHub {
    version = 3;
    date = "2017-07-26";
    rev = "63d60e9d0dbc60cf9164e6510889b0db6683d98c";
    owner  = "mitchellh";
    repo   = "reflectwalk";
    sha256 = "1xpgzn3rgc222yz09nmn1h8xi2769x3b5cmb23wch0w43cj8inkz";
  };

  regexp2 = buildFromGitHub {
    version = 3;
    rev = "v1.1.6";
    owner  = "dlclark";
    repo   = "regexp2";
    sha256 = "1z44159gfiv99p32qgypwflix4krk88mnx1n5h94gy2sqhh07gi0";
  };

  resumable = buildFromGitHub {
    version = 2;
    owner = "stevvooe";
    repo = "resumable";
    date = "2016-09-23";
    rev = "f714bdb9b57a7162bc99aaa0b68a338c0da1c392";
    sha256 = "18jm8ssihjl5flqhahqcvz2s5cifgcl6f7ms23xl70zkls6j0l3a";
  };

  retry_v1 = buildFromGitHub {
    version = 3;
    owner = "go-retry";
    repo = "retry";
    date = "2017-05-31";
    rev = "01631078ef2fdce601e38cfe5f527fab24c9a6d2";
    sha256 = "1j4ys7vd3473acnxxa8x7kxqzsdzq8zrr5cv7m0zv67aaskfpiy8";
    goPackagePath = "gopkg.in/retry.v1";
  };

  rkt = buildFromGitHub {
    version = 3;
    owner = "rkt";
    repo = "rkt";
    rev = "dfa17221c8d88a55da1265f519f06dc38d51fbd4";
    sha256 = "0rdfw8q7h6p1xrlfzbfmq37s9r19wkg0qj4akk5sa1sqwjl4wwzr";
    subPackages = [
      "api/v1"
      "networking/netinfo"
    ];
    propagatedBuildInputs = [
      cni
    ];
    meta.useUnstable = true;
    date = "2017-11-28";
  };

  roaring = buildFromGitHub {
    version = 3;
    rev = "v0.3.16";
    owner  = "RoaringBitmap";
    repo   = "roaring";
    sha256 = "125vrshk7a09w0q6171hlng0z6xvlk74qcxl7bw0dygl62w48gs5";
    propagatedBuildInputs = [
      go-unsnap-stream
      msgp
    ];
  };

  rollinghash = buildFromGitHub {
    version = 3;
    rev = "v3.0.0";
    owner  = "chmduquesne";
    repo   = "rollinghash";
    sha256 = "02sgy0j9p4wwd1ibkm3yj6maw5gdrnw8cykm2skzrk4ib9f9m7id";
    propagatedBuildInputs = [
      bytefmt
    ];
  };

  roundtrip = buildFromGitHub {
    version = 3;
    owner = "gravitational";
    repo = "roundtrip";
    rev = "0.0.2";
    sha256 = "12qqkm9pn398g5bfnaknynii4yqc2sa1i8qhzpp8jkdqf3bczcvz";
    propagatedBuildInputs = [
      trace
    ];
  };

  rpc = buildFromGitHub {
    version = 2;
    owner = "gorilla";
    repo = "rpc";
    rev = "v1.1.0";
    sha256 = "12qqc07dsi4vqc8wkmjlwdiyzh8fdzclmylbx93dxjfrav3psnl5";
  };

  rsc = buildFromGitHub {
    version = 2;
    owner = "mdp";
    repo = "rsc";
    date = "2016-01-31";
    rev = "90f07065088deccf50b28eb37c93dad3078c0f3c";
    sha256 = "0nibwihq09m5chhryi20dcjg9bbk4yy0x2asz0c8ln73hrcijdm1";
    buildInputs = [
      pkgs.qrencode
    ];
  };

  runc = buildFromGitHub {
    version = 2;
    rev = "v1.0.0-rc1";
    owner = "opencontainers";
    repo = "runc";
    sha256 = "f9d79f48bbaf1c385219bf8617a25eb88f9a81f25f1a168830700e8ea9004db1";
    propagatedBuildInputs = [
      dbus
      fileutils
      go-systemd
      go-units
      gocapability
      libseccomp-golang
      logrus
      moby_for_runc
      netlink
      protobuf
      runtime-spec
      urfave_cli
    ];
    meta.autoUpdate = false;
  };

  runtime-spec = buildFromGitHub {
    version = 2;
    rev = "v1.0.0-rc1";
    owner = "opencontainers";
    repo = "runtime-spec";
    sha256 = "f5b8967328a8c42eafac05ae8569f6e23cbb5b23d7af55072ee57c04c4622742";
    buildInputs = [
      gojsonschema
    ];
    meta.autoUpdate = false;
  };

  sanitized-anchor-name = buildFromGitHub {
    version = 3;
    owner = "shurcooL";
    repo = "sanitized_anchor_name";
    rev = "86672fcb3f950f35f2e675df2240550f2a50762f";
    date = "2017-09-18";
    sha256 = "1wz3vr7cm291bmrc7xd6v6vb5fk66iqjkky34snfkv5k1bvqlkqv";
  };

  sarama_v1 = buildFromGitHub {
    version = 3;
    owner = "Shopify";
    repo = "sarama";
    rev = "v1.14.0";
    sha256 = "1fj057mn3sf862kvjj6a9z15khzlaz8p3ww157nrj09g0z6dvsj8";
    goPackagePath = "gopkg.in/Shopify/sarama.v1";
    excludedPackages = "\\(mock\\|tools\\)";
    propagatedBuildInputs = [
      go-resiliency
      go-spew
      go-xerial-snappy
      lz4
      queue
      rcrowley_go-metrics
    ];
  };

  scada-client = buildFromGitHub {
    version = 3;
    date = "2016-06-01";
    rev = "6e896784f66f82cdc6f17e00052db91699dc277d";
    owner  = "hashicorp";
    repo   = "scada-client";
    sha256 = "0qafn7fq202skkdrvsgacifbpznclx6cqkscahldaan2rc2rglys";
    buildInputs = [
      armon_go-metrics
    ];
    propagatedBuildInputs = [
      net-rpc-msgpackrpc
      hashicorp_yamux
    ];
  };

  scaleway-sdk = buildFromGitHub {
    version = 3;
    owner = "nicolai86";
    repo = "scaleway-sdk";
    rev = "1e16a43b03e72c6a1451e5d7bb507a3ce64995ae";
    sha256 = "1zg5vjik4p5vg0np5nld8bmr50iqcimw4in3yjwljd1krbnxhvrr";
    meta.useUnstable = true;
    date = "2017-12-04";
    goPackageAliases = [
      "github.com/nicolai86/scaleway-sdk/api"
    ];
    propagatedBuildInputs = [
      sync
    ];
  };

  schema = buildFromGitHub {
    version = 3;
    owner = "juju";
    repo = "schema";
    rev = "e4e05803c9a103fdfa880476044100ac17e54830";
    sha256 = "0m52ghnbi088l106ajsqwlsksjnryji6xhwi3biyhhi7lxc8iy4r";
    date = "2016-09-16";
    propagatedBuildInputs = [
      utils
    ];
  };

  sdnotify = buildFromGitHub {
    version = 3;
    rev = "ed8ca104421a21947710335006107540e3ecb335";
    owner = "okzk";
    repo = "sdnotify";
    sha256 = "089plny2r6hf1h8zwf97zfahdkizvnnla4ybd04likinvh45hb38";
    date = "2016-08-04";
  };

  seed = buildFromGitHub {
    version = 2;
    rev = "e2103e2c35297fb7e17febb81e49b312087a2372";
    owner = "sean-";
    repo = "seed";
    sha256 = "0hnkw8zjiqkyffxfbgh1020dgy0vxzad1kby0kkm8ld3i5g0aq7a";
    date = "2017-03-13";
  };

  semver = buildFromGitHub {
    version = 3;
    rev = "v3.5.1";
    owner = "blang";
    repo = "semver";
    sha256 = "0aanqrqs0kybkvnd5rqpd5lrdv8bnh8k9i938r3rch49a6gwq6qq";
  };

  sentences_v1 = buildFromGitHub {
    version = 3;
    rev = "v1.0.6";
    owner = "neurosnap";
    repo = "sentences";
    sha256 = "1shbz0hapziqswhfj2ddq3ppal10xjk63i3ndvf81sv41ipnpi7d";
    goPackagePath = "gopkg.in/neurosnap/sentences.v1";
  };

  serf = buildFromGitHub {
    version = 3;
    rev = "a110af454b635c75adc2b7eee541af2c68666d97";
    owner  = "hashicorp";
    repo   = "serf";
    sha256 = "0bgglxm0qzikqs116a8in8ln6f646wpm1357r8xag7ay6jnj04vx";

    buildInputs = [
      armon_go-metrics
      circbuf
      columnize
      go-syslog
      logutils
      mapstructure
      hashicorp_mdns
      memberlist
      mitchellh_cli
      ugorji_go
    ];
    meta.useUnstable = true;
    date = "2017-12-07";
  };

  session = buildFromGitHub {
    version = 2;
    rev = "b8e286a0dba8f4999042d6b258daf51b31d08938";
    owner  = "go-macaron";
    repo   = "session";
    sha256 = "12a9irqcs1jsvxpfb6i1357r5xn14qchn4k9a211f4w1ddgiiw7d";
    date = "2017-03-20";
    propagatedBuildInputs = [
      com
      gomemcache
      go-couchbase
      ini_v1
      ledisdb
      macaron_v1
      mysql
      nodb
      pq
      redis_v2
    ];
  };

  sftp = buildFromGitHub {
    version = 3;
    owner = "pkg";
    repo = "sftp";
    rev = "1.0.0";
    sha256 = "cbbc01da5c0c3509df743d99bf801534ad71865530fa119f5c2b280c726b41e9";
    propagatedBuildInputs = [
      crypto
      errors
      fs
    ];
  };

  sha256-simd = buildFromGitHub {
    version = 3;
    owner = "minio";
    repo = "sha256-simd";
    date = "2017-11-07";
    rev = "c985c18ac142249e0b2ca0d455d2192560e1b145";
    sha256 = "0l0r01n6wma4yjmb62a5qlbj4kl4rclncqhmrdckhbvvjzqr820g";
  };

  shell = buildGoPackage rec {
    name = nameFunc {
      inherit
        goPackagePath
        rev;
      date = "2016-01-05";
    };
    rev = "4e4a4403205db46f1ef0590e98dc814a38d2ea63";
    goPackagePath = "bitbucket.org/creachadair/shell";
    src = fetchzip {
      version = 3;
      inherit name;
      url = "https://bitbucket.org/creachadair/shell/get/${rev}.tar.gz";
      sha256 = "15sv6548dcjnp1bv17gmk3lxjdbcf6309x0q9g0nk1k9j2mas725";
    };
  };


  shellescape = buildFromGitHub {
    version = 3;
    owner = "alessio";
    repo = "shellescape";
    rev = "v1.2";
    sha256 = "0vr93zsjhcdgf7q91hv0shj5r3kabagjgv43zakwp7yw9d46bvrk";
  };

  skyring-common = buildFromGitHub {
    version = 2;
    owner = "skyrings";
    repo = "skyring-common";
    date = "2016-09-29";
    rev = "d1c0bb1cbd5ed8438be1385c85c4f494608cde1e";
    sha256 = "0wr3bw55daf8ryz46hviwvs1wz1l2c6x3rrccr70gllg74lg1wd5";
    buildInputs = [
      crypto
      go-logging
      go-python
      gorequest
      graphite-golang
      influxdb_client
      mgo_v2
    ];
    postPatch = /* go-python now uses float64 */ ''
      sed -i tools/gopy/gopy.go \
        -e 's/python.PyFloat_FromDouble(f32)/python.PyFloat_FromDouble(f64)/'
    '';
  };

  slices = buildFromGitHub {
    version = 2;
    rev = "145c47818f5f4e3ab04935822b3bd440e54ffc45";
    owner  = "feyeleanor";
    repo   = "slices";
    sha256 = "1bgzczwymd0498gk9ikrdfw32s5cir9n1skrnz0jh5qwkxdljm9n";
    date = "2016-12-30";
    propagatedBuildInputs = [
      raw
    ];
  };

  slug = buildFromGitHub {
    version = 3;
    rev = "v1.1.1";
    owner  = "gosimple";
    repo   = "slug";
    sha256 = "0zps9gpk356lff5ryxva633fch8ljcn7h6cjl35q0vfwnvx817cj";
    propagatedBuildInputs = [
      com
      macaron_v1
      unidecode
    ];
  };

  smux = buildFromGitHub {
    version = 3;
    rev = "v1.0.6";
    owner  = "xtaci";
    repo   = "smux";
    sha256 = "0w427s57hj65j8vh1hga1akxmgqk3jrl9m1g7mh7adrmynjsfwpf";
    propagatedBuildInputs = [
      errors
    ];
  };

  softlayer-go = buildFromGitHub {
    version = 3;
    date = "2017-12-06";
    rev = "4ab45e703b87b8f8eba4d0715933bc4e061b4ce5";
    owner = "softlayer";
    repo = "softlayer-go";
    sha256 = "1xlyfb9ffcgmrr6ffh8836mr0gv32m84gsk4sma77918b71drs1p";
    propagatedBuildInputs = [
      tools
      xmlrpc
    ];
  };

  sortutil = buildFromGitHub {
    version = 3;
    date = "2015-06-17";
    rev = "4c7342852e65c2088c981288f2c5610d10b9f7f4";
    owner = "cznic";
    repo = "sortutil";
    sha256 = "1r57m3g20dm3ayp9mjqp4s4bl0wvak5ahgisgb1k6hbsc5si27vr";
  };

  spacelog = buildFromGitHub {
    version = 3;
    date = "2017-11-03";
    rev = "081216856ee01315ad130cb9ccd5d2a40624c619";
    owner = "spacemonkeygo";
    repo = "spacelog";
    sha256 = "0ikfdrly4qnsvvri96jcz9d7lgpbf9xl9x82y23lpcrd1fwkis39";
    buildInputs = [
      flagfile
      sys
    ];
  };

  spdystream = buildFromGitHub {
    version = 3;
    rev = "bc6354cbbc295e925e4c611ffe90c1f287ee54db";
    owner = "docker";
    repo = "spdystream";
    sha256 = "0fmssdkjhb18p4inqzf2ydqsa3rza903ni8id9j5qb8pfakx7pqh";
    date = "2017-09-12";
    propagatedBuildInputs = [
      websocket
    ];
  };

  speakeasy = buildFromGitHub {
    version = 3;
    rev = "v0.1.0";
    owner = "bgentry";
    repo = "speakeasy";
    sha256 = "1zg744bdadwcpln9lcl2837hkdx0iynrjz99incqavp2nl3974yk";
  };

  spec_appc = buildFromGitHub {
    version = 3;
    rev = "v0.8.11";
    owner  = "appc";
    repo   = "spec";
    sha256 = "1zglgv1nazzh1sm1p10vpz371njxd2xhh6lhqlsc5zqlk3h2qdzb";
    propagatedBuildInputs = [
      go4
      go-semver
      inf_v0
      net
      pflag
    ];
  };

  spec_openapi = buildFromGitHub {
    version = 3;
    date = "2017-12-06";
    rev = "01738944bdee0f26bf66420c5b17d54cfdf55341";
    owner  = "go-openapi";
    repo   = "spec";
    sha256 = "1ywidykqq164v9r50acldkm153zqk8ajl26x0gkdw92qkqq5lvf1";
    propagatedBuildInputs = [
      jsonpointer
      jsonreference
      swag
    ];
  };

  srslog = buildFromGitHub {
    version = 3;
    rev = "4d2c753a4ee12647a5a279ee6e6e767861509706";
    date = "2017-09-20";
    owner  = "RackSec";
    repo   = "srslog";
    sha256 = "0kpfdbh9852zqd4amlj0v3mwhlz650h2czlbgm9vdidps9siz6yq";
  };

  ssh-agent = buildFromGitHub {
    version = 3;
    rev = "ba9c9e33906f58169366275e3450db66139a31a9";
    date = "2015-12-15";
    owner  = "xanzy";
    repo   = "ssh-agent";
    sha256 = "0qrzy6mla0wdf7nwgy22biccmavznqh4cw8nhzyj4i9pf3vy6570";
    propagatedBuildInputs = [
      crypto
    ];
  };

  stack = buildFromGitHub {
    version = 3;
    rev = "v1.7.0";
    owner = "go-stack";
    repo = "stack";
    sha256 = "12mzkgxayiblwzdharhi7wqf6wmwn69k4bdvpyzn3xyw5czws9z3";
  };

  stathat = buildFromGitHub {
    version = 3;
    date = "2016-07-15";
    rev = "74669b9f388d9d788c97399a0824adbfee78400e";
    owner = "stathat";
    repo = "go";
    sha256 = "1sj08j6pqq43x3d73ql0y947lvwn5xybvf7waqc7nixvjxla0mcp";
  };

  statik = buildFromGitHub {
    version = 2;
    owner = "rakyll";
    repo = "statik";
    date = "2017-04-10";
    rev = "89fe3459b5c829c32e89bdff9c43f18aad728f2f";
    sha256 = "027iy2yrppplr4yc14ixriaar5m6b1y3x3z0svlfi8b5n62l5frm";
    postPatch = /* Remove recursive import of itself */ ''
      sed -i example/main.go \
        -e '/"github.com\/rakyll\/statik\/example\/statik"/d'
    '';
  };

  stats = buildFromGitHub {
    version = 3;
    rev = "1bf9dbcd8cbe1fdb75add3785b1d4a9a646269ab";
    owner = "montanaflynn";
    repo = "stats";
    sha256 = "1bc074vn5dsfylg3kjjvz7z7p9pqhz6v81i5klq141587nz7vksw";
    date = "2017-12-01";
  };

  structs = buildFromGitHub {
    version = 3;
    rev = "f5faa72e73092639913f5833b75e1ac1d6bc7a63";
    owner  = "fatih";
    repo   = "structs";
    sha256 = "01bgx9gnfy5pn563ip1x10i4qxf82xgc8ypz9i0vn1x3p415n099";
    date = "2017-10-20";
  };

  stump = buildFromGitHub {
    version = 3;
    date = "2016-06-11";
    rev = "206f8f13aae1697a6fc1f4a55799faf955971fc5";
    owner = "whyrusleeping";
    repo = "stump";
    sha256 = "0vxx2mf7pz5b33icjy3sc6ndm6ahrhqzmgb1kmnlnjxs1ilmca53";
  };

  strutil = buildFromGitHub {
    version = 3;
    date = "2017-10-16";
    rev = "529a34b1c186b483642a7a230c67521d9aa4b0fb";
    owner = "cznic";
    repo = "strutil";
    sha256 = "09wimc44daxzmn560s7wffbijqacw1apvsmvrinc1ypllqxmymsl";
  };

  suture = buildFromGitHub {
    version = 3;
    rev = "87e298c9891673c9ae76e10c2c9be589127e5f49";
    owner  = "thejerf";
    repo   = "suture";
    sha256 = "09ghhfdaza655irwymlpa128fkfg1k6rxa6agb4d5wyir8y6szgh";
    date = "2017-10-23";
  };

  swag = buildFromGitHub {
    version = 3;
    rev = "cf0bdb963811675a4d7e74901cefc7411a1df939";
    owner = "go-openapi";
    repo = "swag";
    sha256 = "1fd1xr6kd26wpy53jk9z86zshnfbmczmfbklv2p6b0214ixnznil";
    date = "2017-11-11";
    propagatedBuildInputs = [
      easyjson
      yaml_v2
    ];
  };

  swarmkit = buildFromGitHub {
    version = 3;
    rev = "8d2daa633988e7a3977fad72a4e17d624305b0aa";
    owner = "docker";
    repo = "swarmkit";
    sha256 = "0jwwwhyivf2n2w8r5vvcpm84xdlh75xhsznkxa2zm7czcczsaf5a";
    date = "2017-12-07";
    subPackages = [
      "api"
      "api/deepcopy"
      "api/equality"
      "api/genericresource"
      "api/naming"
      "ca"
      "connectionbroker"
      "identity"
      "ioutils"
      "log"
      "manager/raftselector"
      "manager/state"
      "manager/state/store"
      "protobuf/plugin"
      "remotes"
      "watch"
      "watch/queue"
    ];
    propagatedBuildInputs = [
      cfssl
      errors
      etcd_for_swarmkit
      go-digest
      go-events
      go-grpc-prometheus
      go-memdb
      docker_go-metrics
      gogo_protobuf
      grpc
      logrus
      net
    ];
    postPatch = ''
      find . -name \*.pb.go -exec sed -i {} \
        -e 's,metadata\.FromContext,metadata.FromIncomingContext,' \
        -e 's,metadata\.NewContext,metadata.NewOutgoingContext,' \;
    '';
  };

  swift = buildFromGitHub {
    version = 3;
    rev = "c95c6e5c2d1a3d37fc44c8c6dc9e231c7500667d";
    owner  = "ncw";
    repo   = "swift";
    sha256 = "1pqywd3hnpha4414ny0f86fqdf7nbays3n8bc7zafirzdv4h134f";
    date = "2017-10-19";
  };

  syncthing = buildFromGitHub rec {
    version = 3;
    rev = "v0.14.41";
    owner = "syncthing";
    repo = "syncthing";
    sha256 = "0fx0askmzzq566g4lr059ysfr2rg33jyf5f6vff1774wkb8c6g46";
    buildFlags = [ "-tags noupgrade" ];
    buildInputs = [
      AudriusButkevicius_cli
      crypto
      du
      gateway
      geoip2-golang
      glob
      go-deadlock
      go-lz4
      AudriusButkevicius_go-nat-pmp
      go-shellquote
      go-stun
      gogo_protobuf
      goleveldb
      groupcache
      kcp-go
      luhn
      net
      notify
      osext
      pfilter
      pq
      qart
      ql
      rcrowley_go-metrics
      rollinghash
      sha256-simd
      smux
      suture
      text
      time
      xdr
    ];
    postPatch = ''
      # Mostly a cosmetic change
      sed -i 's,unknown-dev,${rev},g' cmd/syncthing/main.go
    '';
    preBuild = ''
      pushd go/src/$goPackagePath
      go run script/genassets.go gui > lib/auto/gui.files.go
      popd
    '';
  };

  tablewriter = buildFromGitHub {
    version = 3;
    rev = "65fec0d89a572b4367094e2058d3ebe667de3b60";
    date = "2017-12-03";
    owner  = "olekukonko";
    repo   = "tablewriter";
    sha256 = "1xcarkyccm5lz3iqdydg67z5xdgyjvy5grf3s9q8ysvi82izfl1i";
    propagatedBuildInputs = [
      go-runewidth
    ];
  };

  tail = buildFromGitHub {
    version = 3;
    rev = "37f4271387456dd1bf82ab1ad9229f060cc45386";
    owner  = "hpcloud";
    repo   = "tail";
    sha256 = "1ki7svma2y9va1wb0fc8vwa0wncgsgs17nxz1rqc9i8iim21mfp1";
    propagatedBuildInputs = [
      fsnotify_v1
      tomb_v1
    ];
    date = "2017-08-14";
  };

  tally = buildFromGitHub {
    version = 3;
    rev = "v3.3.1";
    owner  = "uber-go";
    repo   = "tally";
    sha256 = "089hpbh72lf06hl2nj54qs9vh9s8k2w5ih0w1mb3xiijbzhbdlk5";
    subPackages = [
      "."
    ];
    propagatedBuildInputs = [
      clock
    ];
  };

  tar-split = buildFromGitHub {
    version = 2;
    owner = "vbatts";
    repo = "tar-split";
    rev = "bd4c5d64c3e9297f410025a3b1bd0c58f659e721";
    date = "2016-09-26";
    sha256 = "e317e4bb73fab3e03ff34b96a861fec72e716f61fc01343876131e50dfacc402";
    propagatedBuildInputs = [
      urfave_cli
      logrus
    ];
  };

  tar-utils = buildFromGitHub {
    version = 3;
    rev = "beab27159606f5a7c978268dd1c3b12a0f1de8a7";
    date = "2016-03-22";
    owner  = "whyrusleeping";
    repo   = "tar-utils";
    sha256 = "0gib1c3in07m6pj0wdmx2s2h2hcy0dpqak9igxmcfxx22ygjcwwk";
  };

  tb = buildFromGitHub {
    version = 2;
    owner = "tsenart";
    repo = "tb";
    rev = "19f4c3d79d2bd67d0911b2e310b999eeea4454c1";
    date = "2015-12-08";
    sha256 = "fb8fb335f10f48e641b3a6abcfe3eb20737cfb5a71aa6b6dbd3399aaedcb8fad";
  };

  teleport = buildFromGitHub {
    version = 3;
    rev = "v2.3.6";
    owner = "gravitational";
    repo = "teleport";
    sha256 = "f8096f0c801b1292c82367d169049f3d5363f6c00a92240d5f10a9c970ce6e8a";
    nativeBuildInputs = [
      pkgs.protobuf-cpp
      protobuf.bin
    ];
    buildInputs = [
      aws-sdk-go
      backoff
      bolt
      configure
      clockwork
      crypto
      etcd_client
      etree
      form
      genproto
      go-oidc
      go-shellwords
      gops
      gosaml2
      goterm
      goxmldsig
      grpc
      grpc-gateway
      hdrhistogram
      hotp
      httprouter
      gravitational_kingpin
      lemma
      logrus
      kubernetes-apimachinery
      moby_for_runc
      net
      osext
      otp
      oxy
      predicate
      prometheus_client_golang
      protobuf
      pty
      roundtrip
      shellescape
      text
      timetools
      trace
      gravitational_ttlmap
      mailgun_ttlmap
      u2f
      pborman_uuid
      yaml
      yaml_v2
    ];
    excludedPackages = "\\(test\\|suite\\|fixtures\\|examples\\|docker\\)";
    meta.autoUpdate = false;
    patches = [
      (fetchTritonPatch {
        rev = "bbf0173a53b7b44b052022532eaca9aa0565f5e3";
        file = "t/teleport/fix.patch";
        sha256 = "7deb529032415073c1883b0557b35156c28b9010f6dab0ae41c4262f1ab38f8b";
      })
    ];
    postPatch = ''
      sed -i 's,--gofast_out,--go_out,' Makefile
    '';
    preBuild = ''
      GATEWAY_SRC=$(readlink -f unpack/grpc-gateway*)/src
      API_SRC=$GATEWAY_SRC/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis
      PROTO_INCLUDE=$GATEWAY_SRC:$API_SRC \
        make -C go/src/$goPackagePath buildbox-grpc
    '';
    preFixup = ''
      test -f "$bin"/bin/tctl
    '';
  };

  template = buildFromGitHub {
    version = 3;
    rev = "a0175ee3bccc567396460bf5acd36800cb10c49c";
    owner = "alecthomas";
    repo = "template";
    sha256 = "1wp7bswkmzm8rzzz0pg10w7092mbjv1l5gdwv7nncxapr9wbdigr";
    date = "2016-04-05";
  };

  termbox-go = buildFromGitHub {
    version = 3;
    rev = "aa4a75b1c20a2b03751b1a9f7e41d58bd6f71c43";
    date = "2017-11-04";
    owner = "nsf";
    repo = "termbox-go";
    sha256 = "010g0l17277rnzxa1h1ib90kl0a49cmfak497r8jw9g34m355xjp";
    propagatedBuildInputs = [
      go-runewidth
    ];
  };

  testify = buildFromGitHub {
    version = 3;
    rev = "2aa2c176b9dab406a6970f6a55f513e8a8c8b18f";
    owner = "stretchr";
    repo = "testify";
    sha256 = "16zqwr4c60zsmbd5rfp76l9l37x1j88ln17zv0jbv3i6pp8h7n0x";
    propagatedBuildInputs = [
      go-difflib
      go-spew
      objx
    ];
    date = "2017-10-18";
  };

  kr_text = buildFromGitHub {
    version = 2;
    rev = "7cafcd837844e784b526369c9bce262804aebc60";
    date = "2016-05-04";
    owner = "kr";
    repo = "text";
    sha256 = "0qmc5rl6rhafiqiqnfrajngzr7qmwfwnj18yccd8jkpd5ix4r70d";
    propagatedBuildInputs = [
      pty
    ];
  };

  thrift = buildFromGitHub {
    version = 3;
    rev = "0.11.0";
    owner  = "apache";
    repo   = "thrift";
    sha256 = "0a3yk479zkyak9g7rakif60dpci29rhmqn3iq8w5afdfyfmj9cfm";
    subPackages = [
      "lib/go/thrift"
    ];
    propagatedBuildInputs = [
      net
    ];
  };

  timecache = buildFromGitHub {
    version = 2;
    rev = "cfcb2f1abfee846c430233aef0b630a946e0a5a6";
    date = "2016-09-10";
    owner  = "whyrusleeping";
    repo   = "timecache";
    sha256 = "0w65wbpf0fzxdj2f1d8km9hg91yp9519agdgb6v6jnxnjvi7d43j";
  };

  times = buildFromGitHub {
    version = 3;
    rev = "d25002f62be22438b4cd804b9d3c8db1231164d0";
    date = "2017-02-15";
    owner  = "djherbis";
    repo   = "times";
    sha256 = "0cy5z8zba7mgxm4fwad3fd698jyr5gmr2i4j2zisffg5j4xsn631";
  };

  timetools = buildFromGitHub {
    version = 3;
    rev = "f3a7b8ffff474320c4f5cc564c9abb2c52ded8bc";
    date = "2017-06-19";
    owner = "mailgun";
    repo = "timetools";
    sha256 = "0kjrg9l3w7znm26anbb655ncgw0ya2lcjry78lk77j08a9hmj6r2";
    propagatedBuildInputs = [
      mgo_v2
    ];
  };

  tokenbucket = buildFromGitHub {
    version = 3;
    rev = "c5a927568de7aad8a58127d80bcd36ca4e71e454";
    date = "2013-12-01";
    owner = "ChimeraCoder";
    repo = "tokenbucket";
    sha256 = "1rc2kdapbr8aw8sf1y5gpqjq4absx57aabr8qg74v9hqirqy9nmp";
  };

  tomb_v2 = buildFromGitHub {
    version = 2;
    date = "2016-12-08";
    rev = "d5d1b5820637886def9eef33e03a27a9f166942c";
    owner = "go-tomb";
    repo = "tomb";
    sha256 = "0azb4hkv41wl750wapl4jbnpvn1jg54z1clcnqvvs84rh75ywqj1";
    goPackagePath = "gopkg.in/tomb.v2";
    buildInputs = [
      net
    ];
  };

  tomb_v1 = buildFromGitHub {
    version = 3;
    date = "2014-10-24";
    rev = "dd632973f1e7218eb1089048e0798ec9ae7dceb8";
    owner = "go-tomb";
    repo = "tomb";
    sha256 = "17ij7zjw58949hrjmq4kjysnd7cqrawlzmwafrf4msxi1mylkk7q";
    goPackagePath = "gopkg.in/tomb.v1";
  };

  toml = buildFromGitHub {
    version = 2;
    owner = "BurntSushi";
    repo = "toml";
    rev = "v0.3.0";
    sha256 = "1cnryizxrj7si27knhh83dd03abw5r0yhac2vmv861inpl3lflx2";
    goPackageAliases = [
      "github.com/burntsushi/toml"
    ];
  };

  trace = buildFromGitHub {
    version = 3;
    owner = "gravitational";
    repo = "trace";
    rev = "1.1.3";
    sha256 = "05bg05aigxxkddq4i7f15vps70n6q9b6qwbrh7m23z7iswnplxn5";
    propagatedBuildInputs = [
      clockwork
      grpc
      logrus
      net
    ];
    postPatch = ''
      sed \
        -e 's,metadata\.FromContext,metadata.FromIncomingContext,' \
        -e 's,metadata\.NewContext,metadata.NewOutgoingContext,' \
        -i trail/trail.go
    '';
  };

  tree = buildFromGitHub {
    version = 3;
    rev = "5554ed4554293f11a726accc1ebf2bd3342742f8";
    owner  = "a8m";
    repo   = "tree";
    sha256 = "1gv2xkrg8gsfl36s5gmlb2l86ns1fv02na7gjb8qwmcfvrhzzqr1";
    date = "2017-11-06";
  };

  trillian = buildFromGitHub {
    version = 3;
    rev = "8842731903be9e99aba531f84782de790c1c9785";
    owner  = "google";
    repo   = "trillian";
    sha256 = "0zbmkk4a6q2s23aab3rsjzzv1dsxp8bmxk13fgxw7zpswn64gsx0";
    date = "2017-08-02";
    propagatedBuildInputs = [
      btree
      etcd_client
      genproto
      glog
      gogo_protobuf
      grpc
      grpc-gateway
      mock
      mysql
      net
      objecthash
      pkcs11key
      prometheus_client_golang
      prometheus_client_model
      protobuf
      shell
    ];
    excludedPackages = "\\(test\\|cmd\\)";
  };

  gravitational_ttlmap = buildFromGitHub {
    version = 3;
    owner = "gravitational";
    repo = "ttlmap";
    rev = "91fd36b9004c1ee5a778739752ea1aba5638c03a";
    sha256 = "02babvj8xj4s6njrjd14l1il1zl35bfxkrb77bfslvv3wfz66b15";
    propagatedBuildInputs = [
      clockwork
      minheap
      trace
    ];
    meta.useUnstable = true;
    date = "2017-11-16";
  };

  mailgun_ttlmap = buildFromGitHub {
    version = 3;
    owner = "mailgun";
    repo = "ttlmap";
    rev = "c1c17f74874f2a5ea48bfb06b5459d4ef2689749";
    sha256 = "0v0ib54klps23bziczws1vk5vqv3649pl0gamirzzj6z0fcmn08s";
    date = "2017-06-19";
    propagatedBuildInputs = [
      minheap
      timetools
    ];
  };

  u2f = buildFromGitHub {
    version = 2;
    rev = "eb799ce68da4150b16ff5d0c89a24e2a2ad993d8";
    owner = "tstranex";
    repo = "u2f";
    sha256 = "8b2e6912aeced8aa055feedbbe3de2ef065666b81181eb1c9e2826cc6d37f81f";
    date = "2016-05-08";
    meta.autoUpdate = false;
  };

  unidecode = buildFromGitHub {
    version = 3;
    rev = "cb7f23ec59bec0d61b19c56cd88cee3d0cc1870c";
    owner = "rainycape";
    repo = "unidecode";
    sha256 = "0ldjpakbmw0kkmcgcfnp4agjilr6lx9z53dcmcnvimshlgbafms2";
    date = "2015-09-07";
  };

  units = buildFromGitHub {
    version = 3;
    rev = "2efee857e7cfd4f3d0138cc3cbb1b4966962b93a";
    owner = "alecthomas";
    repo = "units";
    sha256 = "180b1kxzm03hr4jsy2nnh23g3a3rr0xdlg004a6vla4qvbysj7jh";
    date = "2015-10-22";
  };

  urlesc = buildFromGitHub {
    version = 3;
    owner = "PuerkitoBio";
    repo = "urlesc";
    rev = "de5bf2ad457846296e2031421a34e2568e304e35";
    sate = "2015-02-08";
    sha256 = "0q4m7vhh0bxcj2r6di0f19g7zzgx6sq2m4nrb3p9ds19gbbyg099";
    date = "2017-08-10";
  };

  usage-client = buildFromGitHub {
    version = 2;
    owner = "influxdata";
    repo = "usage-client";
    date = "2016-08-29";
    rev = "6d3895376368aa52a3a81d2a16e90f0f52371967";
    sha256 = "37a9a3330c2a7fac370ccb7117c681dd6fafeef57d327b3071ec13a279fa7996";
  };

  usso = buildFromGitHub {
    version = 3;
    rev = "5b79b358f4bb6735c1b00f6ad051c07c1a1a03e9";
    owner = "juju";
    repo = "usso";
    sha256 = "0q450q292i3ih20n50rf2rc1d3idf1kl8ky2jwrf6r2aq49zw82x";
    date = "2016-04-18";
    propagatedBuildInputs = [
      errgo_v1
      openid-go
    ];
  };

  utils = buildFromGitHub {
    version = 3;
    rev = "4d9b38694f1e441c16421e2320f2b2fbd97fa597";
    owner = "juju";
    repo = "utils";
    sha256 = "057bll3ypwp84320mjk1lp0l6xbl5lkmlg9448n2ywlwv5hayrz9";
    date = "2017-11-22";
    subPackages = [
      "."
      "cache"
      "clock"
      "keyvalues"
    ];
    propagatedBuildInputs = [
      errgo_v1
      juju_errors
      loggo
      crypto
      net
      yaml_v2
    ];
  };

  utfbom = buildFromGitHub {
    version = 3;
    rev = "6c6132ff69f0f6c088739067407b5d32c52e1d0f";
    owner = "dimchansky";
    repo = "utfbom";
    sha256 = "0hibb137n78v50hznzh7080346jgllv6da8wlpr000ajypzw228a";
    date = "2017-03-28";
  };

  pborman_uuid = buildFromGitHub {
    version = 3;
    rev = "v1.1";
    owner = "pborman";
    repo = "uuid";
    sha256 = "1fxshlxq927ak7cywlzcyqw8w1pfqs5cvidk7qdn685vm0rns5d9";
  };

  satori_uuid = buildFromGitHub {
    version = 2;
    rev = "5bf94b69c6b68ee1b541973bb8e1144db23a194b";
    owner = "satori";
    repo = "uuid";
    sha256 = "0qjww7ng1amsn9m3lhnbxalvlv0gndl86g7l6rsxaybhvbcpr15s";
    date = "2017-03-21";
  };

  validator_v2 = buildFromGitHub {
    version = 3;
    rev = "460c83432a98c35224a6fe352acf8b23e067ad06";
    owner = "go-validator";
    repo = "validator";
    sha256 = "0fsicvc6vciyyv0i19v8a572c3z8kxvayf626md8cz44fz3jrdxn";
    goPackagePath = "gopkg.in/validator.v2";
    date = "2017-08-14";
  };

  vault = buildFromGitHub {
    version = 3;
    rev = "v0.9.0";
    owner = "hashicorp";
    repo = "vault";
    sha256 = "0mpllbxhnk39iwcr57pfg20hzn0bw4gnv63ly6jvb6sjy6cz1cm3";

    nativeBuildInputs = [
      pkgs.protobuf-cpp
      protobuf.bin
    ];

    buildInputs = [
      armon_go-metrics
      aws-sdk-go
      columnize
      cockroach-go
      complete
      consul_api
      copystructure
      crypto
      duo_api_golang
      errwrap
      errors
      etcd_client
      go-cache
      go-cleanhttp
      go-colorable
      keybase_go-crypto
      go-errors
      go-github
      go-glob
      go-hclog
      go-hdb
      go-homedir
      go-memdb
      go-mssqldb
      go-multierror
      go-okta
      go-plugin
      go-proxyproto
      go-radix
      go-rootcerts
      go-semver
      hashicorp_go-sockaddr
      go-syslog
      go-testing-interface
      hashicorp_go-uuid
      go-zookeeper
      gocql
      golang-lru
      google-api-go-client
      google-cloud-go
      govalidator
      grpc
      hcl
      jose
      jsonx
      ldap
      logxi
      mapstructure
      mgo_v2
      mitchellh_cli
      mysql
      net
      oauth2
      oktasdk-go
      otp
      pester
      pkcs7
      pq
      protobuf
      gogo_protobuf
      rabbit-hole
      radius
      reflectwalk
      scada-client
      snappy
      structs
      swift
      sys
      vault-plugin-auth-gcp
      vault-plugin-auth-kubernetes
      yaml
    ];

    postPatch = ''
      rm -r physical/azure
      sed -i '/physAzure/d' cli/commands.go
    '';

    # Regerate protos
    preBuild = ''
      srcDir="$(pwd)"/go/src
      pushd go/src/$goPackagePath >/dev/null
      find . -name \*pb.go -delete
      for file in $(find . -name \*.proto | sort | uniq); do
        pushd "$(dirname "$file")" > /dev/null
        echo "Regenerating protobuf: $file" >&2
        protoc -I "$srcDir" -I "$srcDir/$goPackagePath" -I . --go_out=plugins=grpc:. "$(basename "$file")"
        popd >/dev/null
      done
      popd >/dev/null
    '';
  };

  vault_api = vault.override {
    subPackages = [
      "api"
      "helper/compressutil"
      "helper/jsonutil"
      "helper/parseutil"
    ];
    nativeBuildInputs = [
    ];
    buildInputs = [
    ];
    preBuild = ''
    '';
    propagatedBuildInputs = [
      errwrap
      hcl
      go-cleanhttp
      go-multierror
      go-rootcerts
      mapstructure
      net
      pester
      snappy
      structs
    ];
  };

  vault_for_plugins = vault.override {
    subPackages = [
      "api"
      "helper/certutil"
      "helper/compressutil"
      "helper/consts"
      "helper/errutil"
      "helper/jsonutil"
      "helper/logformat"
      "helper/mlock"
      "helper/parseutil"
      "helper/pluginutil"
      "helper/policyutil"
      "helper/salt"
      "helper/strutil"
      "helper/wrapping"
      "logical"
      "logical/framework"
      "logical/plugin"
      "version"
    ];
    nativeBuildInputs = [
    ];
    buildInputs = [
    ];
    preBuild = ''
    '';
    propagatedBuildInputs = [
      errwrap
      go-cleanhttp
      go-glob
      go-hclog
      go-multierror
      go-plugin
      go-radix
      go-rootcerts
      hashicorp_go-uuid
      hcl
      jose
      logxi
      mapstructure
      net
      pester
      snappy
      structs
      sys
    ];
  };

  vault-plugin-auth-gcp = buildFromGitHub {
    version = 3;
    owner = "hashicorp";
    repo = "vault-plugin-auth-gcp";
    rev = "0f25611d56aa41d39f5e82a2f85951fece7cf2d0";
    sha256 = "1v4gjqrc0n2nqmdiybgm1fp42y448y8bvyfqw18ilhlwj057hmj2";
    date = "2017-11-15";
    propagatedBuildInputs = [
      go-cleanhttp
      google-api-go-client
      go-jose_v2
      jose
      oauth2
      vault_for_plugins
    ];
  };

  vault-plugin-auth-kubernetes = buildFromGitHub {
    version = 3;
    owner = "hashicorp";
    repo = "vault-plugin-auth-kubernetes";
    rev = "9d1bbbd0106e1e3c4ebe16cf104cfe855874133e";
    sha256 = "1n79ri5wffhwnxqinac4ikpjn7r06hcpbq6pr2mlapwgdsnn9lgg";
    date = "2017-11-15";
    propagatedBuildInputs = [
      go-cleanhttp
      go-multierror
      jose
      kubernetes-api
      kubernetes-apimachinery
      logxi
      mapstructure
      vault_for_plugins
    ];
  };

  viper = buildFromGitHub {
    version = 3;
    owner = "spf13";
    repo = "viper";
    rev = "v1.0.0";
    sha256 = "0x36dg3if4c5nliyq73801jjs0q2k94kjb0q8fssh9azzfqm8cf4";
    buildInputs = [
      crypt
      pflag
    ];
    propagatedBuildInputs = [
      afero
      cast
      fsnotify
      go-toml
      hcl
      jwalterweatherman
      mapstructure
      properties
      #toml
      yaml_v2
    ];
  };

  vtclean = buildFromGitHub {
    version = 3;
    rev = "d14193dfc626125c831501c1c42340b4248e1f5a";
    owner  = "lunixbochs";
    repo   = "vtclean";
    sha256 = "09cnxishcajlxkfvavphzvzkyjya24ckjsxjq9lawfkzvwv1kf5p";
    date = "2017-05-04";
  };

  vultr = buildFromGitHub {
    version = 3;
    rev = "e5dad9a80e61623e1da10706f486596f77469049";
    owner  = "JamesClonk";
    repo   = "vultr";
    sha256 = "0qhpsbbjb8s51m8x4kn95168cvnflf1rpc82y16nk6jb8pv190ha";
    propagatedBuildInputs = [
      crypto
      mow-cli
      tokenbucket
      ratelimit
    ];
    date = "2017-10-27";
  };

  w32 = buildFromGitHub {
    version = 2;
    rev = "bb4de0191aa41b5507caa14b0650cdbddcd9280b";
    owner = "shirou";
    repo = "w32";
    sha256 = "021764v4m4xp2xdsnlzx6871h5l8vraww39qig7sjsvbpw0v1igx";
    date = "2016-09-30";
  };

  webbrowser = buildFromGitHub {
    version = 3;
    rev = "54b8c57083b4afb7dc75da7f13e2967b2606a507";
    owner  = "juju";
    repo   = "webbrowser";
    sha256 = "0i98zmgrl6zdrg8brjyyr04krpcn01ssvv5g85fmwpiq9qlis12a";
    date = "2016-03-09";
  };

  websocket = buildFromGitHub {
    version = 3;
    rev = "v1.2.0";
    owner  = "gorilla";
    repo   = "websocket";
    sha256 = "1darksigd1zsxpajhvgp39bypif3sjbzc43rhqm0c2n6395k8psp";
  };

  whirlpool = buildFromGitHub {
    version = 3;
    rev = "c19460b8caa623b49cd9060e866f812c4b10c4ce";
    owner = "jzelinskie";
    repo = "whirlpool";
    sha256 = "1dhhxpm9hwnddxajkqc6k6kf6rbj926nkvw88rngycvqxir6bs5k";
    date = "2017-06-03";
  };

  wmi = buildFromGitHub {
    version = 2;
    rev = "ea383cf3ba6ec950874b8486cd72356d007c768f";
    owner = "StackExchange";
    repo = "wmi";
    sha256 = "00s17x9649l6j5i89ccbg3lx0md0ly858yyszn1j7xkx5nkhdq01";
    date = "2017-04-10";
    buildInputs = [
      go-ole
    ];
  };

  yaml = buildFromGitHub {
    version = 2;
    rev = "v1.0.0";
    owner = "ghodss";
    repo = "yaml";
    sha256 = "00g8p1grc0m34m55s3572d0d22f4vmws39f4vxp6djs4i2rzrqx3";
    propagatedBuildInputs = [
      yaml_v2
    ];
  };

  yaml_v2 = buildFromGitHub {
    version = 3;
    rev = "287cf08546ab5e7e37d55a84f7ed3fd1db036de5";
    date = "2017-11-16";
    owner = "go-yaml";
    repo = "yaml";
    sha256 = "0fv2x7hlsv5w9x1dfv7k4i1y69yrpgv3dqhypakq55divs70nlfz";
    goPackagePath = "gopkg.in/yaml.v2";
  };

  yaml_v1 = buildFromGitHub {
    version = 3;
    rev = "9f9df34309c04878acc86042b16630b0f696e1de";
    date = "2014-09-24";
    owner = "go-yaml";
    repo = "yaml";
    sha256 = "0r3zpg7d7i2wl6qdi75sh33d20sm5lh5cvbw60j13xxkbpy04ggs";
    goPackagePath = "gopkg.in/yaml.v1";
  };

  hashicorp_yamux = buildFromGitHub {
    version = 3;
    date = "2017-10-05";
    rev = "f5742cb6b85602e7fa834e9d5d91a7d7fa850824";
    owner  = "hashicorp";
    repo   = "yamux";
    sha256 = "140jjs68b623wm2snv4fgxylwx1fb0zfssijdw1r2s3apr63ihiv";
  };

  whyrusleeping_yamux = buildFromGitHub {
    version = 3;
    date = "2017-09-16";
    rev = "74057c4936c275b645fd51200c33a9c8a223be61";
    owner  = "whyrusleeping";
    repo   = "yamux";
    sha256 = "0vs0aggmqhjzhn85xncihz5hhvrid04p13v9pg6j92a9i00wybdi";
  };

  xdr = buildFromGitHub {
    version = 2;
    rev = "08e072f9cb164f943a92eb59f90f3abc64ac6e8f";
    owner  = "calmh";
    repo   = "xdr";
    sha256 = "01dmdnxvrj40s65w729pjdjh6bf18lm3k57b1mx0z3xql00xsc4k";
    date = "2017-01-04";
  };

  xhandler = buildFromGitHub {
    version = 3;
    owner = "rs";
    repo = "xhandler";
    date = "2017-07-07";
    rev = "1eb70cf1520d43c307a89c5dabb7a7efd132fccd";
    sha256 = "0c1g5pipaj6z08778xx7q47lwp516qyd1zv82jhhls5jzy53c845";
    propagatedBuildInputs = [
      net
    ];
  };

  xmlrpc = buildFromGitHub {
    version = 3;
    rev = "ce4a1a486c03a3c6e1816df25b8c559d1879d380";
    owner  = "renier";
    repo   = "xmlrpc";
    sha256 = "10hl5zlhh4kayp0pvr1yjlpcywmmz6k35n8i8jrnglz2cj5cvm56";
    date = "2017-07-08";
    propagatedBuildInputs = [
      text
    ];
  };

  xor = buildFromGitHub {
    version = 3;
    rev = "0.1.2";
    owner  = "templexxx";
    repo   = "xor";
    sha256 = "0r0gcii6p1qaxxd9sgbwl693jp4kvciqw2qnr1a80l4rv6dyaigf";
    propagatedBuildInputs = [
      cpufeat
    ];
  };

  xorm = buildFromGitHub {
    version = 3;
    rev = "v0.6.4";
    owner  = "go-xorm";
    repo   = "xorm";
    sha256 = "1r3z9i0zna80rdirm8fc0rvmhgqm0n044xscnwlll64v4drbaiwz";
    propagatedBuildInputs = [
      builder
      core
    ];
  };

  xstrings = buildFromGitHub {
    version = 3;
    rev = "d6590c0c31d16526217fa60fbd2067f7afcd78c5";
    date = "2017-09-08";
    owner  = "huandu";
    repo   = "xstrings";
    sha256 = "03ff5krgpq5js8bm32vj31qc7z45a0cswa97c5bqn9kag44cmidm";
  };

  cespare_xxhash = buildFromGitHub {
    version = 3;
    rev = "1b6d2e40c16ba0dfce5c8eac2480ad6e7394819b";
    owner  = "cespare";
    repo   = "xxhash";
    sha256 = "0lnc15cw0rvcpcqh91dx7ljrd2dl1g5c77xpqs956q81g7bq0ls4";
    date = "2017-06-04";
  };

  pierrec_xxhash = buildFromGitHub {
    version = 3;
    rev = "a0006b13c722f7f12368c00a3d3c2ae8a999a0c6";
    owner  = "pierrec";
    repo   = "xxHash";
    sha256 = "0zzllb2d027l3862rz3r77a07pvfjv4a12jhv4ncj0y69gw4lf7l";
    date = "2017-07-14";
  };

  xz = buildFromGitHub {
    version = 3;
    rev = "v0.5.4";
    owner  = "ulikunitz";
    repo   = "xz";
    sha256 = "0anf7p3y1d3m1ll0bacyp093lz6ahgxqv1pji59xg9wwx88vmgl3";
  };

  zap = buildFromGitHub {
    version = 3;
    rev = "v1.7.1";
    owner  = "uber-go";
    repo   = "zap";
    sha256 = "0i05s29x2v7kx8s8gr04nzqp4frkmcy49wzpzng44r4n3glpyvyi";
    goPackagePath = "go.uber.org/zap";
    goPackageAliases = [
      "github.com/uber-go/zap"
    ];
    propagatedBuildInputs = [
      atomic
      multierr
    ];
  };

  zappy = buildFromGitHub {
    version = 3;
    date = "2016-07-23";
    rev = "2533cb5b45cc6c07421468ce262899ddc9d53fb7";
    owner = "cznic";
    repo = "zappy";
    sha256 = "1lvc4gi9h8xbgjq6x2bvxnq9pxh707zlgccpwmycpzx86gfvigmh";
    buildInputs = [
      mathutil
    ];
    extraSrcs = [
      internal
    ];
  };
}; in self
