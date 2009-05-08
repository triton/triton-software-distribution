let

  allPackages = import ./all-packages.nix;

  pkgs = allPackages {};

  /* Set the Hydra scheduling priority for a job.  The default
     priority (100) should be used for most jobs.  A different
     priority should only be used for a few particularly interesting
     jobs (in terms of giving feedback to developers), such as stdenv.
  */
  prio = level: job: toJob job // { schedulingPriority = level; };

  toJob = x: if builtins.isAttrs x then x else
    { type = "job"; systems = x; schedulingPriority = 20; };

  /* Perform a job on the given set of platforms.  The function `f' is
     called by Hydra for each platform, and should return some job
     to build on that platform.  `f' is passed the Nixpkgs collection
     for the platform in question. */
  testOn = systems: f: {system ? builtins.currentSystem}:
    if pkgs.lib.elem system systems then f (allPackages {inherit system;}) else {};

  /* Map an attribute of the form `foo = [platforms...]'  to `testOn
     [platforms...] (pkgs: pkgs.foo)'. */
  mapTestOn = pkgs.lib.mapAttrsRecursiveCond
    (as: !(as ? type && as.type == "job"))
    (path: value:
      let
        job = toJob value;
        getPkg = pkgs:
          pkgs.lib.addMetaAttrs { schedulingPriority = toString job.schedulingPriority; }
          (pkgs.lib.getAttrFromPath path pkgs);
      in testOn job.systems getPkg);

  /* Common platform groups on which to test packages. */
  linux = ["i686-linux" "x86_64-linux"];
  darwin = ["i686-darwin"];
  cygwin = ["i686-cygwin"];
  all = linux ++ darwin ++ cygwin;
  allBut = platform: pkgs.lib.filter (x: platform != x) all;

  /* Platform groups for specific kinds of applications. */
  x11Supported = linux;
  gtkSupported = linux;
  ghcSupported = linux ++ darwin;

in {

  tarball = import ./make-tarball.nix;

} // mapTestOn {

  MPlayer = linux;
  abcde = linux;
  alsaUtils = linux;
  apacheHttpd = linux;
  aspell = all;
  at = linux;
  aterm25 = all;
  aterm28 = all;
  audacious = linux;
  audacious_plugins = linux;
  autoconf = all;
  automake110x = all;
  automake19x = all;
  avahi = allBut "i686-cygwin";  # Cygwin builds fail
  bash = all;
  bashInteractive = all;
  bazaar = linux; # first let sqlite3 work on darwin
  bc = all;
  binutils = linux;
  bind = linux;
  bison23 = all;
  bison24 = all;
  bitlbee = linux; 
  bittorrent = linux;
  boost = all;
  boostFull = all;
  bsdiff = all;
  btrfsProgs = linux;
  bvi = all;
  bzip2 = all;
  cabextract = all;
  castleCombat = linux;
  cdrkit = linux;
  cedet = linux;
  chatzilla = linux;
  cksfv = all;
  clisp = linux;
  cmake = all;
  compiz = linux;
  coreutils = all;
  cpio = all;
  cron = linux;
  cups = linux;
  cvs = linux;
  db4 = all;
  ddrescue = linux;
  dhcp = linux;
  dico = linux;
  dietlibc = linux;
  diffutils = all;
  docbook5 = all;
  docbook5_xsl = all;
  docbook_xml_dtd_42 = all;
  docbook_xml_dtd_43 = all;
  docbook_xsl = all;
  dosbox = linux;
  dovecot = linux;
  doxygen = linux;
  e2fsprogs = linux;
  ejabberd = linux;
  elinks = linux;
  emacs22 = all;
  emacsUnicode = all;
  emms = linux;
  enscript = all;
  eprover = linux;
  evince = linux;
  expect = linux;
  exult = linux;
  feh = linux;
  file = all;
  findutils = all;
  firefox2 = linux;
  firefox3 = prio 150 linux;
  firefox3_5 = prio 15 linux;
  flex = all;
  flex2535 = all;
  fontforge = linux;
  fuse = linux;
  gajim = linux;
  gawk = all;
  gcc = all;
  gcc33 = linux;
  gcc34 = linux;
  gcc42 = linux;
  gcc43_multi = ["x86_64-linux"];
  gdb = all;
  ghostscript = linux;
  ghostscriptX = linux;
  gimp = linux;
  git = linux;
  glibc = linux;
  glibcLocales = linux;
  glxinfo = linux;
  gnash = linux;
  gnugrep = all;
  gnum4 = all;
  gnumake = all;
  gnupatch = all;
  gnupg2 = linux;
  gnuplot = allBut "i686-cygwin";
  gnuplotX = linux;
  gnused = all;
  gnutar = all;
  gnutls = linux;
  gphoto2 = linux;
  gpm = linux;
  gprolog = linux;
  gqview = gtkSupported;
  graphviz = all;
  grub = linux;
  gsl = linux;
  guile = linux;  # tests fail on Cygwin
  guileLib = linux;
  gv = linux;
  gw6c = linux;
  gzip = all;
  hal = linux;
  hddtemp = linux;
  hdparm = linux;
  hello = all;
  host = linux;
  hugin = linux;
  iana_etc = linux;
  icecat3Xul = [ "i686-linux" ];
  idutils = all;
  ifplugd = linux;
  imagemagick = allBut "i686-cygwin";
  impressive = linux;
  inetutils = linux;
  inkscape = linux;
  iputils = linux;
  iproute = linux;
  irssi = linux;
  jfsUtils = linux;
  jfsrec = linux;
  jnettop = linux;
  jwhois = linux;
  k3b = linux;
  kbd = linux;
  kcachegrind = linux;
  keen4 = ["i686-linux"];
  kile = linux;
  klibc = linux;
  konversation = linux;
  ktorrent = linux;
  kvm = linux;
  less = all;
  lftp = all;
  libarchive = linux;
  libsmbios = linux;
  libtool = all;
  libtool_2 = all;
  libxml2 = all;
  libxslt = all;
  lout = linux;
  lsh = linux;
  lsof = linux;
  ltrace = linux;
  lvm2 = linux;
  lynx = linux;
  lzma = linux;
  man = linux;
  manpages = linux;
  maxima = linux;
  mc = all;
  mcabber = linux;
  mcron = linux;
  mdadm = linux;
  mercurial = allBut "i686-cygwin";
  mesa = linux;
  mingetty = linux;
  mk = linux;
  mktemp = all;
  mod_python = linux;
  module_init_tools = linux;
  mono = linux;
  monotone = linux;
  mpg321 = linux;
  mutt = linux;
  mysql = linux;
  nano = allBut "i686-cygwin";
  ncat = linux;
  netcat = all;
  nfsUtils = linux;
  nix = all;
  nixUnstable = all;
  nss_ldap = linux;
  nssmdns = linux;
  ntfs3g = linux;
  ntp = linux;
  nxml = all;
  ocaml = linux;
  octave = linux;
  openoffice = linux;
  openssh = linux;
  openssl = all;
  pam_console = linux;
  pam_ldap = linux;
  pam_login = linux;
  pam_unix2 = linux;
  pan = gtkSupported;
  par2cmdline = all;
  pavucontrol = linux;
  pciutils = linux;
  perl = all;
  php = linux;
  pidgin = linux;
  pinentry = linux;
  pkgconfig = all;
  pltScheme = linux;
  pmccabe = linux;
  portmap = linux;
  postgresql = all;
  procps = linux;
  pwdutils = linux;
  pthreadmanpages = all;
  python = allBut "i686-cygwin";
  pythonFull = linux;
  qt3 = allBut "i686-cygwin";
  qt4 = linux;
  quake3demo = linux;
  readline = all;
  reiserfsprogs = linux;
  rogue = all;
  rpm = linux;
  rsync = linux;
  rubber = allBut "i686-cygwin";
  ruby = all;
  rxvt_unicode = all;
  samba = linux;
  screen = linux ++ darwin;
  sdparm = linux;
  seccure = linux;
  seccureUser = linux;
  sharutils = all;
  slim = linux;
  sloccount = allBut "i686-cygwin";
  smbfsFuse = linux;
  socat = linux;
  spidermonkey = linux;
  splashutils_13 = linux;
  splashutils_15 = linux;
  sqlite = allBut "i686-cygwin";
  squid = linux;
  ssmtp = linux;
  stdenv = prio 175 all;
  stlport = linux;
  strace = linux;
  su = linux;
  subversion = all;
  subversion16 = all;
  sudo = linux;
  superTuxKart = linux;
  swig = linux;
  sylpheed = linux;
  sysklogd = linux;
  syslinux = ["i686-linux"];
  sysvinit = linux;
  sysvtools = linux;
  tcl = linux;
  tcpdump = linux;
  teeworlds = linux;
  tetex = linux;
  texLive = linux;
  texLiveBeamer = linux;
  texLiveExtra = linux;
  texinfo = all;
  thunderbird = linux;
  tightvnc = linux;
  time = linux;
  tinycc = ["i686-linux"];
  udev = linux;
  uml = ["i686-linux"];
  unrar = linux;
  unzip = all;
  upstart = linux;
  usbutils = linux;
  utillinux = linux;
  utillinuxCurses = linux;
  valgrind = linux;
  vim = linux;
  vimHugeX = linux;
  vlc = linux;
  vorbisTools = linux;
  vpnc = linux;
  vsftpd = linux;
  w3m = all;
  webkit = linux;
  wget = all;
  which = all;
  wine = ["i686-linux"];
  wireshark = linux;
  wirelesstools = linux;
  wpa_supplicant = linux;
  x11_ssh_askpass = linux;
  xchm = linux;
  xfig = x11Supported;
  xfsProgs = linux;
  xineUI = linux;
  xkeyboard_config = linux;
  xlockmore = linux;
  xmltv = linux;
  xpdf = linux;
  xscreensaver = linux;
  xsel = linux;
  xterm = linux;
  zdelta = linux;
  zile = linux;
  zip = all;
  zsh = linux;

  aspellDicts = {
    de = all;
    en = all;
    es = all;
    fr = all;
    nl = all;
    ru = all;
  };
  
  gnome = {
    gconfeditor = linux;
    gnomepanel = linux;
    gnometerminal = linux;
    gnomeutils = linux;
    metacity = linux;
  };

  gtkLibs = {
    gtk = linux;
  };

  haskellPackages_ghc683 = {
    ghc = ghcSupported;
  };

  haskellPackages_ghc6101 = {
    ghc = ghcSupported;
  };

  haskellPackages_ghc6102 = {
    darcs = ghcSupported;
    ghc = ghcSupported;
    gtk2hs = linux;
    leksah = linux;
    lhs2tex = ghcSupported;
    haskellPlatform = linux; /* OpenGL/mesa seems to fail on darwin */
    xmonad = linux;
  };

  kde3 = {
    kdebase = linux;
    kdelibs = linux;
  };

  kde42 = {
    amarok = linux;
    kdeadmin = linux;
    kdeartwork = linux;
    kdebase = linux;
    kdebase_runtime = linux;
    kdebase_workspace = linux;
    kdeedu = linux;
    kdegames = linux;
    kdegraphics = linux;
    kdelibs = linux;
    kdemultimedia = linux;
    kdenetwork = linux;
    kdepim = linux;
    kdeplasma_addons = linux;
    kdesdk = linux;
    kdetoys = linux;
    kdeutils = linux;
    kdewebdev = linux;
    ktorrent = linux;
    kdesvn = linux;
    krusader = linux;
  };

  kernelPackages_2_6_25 = {
    aufs = linux;
    kernel = linux;
    virtualbox = linux;
  };

  kernelPackages_2_6_26 = {
    aufs = linux;
    kernel = linux;
    virtualbox = linux;
  };
  
  kernelPackages_2_6_27 = {
    aufs = linux;
    kernel = linux;
    virtualbox = linux;
  };
  
  kernelPackages_2_6_28 = {
    aufs = linux;
    kernel = linux;
    virtualbox = linux;
  };

  strategoPackages = {
    sdf = all;
    strategoxt = all;
    javafront = all;
    dryad = linux;
  };

  perlPackages = {
    TaskCatalystTutorial = linux;
  };
  
  xorg = {
    fontadobe100dpi = linux;
    fontadobe75dpi = linux;
    fontbh100dpi = linux;
    fontbhlucidatypewriter100dpi = linux;
    fontbhlucidatypewriter75dpi = linux;
    fontbhttf = linux;
    fontcursormisc = linux;
    fontmiscmisc = linux;
    iceauth = linux;
    libX11 = linux;
    lndir = all;
    setxkbmap = linux;
    xauth = linux;
    xev = linux;
    xf86inputkeyboard = linux;
    xf86inputmouse = linux;
    xf86inputevdev = linux;
    xf86videointel = linux;
    xf86videovesa = linux;
    xfs = linux;
    xkbcomp = linux;
    xmessage = linux;
    xorgserver = linux;
    xrandr = linux;
    xrdb = linux;
    xset = linux;
  };

}
