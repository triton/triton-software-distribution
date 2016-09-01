# THIS IS A GENERATED FILE.  DO NOT EDIT!
args @ { fetchurl, fetchgit, fetchpatch, stdenv, pkgconfig, intltool, freetype, fontconfig
, libxslt, expat, libpng, zlib, perl, mesa_noglu, mesa_drivers, spice-protocol, spice
, dbus, util-linux_lib, openssl, gperf, gnum4, libevdev, tradcpp, libinput, mcpp, makeWrapper, autoreconfHook
, autoconf, automake, libtool, xmlto, asciidoc, flex, bison, python, mtdev, cairo, glib
, libepoxy, wayland, libbsd, systemd_lib, gettext, pciutils, python3, ... }: with args;

let

  mkDerivation = name: attrs:
    let newAttrs = (overrides."${name}" or (x: x)) attrs;
        stdenv = newAttrs.stdenv or args.stdenv;
    in stdenv.mkDerivation (removeAttrs newAttrs [ "stdenv" ] // {
      builder = ./builder.sh;
      postPatch = (attrs.postPatch or "") + ''
        patchShebangs .
      '';
      meta.platforms = with stdenv.lib.platforms;
        x86_64-linux;
	});

  overrides = import ./overrides.nix {inherit args xorg;};

  xorg = rec {

  appres = (mkDerivation "appres" {
    name = "appres-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/appres-1.0.4.tar.bz2;
      sha256 = "139yp08qy1w6dccamdy0fh343yhaf1am1v81m2j435nd4ya4wqcz";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto libXt ];

  }) // {inherit libX11 xproto libXt ;};

  bdftopcf = (mkDerivation "bdftopcf" {
    name = "bdftopcf-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/bdftopcf-1.0.5.tar.bz2;
      sha256 = "09i03sk878cmx2i40lkpsysn7zqcvlczb30j7x3lryb11jz4gx1q";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXfont ];

  }) // {inherit libXfont ;};

  beforelight = (mkDerivation "beforelight" {
    name = "beforelight-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/beforelight-1.0.5.tar.bz2;
      sha256 = "0rl16jgbwwpjvj5wyhplfshfdy21rdyxxa1x1l66ijj8a7qvdjlg";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXScrnSaver libXt ];

  }) // {inherit libX11 libXScrnSaver libXt ;};

  bigreqsproto = (mkDerivation "bigreqsproto" {
    name = "bigreqsproto-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/proto/bigreqsproto-1.1.2.tar.bz2;
      sha256 = "07hvfm84scz8zjw14riiln2v4w03jlhp756ypwhq27g48jmic8a6";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  bitmap = (mkDerivation "bitmap" {
    name = "bitmap-1.0.8";
    src = fetchurl {
      url = mirror://xorg/individual/app/bitmap-1.0.8.tar.bz2;
      sha256 = "0pf31rj8fn61frdbqmqsxwr4ngidz1m6rk78468vlrjl1ywdwv40";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw xbitmaps libXmu xproto libXt ];

  }) // {inherit libX11 libXaw xbitmaps libXmu xproto libXt ;};

  compiz = (mkDerivation "compiz" {
    name = "compiz-0.5.0";
    src = fetchurl {
      url = mirror://xorg/individual/app/compiz-0.5.0.tar.bz2;
      sha256 = "1rm4lbbqrldf57yf7hpag60d5qgx381z16y7rpj7vhxyhrfp94a1";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ cairo dbus dbus-glib fuse gconf glib librsvg libXcomposite libXdamage libXinerama libXrender ];

  }) // {inherit cairo dbus dbus-glib fuse gconf glib librsvg libXcomposite libXdamage libXinerama libXrender ;};

  compositeproto = (mkDerivation "compositeproto" {
    name = "compositeproto-0.4.2";
    src = fetchurl {
      url = mirror://xorg/individual/proto/compositeproto-0.4.2.tar.bz2;
      sha256 = "1z0crmf669hirw4s7972mmp8xig80kfndja9h559haqbpvq5k4q4";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  constype = (mkDerivation "constype" {
    name = "constype-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/constype-1.0.4.tar.bz2;
      sha256 = "16h4l2scdz58a1x1wkpcxvs2q5falgcy21aribdsc01jz4x8m161";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  damageproto = (mkDerivation "damageproto" {
    name = "damageproto-1.2.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/damageproto-1.2.1.tar.bz2;
      sha256 = "0nzwr5pv9hg7c21n995pdiv0zqhs91yz3r8rn3aska4ykcp12z2w";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  dmxproto = (mkDerivation "dmxproto" {
    name = "dmxproto-2.3.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/dmxproto-2.3.1.tar.bz2;
      sha256 = "02b5x9dkgajizm8dqyx2w6hmqx3v25l67mgf35nj6sz0lgk52877";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  dri2proto = (mkDerivation "dri2proto" {
    name = "dri2proto-2.8";
    src = fetchurl {
      url = mirror://xorg/individual/proto/dri2proto-2.8.tar.bz2;
      sha256 = "015az1vfdqmil1yay5nlsmpf6cf7vcbpslxjb72cfkzlvrv59dgr";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  dri3proto = (mkDerivation "dri3proto" {
    name = "dri3proto-1.0";
    src = fetchurl {
      url = mirror://xorg/individual/proto/dri3proto-1.0.tar.bz2;
      sha256 = "0x609xvnl8jky5m8jdklw4nymx3irkv32w99dfd8nl800bblkgh1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  editres = (mkDerivation "editres" {
    name = "editres-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/editres-1.0.6.tar.bz2;
      sha256 = "1w2d5hb5pw9ii2jlf4yjlp899402zfwc8hdkpdr3i1fy1cjd2riv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu libXt ];

  }) // {inherit libX11 libXaw libXmu libXt ;};

  encodings = (mkDerivation "encodings" {
    name = "encodings-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/font/encodings-1.0.4.tar.bz2;
      sha256 = "0ffmaw80vmfwdgvdkp6495xgsqszb6s0iira5j0j6pd4i0lk3mnf";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  evieext = (mkDerivation "evieext" {
    name = "evieext-1.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/evieext-1.1.1.tar.bz2;
      sha256 = "1zik4xcvm6hppd13irn9520ip8rblcw682x9fxjzb6bd8ca43xqw";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  fixesproto = (mkDerivation "fixesproto" {
    name = "fixesproto-5.0";
    src = fetchurl {
      url = mirror://xorg/individual/proto/fixesproto-5.0.tar.bz2;
      sha256 = "1ki4wiq2iivx5g4w5ckzbjbap759kfqd72yg18m3zpbb4hqkybxs";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xextproto ];

  }) // {inherit xextproto ;};

  fontadobe100dpi = (mkDerivation "fontadobe100dpi" {
    name = "font-adobe-100dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-adobe-100dpi-1.0.3.tar.bz2;
      sha256 = "0m60f5bd0caambrk8ksknb5dks7wzsg7g7xaf0j21jxmx8rq9h5j";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontadobe75dpi = (mkDerivation "fontadobe75dpi" {
    name = "font-adobe-75dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-adobe-75dpi-1.0.3.tar.bz2;
      sha256 = "02advcv9lyxpvrjv8bjh1b797lzg6jvhipclz49z8r8y98g4l0n6";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontadobeutopia100dpi = (mkDerivation "fontadobeutopia100dpi" {
    name = "font-adobe-utopia-100dpi-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-adobe-utopia-100dpi-1.0.4.tar.bz2;
      sha256 = "19dd9znam1ah72jmdh7i6ny2ss2r6m21z9v0l43xvikw48zmwvyi";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontadobeutopia75dpi = (mkDerivation "fontadobeutopia75dpi" {
    name = "font-adobe-utopia-75dpi-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-adobe-utopia-75dpi-1.0.4.tar.bz2;
      sha256 = "152wigpph5wvl4k9m3l4mchxxisgsnzlx033mn5iqrpkc6f72cl7";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontadobeutopiatype1 = (mkDerivation "fontadobeutopiatype1" {
    name = "font-adobe-utopia-type1-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-adobe-utopia-type1-1.0.4.tar.bz2;
      sha256 = "0xw0pdnzj5jljsbbhakc6q9ha2qnca1jr81zk7w70yl9bw83b54p";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontalias = (mkDerivation "fontalias" {
    name = "font-alias-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-alias-1.0.3.tar.bz2;
      sha256 = "16ic8wfwwr3jicaml7b5a0sk6plcgc1kg84w02881yhwmqm3nicb";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  fontarabicmisc = (mkDerivation "fontarabicmisc" {
    name = "font-arabic-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-arabic-misc-1.0.3.tar.bz2;
      sha256 = "1x246dfnxnmflzf0qzy62k8jdpkb6jkgspcjgbk8jcq9lw99npah";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbh100dpi = (mkDerivation "fontbh100dpi" {
    name = "font-bh-100dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bh-100dpi-1.0.3.tar.bz2;
      sha256 = "10cl4gm38dw68jzln99ijix730y7cbx8np096gmpjjwff1i73h13";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbh75dpi = (mkDerivation "fontbh75dpi" {
    name = "font-bh-75dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bh-75dpi-1.0.3.tar.bz2;
      sha256 = "073jmhf0sr2j1l8da97pzsqj805f7mf9r2gy92j4diljmi8sm1il";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbhlucidatypewriter100dpi = (mkDerivation "fontbhlucidatypewriter100dpi" {
    name = "font-bh-lucidatypewriter-100dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bh-lucidatypewriter-100dpi-1.0.3.tar.bz2;
      sha256 = "1fqzckxdzjv4802iad2fdrkpaxl4w0hhs9lxlkyraq2kq9ik7a32";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbhlucidatypewriter75dpi = (mkDerivation "fontbhlucidatypewriter75dpi" {
    name = "font-bh-lucidatypewriter-75dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bh-lucidatypewriter-75dpi-1.0.3.tar.bz2;
      sha256 = "0cfbxdp5m12cm7jsh3my0lym9328cgm7fa9faz2hqj05wbxnmhaa";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbhttf = (mkDerivation "fontbhttf" {
    name = "font-bh-ttf-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bh-ttf-1.0.3.tar.bz2;
      sha256 = "0pyjmc0ha288d4i4j0si4dh3ncf3jiwwjljvddrb0k8v4xiyljqv";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbhtype1 = (mkDerivation "fontbhtype1" {
    name = "font-bh-type1-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bh-type1-1.0.3.tar.bz2;
      sha256 = "1hb3iav089albp4sdgnlh50k47cdjif9p4axm0kkjvs8jyi5a53n";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbitstream100dpi = (mkDerivation "fontbitstream100dpi" {
    name = "font-bitstream-100dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bitstream-100dpi-1.0.3.tar.bz2;
      sha256 = "1kmn9jbck3vghz6rj3bhc3h0w6gh0qiaqm90cjkqsz1x9r2dgq7b";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbitstream75dpi = (mkDerivation "fontbitstream75dpi" {
    name = "font-bitstream-75dpi-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bitstream-75dpi-1.0.3.tar.bz2;
      sha256 = "13plbifkvfvdfym6gjbgy9wx2xbdxi9hfrl1k22xayy02135wgxs";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbitstreamspeedo = (mkDerivation "fontbitstreamspeedo" {
    name = "font-bitstream-speedo-1.0.2";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bitstream-speedo-1.0.2.tar.bz2;
      sha256 = "0qv7sxrvfgzjplj0czq8vzf425w6iapl8n5mhb08hywl8q0gw207";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontbitstreamtype1 = (mkDerivation "fontbitstreamtype1" {
    name = "font-bitstream-type1-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-bitstream-type1-1.0.3.tar.bz2;
      sha256 = "1256z0jhcf5gbh1d03593qdwnag708rxqa032izmfb5dmmlhbsn6";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontcacheproto = (mkDerivation "fontcacheproto" {
    name = "fontcacheproto-0.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/proto/fontcacheproto-0.1.3.tar.bz2;
      sha256 = "1jz3vdiwbmnczk7q7f8kixv6kqy1rh81jzanivv2y9qnsicsdjhx";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  fontcronyxcyrillic = (mkDerivation "fontcronyxcyrillic" {
    name = "font-cronyx-cyrillic-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-cronyx-cyrillic-1.0.3.tar.bz2;
      sha256 = "0ai1v4n61k8j9x2a1knvfbl2xjxk3xxmqaq3p9vpqrspc69k31kf";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontcursormisc = (mkDerivation "fontcursormisc" {
    name = "font-cursor-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-cursor-misc-1.0.3.tar.bz2;
      sha256 = "0dd6vfiagjc4zmvlskrbjz85jfqhf060cpys8j0y1qpcbsrkwdhp";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontdaewoomisc = (mkDerivation "fontdaewoomisc" {
    name = "font-daewoo-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-daewoo-misc-1.0.3.tar.bz2;
      sha256 = "1s2bbhizzgbbbn5wqs3vw53n619cclxksljvm759h9p1prqdwrdw";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontdecmisc = (mkDerivation "fontdecmisc" {
    name = "font-dec-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-dec-misc-1.0.3.tar.bz2;
      sha256 = "0yzza0l4zwyy7accr1s8ab7fjqkpwggqydbm2vc19scdby5xz7g1";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontibmtype1 = (mkDerivation "fontibmtype1" {
    name = "font-ibm-type1-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-ibm-type1-1.0.3.tar.bz2;
      sha256 = "1pyjll4adch3z5cg663s6vhi02k8m6488f0mrasg81ssvg9jinzx";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontisasmisc = (mkDerivation "fontisasmisc" {
    name = "font-isas-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-isas-misc-1.0.3.tar.bz2;
      sha256 = "0rx8q02rkx673a7skkpnvfkg28i8gmqzgf25s9yi0lar915sn92q";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontjismisc = (mkDerivation "fontjismisc" {
    name = "font-jis-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-jis-misc-1.0.3.tar.bz2;
      sha256 = "0rdc3xdz12pnv951538q6wilx8mrdndpkphpbblszsv7nc8cw61b";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontmicromisc = (mkDerivation "fontmicromisc" {
    name = "font-micro-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-micro-misc-1.0.3.tar.bz2;
      sha256 = "1dldxlh54zq1yzfnrh83j5vm0k4ijprrs5yl18gm3n9j1z0q2cws";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontmisccyrillic = (mkDerivation "fontmisccyrillic" {
    name = "font-misc-cyrillic-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-misc-cyrillic-1.0.3.tar.bz2;
      sha256 = "0q2ybxs8wvylvw95j6x9i800rismsmx4b587alwbfqiw6biy63z4";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontmiscethiopic = (mkDerivation "fontmiscethiopic" {
    name = "font-misc-ethiopic-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-misc-ethiopic-1.0.3.tar.bz2;
      sha256 = "19cq7iq0pfad0nc2v28n681fdq3fcw1l1hzaq0wpkgpx7bc1zjsk";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontmiscmeltho = (mkDerivation "fontmiscmeltho" {
    name = "font-misc-meltho-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-misc-meltho-1.0.3.tar.bz2;
      sha256 = "148793fqwzrc3bmh2vlw5fdiwjc2n7vs25cic35gfp452czk489p";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontmiscmisc = (mkDerivation "fontmiscmisc" {
    name = "font-misc-misc-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-misc-misc-1.1.2.tar.bz2;
      sha256 = "150pq6n8n984fah34n3k133kggn9v0c5k07igv29sxp1wi07krxq";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontmuttmisc = (mkDerivation "fontmuttmisc" {
    name = "font-mutt-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-mutt-misc-1.0.3.tar.bz2;
      sha256 = "13qghgr1zzpv64m0p42195k1kc77pksiv059fdvijz1n6kdplpxx";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontschumachermisc = (mkDerivation "fontschumachermisc" {
    name = "font-schumacher-misc-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-schumacher-misc-1.1.2.tar.bz2;
      sha256 = "0nkym3n48b4v36y4s927bbkjnsmicajarnf6vlp7wxp0as304i74";
    };
    nativeBuildInputs = [ bdftopcf fontutil mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontscreencyrillic = (mkDerivation "fontscreencyrillic" {
    name = "font-screen-cyrillic-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-screen-cyrillic-1.0.4.tar.bz2;
      sha256 = "0yayf1qlv7irf58nngddz2f1q04qkpr5jwp4aja2j5gyvzl32hl2";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontsonymisc = (mkDerivation "fontsonymisc" {
    name = "font-sony-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-sony-misc-1.0.3.tar.bz2;
      sha256 = "1xfgcx4gsgik5mkgkca31fj3w72jw9iw76qyrajrsz1lp8ka6hr0";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontsproto = (mkDerivation "fontsproto" {
    name = "fontsproto-2.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/proto/fontsproto-2.1.3.tar.bz2;
      sha256 = "1f2sdsd74y34nnaf4m1zlcbhyv8xb6irnisc99f84c4ivnq4d415";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  fontsunmisc = (mkDerivation "fontsunmisc" {
    name = "font-sun-misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-sun-misc-1.0.3.tar.bz2;
      sha256 = "1q6jcqrffg9q5f5raivzwx9ffvf7r11g6g0b125na1bhpz5ly7s8";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fonttosfnt = (mkDerivation "fonttosfnt" {
    name = "fonttosfnt-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/fonttosfnt-1.0.4.tar.bz2;
      sha256 = "157mf1j790pnsx2lhybkpcpmprpx83fjbixxp3lwgydkk6samsiz";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libfontenc freetype xproto ];

  }) // {inherit libfontenc freetype xproto ;};

  fontutil = (mkDerivation "fontutil" {
    name = "font-util-1.3.1";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-util-1.3.1.tar.bz2;
      sha256 = "08drjb6cf84pf5ysghjpb4i7xkd2p86k3wl2a0jxs1jif6qbszma";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  fontwinitzkicyrillic = (mkDerivation "fontwinitzkicyrillic" {
    name = "font-winitzki-cyrillic-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-winitzki-cyrillic-1.0.3.tar.bz2;
      sha256 = "181n1bgq8vxfxqicmy1jpm1hnr6gwn1kdhl6hr4frjigs1ikpldb";
    };
    nativeBuildInputs = [ bdftopcf mkfontdir utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fontxfree86type1 = (mkDerivation "fontxfree86type1" {
    name = "font-xfree86-type1-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/font/font-xfree86-type1-1.0.4.tar.bz2;
      sha256 = "0jp3zc0qfdaqfkgzrb44vi9vi0a8ygb35wp082yz7rvvxhmg9sya";
    };
    nativeBuildInputs = [ mkfontdir mkfontscale utilmacros ];
    buildInputs = [ ];
    configureFlags = [ "--with-fontrootdir=$(out)/lib/X11/fonts" ];

  }) // {inherit ;};

  fslsfonts = (mkDerivation "fslsfonts" {
    name = "fslsfonts-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/fslsfonts-1.0.5.tar.bz2;
      sha256 = "1xnp4vk64s9r6kbn4mapi3z13v225psj53b7qap8vdsn6c4mbvgi";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libFS xproto ];

  }) // {inherit libFS xproto ;};

  fstobdf = (mkDerivation "fstobdf" {
    name = "fstobdf-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/fstobdf-1.0.6.tar.bz2;
      sha256 = "0bp968vq1jlwzsk9fwqfiyfvz8rklp28w2i67w2fg4y94q1mbkv6";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libFS libX11 xproto ];

  }) // {inherit libFS libX11 xproto ;};

  gccmakedep = (mkDerivation "gccmakedep" {
    name = "gccmakedep-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/util/gccmakedep-1.0.3.tar.bz2;
      sha256 = "1r1fpy5ni8chbgx7j5sz0008fpb6vbazpy1nifgdhgijyzqxqxdj";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  glamoregl = (mkDerivation "glamoregl" {
    name = "glamor-egl-0.6.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/glamor-egl-0.6.0.tar.bz2;
      sha256 = "1jg5clihklb9drh1jd7nhhdsszla6nv7xmbvm8yvakh5wrb1nlv6";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ dri2proto mesa_noglu libdrm xorgserver ];

  }) // {inherit dri2proto mesa_noglu libdrm xorgserver ;};

  glproto = (mkDerivation "glproto" {
    name = "glproto-1.4.17";
    src = fetchurl {
      url = mirror://xorg/individual/proto/glproto-1.4.17.tar.bz2;
      sha256 = "0h5ykmcddwid5qj6sbrszgkcypwn3mslvswxpgy2n2iixnyr9amd";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  grandr = (mkDerivation "grandr" {
    name = "grandr-0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/grandr-0.1.tar.bz2;
      sha256 = "1gkjw2khxd0ymrsma4xs7j681jijh82r28cnb2qfzac3ysm1p4lj";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ ];

  }) // {inherit ;};

  hsakmt = (mkDerivation "hsakmt" {
    name = "hsakmt-1.0.0";
    src = fetchurl {
      url = mirror://xorg/individual/lib/hsakmt-1.0.0.tar.bz2;
      sha256 = "0gbf99sljhd3kmd72rdbr7wgn75cd10vzg80p9jmv7adfsicwn7m";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ ];

  }) // {inherit ;};

  iceauth = (mkDerivation "iceauth" {
    name = "iceauth-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/app/iceauth-1.0.7.tar.bz2;
      sha256 = "02izdyzhwpgiyjd8brzilwvwnfr72ncjb6mzz3y1icwrxqnsy5hj";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE xproto ];

  }) // {inherit libICE xproto ;};

  ico = (mkDerivation "ico" {
    name = "ico-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/ico-1.0.4.tar.bz2;
      sha256 = "141mqphg9sfz7x1gfiqpkjkqkiqq1b5zxw67l0ls2p7rk1q7cci9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  imake = (mkDerivation "imake" {
    name = "imake-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/util/imake-1.0.7.tar.bz2;
      sha256 = "0zpk8p044jh14bis838shbf4100bjg7mccd7bq54glpsq552q339";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  inputproto = (mkDerivation "inputproto" {
    name = "inputproto-2.3.2";
    src = fetchurl {
      url = mirror://xorg/individual/proto/inputproto-2.3.2.tar.bz2;
      sha256 = "07gk7v006zqn3dcfh16l06gnccy7xnqywf3vl9c209ikazsnlfl9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  intelgputools = (mkDerivation "intelgputools" {
    name = "intel-gpu-tools-1.15";
    src = fetchurl {
      url = mirror://xorg/individual/app/intel-gpu-tools-1.15.tar.bz2;
      sha256 = "1gb22hvj4gdjj92iqbwcp44kf2znk2l1fvbcrr4sm4i65l8mdwnw";
    };
    nativeBuildInputs = [ bison flex python python3 utilmacros ];
    buildInputs = [ cairo dri2proto glib libdrm systemd_lib libunwind libpciaccess libX11 libXext libXrandr libXv ];

  }) // {inherit cairo dri2proto glib libdrm systemd_lib libunwind libpciaccess libX11 libXext libXrandr libXv ;};

  kbproto = (mkDerivation "kbproto" {
    name = "kbproto-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/proto/kbproto-1.0.7.tar.bz2;
      sha256 = "0mxqj1pzhjpz9495vrjnpi10kv2n1s4vs7di0sh3yvipfq5j30pq";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  lbxproxy = (mkDerivation "lbxproxy" {
    name = "lbxproxy-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/lbxproxy-1.0.3.tar.bz2;
      sha256 = "1vb9fg9f359glk7018cmnwgsmnjq89s5hajsxb7h0lj6sdlb0pq1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ bigreqsproto libICE liblbxutil libX11 libXext xproxymanagementprotocol xtrans ];

  }) // {inherit bigreqsproto libICE liblbxutil libX11 libXext xproxymanagementprotocol xtrans ;};

  libFS = (mkDerivation "libFS" {
    name = "libFS-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libFS-1.0.7.tar.bz2;
      sha256 = "1wy4km3qwwajbyl8y9pka0zwizn7d9pfiyjgzba02x3a083lr79f";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto xproto xtrans ];

  }) // {inherit fontsproto xproto xtrans ;};

  libICE = (mkDerivation "libICE" {
    name = "libICE-1.0.9";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libICE-1.0.9.tar.bz2;
      sha256 = "00p2b6bsg6kcdbb39bv46339qcywxfl4hsrz8asm4hy6q7r34w4g";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libbsd xproto xtrans ];

  }) // {inherit libbsd xproto xtrans ;};

  libSM = (mkDerivation "libSM" {
    name = "libSM-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libSM-1.2.2.tar.bz2;
      sha256 = "1gc7wavgs435g9qkp9jw4lhmaiq6ip9llv49f054ad6ryp4sib0b";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE util-linux_lib xproto xtrans ];

  }) // {inherit libICE util-linux_lib xproto xtrans ;};

  libWindowsWM = (mkDerivation "libWindowsWM" {
    name = "libWindowsWM-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libWindowsWM-1.0.1.tar.bz2;
      sha256 = "1p0flwb67xawyv6yhri9w17m1i4lji5qnd0gq8v1vsfb8zw7rw15";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ windowswmproto libX11 libXext xextproto ];

  }) // {inherit windowswmproto libX11 libXext xextproto ;};

  libX11 = (mkDerivation "libX11" {
    name = "libX11-1.6.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libX11-1.6.3.tar.bz2;
      sha256 = "04c1vj53xq2xgyxx5vhln3wm2d76hh1n95fvs3myhligkz1sfcfg";
    };
    nativeBuildInputs = [ perl utilmacros ];
    buildInputs = [ inputproto kbproto libxcb xextproto xf86bigfontproto xproto xtrans ];

  }) // {inherit inputproto kbproto libxcb xextproto xf86bigfontproto xproto xtrans ;};

  libXScrnSaver = (mkDerivation "libXScrnSaver" {
    name = "libXScrnSaver-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXScrnSaver-1.2.2.tar.bz2;
      sha256 = "07ff4r20nkkrj7h08f9fwamds9b3imj8jz5iz6y38zqw6jkyzwcg";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ scrnsaverproto libX11 libXext xextproto ];

  }) // {inherit scrnsaverproto libX11 libXext xextproto ;};

  libXTrap = (mkDerivation "libXTrap" {
    name = "libXTrap-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXTrap-1.0.1.tar.bz2;
      sha256 = "0bi5wxj6avim61yidh9fd3j4n8czxias5m8vss9vhxjnk1aksdwg";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ trapproto libX11 libXext xextproto libXt ];

  }) // {inherit trapproto libX11 libXext xextproto libXt ;};

  libXau = (mkDerivation "libXau" {
    name = "libXau-1.0.8";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXau-1.0.8.tar.bz2;
      sha256 = "1wm4pv12f36cwzhldpp7vy3lhm3xdcnp4f184xkxsp7b18r7gm7x";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  libXaw = (mkDerivation "libXaw" {
    name = "libXaw-1.0.13";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXaw-1.0.13.tar.bz2;
      sha256 = "1kdhxplwrn43d9jp3v54llp05kwx210lrsdvqb6944jp29rhdy4f";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext xextproto libXmu libXpm xproto libXt ];

  }) // {inherit libX11 libXext xextproto libXmu libXpm xproto libXt ;};

  libXaw3d = (mkDerivation "libXaw3d" {
    name = "libXaw3d-1.6.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXaw3d-1.6.2.tar.bz2;
      sha256 = "0awplv1nf53ywv01yxphga3v6dcniwqnxgnb0cn4khb121l12kxp";
    };
    nativeBuildInputs = [ bison flex utilmacros ];
    buildInputs = [ libX11 libXext libXmu libXpm xproto libXt ];

  }) // {inherit libX11 libXext libXmu libXpm xproto libXt ;};

  libXcomposite = (mkDerivation "libXcomposite" {
    name = "libXcomposite-0.4.4";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXcomposite-0.4.4.tar.bz2;
      sha256 = "0y21nfpa5s8qmx0srdlilyndas3sgl0c6rc26d5fx2vx436m1qpd";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ compositeproto libX11 libXfixes xproto ];

  }) // {inherit compositeproto libX11 libXfixes xproto ;};

  libXcursor = (mkDerivation "libXcursor" {
    name = "libXcursor-1.1.14";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXcursor-1.1.14.tar.bz2;
      sha256 = "1prkdicl5y5yx32h1azh6gjfbijvjp415javv8dsakd13jrarilv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fixesproto libX11 libXfixes xproto libXrender ];

  }) // {inherit fixesproto libX11 libXfixes xproto libXrender ;};

  libXdamage = (mkDerivation "libXdamage" {
    name = "libXdamage-1.1.4";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXdamage-1.1.4.tar.bz2;
      sha256 = "1bamagq7g6s0d23l8rb3nppj8ifqj05f7z9bhbs4fdg8az3ffgvw";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ damageproto fixesproto libX11 xextproto libXfixes xproto ];

  }) // {inherit damageproto fixesproto libX11 xextproto libXfixes xproto ;};

  libXdmcp = (mkDerivation "libXdmcp" {
    name = "libXdmcp-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXdmcp-1.1.2.tar.bz2;
      sha256 = "1qp4yhxbfnpj34swa0fj635kkihdkwaiw7kf55cg5zqqg630kzl1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libbsd xproto ];

  }) // {inherit libbsd xproto ;};

  libXevie = (mkDerivation "libXevie" {
    name = "libXevie-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXevie-1.0.3.tar.bz2;
      sha256 = "0wzx8ic38rj2v53ax4jz1rk39idy3r3m1apc7idmk3z54chkh2y0";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ evieext libX11 libXext xextproto xproto ];

  }) // {inherit evieext libX11 libXext xextproto xproto ;};

  libXext = (mkDerivation "libXext" {
    name = "libXext-1.3.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXext-1.3.3.tar.bz2;
      sha256 = "0dbfn5bznnrhqzvkrcmw4c44yvvpwdcsrvzxf4rk27r36b9x865m";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xextproto xproto ];

  }) // {inherit libX11 xextproto xproto ;};

  libXfixes = (mkDerivation "libXfixes" {
    name = "libXfixes-5.0.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXfixes-5.0.2.tar.bz2;
      sha256 = "1slsk898386xii0r3l7szwwq3s6y2m4dsj0x93ninjh8xkghxllv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fixesproto libX11 xextproto xproto ];

  }) // {inherit fixesproto libX11 xextproto xproto ;};

  libXfont = (mkDerivation "libXfont" {
    name = "libXfont-1.5.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXfont-1.5.2.tar.bz2;
      sha256 = "0w8d07bkmjiarkx09579bl8zsq903mn8javc7qpi0ix4ink5x502";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libfontenc fontsproto freetype xproto xtrans zlib ];

  }) // {inherit libfontenc fontsproto freetype xproto xtrans zlib ;};

  libXfont2 = (mkDerivation "libXfont2" {
    name = "libXfont2-2.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXfont2-2.0.1.tar.bz2;
      sha256 = "0znvwk36nhmyqpmhbm9mzisgixp1mp5qkfald8x1n5yxbm3vpyz9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libfontenc fontsproto freetype xproto xtrans zlib ];

  }) // {inherit libfontenc fontsproto freetype xproto xtrans zlib ;};

  libXfontcache = (mkDerivation "libXfontcache" {
    name = "libXfontcache-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXfontcache-1.0.5.tar.bz2;
      sha256 = "1knbzagrisr68r7l7cv6iriw3rhkblzkh524dc7gllczahcr4qqd";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontcacheproto libX11 libXext xextproto ];

  }) // {inherit fontcacheproto libX11 libXext xextproto ;};

  libXft = (mkDerivation "libXft" {
    name = "libXft-2.3.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXft-2.3.2.tar.bz2;
      sha256 = "0k6wzi5rzs0d0n338ms8n8lfyhq914hw4yl2j7553wqxfqjci8zm";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontconfig freetype libX11 xproto libXrender ];

  }) // {inherit fontconfig freetype libX11 xproto libXrender ;};

  libXi = (mkDerivation "libXi" {
    name = "libXi-1.7.6";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXi-1.7.6.tar.bz2;
      sha256 = "1b5p0l19ynmd6blnqr205wyngh6fagl35nqb4v05dw60rr9aachz";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto libX11 libXext xextproto libXfixes xproto ];

  }) // {inherit inputproto libX11 libXext xextproto libXfixes xproto ;};

  libXinerama = (mkDerivation "libXinerama" {
    name = "libXinerama-1.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXinerama-1.1.3.tar.bz2;
      sha256 = "1qlqfvzw45gdzk9xirgwlp2qgj0hbsyiqj8yh8zml2bk2ygnjibs";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext xextproto xineramaproto ];

  }) // {inherit libX11 libXext xextproto xineramaproto ;};

  libXmu = (mkDerivation "libXmu" {
    name = "libXmu-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXmu-1.1.2.tar.bz2;
      sha256 = "02wx6jw7i0q5qwx87yf94fsn3h0xpz1k7dz1nkwfwm1j71ydqvkm";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext xextproto xproto libXt ];

  }) // {inherit libX11 libXext xextproto xproto libXt ;};

  libXp = (mkDerivation "libXp" {
    name = "libXp-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXp-1.0.3.tar.bz2;
      sha256 = "0mwc2jwmq03b1m9ihax5c6gw2ln8rc70zz4fsj3kb7440nchqdkz";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ printproto libX11 libXau libXext xextproto ];

  }) // {inherit printproto libX11 libXau libXext xextproto ;};

  libXpm = (mkDerivation "libXpm" {
    name = "libXpm-3.5.11";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXpm-3.5.11.tar.bz2;
      sha256 = "07041q4k8m4nirzl7lrqn8by2zylx0xvh6n0za301qqs3njszgf5";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext xextproto xproto libXt ];

  }) // {inherit libX11 libXext xextproto xproto libXt ;};

  libXpresent = (mkDerivation "libXpresent" {
    name = "libXpresent-1.0.0";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXpresent-1.0.0.tar.bz2;
      sha256 = "12kvvar3ihf6sw49h6ywfdiwmb8i1gh8wasg1zhzp6hs2hay06n1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ presentproto libX11 xextproto xproto ];

  }) // {inherit presentproto libX11 xextproto xproto ;};

  libXprintAppUtil = (mkDerivation "libXprintAppUtil" {
    name = "libXprintAppUtil-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXprintAppUtil-1.0.1.tar.bz2;
      sha256 = "198ad7pmkp31vcs0iwd8z3vw08p69hlyjmzgk7sdny9k01368q14";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ printproto libX11 libXau libXp libXprintUtil xproto ];

  }) // {inherit printproto libX11 libXau libXp libXprintUtil xproto ;};

  libXprintUtil = (mkDerivation "libXprintUtil" {
    name = "libXprintUtil-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXprintUtil-1.0.1.tar.bz2;
      sha256 = "0v3fh9fqgravl8xl509swwd9a2v7iw38szhlpraiyq5r402axdkj";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ printproto libX11 libXau libXp libXt ];

  }) // {inherit printproto libX11 libXau libXp libXt ;};

  libXrandr = (mkDerivation "libXrandr" {
    name = "libXrandr-1.5.0";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXrandr-1.5.0.tar.bz2;
      sha256 = "0n6ycs1arf4wb1cal9il6v7vbxbf21qhs9sbfl8xndgwnxclk1kg";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ randrproto renderproto libX11 libXext xextproto xproto libXrender ];

  }) // {inherit randrproto renderproto libX11 libXext xextproto xproto libXrender ;};

  libXrender = (mkDerivation "libXrender" {
    name = "libXrender-0.9.9";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXrender-0.9.9.tar.bz2;
      sha256 = "06myx7044qqdswxndsmd82fpp670klnizkgzdm194h51h1wyabzw";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ renderproto libX11 xproto ];

  }) // {inherit renderproto libX11 xproto ;};

  libXres = (mkDerivation "libXres" {
    name = "libXres-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXres-1.0.7.tar.bz2;
      sha256 = "1rd0bzn67cpb2qkc946gch2183r4bdjfhs6cpqbipy47m9a91296";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ resourceproto libX11 libXext xextproto xproto ];

  }) // {inherit resourceproto libX11 libXext xextproto xproto ;};

  libXt = (mkDerivation "libXt" {
    name = "libXt-1.1.5";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXt-1.1.5.tar.bz2;
      sha256 = "06lz6i7rbrp19kgikpaz4c97fw7n31k2h2aiikczs482g2zbdvj6";
    };
    nativeBuildInputs = [ perl utilmacros ];
    buildInputs = [ libICE kbproto libSM libX11 xproto ];

  }) // {inherit libICE kbproto libSM libX11 xproto ;};

  libXtst = (mkDerivation "libXtst" {
    name = "libXtst-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXtst-1.2.2.tar.bz2;
      sha256 = "1ngn161nq679ffmbwl81i2hn75jjg5b3ffv6n4jilpvyazypy2pg";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto recordproto libX11 libXext xextproto libXi ];

  }) // {inherit inputproto recordproto libX11 libXext xextproto libXi ;};

  libXv = (mkDerivation "libXv" {
    name = "libXv-1.0.10";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXv-1.0.10.tar.bz2;
      sha256 = "09a5j6bisysiipd0nw6s352565bp0n6gbyhv5hp63s3cd3w95zjm";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ videoproto libX11 libXext xextproto xproto ];

  }) // {inherit videoproto libX11 libXext xextproto xproto ;};

  libXvMC = (mkDerivation "libXvMC" {
    name = "libXvMC-1.0.9";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXvMC-1.0.9.tar.bz2;
      sha256 = "0mjp1b21dvkaz7r0iq085r92nh5vkpmx99awfgqq9hgzyvgxf0q7";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ videoproto libX11 libXext xextproto xproto libXv ];

  }) // {inherit videoproto libX11 libXext xextproto xproto libXv ;};

  libXxf86dga = (mkDerivation "libXxf86dga" {
    name = "libXxf86dga-1.1.4";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXxf86dga-1.1.4.tar.bz2;
      sha256 = "0zn7aqj8x0951d8zb2h2andldvwkzbsc4cs7q023g6nzq6vd9v4f";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext xextproto xf86dgaproto xproto ];

  }) // {inherit libX11 libXext xextproto xf86dgaproto xproto ;};

  libXxf86misc = (mkDerivation "libXxf86misc" {
    name = "libXxf86misc-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXxf86misc-1.0.3.tar.bz2;
      sha256 = "0nvbq9y6k6m9hxdvg3crycqsnnxf1859wrisqcs37z9fhq044gsn";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext xextproto xf86miscproto xproto ];

  }) // {inherit libX11 libXext xextproto xf86miscproto xproto ;};

  libXxf86vm = (mkDerivation "libXxf86vm" {
    name = "libXxf86vm-1.1.4";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libXxf86vm-1.1.4.tar.bz2;
      sha256 = "0mydhlyn72i7brjwypsqrpkls3nm6vxw0li8b2nw0caz7kwjgvmg";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext xextproto xf86vidmodeproto xproto ];

  }) // {inherit libX11 libXext xextproto xf86vidmodeproto xproto ;};

  libdmx = (mkDerivation "libdmx" {
    name = "libdmx-1.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libdmx-1.1.3.tar.bz2;
      sha256 = "00djlxas38kbsrglcmwmxfbmxjdchlbj95pqwjvdg8jn5rns6zf9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ dmxproto libX11 libXext xextproto ];

  }) // {inherit dmxproto libX11 libXext xextproto ;};

  libfontenc = (mkDerivation "libfontenc" {
    name = "libfontenc-1.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libfontenc-1.1.3.tar.bz2;
      sha256 = "08gxmrhgw97mv0pvkfmd46zzxrn6zdw4g27073zl55gwwqq8jn3h";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto zlib ];

  }) // {inherit xproto zlib ;};

  liblbxutil = (mkDerivation "liblbxutil" {
    name = "liblbxutil-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/lib/liblbxutil-1.1.0.tar.bz2;
      sha256 = "1bpqgh0zvis3sqp7hjl4l885d37pdg5fnp90m2prqqgcb1wgzdn6";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xextproto xproto zlib ];

  }) // {inherit xextproto xproto zlib ;};

  liboldX = (mkDerivation "liboldX" {
    name = "liboldX-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/lib/liboldX-1.0.1.tar.bz2;
      sha256 = "03rl20g5fx0qfli1a1cxg4mvivgpsblwv9amszjq93z2yl0x748h";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libX11 ];

  }) // {inherit libX11 ;};

  libpciaccess = (mkDerivation "libpciaccess" {
    name = "libpciaccess-0.13.4";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libpciaccess-0.13.4.tar.bz2;
      sha256 = "1krgryi9ngjr66242v0v5mczihgv0y7rrvx0563arr318mjn9y07";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ zlib ];

  }) // {inherit zlib ;};

  libpthreadstubs = (mkDerivation "libpthreadstubs" {
    name = "libpthread-stubs-0.3";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/libpthread-stubs-0.3.tar.bz2;
      sha256 = "16bjv3in19l84hbri41iayvvg4ls9gv1ma0x0qlbmwy67i7dbdim";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ ];

  }) // {inherit ;};

  libxcb = (mkDerivation "libxcb" {
    name = "libxcb-1.12";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/libxcb-1.12.tar.bz2;
      sha256 = "0nvv0la91cf8p5qqlb3r5xnmg1jn2wphn4fb5jfbr6byqsvv3psa";
    };
    nativeBuildInputs = [ python utilmacros ];
    buildInputs = [ libpthreadstubs libXau xcbproto libXdmcp ];

  }) // {inherit libpthreadstubs libXau xcbproto libXdmcp ;};

  libxkbfile = (mkDerivation "libxkbfile" {
    name = "libxkbfile-1.0.9";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libxkbfile-1.0.9.tar.bz2;
      sha256 = "0smimr14zvail7ar68n7spvpblpdnih3jxrva7cpa6cn602px0ai";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ kbproto libX11 ];

  }) // {inherit kbproto libX11 ;};

  libxkbui = (mkDerivation "libxkbui" {
    name = "libxkbui-1.0.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libxkbui-1.0.2.tar.bz2;
      sha256 = "0552zyrm0nvhsyy37x7g767cbii9kc3glvb9dmgywd1jsq0k3hi0";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ kbproto libX11 libxkbfile libXt ];

  }) // {inherit kbproto libX11 libxkbfile libXt ;};

  libxshmfence = (mkDerivation "libxshmfence" {
    name = "libxshmfence-1.2";
    src = fetchurl {
      url = mirror://xorg/individual/lib/libxshmfence-1.2.tar.bz2;
      sha256 = "032b0nlkdrpbimdld4gqvhqx53rzn8fawvf1ybhzn7lcswgjs6yj";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  listres = (mkDerivation "listres" {
    name = "listres-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/listres-1.0.3.tar.bz2;
      sha256 = "13j7xnapaga4lykm14rrkqyz0bi0s2f796hqf3a3y3k506d1xmy3";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXaw libXmu xproto libXt ];

  }) // {inherit libXaw libXmu xproto libXt ;};

  lndir = (mkDerivation "lndir" {
    name = "lndir-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/util/lndir-1.0.3.tar.bz2;
      sha256 = "0pdngiy8zdhsiqx2am75yfcl36l7kd7d7nl0rss8shcdvsqgmx29";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  luit = (mkDerivation "luit" {
    name = "luit-1.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/luit-1.1.1.tar.bz2;
      sha256 = "0dn694mk56x6hdk6y9ylx4f128h5jcin278gnw2gb807rf3ygc1h";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libfontenc ];

  }) // {inherit libfontenc ;};

  makedepend = (mkDerivation "makedepend" {
    name = "makedepend-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/util/makedepend-1.0.5.tar.bz2;
      sha256 = "09alw99r6y2bbd1dc786n3jfgv4j520apblyn7cw6jkjydshba7p";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  mkcfm = (mkDerivation "mkcfm" {
    name = "mkcfm-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/mkcfm-1.0.1.tar.bz2;
      sha256 = "00dymjrv6k230pzyhnlv3kyk5jx0qia2hyab45adgxrqrfjxzfkz";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libfontenc libFS libX11 libXfont ];

  }) // {inherit libfontenc libFS libX11 libXfont ;};

  mkcomposecache = (mkDerivation "mkcomposecache" {
    name = "mkcomposecache-1.2.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/mkcomposecache-1.2.1.tar.bz2;
      sha256 = "1brcrz4rpjh8zz54dbrqlprnkn4fxl4dvlnqzk2s1a5rik8m9vn9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 ];

  }) // {inherit libX11 ;};

  mkfontdir = (mkDerivation "mkfontdir" {
    name = "mkfontdir-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/app/mkfontdir-1.0.7.tar.bz2;
      sha256 = "0c3563kw9fg15dpgx4dwvl12qz6sdqdns1pxa574hc7i5m42mman";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  mkfontscale = (mkDerivation "mkfontscale" {
    name = "mkfontscale-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/mkfontscale-1.1.2.tar.bz2;
      sha256 = "081z8lwh9c1gyrx3ad12whnpv3jpfbqsc366mswpfm48mwl54vcc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libfontenc freetype xproto zlib ];

  }) // {inherit libfontenc freetype xproto zlib ;};

  oclock = (mkDerivation "oclock" {
    name = "oclock-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/oclock-1.0.3.tar.bz2;
      sha256 = "14ahj5immbmhc6jjvs2sn4nk6lw7n6gmazj57xl0b1w2yn2zpxal";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext libXmu libXt ];

  }) // {inherit libX11 libXext libXmu libXt ;};

  pixman = (mkDerivation "pixman" {
    name = "pixman-0.34.0";
    src = fetchurl {
      url = mirror://xorg/individual/lib/pixman-0.34.0.tar.bz2;
      sha256 = "184lazwdpv67zrlxxswpxrdap85wminh1gmq1i5lcz6iycw39fir";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libpng ];

  }) // {inherit libpng ;};

  presentproto = (mkDerivation "presentproto" {
    name = "presentproto-1.0";
    src = fetchurl {
      url = mirror://xorg/individual/proto/presentproto-1.0.tar.bz2;
      sha256 = "1kir51aqg9cwazs14ivcldcn3mzadqgykc9cg87rm40zf947sb41";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  printproto = (mkDerivation "printproto" {
    name = "printproto-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/proto/printproto-1.0.5.tar.bz2;
      sha256 = "06liap8n4s25sgp27d371cc7yg9a08dxcr3pmdjp761vyin3360j";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXau ];

  }) // {inherit libXau ;};

  proxymngr = (mkDerivation "proxymngr" {
    name = "proxymngr-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/proxymngr-1.0.4.tar.bz2;
      sha256 = "0l3zj5v0g079143dm33zass0fwmgsqvlllfbhaqp5rwhavx0k62g";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE xproto xproxymanagementprotocol libXt ];

  }) // {inherit libICE xproto xproxymanagementprotocol libXt ;};

  randrproto = (mkDerivation "randrproto" {
    name = "randrproto-1.5.0";
    src = fetchurl {
      url = mirror://xorg/individual/proto/randrproto-1.5.0.tar.bz2;
      sha256 = "0s4496z61y5q45q20gldwpf788b9nsa8hb13gnck1mwwwwrmarsc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  recordproto = (mkDerivation "recordproto" {
    name = "recordproto-1.14.2";
    src = fetchurl {
      url = mirror://xorg/individual/proto/recordproto-1.14.2.tar.bz2;
      sha256 = "0w3kgr1zabwf79bpc28dcnj0fpni6r53rpi82ngjbalj5s6m8xx7";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  rendercheck = (mkDerivation "rendercheck" {
    name = "rendercheck-1.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/rendercheck-1.5.tar.bz2;
      sha256 = "1k7i16q18ardj9kyh8bqiarfi8ppdlhcpwgilvwwqrbd8dwmcq00";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto libXrender ];

  }) // {inherit libX11 xproto libXrender ;};

  renderproto = (mkDerivation "renderproto" {
    name = "renderproto-0.11.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/renderproto-0.11.1.tar.bz2;
      sha256 = "0dr5xw6s0qmqg0q5pdkb4jkdhaja0vbfqla79qh5j1xjj9dmlwq6";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  resourceproto = (mkDerivation "resourceproto" {
    name = "resourceproto-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/proto/resourceproto-1.2.0.tar.bz2;
      sha256 = "0638iyfiiyjw1hg3139pai0j6m65gkskrvd9684zgc6ydcx00riw";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  rgb = (mkDerivation "rgb" {
    name = "rgb-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/rgb-1.0.6.tar.bz2;
      sha256 = "1c76zcjs39ljil6f6jpx1x17c8fnvwazz7zvl3vbjfcrlmm7rjmv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xorgserver xproto ];

  }) // {inherit xorgserver xproto ;};

  rstart = (mkDerivation "rstart" {
    name = "rstart-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/rstart-1.0.5.tar.bz2;
      sha256 = "1szzs3jah6av90aj1g8zaz7979565cwknaacj336m3gwvyglw4r9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  scripts = (mkDerivation "scripts" {
    name = "scripts-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/scripts-1.0.1.tar.bz2;
      sha256 = "0dm1jhwq1r396xfcxx3g9lvgzydf4mikjicch6cs8b1hb51ln58v";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libX11 ];

  }) // {inherit libX11 ;};

  scrnsaverproto = (mkDerivation "scrnsaverproto" {
    name = "scrnsaverproto-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/proto/scrnsaverproto-1.2.2.tar.bz2;
      sha256 = "0rfdbfwd35d761xkfifcscx56q0n56043ixlmv70r4v4l66hmdwb";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  sessreg = (mkDerivation "sessreg" {
    name = "sessreg-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/app/sessreg-1.1.0.tar.bz2;
      sha256 = "0z013rskwmdadd8cdlxvh4asmgim61qijyzfbqmr1q1mg1jpf4am";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  setxkbmap = (mkDerivation "setxkbmap" {
    name = "setxkbmap-1.3.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/setxkbmap-1.3.1.tar.bz2;
      sha256 = "1qfk097vjysqb72pq89h0la3462kbb2dh1d11qzs2fr67ybb7pd9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libxkbfile ];

  }) // {inherit libX11 libxkbfile ;};

  showfont = (mkDerivation "showfont" {
    name = "showfont-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/showfont-1.0.5.tar.bz2;
      sha256 = "12dcc5j4f9wsd35z852i164ji3bzzp05qhdpzbnm52hbacf5qwz9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libFS ];

  }) // {inherit libFS ;};

  smproxy = (mkDerivation "smproxy" {
    name = "smproxy-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/smproxy-1.0.6.tar.bz2;
      sha256 = "0rkjyzmsdqmlrkx8gy2j4q6iksk58hcc92xzdprkf8kml9ar3wbc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE libSM libXmu libXt ];

  }) // {inherit libICE libSM libXmu libXt ;};

  transset = (mkDerivation "transset" {
    name = "transset-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/transset-1.0.1.tar.bz2;
      sha256 = "0v8330i4gd0vzq37a6zjs36fiwi7j3gdawa9pj385r2ghwrx1hvh";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  trapproto = (mkDerivation "trapproto" {
    name = "trapproto-3.4.3";
    src = fetchurl {
      url = mirror://xorg/individual/proto/trapproto-3.4.3.tar.bz2;
      sha256 = "1qd06blxgah1pf49259gm9njpbqqk1gcisbv8p1ssv39pk9s0cpz";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libXt ];

  }) // {inherit libXt ;};

  twm = (mkDerivation "twm" {
    name = "twm-1.0.9";
    src = fetchurl {
      url = mirror://xorg/individual/app/twm-1.0.9.tar.bz2;
      sha256 = "02iicvhkp3i7q5rliyymiq9bppjr0pzfs6rgb78kppryqdx1cxf5";
    };
    nativeBuildInputs = [ bison flex utilmacros ];
    buildInputs = [ libICE libSM libX11 libXext libXmu xproto libXt ];

  }) // {inherit libICE libSM libX11 libXext libXmu xproto libXt ;};

  utilmacros = (mkDerivation "utilmacros" {
    name = "util-macros-1.19.0";
    src = fetchurl {
      url = mirror://xorg/individual/util/util-macros-1.19.0.tar.bz2;
      sha256 = "1fnhpryf55l0yqajxn0cxan3kvsjzi67nlanz8clwqzf54cb2d98";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ ];

  }) // {inherit ;};

  videoproto = (mkDerivation "videoproto" {
    name = "videoproto-2.3.3";
    src = fetchurl {
      url = mirror://xorg/individual/proto/videoproto-2.3.3.tar.bz2;
      sha256 = "00m7rh3pwmsld4d5fpii3xfk5ciqn17kkk38gfpzrrh8zn4ki067";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  viewres = (mkDerivation "viewres" {
    name = "viewres-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/viewres-1.0.4.tar.bz2;
      sha256 = "0n9fhwf6asijd1g9n3iqz3j8av680jp2hd5kz1nr54cdj121phfr";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXaw libXmu libXt ];

  }) // {inherit libXaw libXmu libXt ;};

  windowswmproto = (mkDerivation "windowswmproto" {
    name = "windowswmproto-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/proto/windowswmproto-1.0.4.tar.bz2;
      sha256 = "0syjxgy4m8l94qrm03nvn5k6bkxc8knnlld1gbllym97nvnv0ny0";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  x11perf = (mkDerivation "x11perf" {
    name = "x11perf-1.6.0";
    src = fetchurl {
      url = mirror://xorg/individual/app/x11perf-1.6.0.tar.bz2;
      sha256 = "0lb716yfdb8f11h4cz93d1bapqdxf1xplsb21kbp4xclq7g9hw78";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext libXft libXmu xproto libXrender ];

  }) // {inherit libX11 libXext libXft libXmu xproto libXrender ;};

  xauth = (mkDerivation "xauth" {
    name = "xauth-1.0.9";
    src = fetchurl {
      url = mirror://xorg/individual/app/xauth-1.0.9.tar.bz2;
      sha256 = "13y2invb0894b1in03jbglximbz6v31y2kr4yjjgica8xciibkjn";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXau libXext libXmu xproto ];

  }) // {inherit libX11 libXau libXext libXmu xproto ;};

  xbacklight = (mkDerivation "xbacklight" {
    name = "xbacklight-1.2.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xbacklight-1.2.1.tar.bz2;
      sha256 = "0arnd1j8vzhzmw72mqhjjcb2qwcbs9qphsy3ps593ajyld8wzxhp";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libxcb xcbutil ];

  }) // {inherit libxcb xcbutil ;};

  xbiff = (mkDerivation "xbiff" {
    name = "xbiff-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xbiff-1.0.3.tar.bz2;
      sha256 = "1s3wqhbwhhrhg1j98057y4ff8zgzh3izczys3c9zxz3s3zrv87da";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw xbitmaps libXext libXmu ];

  }) // {inherit libX11 libXaw xbitmaps libXext libXmu ;};

  xbitmaps = (mkDerivation "xbitmaps" {
    name = "xbitmaps-1.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/data/xbitmaps-1.1.1.tar.bz2;
      sha256 = "178ym90kwidia6nas4qr5n5yqh698vv8r02js0r4vg3b6lsb0w9n";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xcalc = (mkDerivation "xcalc" {
    name = "xcalc-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/xcalc-1.0.6.tar.bz2;
      sha256 = "1n2pj36rivp4z7cwm65adshw15y8i90alzd0drc35p091hbcfwrg";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw xproto libXt ];

  }) // {inherit libX11 libXaw xproto libXt ;};

  xcbdemo = (mkDerivation "xcbdemo" {
    name = "xcb-demo-0.1";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-demo-0.1.tar.bz2;
      sha256 = "191kswbrpj2rnky7j9bbp02gzz5kqk36yaas38qh1p2qjnsknx90";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libxcb xcbutil xcbutilwm xcbutilimage ];

  }) // {inherit libxcb xcbutil xcbutilwm xcbutilimage ;};

  xcbproto = (mkDerivation "xcbproto" {
    name = "xcb-proto-1.12";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-proto-1.12.tar.bz2;
      sha256 = "01j91946q8f34l1mbvmmgvyc393sm28ym4lxlacpiav4qsjan8jr";
    };
    nativeBuildInputs = [ python ];
    buildInputs = [ ];

  }) // {inherit ;};

  xcbutil = (mkDerivation "xcbutil" {
    name = "xcb-util-0.4.0";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-util-0.4.0.tar.bz2;
      sha256 = "1sahmrgbpyki4bb72hxym0zvxwnycmswsxiisgqlln9vrdlr9r26";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libxcb ];

  }) // {inherit libxcb ;};

  xcbutilcursor = (mkDerivation "xcbutilcursor" {
    name = "xcb-util-cursor-0.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-util-cursor-0.1.3.tar.bz2;
      sha256 = "0krr4rcw6r42cncinzvzzdqnmxk3nrgpnadyg2h8k9x10q3hm885";
    };
    nativeBuildInputs = [ gnum4 utilmacros ];
    buildInputs = [ libxcb xcbutilimage xcbutilrenderutil ];

  }) // {inherit libxcb xcbutilimage xcbutilrenderutil ;};

  xcbutilerrors = (mkDerivation "xcbutilerrors" {
    name = "xcb-util-errors-1.0";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-util-errors-1.0.tar.bz2;
      sha256 = "158rm913dg3hxrrhyvvxr8bcm0pjy5jws70dhy2s12w1krv829k8";
    };
    nativeBuildInputs = [ gnum4 utilmacros ];
    buildInputs = [ libxcb xcbproto ];

  }) // {inherit libxcb xcbproto ;};

  xcbutilimage = (mkDerivation "xcbutilimage" {
    name = "xcb-util-image-0.4.0";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-util-image-0.4.0.tar.bz2;
      sha256 = "1z1gxacg7q4cw6jrd26gvi5y04npsyavblcdad1xccc8swvnmf9d";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libxcb xcbutil xproto ];

  }) // {inherit libxcb xcbutil xproto ;};

  xcbutilkeysyms = (mkDerivation "xcbutilkeysyms" {
    name = "xcb-util-keysyms-0.4.0";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-util-keysyms-0.4.0.tar.bz2;
      sha256 = "1nbd45pzc1wm6v5drr5338j4nicbgxa5hcakvsvm5pnyy47lky0f";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libxcb xproto ];

  }) // {inherit libxcb xproto ;};

  xcbutilrenderutil = (mkDerivation "xcbutilrenderutil" {
    name = "xcb-util-renderutil-0.3.9";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-util-renderutil-0.3.9.tar.bz2;
      sha256 = "0nza1csdvvxbmk8vgv8vpmq7q8h05xrw3cfx9lwxd1hjzd47xsf6";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libxcb ];

  }) // {inherit libxcb ;};

  xcbutilwm = (mkDerivation "xcbutilwm" {
    name = "xcb-util-wm-0.4.1";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xcb-util-wm-0.4.1.tar.bz2;
      sha256 = "0gra7hfyxajic4mjd63cpqvd20si53j1q3rbdlkqkahfciwq3gr8";
    };
    nativeBuildInputs = [ gnum4 utilmacros ];
    buildInputs = [ libxcb ];

  }) // {inherit libxcb ;};

  xclipboard = (mkDerivation "xclipboard" {
    name = "xclipboard-1.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xclipboard-1.1.3.tar.bz2;
      sha256 = "1dgb8qjdicb6whg1m7v7cgy8mqd0bixx5k7kdhygfj8x9wghl3lw";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu xproto libXt ];

  }) // {inherit libX11 libXaw libXmu xproto libXt ;};

  xclock = (mkDerivation "xclock" {
    name = "xclock-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/app/xclock-1.0.7.tar.bz2;
      sha256 = "1l3xv4bsca6bwxx73jyjz0blav86i7vwffkhdb1ac81y9slyrki3";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXft libxkbfile libXmu xproto libXrender libXt ];

  }) // {inherit libX11 libXaw libXft libxkbfile libXmu xproto libXrender libXt ;};

  xcmiscproto = (mkDerivation "xcmiscproto" {
    name = "xcmiscproto-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xcmiscproto-1.2.2.tar.bz2;
      sha256 = "1pyjv45wivnwap2wvsbrzdvjc5ql8bakkbkrvcv6q9bjjf33ccmi";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xcmsdb = (mkDerivation "xcmsdb" {
    name = "xcmsdb-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/xcmsdb-1.0.5.tar.bz2;
      sha256 = "1ik7gzlp2igz183x70883000ygp99r20x3aah6xhaslbpdhm6n75";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 ];

  }) // {inherit libX11 ;};

  xcompmgr = (mkDerivation "xcompmgr" {
    name = "xcompmgr-1.1.7";
    src = fetchurl {
      url = mirror://xorg/individual/app/xcompmgr-1.1.7.tar.bz2;
      sha256 = "14k89mz13jxgp4h2pz0yq0fbkw1lsfcb3acv8vkknc9i4ld9n168";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXcomposite libXdamage libXext libXfixes libXrender ];

  }) // {inherit libXcomposite libXdamage libXext libXfixes libXrender ;};

  xconsole = (mkDerivation "xconsole" {
    name = "xconsole-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/xconsole-1.0.6.tar.bz2;
      sha256 = "1lamd2b75kin5svnrfyacb8iwmcczmf02l0h5jikbdz8dsdraqg5";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu xproto libXt ];

  }) // {inherit libX11 libXaw libXmu xproto libXt ;};

  xcursorgen = (mkDerivation "xcursorgen" {
    name = "xcursorgen-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/xcursorgen-1.0.6.tar.bz2;
      sha256 = "0v7nncj3kaa8c0524j7ricdf4rvld5i7c3m6fj55l5zbah7r3j1i";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libpng libX11 libXcursor ];

  }) // {inherit libpng libX11 libXcursor ;};

  xcursorthemes = (mkDerivation "xcursorthemes" {
    name = "xcursor-themes-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/data/xcursor-themes-1.0.4.tar.bz2;
      sha256 = "11mv661nj1p22sqkv87ryj2lcx4m68a04b0rs6iqh3fzp42jrzg3";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXcursor ];

  }) // {inherit libXcursor ;};

  xdbedizzy = (mkDerivation "xdbedizzy" {
    name = "xdbedizzy-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/app/xdbedizzy-1.1.0.tar.bz2;
      sha256 = "028dri1bwm7dja9jb6ygz9ghmz0yn6vsv2ppr54pcymqkqspnl36";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext ];

  }) // {inherit libX11 libXext ;};

  xditview = (mkDerivation "xditview" {
    name = "xditview-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xditview-1.0.4.tar.bz2;
      sha256 = "0wzzs7jmgc3y09bdbyr7q2mnbhwi1221dzjdlzxsg41ypkqqszrh";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu libXt ];

  }) // {inherit libX11 libXaw libXmu libXt ;};

  xdm = (mkDerivation "xdm" {
    name = "xdm-1.1.11";
    src = fetchurl {
      url = mirror://xorg/individual/app/xdm-1.1.11.tar.bz2;
      sha256 = "0iqw11977lpr9nk1is4fca84d531vck0mq7jldwl44m0vrnl5nnl";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXau libXaw libXdmcp libXext libXft libXinerama libXmu libXpm libXt ];

  }) // {inherit libX11 libXau libXaw libXdmcp libXext libXft libXinerama libXmu libXpm libXt ;};

  xdpyinfo = (mkDerivation "xdpyinfo" {
    name = "xdpyinfo-1.3.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xdpyinfo-1.3.2.tar.bz2;
      sha256 = "0ldgrj4w2fa8jng4b3f3biaj0wyn8zvya88pnk70d7k12pcqw8rh";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libdmx libX11 libxcb libXcomposite libXext libXi libXinerama xproto libXrender libXtst libXxf86dga libXxf86misc libXxf86vm ];

  }) // {inherit libdmx libX11 libxcb libXcomposite libXext libXi libXinerama xproto libXrender libXtst libXxf86dga libXxf86misc libXxf86vm ;};

  xdriinfo = (mkDerivation "xdriinfo" {
    name = "xdriinfo-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/xdriinfo-1.0.5.tar.bz2;
      sha256 = "0681d0y8liqakkpz7mmsf689jcxrvs5291r20qi78mc9xxk3gfjc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ glproto libX11 ];

  }) // {inherit glproto libX11 ;};

  xedit = (mkDerivation "xedit" {
    name = "xedit-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xedit-1.2.2.tar.bz2;
      sha256 = "09r9zi2w6k7fm09l3dv5dmp20jby333irc1fl8n361pwbn445ak9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu libXt ];

  }) // {inherit libX11 libXaw libXmu libXt ;};

  xev = (mkDerivation "xev" {
    name = "xev-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xev-1.2.2.tar.bz2;
      sha256 = "0krivhrxpq6719103r541xpi3i3a0y15f7ypc4lnrx8sdhmfcjnr";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto libXrandr ];

  }) // {inherit libX11 xproto libXrandr ;};

  xextproto = (mkDerivation "xextproto" {
    name = "xextproto-7.3.0";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xextproto-7.3.0.tar.bz2;
      sha256 = "1c2vma9gqgc2v06rfxdiqgwhxmzk2cbmknwf1ng3m76vr0xb5x7k";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xeyes = (mkDerivation "xeyes" {
    name = "xeyes-1.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xeyes-1.1.1.tar.bz2;
      sha256 = "08d5x2kar5kg4yammw6hhk10iva6jmh8cqq176a1z7nm1il9hplp";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext libXmu libXrender libXt ];

  }) // {inherit libX11 libXext libXmu libXrender libXt ;};

  xf86bigfontproto = (mkDerivation "xf86bigfontproto" {
    name = "xf86bigfontproto-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xf86bigfontproto-1.2.0.tar.bz2;
      sha256 = "0j0n7sj5xfjpmmgx6n5x556rw21hdd18fwmavp95wps7qki214ms";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xf86dga = (mkDerivation "xf86dga" {
    name = "xf86dga-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xf86dga-1.0.3.tar.bz2;
      sha256 = "0lm2wrsgzc1g97phm428bkn42zm0np77prdp6dpxnplx0h8p9n5l";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXxf86dga ];

  }) // {inherit libX11 libXxf86dga ;};

  xf86dgaproto = (mkDerivation "xf86dgaproto" {
    name = "xf86dgaproto-2.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xf86dgaproto-2.1.tar.bz2;
      sha256 = "0l4hx48207mx0hp09026r6gy9nl3asbq0c75hri19wp1118zcpmc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xf86driproto = (mkDerivation "xf86driproto" {
    name = "xf86driproto-2.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xf86driproto-2.1.1.tar.bz2;
      sha256 = "07v69m0g2dfzb653jni4x656jlr7l84c1k39j8qc8vfb45r8sjww";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xf86inputacecad = (mkDerivation "xf86inputacecad" {
    name = "xf86-input-acecad-1.5.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-acecad-1.5.0.tar.bz2;
      sha256 = "0j54038ivzprrqbvpvzfcgp8b9h9c7hk526fk4i7fm3vl0w2y0y3";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto kbproto randrproto xorgserver xproto ];

  }) // {inherit inputproto kbproto randrproto xorgserver xproto ;};

  xf86inputaiptek = (mkDerivation "xf86inputaiptek" {
    name = "xf86-input-aiptek-1.4.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-aiptek-1.4.1.tar.bz2;
      sha256 = "0pzn7j5h7qxplbrklrib194kn19d4na415sl3khpawjk9b6j68ms";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto xorgserver xproto ];

  }) // {inherit inputproto xorgserver xproto ;};

  xf86inputcalcomp = (mkDerivation "xf86inputcalcomp" {
    name = "xf86-input-calcomp-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-calcomp-1.1.2.tar.bz2;
      sha256 = "0jr5fg4fhmyz8w7cjgj2wihi6gmvmrlrxawbdjhm42f9g2fxnvmz";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputcitron = (mkDerivation "xf86inputcitron" {
    name = "xf86-input-citron-2.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-citron-2.2.2.tar.bz2;
      sha256 = "1bzcw5jwifinqifb1zxrqhghlny4cg8lfvwlvi7yj75yy78hh6bd";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputdigitaledge = (mkDerivation "xf86inputdigitaledge" {
    name = "xf86-input-digitaledge-1.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-digitaledge-1.1.1.tar.bz2;
      sha256 = "0x8748splfmlyfxxd51cb7h405dk09wp1mhaxsqmgfqx5gw11l6y";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputdmc = (mkDerivation "xf86inputdmc" {
    name = "xf86-input-dmc-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-dmc-1.1.2.tar.bz2;
      sha256 = "0qgknf4jgap1nav6r7zmvp4hkr6xghyra62jmjjpvamig8vfpx5n";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputdynapro = (mkDerivation "xf86inputdynapro" {
    name = "xf86-input-dynapro-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-dynapro-1.1.2.tar.bz2;
      sha256 = "1v6ylk74779v9jb6hh4hrz1hl06iyrm5c7f80pn944ika3lv5dsm";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputelo2300 = (mkDerivation "xf86inputelo2300" {
    name = "xf86-input-elo2300-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-elo2300-1.1.2.tar.bz2;
      sha256 = "09wn7jxl2iy7ngz3lc5w19jcdkal3n8p4dg6lhll2gx9lmwmymyf";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputelographics = (mkDerivation "xf86inputelographics" {
    name = "xf86-input-elographics-1.4.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-elographics-1.4.1.tar.bz2;
      sha256 = "1966n9mls7xn1ja12ab0dmr8ssy4ma5acq4xzxnqw5bzsm2gf6m2";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputevdev = (mkDerivation "xf86inputevdev" {
    name = "xf86-input-evdev-2.10.3";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-evdev-2.10.3.tar.bz2;
      sha256 = "18ijnclnylrr7vkvflalkw4bqfily3scg6baczjjgycdpsj1p8js";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto libevdev systemd_lib mtdev xorgserver xproto ];

  }) // {inherit inputproto libevdev systemd_lib mtdev xorgserver xproto ;};

  xf86inputfpit = (mkDerivation "xf86inputfpit" {
    name = "xf86-input-fpit-1.4.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-fpit-1.4.0.tar.bz2;
      sha256 = "16lgwrqj4k7118csadd8kv02375v1cpgjbhb75lf0rxkx7b0ma1q";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputhyperpen = (mkDerivation "xf86inputhyperpen" {
    name = "xf86-input-hyperpen-1.4.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-hyperpen-1.4.1.tar.bz2;
      sha256 = "05k88f4gy428n0k1fzilaa0m59wi261i364h22zg9bd26bq1da1i";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputjamstudio = (mkDerivation "xf86inputjamstudio" {
    name = "xf86-input-jamstudio-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-jamstudio-1.2.0.tar.bz2;
      sha256 = "1h2a2qfkdjfkqknq19m8656skmgrr25f0m2scrgv8j8qdzlsvfy5";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputjoystick = (mkDerivation "xf86inputjoystick" {
    name = "xf86-input-joystick-1.6.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-joystick-1.6.2.tar.bz2;
      sha256 = "038mfqairyyqvz02rk7v3i070sab1wr0k6fkxvyvxdgkfbnqcfzf";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto kbproto xorgserver xproto ];

  }) // {inherit inputproto kbproto xorgserver xproto ;};

  xf86inputkeyboard = (mkDerivation "xf86inputkeyboard" {
    name = "xf86-input-keyboard-1.8.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-keyboard-1.8.1.tar.bz2;
      sha256 = "04d27kwqq03fc26an6051hs3i0bff8albhnngzyd59wxpwwzzj0s";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto xorgserver xproto ];

  }) // {inherit inputproto xorgserver xproto ;};

  xf86inputlibinput = (mkDerivation "xf86inputlibinput" {
    name = "xf86-input-libinput-0.19.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-libinput-0.19.0.tar.bz2;
      sha256 = "0xzl3aiah9vma3pvi170g1847vxqrg4is3ilc51f72lbgkf30pbc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto libinput xorgserver xproto ];

  }) // {inherit inputproto libinput xorgserver xproto ;};

  xf86inputmagellan = (mkDerivation "xf86inputmagellan" {
    name = "xf86-input-magellan-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-magellan-1.2.0.tar.bz2;
      sha256 = "1r0hll4xksk7fwpfv8pjsv9q5j9vjpjw1dywsl7mn2yzli3m2a65";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputmagictouch = (mkDerivation "xf86inputmagictouch" {
    name = "xf86-input-magictouch-1.0.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-magictouch-1.0.0.5.tar.bz2;
      sha256 = "0k24sy0wcv49xcm4jwfxq3c5xzla8zqviqzvfgs8js6qx4qwivcw";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputmicrotouch = (mkDerivation "xf86inputmicrotouch" {
    name = "xf86-input-microtouch-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-microtouch-1.2.0.tar.bz2;
      sha256 = "0fsghvz6xbr12844hn44iqiz63fh2ka9vmalm5p68kwcfq54w0xk";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputmouse = (mkDerivation "xf86inputmouse" {
    name = "xf86-input-mouse-1.9.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-mouse-1.9.1.tar.bz2;
      sha256 = "1kn5kx3qyn9qqvd6s24a2l1wfgck2pgfvzl90xpl024wfxsx719l";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto xorgserver xproto ];

  }) // {inherit inputproto xorgserver xproto ;};

  xf86inputmutouch = (mkDerivation "xf86inputmutouch" {
    name = "xf86-input-mutouch-1.3.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-mutouch-1.3.0.tar.bz2;
      sha256 = "0g5490j06pi8nngkg15dqrlrkdb1y6hwg5z8a0ska47hf7n0g2g2";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputpalmax = (mkDerivation "xf86inputpalmax" {
    name = "xf86-input-palmax-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-palmax-1.2.0.tar.bz2;
      sha256 = "0nxh574r85hjq73r1zm66rzj951f68xcjfrdjk6bc3x6kcrpq5q2";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputpenmount = (mkDerivation "xf86inputpenmount" {
    name = "xf86-input-penmount-1.5.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-penmount-1.5.0.tar.bz2;
      sha256 = "1rrw24hvrv7k3f45djl6pfln4pqxsd4mzhc49yi7nr2r3a8qanpl";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputspaceorb = (mkDerivation "xf86inputspaceorb" {
    name = "xf86-input-spaceorb-1.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-spaceorb-1.1.1.tar.bz2;
      sha256 = "1ks94h6xrla34fk65cd1kw72i7hs2yvw021ayja91lrjf4p0b3xy";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputsumma = (mkDerivation "xf86inputsumma" {
    name = "xf86-input-summa-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-summa-1.2.0.tar.bz2;
      sha256 = "1n4c9xpslr16lfz2qjgylz6a7cmc857mi91qydvndy5knj4wv2ry";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputsynaptics = (mkDerivation "xf86inputsynaptics" {
    name = "xf86-input-synaptics-1.8.99.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-synaptics-1.8.99.1.tar.bz2;
      sha256 = "1apbcwn20p7sy07ghlldmqcnxag2r9sdjqmb4xxzki0hz8wm72ac";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto libevdev randrproto recordproto libX11 libXi xorgserver xproto libXtst ];

  }) // {inherit inputproto libevdev randrproto recordproto libX11 libXi xorgserver xproto libXtst ;};

  xf86inputtek4957 = (mkDerivation "xf86inputtek4957" {
    name = "xf86-input-tek4957-1.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-tek4957-1.2.0.tar.bz2;
      sha256 = "18jq6c7k6dldaz0pgyplcls8l70z7801736jlnf2swxxmjqsb5xh";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputur98 = (mkDerivation "xf86inputur98" {
    name = "xf86-input-ur98-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-ur98-1.1.0.tar.bz2;
      sha256 = "0aj7qvpbfk3hfwlx9qqp0rkfdlpf75jxc0yf93a35aajznqcwjr1";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto randrproto xorgserver xproto ];

  }) // {inherit inputproto randrproto xorgserver xproto ;};

  xf86inputvmmouse = (mkDerivation "xf86inputvmmouse" {
    name = "xf86-input-vmmouse-13.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-vmmouse-13.1.0.tar.bz2;
      sha256 = "06ckn4hlkpig5vnivl0zj8a7ykcgvrsj8b3iccl1pgn1gaamix8a";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto systemd_lib randrproto xorgserver xproto ];

  }) // {inherit inputproto systemd_lib randrproto xorgserver xproto ;};

  xf86inputvoid = (mkDerivation "xf86inputvoid" {
    name = "xf86-input-void-1.4.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-input-void-1.4.1.tar.bz2;
      sha256 = "171k8b8s42s3w73l7ln9jqwk88w4l7r1km2blx1vy898c854yvpr";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xorgserver xproto ];

  }) // {inherit xorgserver xproto ;};

  xf86miscproto = (mkDerivation "xf86miscproto" {
    name = "xf86miscproto-0.9.3";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xf86miscproto-0.9.3.tar.bz2;
      sha256 = "15dhcdpv61fyj6rhzrhnwri9hlw8rjfy05z1vik118lc99mfrf25";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xf86rushproto = (mkDerivation "xf86rushproto" {
    name = "xf86rushproto-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xf86rushproto-1.1.2.tar.bz2;
      sha256 = "1bm3d7ck33y4gkvk7cc7djrnd9w7v4sm73xjnl9n6b8zahvv5n87";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ ];

  }) // {inherit ;};

  xf86videoamd = (mkDerivation "xf86videoamd" {
    name = "xf86-video-amd-2.7.7.7";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-amd-2.7.7.7.tar.bz2;
      sha256 = "1pp9d3vpyj7iz5iz2wzvb2awmpiw1xdf2lff64nkkilbi01pqqrz";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videoamdgpu = (mkDerivation "xf86videoamdgpu" {
    name = "xf86-video-amdgpu-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-amdgpu-1.1.0.tar.bz2;
      sha256 = "0cbrqpmi1hgbsi0i93v0yp7lv3wf4s0vbdlrj19cxmglv7gd1xb9";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto mesa_noglu glamoregl libdrm systemd_lib randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto mesa_noglu glamoregl libdrm systemd_lib randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videoapm = (mkDerivation "xf86videoapm" {
    name = "xf86-video-apm-1.2.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-apm-1.2.5.tar.bz2;
      sha256 = "03rxipf7fbbygfl2m733kx094mglrr2xwdzvgrdlrc8p04r08fwm";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videoark = (mkDerivation "xf86videoark" {
    name = "xf86-video-ark-0.7.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-ark-0.7.5.tar.bz2;
      sha256 = "07p5vdsj2ckxb6wh02s61akcv4qfg6s1d5ld3jn3lfaayd3f1466";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess xextproto xorgserver xproto ;};

  xf86videoast = (mkDerivation "xf86videoast" {
    name = "xf86-video-ast-1.1.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-ast-1.1.5.tar.bz2;
      sha256 = "1pm2cy81ma7ldsw0yfk28b33h9z2hcj5rccrxhfxfgvxsiavrnqy";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videoati = (mkDerivation "xf86videoati" {
    name = "xf86-video-ati-7.7.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-ati-7.7.0.tar.bz2;
      sha256 = "1hy1n8an98mflfbdcb3q7wv59x971j7nf9zhivf90p0lgdbiqkc4";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto glamoregl libdrm systemd_lib libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto glamoregl libdrm systemd_lib libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videochips = (mkDerivation "xf86videochips" {
    name = "xf86-video-chips-1.2.6";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-chips-1.2.6.tar.bz2;
      sha256 = "073bcdsvvsg19mb963sa5v7x2zs19y0q6javmgpiwfaqkz7zbblr";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videocirrus = (mkDerivation "xf86videocirrus" {
    name = "xf86-video-cirrus-1.5.3";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-cirrus-1.5.3.tar.bz2;
      sha256 = "1asifc6ld2g9kap15vfhvsvyl69lj7pw3d9ra9mi4najllh7pj7d";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videocyrix = (mkDerivation "xf86videocyrix" {
    name = "xf86-video-cyrix-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-cyrix-1.1.0.tar.bz2;
      sha256 = "1bd65iyacnw76nm9znxmfgvjddbbpn346y55rc3xkpgnw1w6g9nn";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto randrproto renderproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videodummy = (mkDerivation "xf86videodummy" {
    name = "xf86-video-dummy-0.3.7";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-dummy-0.3.7.tar.bz2;
      sha256 = "1046p64xap69vlsmsz5rjv0djc970yhvq44fmllmas0mqp5lzy2n";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto videoproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto videoproto xf86dgaproto xorgserver xproto ;};

  xf86videofbdev = (mkDerivation "xf86videofbdev" {
    name = "xf86-video-fbdev-0.4.4";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-fbdev-0.4.4.tar.bz2;
      sha256 = "06ym7yy017lanj730hfkpfk4znx3dsj8jq3qvyzsn8w294kb7m4x";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xorgserver xproto ;};

  xf86videofreedreno = (mkDerivation "xf86videofreedreno" {
    name = "xf86-video-freedreno-1.4.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-freedreno-1.4.0.tar.bz2;
      sha256 = "1hf67nwy223ghzc3ag9l99rjxrwv1fq6f1j42fmlpfmp145xvazm";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libdrm systemd_lib randrproto renderproto xextproto xorgserver xproto ];

  }) // {inherit libdrm systemd_lib randrproto renderproto xextproto xorgserver xproto ;};

  xf86videogeode = (mkDerivation "xf86videogeode" {
    name = "xf86-video-geode-2.11.18";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-geode-2.11.18.tar.bz2;
      sha256 = "1s59kdj573v38sb14xfhp1l926aypbhy11vaz36y72x6calfkv6n";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videoglide = (mkDerivation "xf86videoglide" {
    name = "xf86-video-glide-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-glide-1.2.2.tar.bz2;
      sha256 = "1vaav6kx4n00q4fawgqnjmbdkppl0dir2dkrj4ad372mxrvl9c4y";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xextproto xorgserver xproto ];

  }) // {inherit xextproto xorgserver xproto ;};

  xf86videoglint = (mkDerivation "xf86videoglint" {
    name = "xf86-video-glint-1.2.8";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-glint-1.2.8.tar.bz2;
      sha256 = "08a2aark2yn9irws9c78d9q44dichr03i9zbk61jgr54ncxqhzv5";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libpciaccess videoproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit libpciaccess videoproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videoi128 = (mkDerivation "xf86videoi128" {
    name = "xf86-video-i128-1.3.6";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-i128-1.3.6.tar.bz2;
      sha256 = "171b8lbxr56w3isph947dnw7x87hc46v6m3mcxdcz44gk167x0pq";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videoi740 = (mkDerivation "xf86videoi740" {
    name = "xf86-video-i740-1.3.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-i740-1.3.5.tar.bz2;
      sha256 = "0973zzmdsvlmplcax1c91is7v78lcwy6d9mwp11npgqzl782vq0w";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videoi810 = (mkDerivation "xf86videoi810" {
    name = "xf86-video-i810-1.7.4";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-i810-1.7.4.tar.bz2;
      sha256 = "0na2qy78waa9jy0ikd10g805v0w048icnkdcss6yd753kffdi37z";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto libdrm randrproto renderproto libX11 xextproto xf86driproto xineramaproto xorgserver xproto libXvMC ];

  }) // {inherit fontsproto libdrm randrproto renderproto libX11 xextproto xf86driproto xineramaproto xorgserver xproto libXvMC ;};

  xf86videoimpact = (mkDerivation "xf86videoimpact" {
    name = "xf86-video-impact-0.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-impact-0.2.0.tar.bz2;
      sha256 = "08h007qrz4k7pi6gcwfa5h35yfc6c18c6dwfxc32bx0vnhis2a0m";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ xorgserver xproto ];

  }) // {inherit xorgserver xproto ;};

  xf86videoimstt = (mkDerivation "xf86videoimstt" {
    name = "xf86-video-imstt-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-imstt-1.1.0.tar.bz2;
      sha256 = "0zgv20zj4gr4sv93ffl3zzsy446041zrs13wndxdsdwlgwjw4f4j";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto randrproto renderproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xorgserver xproto ;};

  xf86videointel = (mkDerivation "xf86videointel" {
    name = "xf86-video-intel-2.99.917";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-intel-2.99.917.tar.bz2;
      sha256 = "1jb7jspmzidfixbc0gghyjmnmpqv85i7pi13l4h2hn2ml3p83dq0";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ cairo dri2proto dri3proto fontsproto intelgputools libdrm libpng systemd_lib libpciaccess pixman presentproto randrproto renderproto libX11 xcbutil libxcb libXcursor libXdamage libXext xextproto xf86driproto libXfixes xorgserver xproto libXrandr libXrender libxshmfence libXtst libXvMC ];

  }) // {inherit cairo dri2proto dri3proto fontsproto intelgputools libdrm libpng systemd_lib libpciaccess pixman presentproto randrproto renderproto libX11 xcbutil libxcb libXcursor libXdamage libXext xextproto xf86driproto libXfixes xorgserver xproto libXrandr libXrender libxshmfence libXtst libXvMC ;};

  xf86videomach64 = (mkDerivation "xf86videomach64" {
    name = "xf86-video-mach64-6.9.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-mach64-6.9.5.tar.bz2;
      sha256 = "07xlf5nsjm0x18ij5gyy4lf8hwpl10i8chi3skpqjh84drdri61y";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videomga = (mkDerivation "xf86videomga" {
    name = "xf86-video-mga-1.9.100";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-mga-1.9.100.tar.bz2;
      sha256 = "0p3ssy55jyyz9j3j82jb1lr3qkbagbab77a9ppwjksv9aa6yxvz8";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videomodesetting = (mkDerivation "xf86videomodesetting" {
    name = "xf86-video-modesetting-0.9.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-modesetting-0.9.0.tar.bz2;
      sha256 = "0p6pjn5bnd2wr3lmas4b12zcq12d9ilvssga93fzlg90fdahikwh";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm systemd_lib libpciaccess randrproto libX11 xextproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm systemd_lib libpciaccess randrproto libX11 xextproto xorgserver xproto ;};

  xf86videoneomagic = (mkDerivation "xf86videoneomagic" {
    name = "xf86-video-neomagic-1.2.9";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-neomagic-1.2.9.tar.bz2;
      sha256 = "1whb2kgyqaxdjim27ya404acz50izgmafwnb6y9m89q5n6b97y3j";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess xorgserver xproto ;};

  xf86videonewport = (mkDerivation "xf86videonewport" {
    name = "xf86-video-newport-0.2.4";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-newport-0.2.4.tar.bz2;
      sha256 = "1yafmp23jrfdmc094i6a4dsizapsc9v0pl65cpc8w1kvn7343k4i";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto videoproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto videoproto xorgserver xproto ;};

  xf86videonouveau = (mkDerivation "xf86videonouveau" {
    name = "xf86-video-nouveau-1.0.12";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-nouveau-1.0.12.tar.bz2;
      sha256 = "07irv1zkk0rkyn1d7f2gn1icgcz2ix0pwv74sjian763gynmg80f";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ dri2proto fontsproto libdrm systemd_lib libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit dri2proto fontsproto libdrm systemd_lib libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videonsc = (mkDerivation "xf86videonsc" {
    name = "xf86-video-nsc-2.8.3";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-nsc-2.8.3.tar.bz2;
      sha256 = "0f8qicx3b5ibi2y62lmc3r7y093366b61h1rxrdrgf3p301a5ig5";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videonv = (mkDerivation "xf86videonv" {
    name = "xf86-video-nv-2.1.20";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-nv-2.1.20.tar.bz2;
      sha256 = "1gqh1khc4zalip5hh2nksgs7i3piqq18nncgmsx9qvzi05azd5c3";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videoomap = (mkDerivation "xf86videoomap" {
    name = "xf86-video-omap-0.4.4";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-omap-0.4.4.tar.bz2;
      sha256 = "1g3ykvbzihzml8vhy1ylxli1w20krh3sw6qsc66mr3v3p282c6d7";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videoopenchrome = (mkDerivation "xf86videoopenchrome" {
    name = "xf86-video-openchrome-0.5.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-openchrome-0.5.0.tar.bz2;
      sha256 = "1fsmr455lk89zl795d6b5ypyqjim40j3h2vjch52lcssjw9xdza9";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto glproto libdrm systemd_lib libpciaccess randrproto renderproto videoproto libX11 libXext xextproto xf86driproto xorgserver xproto libXvMC ];

  }) // {inherit fontsproto glproto libdrm systemd_lib libpciaccess randrproto renderproto videoproto libX11 libXext xextproto xf86driproto xorgserver xproto libXvMC ;};

  xf86videoqxl = (mkDerivation "xf86videoqxl" {
    name = "xf86-video-qxl-0.1.4";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-qxl-0.1.4.tar.bz2;
      sha256 = "018ic9ddxfnjcv2yss0mwk1gq6rmip1hrgi2wxwqkbqx1cpx4yp5";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libcacard libdrm pcsclite_lib systemd_lib libpciaccess randrproto renderproto spice-protocol spice videoproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto libcacard libdrm pcsclite_lib systemd_lib libpciaccess randrproto renderproto spice-protocol spice videoproto xf86dgaproto xorgserver xproto ;};

  xf86videor128 = (mkDerivation "xf86videor128" {
    name = "xf86-video-r128-6.10.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-r128-6.10.1.tar.bz2;
      sha256 = "1sp4glyyj23rs77vgffmn0mar5h504a86701nzvi56qwhd4yzgsy";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xf86miscproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xf86miscproto xorgserver xproto ;};

  xf86videoradeonhd = (mkDerivation "xf86videoradeonhd" {
    name = "xf86-video-radeonhd-1.3.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-radeonhd-1.3.0.tar.bz2;
      sha256 = "1mcad5g6wbh993z90l00npxmfh91v5bi98126lp3z5qfwrsxdnjs";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto glproto libdrm pciutils libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto glproto libdrm pciutils libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videorendition = (mkDerivation "xf86videorendition" {
    name = "xf86-video-rendition-4.2.6";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-rendition-4.2.6.tar.bz2;
      sha256 = "1a7rqafxzc2hd0s5pnq8s8j9d3jg64ndc0xnq4160kasyqhwy3k6";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto xextproto xorgserver xproto ;};

  xf86videos3 = (mkDerivation "xf86videos3" {
    name = "xf86-video-s3-0.6.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-s3-0.6.5.tar.bz2;
      sha256 = "0fddldz2s8c90q6zw8ng7bx6bw3n8mk07gprc8shqjb13m7wsy27";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videos3virge = (mkDerivation "xf86videos3virge" {
    name = "xf86-video-s3virge-1.10.7";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-s3virge-1.10.7.tar.bz2;
      sha256 = "1nm4cngjbw226q63rdacw6nx5lgxv7l7rsa8vhpr0gs80pg6igjx";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videosavage = (mkDerivation "xf86videosavage" {
    name = "xf86-video-savage-2.3.8";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-savage-2.3.8.tar.bz2;
      sha256 = "0qzshncynjdmyhavhqw4x5ha3gwbygi0zbsy158fpg1jcnla9kpx";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videosiliconmotion = (mkDerivation "xf86videosiliconmotion" {
    name = "xf86-video-siliconmotion-1.7.8";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-siliconmotion-1.7.8.tar.bz2;
      sha256 = "1sqv0y31mi4zmh9yaxqpzg7p8y2z01j6qys433hb8n4yznllkm79";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess videoproto xextproto xorgserver xproto ;};

  xf86videosis = (mkDerivation "xf86videosis" {
    name = "xf86-video-sis-0.10.8";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-sis-0.10.8.tar.bz2;
      sha256 = "1znkqwdyd6am23xbsfjzamq125j5rrylg5mzqky4scv9gxbz5wy8";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xf86driproto xineramaproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xf86driproto xineramaproto xorgserver xproto ;};

  xf86videosisusb = (mkDerivation "xf86videosisusb" {
    name = "xf86-video-sisusb-0.9.6";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-sisusb-0.9.6.tar.bz2;
      sha256 = "0ip0p62j3sjs156jlvna68y68b06vhnsrsr7bi2f2k3aqm1yznvk";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xineramaproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xineramaproto xorgserver xproto ;};

  xf86videosunbw2 = (mkDerivation "xf86videosunbw2" {
    name = "xf86-video-sunbw2-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-sunbw2-1.1.0.tar.bz2;
      sha256 = "0dl16ccbzzy0dchxzv4g7qjc59a2875c4lb68yn733xd87lp846p";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ randrproto xorgserver xproto ];

  }) // {inherit randrproto xorgserver xproto ;};

  xf86videosuncg14 = (mkDerivation "xf86videosuncg14" {
    name = "xf86-video-suncg14-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-suncg14-1.1.2.tar.bz2;
      sha256 = "0j29jaiznl9fpg2bah26gni14xd1xl91y4dsxqlvfn14jlixkbhw";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xorgserver xproto ;};

  xf86videosuncg3 = (mkDerivation "xf86videosuncg3" {
    name = "xf86-video-suncg3-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-suncg3-1.1.2.tar.bz2;
      sha256 = "15mg48jzsh9vbmd6i1cl44widzg714kffgrm5ighwdl0qj87zff7";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xorgserver xproto ;};

  xf86videosuncg6 = (mkDerivation "xf86videosuncg6" {
    name = "xf86-video-suncg6-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-suncg6-1.1.2.tar.bz2;
      sha256 = "04fgwgk02m4nimlv67rrg1wnyahgymrn6rb2cjj1l8bmzkii4glr";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xorgserver xproto ;};

  xf86videosunffb = (mkDerivation "xf86videosunffb" {
    name = "xf86-video-sunffb-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-sunffb-1.2.2.tar.bz2;
      sha256 = "07z3ngifwg2d4jgq8pms47n5lr2yn0ai72g86xxjnb3k20n5ym7s";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xextproto xorgserver xproto ;};

  xf86videosunleo = (mkDerivation "xf86videosunleo" {
    name = "xf86-video-sunleo-1.2.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-sunleo-1.2.1.tar.bz2;
      sha256 = "07a93wqqdlkrb010zfhx5zrdsqd480a7pbv1imr7dgyv9vhq9khs";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xorgserver xproto ;};

  xf86videosuntcx = (mkDerivation "xf86videosuntcx" {
    name = "xf86-video-suntcx-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-suntcx-1.1.2.tar.bz2;
      sha256 = "0xrp3ng4hgv6d9n37bagdnkk90jzb91awyy6qja4j2ffjw5p88ml";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto randrproto renderproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xorgserver xproto ;};

  xf86videotdfx = (mkDerivation "xf86videotdfx" {
    name = "xf86-video-tdfx-1.4.6";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-tdfx-1.4.6.tar.bz2;
      sha256 = "0dvdrhyn1iv6rr85v1c52s1gl0j1qrxgv7x0r7qn3ba0gj38i2is";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86videotga = (mkDerivation "xf86videotga" {
    name = "xf86-video-tga-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-tga-1.2.2.tar.bz2;
      sha256 = "0cb161lvdgi6qnf1sfz722qn38q7kgakcvj7b45ba3i0020828r0";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videotrident = (mkDerivation "xf86videotrident" {
    name = "xf86-video-trident-1.3.7";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-trident-1.3.7.tar.bz2;
      sha256 = "1bhkwic2acq9za4yz4bwj338cwv5mdrgr2qmgkhlj3bscbg1imgc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videotseng = (mkDerivation "xf86videotseng" {
    name = "xf86-video-tseng-1.2.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-tseng-1.2.5.tar.bz2;
      sha256 = "06bq81a0imns2z85y68z3x7dplfj31gagksyg7y5lzk2bwhcavf0";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto videoproto xextproto xorgserver xproto ;};

  xf86videov4l = (mkDerivation "xf86videov4l" {
    name = "xf86-video-v4l-0.2.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-v4l-0.2.0.tar.bz2;
      sha256 = "0pcjc75hgbih3qvhpsx8d4fljysfk025slxcqyyhr45dzch93zyb";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ randrproto videoproto xorgserver xproto ];

  }) // {inherit randrproto videoproto xorgserver xproto ;};

  xf86videovermilion = (mkDerivation "xf86videovermilion" {
    name = "xf86-video-vermilion-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-vermilion-1.0.1.tar.bz2;
      sha256 = "12qdk0p2r0pbmsl8fkgwhfh7szvb20yjaay88jlvb89rsbc4rssg";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto renderproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto renderproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videovesa = (mkDerivation "xf86videovesa" {
    name = "xf86-video-vesa-2.3.4";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-vesa-2.3.4.tar.bz2;
      sha256 = "1haiw8r1z8ihk68d0jqph2wsld13w4qkl86biq46fvyxg7cg9pbv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto xextproto xorgserver xproto ;};

  xf86videovga = (mkDerivation "xf86videovga" {
    name = "xf86-video-vga-4.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-vga-4.1.0.tar.bz2;
      sha256 = "0havz5hv46qz3g6g0mq2568758apdapzy0yd5ny8qs06yz0g89fa";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto randrproto renderproto xextproto xorgserver xproto ];

  }) // {inherit fontsproto randrproto renderproto xextproto xorgserver xproto ;};

  xf86videovia = (mkDerivation "xf86videovia" {
    name = "xf86-video-via-0.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-via-0.2.2.tar.bz2;
      sha256 = "0qn89m1s50m4jajw95wcidarknyxn19h8696dbkgwy21cjpvs9jh";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ fontsproto libdrm randrproto renderproto libX11 xextproto xf86driproto xorgserver xproto libXvMC ];

  }) // {inherit fontsproto libdrm randrproto renderproto libX11 xextproto xf86driproto xorgserver xproto libXvMC ;};

  xf86videovmware = (mkDerivation "xf86videovmware" {
    name = "xf86-video-vmware-13.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-vmware-13.1.0.tar.bz2;
      sha256 = "1k50whwnkzxam2ihc1sw456dx0pvr76naycm4qhyjxqv9d72879w";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto libX11 libXext xextproto xineramaproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto libX11 libXext xextproto xineramaproto xorgserver xproto ;};

  xf86videovoodoo = (mkDerivation "xf86videovoodoo" {
    name = "xf86-video-voodoo-1.2.5";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-voodoo-1.2.5.tar.bz2;
      sha256 = "1s6p7yxmi12q4y05va53rljwyzd6ry492r1pgi7wwq6cznivhgly";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libpciaccess randrproto renderproto xextproto xf86dgaproto xorgserver xproto ];

  }) // {inherit fontsproto libpciaccess randrproto renderproto xextproto xf86dgaproto xorgserver xproto ;};

  xf86videowsfb = (mkDerivation "xf86videowsfb" {
    name = "xf86-video-wsfb-0.4.0";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-wsfb-0.4.0.tar.bz2;
      sha256 = "0hr8397wpd0by1hc47fqqrnaw3qdqd8aqgwgzv38w5k3l3jy6p4p";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xorgserver xproto ];

  }) // {inherit xorgserver xproto ;};

  xf86videoxgi = (mkDerivation "xf86videoxgi" {
    name = "xf86-video-xgi-1.6.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-xgi-1.6.1.tar.bz2;
      sha256 = "10xd2vah0pnpw5spn40n4p95mpmgvdkly4i1cz51imnlfsw7g8si";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto glproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xineramaproto xorgserver xproto ];

  }) // {inherit fontsproto glproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xineramaproto xorgserver xproto ;};

  xf86videoxgixp = (mkDerivation "xf86videoxgixp" {
    name = "xf86-video-xgixp-1.8.1";
    src = fetchurl {
      url = mirror://xorg/individual/driver/xf86-video-xgixp-1.8.1.tar.bz2;
      sha256 = "0m8xqjh9qa84jbw8lz7hvpjxhsj0xxipidrl4g4vmj2nayycpip1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ];

  }) // {inherit fontsproto libdrm libpciaccess randrproto renderproto videoproto xextproto xf86driproto xorgserver xproto ;};

  xf86vidmodeproto = (mkDerivation "xf86vidmodeproto" {
    name = "xf86vidmodeproto-2.3.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xf86vidmodeproto-2.3.1.tar.bz2;
      sha256 = "0w47d7gfa8zizh2bshdr2rffvbr4jqjv019mdgyh6cmplyd4kna5";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xfd = (mkDerivation "xfd" {
    name = "xfd-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xfd-1.1.2.tar.bz2;
      sha256 = "0n97iqqap9wyxjan2n520vh4rrf5bc0apsw2k9py94dqzci258y1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ fontconfig libXaw libXft libXmu xproto libXrender libXt ];

  }) // {inherit fontconfig libXaw libXft libXmu xproto libXrender libXt ;};

  xfindproxy = (mkDerivation "xfindproxy" {
    name = "xfindproxy-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xfindproxy-1.0.4.tar.bz2;
      sha256 = "07x0z360866szmgbhhnmjs5g1zrq4mazh5ws52z5rakzgjibs9jn";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE xproto xproxymanagementprotocol libXt ];

  }) // {inherit libICE xproto xproxymanagementprotocol libXt ;};

  xfontsel = (mkDerivation "xfontsel" {
    name = "xfontsel-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/xfontsel-1.0.5.tar.bz2;
      sha256 = "1grir464hy52a71r3mpm9mzvkf7nwr3vk0b1vc27pd3gp588a38p";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu libXt ];

  }) // {inherit libX11 libXaw libXmu libXt ;};

  xfs = (mkDerivation "xfs" {
    name = "xfs-1.1.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xfs-1.1.4.tar.bz2;
      sha256 = "1ylz4r7adf567rnlbb52yi9x3qi4pyv954kkhm7ld4f0fkk7a2x4";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXfont xproto xtrans ];

  }) // {inherit libXfont xproto xtrans ;};

  xfsinfo = (mkDerivation "xfsinfo" {
    name = "xfsinfo-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/xfsinfo-1.0.5.tar.bz2;
      sha256 = "13qd29pj9gny2qyw3h2lhhl98ccrjzs3w4h93ax553q3ninlp3yk";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libFS xproto ];

  }) // {inherit libFS xproto ;};

  xfwp = (mkDerivation "xfwp" {
    name = "xfwp-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xfwp-1.0.3.tar.bz2;
      sha256 = "181qs4af6i3x78ayrdxkpb9lv9bxj07pac7ss7gg8c8jaifqv4zv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE xproto xproxymanagementprotocol ];

  }) // {inherit libICE xproto xproxymanagementprotocol ;};

  xgamma = (mkDerivation "xgamma" {
    name = "xgamma-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/xgamma-1.0.6.tar.bz2;
      sha256 = "1lr2nb1fhg5fk2fchqxdxyl739602ggwhmgl2wiv5c8qbidw7w8f";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto libXxf86vm ];

  }) // {inherit libX11 xproto libXxf86vm ;};

  xgc = (mkDerivation "xgc" {
    name = "xgc-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/xgc-1.0.5.tar.bz2;
      sha256 = "0pigvjd3i9fchmj1inqy151aafz3dr0vq1h2zizdb2imvadqv0hl";
    };
    nativeBuildInputs = [ bison flex utilmacros ];
    buildInputs = [ libXaw libXt ];

  }) // {inherit libXaw libXt ;};

  xhost = (mkDerivation "xhost" {
    name = "xhost-1.0.7";
    src = fetchurl {
      url = mirror://xorg/individual/app/xhost-1.0.7.tar.bz2;
      sha256 = "16n26xw6l01zq31d4qvsaz50misvizhn7iihzdn5f7s72pp1krlk";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXau libXmu xproto ];

  }) // {inherit libX11 libXau libXmu xproto ;};

  xineramaproto = (mkDerivation "xineramaproto" {
    name = "xineramaproto-1.2.1";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xineramaproto-1.2.1.tar.bz2;
      sha256 = "0ns8abd27x7gbp4r44z3wc5k9zqxxj8zjnazqpcyr4n17nxp8xcp";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xinit = (mkDerivation "xinit" {
    name = "xinit-1.3.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xinit-1.3.4.tar.bz2;
      sha256 = "1cq2g469mb2cfgr8k57960yrn90bl33vfqri4pdh2zm0jxrqvn3m";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  xinput = (mkDerivation "xinput" {
    name = "xinput-1.6.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xinput-1.6.2.tar.bz2;
      sha256 = "1i75mviz9dyqyf7qigzmxq8vn31i86aybm662fzjz5c086dx551n";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto libX11 libXext libXi libXinerama libXrandr ];

  }) // {inherit inputproto libX11 libXext libXi libXinerama libXrandr ;};

  xkbcomp = (mkDerivation "xkbcomp" {
    name = "xkbcomp-1.3.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xkbcomp-1.3.1.tar.bz2;
      sha256 = "0gcjy70ppmcl610z8gxc7sydsx93f8cm8pggm4qhihaa1ngdq103";
    };
    nativeBuildInputs = [ bison utilmacros ];
    buildInputs = [ libX11 libxkbfile xproto ];

  }) // {inherit libX11 libxkbfile xproto ;};

  xkbdata = (mkDerivation "xkbdata" {
    name = "xkbdata-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/data/xkbdata-1.0.1.tar.bz2;
      sha256 = "1pxl1i4gmw5pa8i1zsx2qhqhjv71ls7ylswawz059xwvmagr1qcl";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ ];

  }) // {inherit ;};

  xkbevd = (mkDerivation "xkbevd" {
    name = "xkbevd-1.1.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xkbevd-1.1.4.tar.bz2;
      sha256 = "0sprjx8i86ljk0l7ldzbz2xlk8916z5zh78cafjv8k1a63js4c14";
    };
    nativeBuildInputs = [ bison utilmacros ];
    buildInputs = [ libX11 libxkbfile ];

  }) // {inherit libX11 libxkbfile ;};

  xkbprint = (mkDerivation "xkbprint" {
    name = "xkbprint-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xkbprint-1.0.4.tar.bz2;
      sha256 = "04iyv5z8aqhabv7wcpvbvq0ji0jrz1666vw6gvxkvl7szswalgqb";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libxkbfile xproto ];

  }) // {inherit libX11 libxkbfile xproto ;};

  xkbutils = (mkDerivation "xkbutils" {
    name = "xkbutils-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xkbutils-1.0.4.tar.bz2;
      sha256 = "0c412isxl65wplhl7nsk12vxlri29lk48g3p52hbrs3m0awqm8fj";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ inputproto libX11 libXaw xproto libXt ];

  }) // {inherit inputproto libX11 libXaw xproto libXt ;};

  xkeyboardconfig = (mkDerivation "xkeyboardconfig" {
    name = "xkeyboard-config-2.18";
    src = fetchurl {
      url = mirror://xorg/individual/data/xkeyboard-config/xkeyboard-config-2.18.tar.bz2;
      sha256 = "1l6x2w357ja8vm94ns79s7yj9a5dlr01r9dxrjvzwncadiyr27f4";
    };
    nativeBuildInputs = [ intltool utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  xkill = (mkDerivation "xkill" {
    name = "xkill-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xkill-1.0.4.tar.bz2;
      sha256 = "0bl1ky8ps9jg842j4mnmf4zbx8nkvk0h77w7bqjlpwij9wq2mvw8";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXmu xproto ];

  }) // {inherit libX11 libXmu xproto ;};

  xload = (mkDerivation "xload" {
    name = "xload-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xload-1.1.2.tar.bz2;
      sha256 = "0y704z8mhl7zbr2fys9hngq7k2v84lrvndjh5qpdzw9m0hkfdy43";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu xproto libXt ];

  }) // {inherit libX11 libXaw libXmu xproto libXt ;};

  xlogo = (mkDerivation "xlogo" {
    name = "xlogo-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xlogo-1.0.4.tar.bz2;
      sha256 = "14msyqx6kr1dwdgax5586xphsaxb7dvmvzpvhzh10wrynx7nzbqp";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libSM libX11 libXaw libXext libXmu libXt ];

  }) // {inherit libSM libX11 libXaw libXext libXmu libXt ;};

  xlsatoms = (mkDerivation "xlsatoms" {
    name = "xlsatoms-1.1.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xlsatoms-1.1.2.tar.bz2;
      sha256 = "196yjik910xsr7dwy8daa0amr0r22ynfs360z0ndp9mx7mydrra7";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libxcb ];

  }) // {inherit libxcb ;};

  xlsclients = (mkDerivation "xlsclients" {
    name = "xlsclients-1.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xlsclients-1.1.3.tar.bz2;
      sha256 = "0g9x7rrggs741x9xwvv1k9qayma980d88nhdqw7j3pn3qvy6d5jx";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libxcb ];

  }) // {inherit libxcb ;};

  xlsfonts = (mkDerivation "xlsfonts" {
    name = "xlsfonts-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/xlsfonts-1.0.5.tar.bz2;
      sha256 = "1yi774g6r1kafsbnxbkrwyndd3i60362ck1fps9ywz076pn5naa0";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  xmag = (mkDerivation "xmag" {
    name = "xmag-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/xmag-1.0.6.tar.bz2;
      sha256 = "0qg12ifbbk9n8fh4jmyb625cknn8ssj86chd6zwdiqjin8ivr8l7";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu libXt ];

  }) // {inherit libX11 libXaw libXmu libXt ;};

  xman = (mkDerivation "xman" {
    name = "xman-1.1.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xman-1.1.4.tar.bz2;
      sha256 = "0afzhiygy1mdxyr22lhys5bn94qdw3qf8vhbxclwai9p7wp9vymk";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXaw xproto libXt ];

  }) // {inherit libXaw xproto libXt ;};

  xmessage = (mkDerivation "xmessage" {
    name = "xmessage-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xmessage-1.0.4.tar.bz2;
      sha256 = "0s5bjlpxnmh8sxx6nfg9m0nr32r1sr3irr71wsnv76s33i34ppxw";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXaw libXt ];

  }) // {inherit libXaw libXt ;};

  xmh = (mkDerivation "xmh" {
    name = "xmh-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xmh-1.0.3.tar.bz2;
      sha256 = "12anbwsb2rd1qx7ilkif7dzk8yq8xad66ayca9nk9djz5a8lybxr";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw xbitmaps libXmu libXt ];

  }) // {inherit libX11 libXaw xbitmaps libXmu libXt ;};

  xmodmap = (mkDerivation "xmodmap" {
    name = "xmodmap-1.0.9";
    src = fetchurl {
      url = mirror://xorg/individual/app/xmodmap-1.0.9.tar.bz2;
      sha256 = "0y649an3jqfq9klkp9y5gj20xb78fw6g193f5mnzpl0hbz6fbc5p";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  xmore = (mkDerivation "xmore" {
    name = "xmore-1.0.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xmore-1.0.2.tar.bz2;
      sha256 = "1qmrc6yr4snsllsbzlxlbpfkln7qd60arj5cfiq4kzd3j5wgj4ra";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libXaw libXt ];

  }) // {inherit libXaw libXt ;};

  xorgcffiles = (mkDerivation "xorgcffiles" {
    name = "xorg-cf-files-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/util/xorg-cf-files-1.0.6.tar.bz2;
      sha256 = "0kckng0zs1viz0nr84rdl6dswgip7ndn4pnh5nfwnviwpsfmmksd";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xorgdocs = (mkDerivation "xorgdocs" {
    name = "xorg-docs-1.7.1";
    src = fetchurl {
      url = mirror://xorg/individual/doc/xorg-docs-1.7.1.tar.bz2;
      sha256 = "0jrc4jmb4raqawx0j9jmhgasr0k6sxv0bm2hrxjh9hb26iy6gf14";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xorggtest = (mkDerivation "xorggtest" {
    name = "xorg-gtest-0.7.1";
    src = fetchurl {
      url = mirror://xorg/individual/test/xorg-gtest-0.7.1.tar.bz2;
      sha256 = "10i6nwvy88m8a7j54h5v12w21cbxfxp6ig8369w751399j8cgvbc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXi ];

  }) // {inherit libX11 libXi ;};

  xorgserver = (mkDerivation "xorgserver" {
    name = "xorg-server-1.18.4";
    src = fetchurl {
      url = mirror://xorg/individual/xserver/xorg-server-1.18.4.tar.bz2;
      sha256 = "1j1i3n5xy1wawhk95kxqdc54h34kg7xp4nnramba2q8xqfr5k117";
    };
    nativeBuildInputs = [ bison flex utilmacros ];
    buildInputs = [ bigreqsproto compositeproto damageproto dbus libdmx dmxproto mesa_noglu dri2proto dri3proto libepoxy fixesproto fontsproto glproto inputproto kbproto libdrm systemd_lib libunwind openssl libpciaccess pixman presentproto randrproto recordproto renderproto resourceproto scrnsaverproto videoproto wayland windowswmproto libX11 libXau libXaw libxcb xcbutil xcbutilwm xcbutilimage xcbutilkeysyms xcbutilrenderutil xcmiscproto libXdmcp libXext xextproto xf86bigfontproto xf86dgaproto xf86driproto xf86vidmodeproto libXfixes libXfont libXi xineramaproto libxkbfile libXmu libXpm xproto libXrender libXres libxshmfence libXt xtrans libXtst ];

  }) // {inherit bigreqsproto compositeproto damageproto dbus libdmx dmxproto mesa_noglu dri2proto dri3proto libepoxy fixesproto fontsproto glproto inputproto kbproto libdrm systemd_lib libunwind openssl libpciaccess pixman presentproto randrproto recordproto renderproto resourceproto scrnsaverproto videoproto wayland windowswmproto libX11 libXau libXaw libxcb xcbutil xcbutilwm xcbutilimage xcbutilkeysyms xcbutilrenderutil xcmiscproto libXdmcp libXext xextproto xf86bigfontproto xf86dgaproto xf86driproto xf86vidmodeproto libXfixes libXfont libXi xineramaproto libxkbfile libXmu libXpm xproto libXrender libXres libxshmfence libXt xtrans libXtst ;};

  xorgsgmldoctools = (mkDerivation "xorgsgmldoctools" {
    name = "xorg-sgml-doctools-1.11";
    src = fetchurl {
      url = mirror://xorg/individual/doc/xorg-sgml-doctools-1.11.tar.bz2;
      sha256 = "0k5pffyi5bx8dmfn033cyhgd3gf6viqj3x769fqixifwhbgy2777";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xphelloworld = (mkDerivation "xphelloworld" {
    name = "xphelloworld-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xphelloworld-1.0.1.tar.bz2;
      sha256 = "09jlwfbhhxnj46wb4cdhagxfm23gg9qmwryqx5g16nsfpbihijmi";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libX11 libXp libXprintAppUtil libXprintUtil libXt ];

  }) // {inherit libX11 libXp libXprintAppUtil libXprintUtil libXt ;};

  xplsprinters = (mkDerivation "xplsprinters" {
    name = "xplsprinters-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xplsprinters-1.0.1.tar.bz2;
      sha256 = "0wmhin7z59fb87288gpqx7ia049ly8i51yg7l1slp5z010c0mimd";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libX11 libXp libXprintUtil ];

  }) // {inherit libX11 libXp libXprintUtil ;};

  xpr = (mkDerivation "xpr" {
    name = "xpr-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xpr-1.0.4.tar.bz2;
      sha256 = "1dbcv26w2yand2qy7b3h5rbvw1mdmdd57jw88v53sgdr3vrqvngy";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXmu xproto ];

  }) // {inherit libX11 libXmu xproto ;};

  xprehashprinterlist = (mkDerivation "xprehashprinterlist" {
    name = "xprehashprinterlist-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xprehashprinterlist-1.0.1.tar.bz2;
      sha256 = "0n82yar7hg1npc63fmxrjj84grr6zivddccip1562gbhdwjyjrxs";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libX11 libXp ];

  }) // {inherit libX11 libXp ;};

  xprop = (mkDerivation "xprop" {
    name = "xprop-1.2.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xprop-1.2.2.tar.bz2;
      sha256 = "1ilvhqfjcg6f1hqahjkp8qaay9rhvmv2blvj3w9asraq0aqqivlv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  xproto = (mkDerivation "xproto" {
    name = "xproto-7.0.29";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xproto-7.0.29.tar.bz2;
      sha256 = "12lzpa9mrzkyrhrphzpi1014np3328qg7mdq08wj6wyaj9q4f6kc";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xproxymanagementprotocol = (mkDerivation "xproxymanagementprotocol" {
    name = "xproxymanagementprotocol-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/proto/xproxymanagementprotocol-1.0.3.tar.bz2;
      sha256 = "1hi6zp27cad7pw4z5d6rpgndrbvzq1nbiji2nsz7g9bgqzcar0kk";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xpyb = (mkDerivation "xpyb" {
    name = "xpyb-1.3.1";
    src = fetchurl {
      url = mirror://xorg/individual/xcb/xpyb-1.3.1.tar.bz2;
      sha256 = "0rkkk2n9g2n2cslvdnb732zwmiijlgn7i9il6w296f5q0mxqfk7x";
    };
    nativeBuildInputs = [ python ];
    buildInputs = [ libxcb xcbproto ];

  }) // {inherit libxcb xcbproto ;};

  xrandr = (mkDerivation "xrandr" {
    name = "xrandr-1.5.0";
    src = fetchurl {
      url = mirror://xorg/individual/app/xrandr-1.5.0.tar.bz2;
      sha256 = "1kaih7rmzxr1vp5a5zzjhm5x7dn9mckya088sqqw026pskhx9ky1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto libXrandr libXrender ];

  }) // {inherit libX11 xproto libXrandr libXrender ;};

  xrdb = (mkDerivation "xrdb" {
    name = "xrdb-1.1.0";
    src = fetchurl {
      url = mirror://xorg/individual/app/xrdb-1.1.0.tar.bz2;
      sha256 = "0nsnr90wazcdd50nc5dqswy0bmq6qcj14nnrhyi7rln9pxmpp0kk";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXmu xproto ];

  }) // {inherit libX11 libXmu xproto ;};

  xrefresh = (mkDerivation "xrefresh" {
    name = "xrefresh-1.0.5";
    src = fetchurl {
      url = mirror://xorg/individual/app/xrefresh-1.0.5.tar.bz2;
      sha256 = "1mlinwgvql6s1rbf46yckbfr9j22d3c3z7jx3n6ix7ca18dnf4rj";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  xrx = (mkDerivation "xrx" {
    name = "xrx-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xrx-1.0.4.tar.bz2;
      sha256 = "1933jy4la9prb4d5942i2jqm3zpr5qf3l6ci5hxlvv85w755xsxm";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE libX11 libXau libXaw libXext xproxymanagementprotocol libXt xtrans ];

  }) // {inherit libICE libX11 libXau libXaw libXext xproxymanagementprotocol libXt xtrans ;};

  xscope = (mkDerivation "xscope" {
    name = "xscope-1.4.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xscope-1.4.1.tar.bz2;
      sha256 = "08zl3zghvbcqy0r5dn54dim84lp52s0ygrr87jr3a942a6ypz01k";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ xproto ];

  }) // {inherit xproto ;};

  xset = (mkDerivation "xset" {
    name = "xset-1.2.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xset-1.2.3.tar.bz2;
      sha256 = "0qw0iic27bz3yz2wynf1gxs70hhkcf9c4jrv7zhlg1mq57xz90j3";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXext libXfontcache libXmu xproto libXxf86misc ];

  }) // {inherit libX11 libXext libXfontcache libXmu xproto libXxf86misc ;};

  xsetmode = (mkDerivation "xsetmode" {
    name = "xsetmode-1.0.0";
    src = fetchurl {
      url = mirror://xorg/individual/app/xsetmode-1.0.0.tar.bz2;
      sha256 = "1am0mylym97m79n54jvlc45njxdchv1mvqdwmpkcd499jb6lg2wq";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libX11 libXi ];

  }) // {inherit libX11 libXi ;};

  xsetpointer = (mkDerivation "xsetpointer" {
    name = "xsetpointer-1.0.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xsetpointer-1.0.1.tar.bz2;
      sha256 = "0wa5q1k03016527kxjnn8m0wxcrwyw9zhmdfpfc1w25m3s3qhpa9";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ inputproto libX11 libXi ];

  }) // {inherit inputproto libX11 libXi ;};

  xsetroot = (mkDerivation "xsetroot" {
    name = "xsetroot-1.1.1";
    src = fetchurl {
      url = mirror://xorg/individual/app/xsetroot-1.1.1.tar.bz2;
      sha256 = "1nf3ii31m1knimbidaaym8p61fq3blv8rrdr2775yhcclym5s8ds";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xbitmaps libXcursor libXmu xproto ];

  }) // {inherit libX11 xbitmaps libXcursor libXmu xproto ;};

  xsm = (mkDerivation "xsm" {
    name = "xsm-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xsm-1.0.3.tar.bz2;
      sha256 = "0jkvhq9c9nx0a9kykxzgx5haxk0a9c0q72jifcgq90x68wlfx7dd";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libICE libSM libX11 libXaw libXt ];

  }) // {inherit libICE libSM libX11 libXaw libXt ;};

  xstdcmap = (mkDerivation "xstdcmap" {
    name = "xstdcmap-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xstdcmap-1.0.3.tar.bz2;
      sha256 = "1h8gb05qwa1j9m3akvfsz30rvqsb433y5679dn2jkahnryqf4j7n";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXmu xproto ];

  }) // {inherit libX11 libXmu xproto ;};

  xtrans = (mkDerivation "xtrans" {
    name = "xtrans-1.3.5";
    src = fetchurl {
      url = mirror://xorg/individual/lib/xtrans-1.3.5.tar.bz2;
      sha256 = "00c3ph17acnsch3gbdmx33b9ifjnl5w7vx8hrmic1r1cjcv3pgdd";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ ];

  }) // {inherit ;};

  xtrap = (mkDerivation "xtrap" {
    name = "xtrap-1.0.2";
    src = fetchurl {
      url = mirror://xorg/individual/app/xtrap-1.0.2.tar.bz2;
      sha256 = "1g0gmvf8fnch5ksq7lky3mbpgmlq19hfaxyllgsdyr8cbfj3slcg";
    };
    nativeBuildInputs = [ ];
    buildInputs = [ libX11 libXTrap ];

  }) // {inherit libX11 libXTrap ;};

  xts = (mkDerivation "xts" {
    name = "xts-0.99.1";
    src = fetchurl {
      url = mirror://xorg/individual/test/xts-0.99.1.tar.bz2;
      sha256 = "08sanl2nhbbscid767i5zwk0nv2q3ds89w96ils8qfigd57kacc5";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXau libXaw libXext libXi libXmu libXt xtrans libXtst ];

  }) // {inherit libX11 libXau libXaw libXext libXi libXmu libXt xtrans libXtst ;};

  xvidtune = (mkDerivation "xvidtune" {
    name = "xvidtune-1.0.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xvidtune-1.0.3.tar.bz2;
      sha256 = "00fgxv5xpb3bakml6wsya6mk2h6pkrhn51fiw6rby11sjc1y3r94";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libXaw libXmu libXt libXxf86vm ];

  }) // {inherit libX11 libXaw libXmu libXt libXxf86vm ;};

  xvinfo = (mkDerivation "xvinfo" {
    name = "xvinfo-1.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xvinfo-1.1.3.tar.bz2;
      sha256 = "1sz5wqhxd1fqsfi1w5advdlwzkizf2fgl12hdpk66f7mv9l8pflz";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto libXv ];

  }) // {inherit libX11 xproto libXv ;};

  xwd = (mkDerivation "xwd" {
    name = "xwd-1.0.6";
    src = fetchurl {
      url = mirror://xorg/individual/app/xwd-1.0.6.tar.bz2;
      sha256 = "0ybx48agdvjp9lgwvcw79r1x6jbqbyl3fliy3i5xwy4d4si9dcrv";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

  xwininfo = (mkDerivation "xwininfo" {
    name = "xwininfo-1.1.3";
    src = fetchurl {
      url = mirror://xorg/individual/app/xwininfo-1.1.3.tar.bz2;
      sha256 = "1y1zn8ijqslb5lfpbq4bb78kllhch8in98ps7n8fg3dxjpmb13i1";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 libxcb xproto ];

  }) // {inherit libX11 libxcb xproto ;};

  xwud = (mkDerivation "xwud" {
    name = "xwud-1.0.4";
    src = fetchurl {
      url = mirror://xorg/individual/app/xwud-1.0.4.tar.bz2;
      sha256 = "1ggql6maivah58kwsh3z9x1hvzxm1a8888xx4s78cl77ryfa1cyn";
    };
    nativeBuildInputs = [ utilmacros ];
    buildInputs = [ libX11 xproto ];

  }) // {inherit libX11 xproto ;};

}; in xorg
