{ stdenv, fetchurl }:

let

  fbcondecorConfig =
    ''
      FB_CON_DECOR y

      # fbcondecor is picky about some other settings.
      FB y
      FB_TILEBLITTING n
      FB_MATROX n
      FB_S3 n
      FB_VT8623 n
      FB_ARK n
      FB_CFB_FILLRECT y
      FB_CFB_COPYAREA y
      FB_CFB_IMAGEBLIT y
      FB_VESA y
      FRAMEBUFFER_CONSOLE y
    '';

  makeTuxonicePatch = { version, kernelVersion, sha256,
    url ? "http://tuxonice.net/files/tuxonice-${version}-for-${kernelVersion}.patch.bz2" }:
    { name = "tuxonice-${kernelVersion}";
      patch = stdenv.mkDerivation {
        name = "tuxonice-${version}-for-${kernelVersion}.patch";
        src = fetchurl {
          inherit url sha256;
        };
        phases = [ "installPhase" ];
        installPhase = ''
          source $stdenv/setup
          bunzip2 -c $src > $out
        '';
      };
    };

in

rec {

  sec_perm_2_6_24 =
    { name = "sec_perm-2.6.24";
      patch = ./sec_perm-2.6.24.patch;
      features.secPermPatch = true;
    };

  fbcondecor_2_6_25 =
    { name = "fbcondecor-0.9.4-2.6.25-rc6";
      patch = fetchurl {
        url = http://dev.gentoo.org/~spock/projects/fbcondecor/archive/fbcondecor-0.9.4-2.6.25-rc6.patch;
        sha256 = "1wm94n7f0qyb8xvafip15r158z5pzw7zb7q8hrgddb092c6ibmq8";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_27 =
    { name = "fbcondecor-0.9.4-2.6.27";
      patch = fetchurl {
        url = http://dev.gentoo.org/~spock/projects/fbcondecor/archive/fbcondecor-0.9.4-2.6.27.patch;
        sha256 = "170l9l5fvbgjrr4klqcwbgjg4kwvrrhjpmgbfpqj0scq0s4q4vk6";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_28 =
    { name = "fbcondecor-0.9.5-2.6.28";
      patch = fetchurl {
        url = http://dev.gentoo.org/~spock/projects/fbcondecor/archive/fbcondecor-0.9.5-2.6.28.patch;
        sha256 = "105q2dwrwi863r7nhlrvljim37aqv67mjc3lgg529jzqgny3fjds";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_29 =
    { name = "fbcondecor-0.9.6-2.6.29.2";
      patch = fetchurl {
        url = http://dev.gentoo.org/~spock/projects/fbcondecor/archive/fbcondecor-0.9.6-2.6.29.2.patch;
        sha256 = "1yppvji13sgnql62h4wmskzl9l198pp1pbixpbymji7mr4a0ylx1";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_31 =
    { name = "fbcondecor-0.9.6-2.6.31.2";
      patch = fetchurl {
        url = http://dev.gentoo.org/~spock/projects/fbcondecor/archive/fbcondecor-0.9.6-2.6.31.2.patch;
        sha256 = "1avk0yn0y2qbpsxf31r6d14y4a1mand01r4k4i71yfxvpqcgxka9";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_33 =
    { name = "fbcondecor-0.9.6-2.6.33-rc7";
      patch = fetchurl {
        url = http://dev.gentoo.org/~spock/projects/fbcondecor/archive/fbcondecor-0.9.6-2.6.33-rc7.patch;
        sha256 = "1v9lg3bgva0xry0s09drpw3n139s8hln8slayaf6i26vg4l4xdz6";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_35 =
    rec {
      name = "fbcondecor-0.9.6-2.6.35-rc4";
      patch = fetchurl {
        url = "http://dev.gentoo.org/~spock/projects/fbcondecor/archive/${name}.patch";
        sha256 = "0dlks1arr3b3hlmw9k1a1swji2x655why61sa0aahm62faibsg1r";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_37 =
    rec {
      name = "fbcondecor-0.9.6-2.6.37";
      patch = fetchurl {
        url = "http://dev.gentoo.org/~spock/projects/fbcondecor/archive/${name}.patch";
        sha256 = "1yap9q6mp15jhsysry4x17cpm5dj35g8l2d0p0vn1xq25x3jfkqk";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  fbcondecor_2_6_38 =
    rec {
      name = "fbcondecor-0.9.6-2.6.38";
      patch = fetchurl {
        url = "http://dev.gentoo.org/~spock/projects/fbcondecor/archive/${name}.patch";
        sha256 = "1l8xqf5z227m5ay6azqba1qw10y26a4cwfhzzapzmmwq1bpr8mlw";
      };
      extraConfig = fbcondecorConfig;
      features.fbConDecor = true;
    };

  # From http://patchwork.kernel.org/patch/19495/
  ext4_softlockups_2_6_28 =
    { name = "ext4-softlockups-fix";
      patch = fetchurl {
        url = http://patchwork.kernel.org/patch/19495/raw;
        sha256 = "0vqcj9qs7jajlvmwm97z8cljr4vb277aqhsjqrakbxfdiwlhrzzf";
      };
    };

  gcov_2_6_28 =
    { name = "gcov";
      patch = fetchurl {
        url = http://buildfarm.st.ewi.tudelft.nl/~eelco/dist/linux-2.6.28-gcov.patch;
        sha256 = "0ck9misa3pgh3vzyb7714ibf7ix7piyg5dvfa9r42v15scjqiyny";
      };
      extraConfig =
        ''
          GCOV_PROFILE y
          GCOV_ALL y
          GCOV_PROC m
          GCOV_HAMMER n
        '';
    };

  tracehook_2_6_32 =
    { # From <http://people.redhat.com/roland/utrace/>.
      name = "tracehook";
      patch = fetchurl {
        url = http://people.redhat.com/roland/utrace/2.6.32/tracehook.patch;
        sha256 = "1y009p8dyqknbjm8ryb495jqmvl372gfhswdn167xh2g1f24xqv8";
      };
    };

  utrace_2_6_32 =
    { # From <http://people.redhat.com/roland/utrace/>, depends on the
      # `tracehook' patch above.
      # See also <http://sourceware.org/systemtap/wiki/utrace>.
      name = "utrace";
      patch = fetchurl {
        url = http://people.redhat.com/roland/utrace/2.6.32/utrace.patch;
        sha256 = "1951mwc8jfiwrl0d2bb1zk9yrl7n7kadc00ymjsxrg2irda1b89r";
      };
      extraConfig =
        '' UTRACE y
        '';
    };

  aufs2_2_6_32 =
    { # From http://git.c3sl.ufpr.br/gitweb?p=aufs/aufs2-standalone.git;a=tree;h=refs/heads/aufs2-32;hb=aufs2-32
      # Note that this merely the patch needed to build AUFS2 as a
      # standalone package.
      name = "aufs2";
      patch = ./aufs2.patch;
      features.aufsBase = true;
    };

  aufs2_2_6_34 =
    { # From http://git.c3sl.ufpr.br/gitweb?p=aufs/aufs2-standalone.git;a=tree;h=refs/heads/aufs2-34;hb=aufs2-34
      # Note that this merely the patch needed to build AUFS2 as a
      # standalone package.
      name = "aufs2";
      patch = ./aufs2-34.patch;
      features.aufsBase = true;
    };

  aufs2_2_6_35 =
    { # From http://git.c3sl.ufpr.br/gitweb?p=aufs/aufs2-standalone.git;a=tree;h=refs/heads/aufs2-35;hb=aufs2-35
      # Note that this merely the patch needed to build AUFS2 as a
      # standalone package.
      name = "aufs2";
      patch = ./aufs2-35.patch;
      features.aufsBase = true;
    };

  aufs2_1_2_6_37 =
    { # From http://git.c3sl.ufpr.br/gitweb?p=aufs/aufs2-standalone.git;a=tree;h=refs/heads/aufs2.1-37;hb=refs/heads/aufs2.1-37
      # Note that this merely the patch needed to build AUFS2.1 as a
      # standalone package.
      name = "aufs2.1";
      patch = ./aufs2.1-37.patch;
      features.aufsBase = true;
      features.aufs2_1 = true;
    };

  aufs2_1_2_6_38 =
    { # From http://aufs.git.sourceforge.net/git/gitweb.cgi?p=aufs/aufs2-standalone.git;a=tree;h=refs/heads/aufs2.1-38;hb=refs/heads/aufs2.1-38
      # Note that this merely the patch needed to build AUFS2.1 as a
      # standalone package.
      name = "aufs2.1";
      patch = ./aufs2.1-38.patch;
      features.aufsBase = true;
      features.aufs2_1 = true;
    };

  # Increase the timeout on CIFS requests from 15 to 120 seconds to
  # make CIFS more resilient to high load on the CIFS server.
  cifs_timeout_2_6_25 =
    { name = "cifs-timeout";
      patch = ./cifs-timeout-2.6.25.patch;
      features.cifsTimeout = true;
    };

  cifs_timeout_2_6_29 =
    { name = "cifs-timeout";
      patch = ./cifs-timeout-2.6.29.patch;
      features.cifsTimeout = true;
    };

  cifs_timeout_2_6_35 =
    { name = "cifs-timeout";
      patch = ./cifs-timeout-2.6.35.patch;
      features.cifsTimeout = true;
    };

  cifs_timeout_2_6_38 =
    { name = "cifs-timeout";
      patch = ./cifs-timeout-2.6.38.patch;
      features.cifsTimeout = true;
    };

  cifs_timeout = cifs_timeout_2_6_29;

  no_xsave =
    { name = "no-xsave";
      patch = fetchurl {
        url = "http://kernel.ubuntu.com/git?p=rtg/ubuntu-maverick.git;a=blobdiff_plain;f=arch/x86/xen/enlighten.c;h=f7ff4c7d22954ab5eda464320241300bd5a32ee5;hp=1ea06f842a921557e958110e22941d53a2822f3c;hb=1a30f99;hpb=8f2ff69dce18ed856a8d1b93176f768b47eeed86";
        name = "no-xsave.patch";
        sha256 = "18732s3vmav5rpg6zqpiw2i0ll83pcc4gw266h6545pmbh9p7hky";
      };
      features.noXsave = true;
    };

  dell_rfkill =
    { name = "dell-rfkill";
      patch = ./dell-rfkill.patch;
    };

  sheevaplug_modules_2_6_35 =
    { name = "sheevaplug_modules-2.6.35";
      patch = ./sheevaplug_modules-2.6.35.patch;
    };

  mips_restart_2_6_36 =
    { name = "mips_restart_2_6_36";
      patch = ./mips_restart.patch;
    };

  guruplug_defconfig =
    { # Default configuration for the GuruPlug.  From
      # <http://www.openplug.org/plugwiki/images/c/c6/Guruplug-patchset-2.6.33.2.tar.bz2>.
      name = "guruplug-defconfig";
      patch = ./guruplug-defconfig.patch;
    };

  guruplug_arch_number =
    { # Hack to match the `arch_number' of the U-Boot that ships with the
      # GuruPlug.  This is only needed when using this specific U-Boot
      # binary.  See
      # <http://www.plugcomputer.org/plugwiki/index.php/Compiling_Linux_Kernel_for_the_Plug_Computer>.
      name = "guruplug-arch-number";
      patch = ./guruplug-mach-type.patch;
    };

  tuxonice_2_6_34 = makeTuxonicePatch {
    version = "3.2-rc2";
    kernelVersion = "2.6.34";
    sha256 = "0bagqinmky1kmvg3vw8cdysqklxrsfjm7gqrpxviq9jq8vyycviz";
  };

  tuxonice_2_6_35 = makeTuxonicePatch {
    version = "3.2-rc2";
    kernelVersion = "2.6.35";
    sha256 = "00jbrqq6p1lyvli835wczc0vqsn0z73jpb2aak3ak0vgnvsxw37q";
  };

  tuxonice_2_6_36 = makeTuxonicePatch {
    version = "3.2-rc2";
    kernelVersion = "2.6.36";
    sha256 = "1vcw3gpjdghnkli46j37pc6rp8mqk8dh688jv8rppzsry0ll7b7k";
  };

  tuxonice_2_6_37 = makeTuxonicePatch {
    version = "3.2-rc2";
    kernelVersion = "2.6.37";
    url = "http://tuxonice.net/files/current-tuxonice-for-2.6.37.patch_0.bz2";
    sha256 = "0acllabvbm9pmjnh0zx9mgnp47xbrl9ih6i037c85h0ymnjsxdhk";
  };

  glibc_getline =
    {
      # Patch to work around conflicting types for the `getline' function
      # with recent Glibcs (2009).
      name = "glibc-getline";
      patch = ./getline.patch;
    };
}
