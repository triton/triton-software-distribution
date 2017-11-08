{ stdenv
, fetchFromGitHub
, fetchTritonPatch
, fetchurl
, lib
, nasm
, perl
, texinfo

/*
 *  Licensing options (yes some are listed twice, filters and such are not listed)
 */
, gplLicensing ? true
, version3Licensing ? true
, nonfreeLicensing ? false
/*
 *  Build options
 */
# Optimize for size instead of speed
, smallBuild ? false
# Detect CPU capabilities at runtime (disable to compile natively)
, runtimeCpuDetectBuild ? true
# Full grayscale support
, grayBuild ? true
# Alpha channel support in swscale
, swscaleAlphaBuild ? true
# Hardcode decode tables instead of runtime generation
, hardcodedTablesBuild ? true
, safeBitstreamReaderBuild ? true  # Buffer boundary checking in bitreaders
, multithreadBuild ? true  # Multithreading via pthreads/win32 threads
, networkBuild ? true  # Network support
, pixelutilsBuild ? true  # Pixel utils in libavutil
/*
 *  Program options
 */
, ffmpegProgram ? true
, ffplayProgram ? true
, ffprobeProgram ? true
, ffserverProgram ? true
, qtFaststartProgram ? true
/*
 *  Library options
 */
, avcodecLibrary ? true
, avdeviceLibrary ? true
, avfilterLibrary ? true
, avformatLibrary ? true
, avresampleLibrary ? false  # Libav api compatibility library
, avutilLibrary ? true
, postprocLibrary ? true
, swresampleLibrary ? true
, swscaleLibrary ? true
/*
 *  Documentation options
 */
, htmlpagesDocumentation ? false
, manpagesDocumentation ? true
, podpagesDocumentation ? false
, txtpagesDocumentation ? false
/*
 *  External libraries options
 */
#, aacplusExtlib ? false, aacplus
, alsa-lib
#, avisynth
, bzip2
, celt
, chromaprint
#, crystalhd
#, decklinkExtlib ? false
#  , blackmagic-design-desktop-video
, fdk-aac
, flite
, fontconfig
, freetype
, frei0r-plugins
, fribidi
, game-music-emu
, gmp
, gnutls
, gsm
#, ilbc
, jni ? null
, kvazaar ? null
, jack2_lib
, ladspa-sdk
, lame
, libass
, libbluray
, libbs2b
, libcaca
#, libcdio-paranoia
, libdc1394
, libdrm
#, libiec61883, libavc1394
, libgcrypt
, libmodplug
, libmysofa ? null
, libnppSupport ? false
, libogg
, libraw1394
, librsvg
, libsndio ? null
, libssh
, libtheora
, libva
, libvdpau
, libvorbis
, libvpx
, libwebp
, libxcbshmExtlib ? true
, libxcbxfixesExtlib ? true
, libxcbshapeExtlib ? true
, libxml2
, mfx-dispatcher
, mmal ? null
, nvenc ? false
, nvidia-cuda-toolkit
, nvidia-drivers
, openal
#, opencl
#, opencore-amr
, opencv
, opengl-dummy
, openh264
, openjpeg
, openssl
, opus
, pulseaudio_lib
, rtmpdump
, rubberband
#, libquvi
, samba_client
, sdl
#, shine
, snappy
, soxr
, speex
, tesseract
#, twolame
#, utvideo
, v4l_lib
, vid-stab
#, vo-aacenc
, vo-amrwbenc ? null
, wavpack
, x264
, x265
, xavs
, xorg
, xvidcore
, xz
, zeromq4
, zimg
, zlib
#, zvbi
/*
 *  Developer options
 */
, debugDeveloper ? false
, optimizationsDeveloper ? true
, extraWarningsDeveloper ? false
, strippingDeveloper ? false

, channel
}:

let
  inherit (builtins)
    compareVersions;

  inherit (stdenv)
    targetSystem;

  inherit (lib)
    boolEn
    elem
    optional
    optionals
    optionalString
    platforms
    versionOlder;

  sources = {
    "3.3" = {
      version = "3.3.5";
      multihash = "QmVZNSJaKnWWeNwSPnuojFHwowFC3HedNUh4573nBqk3VA";
      sha256 = "a893490c3a8a7caaa9c47373b789c0335d0ac3572f2ba61059de842b9e45d802";
    };
    "3.4" = {
      version = "3.4";
      multihash = "QmPwvCQ6r12AgTeNTTDseG9NNo2V7mzqh81GNt58SUpnsd";
      sha256 = "aeee06e4d8b18d852c61ebbfe5e1bb7014b1e118e8728c1c2115f91e51bffbef";
    };
    "9.9" = { # Git
      version = "2017.11.08";
      rev = "ba79a101a2f938e2d83ccc32aca5df6e27f1d8e6";
      sha256 = "4a47f4e9dfe375ad8fc6c9cb9318413c2f3ff64433e05bfa545fd736289eed9d";
    };
  };
  source = sources."${channel}";
in

/*
 *  Licensing dependencies
 */
# GPL
assert
  fdk-aac != null
  #|| avid != null
  #|| avisynth != null
  #|| cdio != null
  || frei0r-plugins != null
  || openssl != null
  || rubberband != null
  || samba_client != null
  #|| utvideo != null
  || vid-stab != null
  || x264 != null
  || x265 != null
  || xavs != null
  || xvidcore != null
  #|| zvbi != null
  -> gplLicensing;
# GPL3
assert
  #opencore-amrnb != null
  #|| opencore-amrwb != null
  #|| libvmaf != null
  samba_client != null
  #|| vo-aacenc != null
  #|| vo-amrwbenc != null
  -> version3Licensing && gplLicensing;
# Non-free
assert
  #decklinkExtlib
  fdk-aac != null
  || libnppSupport
  || openssl != null
  -> nonfreeLicensing && gplLicensing && version3Licensing;
/*
 *  Build dependencies
 */
assert networkBuild -> gnutls != null || openssl != null;
assert pixelutilsBuild -> avutilLibrary;
/*
 *  Program dependencies
 */
assert ffmpegProgram ->
  avcodecLibrary
  && avfilterLibrary
  && avformatLibrary
  && swresampleLibrary;
assert ffplayProgram ->
  avcodecLibrary
  && avformatLibrary
  && swscaleLibrary
  && swresampleLibrary
  && sdl != null;
assert ffprobeProgram ->
  avcodecLibrary
  && avformatLibrary;
assert ffserverProgram -> avformatLibrary;
/*
 *  Library dependencies
 */
assert avcodecLibrary -> avutilLibrary;
assert avdeviceLibrary ->
  avformatLibrary
  && avcodecLibrary
  && avutilLibrary;
assert avformatLibrary ->
  avcodecLibrary
  && avutilLibrary;
assert avresampleLibrary -> avutilLibrary;
assert postprocLibrary -> avutilLibrary;
assert swresampleLibrary -> soxr != null;
assert swscaleLibrary -> avutilLibrary;
/*
 *  External libraries
 */
assert flite != null -> alsa-lib != null;
assert libxcbshmExtlib -> xorg.libxcb != null;
assert libxcbxfixesExtlib -> xorg.libxcb != null;
assert libxcbshapeExtlib -> xorg.libxcb != null;
assert gnutls != null -> openssl == null;
assert openssl != null -> gnutls == null;

let
  # Minimum/maximun/matching version
  reqMin = v: (compareVersions v channel != 1);
  reqMax = v: (compareVersions channel v != 1);
  reqMatch = v: (compareVersions v channel == 0);

  # Usage:
  # f - Configure flag
  # v - Version that the configure option was added
  fflag = f: v:
    if v == null || reqMin v  then
      "${f}"
    else
      null;
  deprfflag = f: vmin: vmax:
    if (vmin == null || reqMin vmin) && (vmax == null || reqMax vmax) then
      "${f}"
    else
      null;
in
stdenv.mkDerivation rec {
  name = "ffmpeg-${source.version}";

  src =
    if channel == "9.9" then
      fetchFromGitHub {
        version = 2;
        owner = "ffmpeg";
        repo = "ffmpeg";
        inherit (source)
          rev
          sha256;
      }
    else
      fetchurl {
        url = "https://www.ffmpeg.org/releases/${name}.tar.xz";
        hashOutput = false;
        inherit (source)
          multihash
          sha256;
      };

  nativeBuildInputs = [
    perl
    texinfo
    nasm
  ];

  buildInputs = [
    alsa-lib
    bzip2
    celt
    chromaprint
    flite
    fontconfig
    freetype
    frei0r-plugins
    fribidi
    game-music-emu
    gmp
    gsm
    gnutls
    jack2_lib
    ladspa-sdk
    lame
    libass
    libbluray
    libbs2b
    libcaca
    libdc1394
    libdrm
    libgcrypt
    libmodplug
    libogg
    libraw1394
    librsvg
    libssh
    libtheora
    libva
    libvdpau
    libvorbis
    libvpx
    libwebp
    libxml2
    mfx-dispatcher
    nvidia-cuda-toolkit
    nvidia-drivers
    openal
    opengl-dummy
    openh264
    openjpeg
    opus
    pulseaudio_lib
    rtmpdump
    rubberband
    samba_client
    sdl
    soxr
    snappy
    speex
    tesseract
    v4l_lib
    vid-stab
    wavpack
    x264
    x265
    xavs
    xorg.libX11
    xorg.libxcb
    xorg.libXext
    xorg.libXfixes
    xorg.libXv
    #xorg.libXvMC
    xorg.xproto
    xvidcore
    xz
    zeromq4
    zimg
    zlib
  ] ++ optionals nonfreeLicensing [
    fdk-aac
    openssl
  ];

  patches = optionals (!versionOlder channel "3.5") [
    (fetchTritonPatch {
      rev = "7deabe056f426f80c70a73b0bc310cfbf53d0231";
      file = "f/ffmpeg/ffmpeg-3.5.dev-revert-libva2-uncompat-changes.patch";
      sha256 = "84c6302fd49203735c4286acf5310b47504e6cbf39ba7fb8d388265a4c635acc";
    })
  ];

  postPatch = ''
    patchShebangs .
  '' + optionalString (frei0r-plugins != null) ''
    sed -i libavfilter/vf_frei0r.c \
      -e 's,/usr,${frei0r-plugins},g'
  '' + optionalString (ladspa-sdk != null) ''
    sed -i libavfilter/af_ladspa.c \
      -e 's,/usr,${ladspa-sdk},g'
  '';

  configureFlags = [
    /*
     *  Licensing flags
     */
    "--${boolEn gplLicensing}-gpl"
    "--${boolEn version3Licensing}-version3"
    "--${boolEn nonfreeLicensing}-nonfree"
    /*
     *  Build flags
     */
    # On some ARM platforms --enable-thumb
    /**/"--disable-thumb"
    "--enable-shared --disable-static"
    "--enable-pic"
    (if stdenv.cc.isClang then "--cc=clang" else null)
    "--${boolEn smallBuild}-small"
    "--${boolEn runtimeCpuDetectBuild}-runtime-cpudetect"
    "--${boolEn grayBuild}-gray"
    "--${boolEn swscaleAlphaBuild}-swscale-alpha"
    #(fflag "--disable-autodetect" "3.4")
    "--${boolEn hardcodedTablesBuild}-hardcoded-tables"
    "--${boolEn safeBitstreamReaderBuild}-safe-bitstream-reader"
    "--enable-pthreads"
    "--disable-w32threads"  # Windows
    "--disable-os2threads"  # OS/2
    "--${boolEn networkBuild}-network"
    "--${boolEn pixelutilsBuild}-pixelutils"
    /*
     *  Program flags
     */
    "--${boolEn ffmpegProgram}-ffmpeg"
    "--${boolEn ffplayProgram}-ffplay"
    "--${boolEn ffprobeProgram}-ffprobe"
    "--${boolEn ffserverProgram}-ffserver"
    /*
     *  Library flags
     */
    "--${boolEn avcodecLibrary}-avcodec"
    "--${boolEn avdeviceLibrary}-avdevice"
    "--${boolEn avfilterLibrary}-avfilter"
    "--${boolEn avformatLibrary}-avformat"
    "--${boolEn avresampleLibrary}-avresample"
    "--${boolEn avutilLibrary}-avutil"
    "--${boolEn (postprocLibrary && gplLicensing)}-postproc"
    "--${boolEn swresampleLibrary}-swresample"
    "--${boolEn swscaleLibrary}-swscale"
    /*
     *  Documentation flags
     */
    "--${boolEn (
      htmlpagesDocumentation
      || manpagesDocumentation
      || podpagesDocumentation
      || txtpagesDocumentation)}-doc"
    "--${boolEn htmlpagesDocumentation}-htmlpages"
    "--${boolEn manpagesDocumentation}-manpages"
    "--${boolEn podpagesDocumentation}-podpages"
    "--${boolEn txtpagesDocumentation}-txtpages"
    /*
     *  Hardware accelerators
     */
    "--disable-audiotoolbox"  # macOS
    "--${boolEn (
      nvidia-cuda-toolkit != null
      && nvidia-drivers != null)}-cuda"
    (fflag "--${boolEn (
      nvidia-cuda-toolkit != null
      && nvidia-drivers != null)}-cuda-sdk" "3.4")
    "--${boolEn (
      nvidia-cuda-toolkit != null
      && nvidia-drivers != null)}-cuvid"
    "--disable-d3d11va"  # Windows
    "--disable-dxva2"  # Windows
    (fflag "--${boolEn (libdrm != null)}-libdrm" "3.4")
    "--${boolEn (mfx-dispatcher != null)}-libmfx"
    "--${boolEn libnppSupport}-libnpp"
    #"--${boolEn (mmal != null)}-mmal"
    /**/"--disable-mmal"
    "--${boolEn nvenc}-nvenc"
    /**/(fflag "--disable-omx" "3.4")
    /**/(fflag "--disable-omx-rpi" "3.4")
    /**/(fflag "--disable-rkmpp" "3.4")
    "--${boolEn (libva != null)}-vaapi"
    (deprfflag "--disable-vda" null "3.4")  # macOS
    "--${boolEn (libvdpau != null)}-vdpau"
    "--disable-videotoolbox"  # macOS
    # Undocumented
    # FIXME
    #"--${boolEn (xorg.libXvMC != null)}-xvmc"
    "--disable-xvmc"
    /*
     *  External libraries
     */
    (fflag "--${boolEn (alsa-lib != null)}-alsa" "3.4")
    (fflag "--disable-appkit" "3.4")  # macOS
    (fflag "--disable-avfoundation" "3.4")  # macOS
    #"--${boolEn (avisynth != null)}-avisynth"
    /**/"--disable-avisynth"
    "--${boolEn (bzip2 != null)}-bzlib"
    (fflag "--disable-coreimage" "3.4")  # macOS
    # Recursive dependency
    "--${boolEn (chromaprint != null)}-chromaprint"
    # Undocumented (broadcom)
    #"--${boolEn (crystalhd != null)}-crystalhd"
    /**/"--disable-crystalhd"
    "--${boolEn (frei0r-plugins != null)}-frei0r"
    "--${boolEn (libgcrypt != null)}-gcrypt"
    "--${boolEn (gmp != null)}-gmp"
    "--${boolEn (gnutls != null)}-gnutls"
    "--${boolEn (stdenv.cc.libc != null)}-iconv"
    (deprfflag "--${boolEn (jack2_lib != null)}-jack" "3.4" "3.4")
    "--${boolEn (jni != null)}-jni"
    "--${boolEn (ladspa-sdk != null)}-ladspa"
    "--${boolEn (libass != null)}-libass"
    "--${boolEn (libbluray != null)}-libbluray"
    "--${boolEn (libbs2b != null)}-libbs2b"
    "--${boolEn (libcaca != null)}-libcaca"
    "--${boolEn (celt != null)}-libcelt"
    #"--${boolEn (libcdio != null)}-libcdio"
    /**/"--disable-libcdio"
    "--${boolEn (
      libdc1394 != null
      && libraw1394 != null)}-libdc1394"
    "--${boolEn (fdk-aac != null)}-libfdk-aac"
    "--${boolEn (fontconfig != null)}-libfontconfig"
    "--${boolEn (flite != null)}-libflite"
    "--${boolEn (freetype != null)}-libfreetype"
    "--${boolEn (fribidi != null)}-libfribidi"
    "--${boolEn (game-music-emu != null)}-libgme"
    "--${boolEn (gsm != null)}-libgsm"
    #"--${boolEn (
    #  libiec61883 != null
    #  && libavc1394 != null
    #  && libraw1394 != null)}-libiec61883"
    "--disable-libiec61883"
    #"--${boolEn (ilbc != null)}-libilbc"
    "--disable-libilbc"
    (fflag "--${boolEn (jack2_lib != null)}-libjack" "3.5")
    "--${boolEn (kvazaar != null)}-libkvazaar"
    "--${boolEn (libmodplug != null)}-libmodplug"
    "--${boolEn (lame != null)}-libmp3lame"
    (deprfflag null "3.3" "--disable-libnut")
    #"--${boolEn (opencore-amr != null)}-libopencore-amrnb"
    /**/"--disable-libopencore-amrnb"
    #"--${boolEn (opencore-amr != null)}-libopencore-amrwb"
    /**/"--disable-libopencore-amrwb"
    #"--${boolEn (opencv != null)}-libopencv"
    /**/"--disable-libopencv"
    "--${boolEn (openh264 != null)}-libopenh264"
    "--${boolEn (openjpeg != null)}-libopenjpeg"
    #"--${boolEn (libopenmpt != null)}-libopenmpt"
    /**/"--disable-libopenmpt"
    "--${boolEn (opus != null)}-libopus"
    "--${boolEn (pulseaudio_lib != null)}-libpulse"
    (fflag "--${boolEn (librsvg != null)}-librsvg" "3.4")
    "--${boolEn (rubberband != null)}-librubberband"
    "--${boolEn (rtmpdump != null)}-librtmp"
    (deprfflag null "3.3" "--disable-libschroedinger")
    #"--${boolEn (shine != null)}-libshine"
    /**/"--disable-libshine"
    "--${boolEn (samba_client != null)}-libsmbclient"
    "--${boolEn (snappy != null)}-libsnappy"
    "--${boolEn (soxr != null)}-libsoxr"
    "--${boolEn (speex != null)}-libspeex"
    "--${boolEn (libssh != null)}-libssh"
    #"--${boolEn (tesseract != null)}-libtesseract"
    /**/"--disable-libtesseract"
    "--${boolEn (libtheora != null)}-libtheora"
    #"--${boolEn (twolame != null)}-libtwolame"
    /**/"--disable-libtwolame"
    "--${boolEn (v4l_lib != null)}-libv4l2"
    (fflag "--${boolEn (v4l_lib != null)}-v4l2_m2m" "3.4")
    "--${boolEn (vid-stab != null)}-libvidstab"
    /**/(fflag "--disable-libvmaf" "3.4")
    "--${boolEn (vo-amrwbenc != null)}-libvo-amrwbenc"
    "--${boolEn (libvorbis != null)}-libvorbis"
    "--${boolEn (libvpx != null)}-libvpx"
    "--${boolEn (wavpack != null)}-libwavpack"
    "--${boolEn (libwebp != null)}-libwebp"
    "--${boolEn (x264 != null)}-libx264"
    "--${boolEn (x265 != null)}-libx265"
    "--${boolEn (xavs != null)}-libxavs"
    #"--${boolEn (xorg.libxcb != null)}-libxcb"
    "--${boolEn libxcbshmExtlib}-libxcb-shm"
    "--${boolEn libxcbxfixesExtlib}-libxcb-xfixes"
    "--${boolEn libxcbshapeExtlib}-libxcb-shape"
    "--${boolEn (xvidcore != null)}-libxvid"
    (fflag "--${boolEn (libxml2 != null)}-libxml2" "3.4")
    "--${boolEn (zimg != null)}-libzimg"
    "--${boolEn (zeromq4 != null)}-libzmq"
    #"--${boolEn (zvbi != null)}-libzvbi"
    /**/"--disable-libzvbi"
    "--${boolEn (xz != null)}-lzma"
    #"--${boolEn decklinkExtlib}-decklink"
    /**/"--disable-decklink"
    /**/(fflag "--disable-libndi_newtek" "3.4")
    "--disable-mediacodec"  # android
    (fflag "--${boolEn (libmysofa != null)}-libmysofa" "3.4")
    (deprfflag null "3.3" "--disable-netcdf")
    "--${boolEn (openal != null)}-openal"
    #"--${boolEn (opencl != null)}-opencl"
    /**/"--disable-opencl"
    "--${boolEn (opengl-dummy != null && opengl-dummy.glx)}-opengl"
    "--${boolEn (openssl != null)}-openssl"
    /**/(fflag "--disable-sndio" "3.4")
    "--disable-schannel"  # Windows
    "--${boolEn (sdl != null)}-sdl"
    "--${boolEn (sdl != null)}-sdl2"
    "--disable-securetransport"
    #"--${boolEn (xorg.libX11 != null && xorg.libXv != null)}-xlib"
    "--${boolEn (zlib != null)}-zlib"
    /*
     *  Developer flags
     */
    "--${boolEn debugDeveloper}-debug"
    "--${boolEn optimizationsDeveloper}-optimizations"
    "--${boolEn extraWarningsDeveloper}-extra-warnings"
    "--${boolEn strippingDeveloper}-stripping"
    (fflag "--${boolEn (elem targetSystem platforms.linux)}-linux-perf" "3.4")
  ] ++ optionals (alsa-lib != null && flite != null) [
    # Flite requires alsa but the configure test under specifies
    # dependencies and fails without -lasound.
    "--extra-ldflags=-lasound"
  ];

  # Build qt-faststart executable
  postBuild = optionalString qtFaststartProgram ''
    make tools/qt-faststart
  '';

  postInstall = optionalString qtFaststartProgram ''
    install -D -m 755 -v 'tools/qt-faststart' "$out/bin/qt-faststart"
  '';

  passthru = {
    features = {
      cuda = nvidia-cuda-toolkit != null && nvidia-drivers != null;
    };
    srcVerification = assert channel != "9.9"; fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "FCF9 86EA 15E6 E293 A564  4F10 B432 2F04 D676 58D8";
    };
  };

  meta = with lib; {
    description = "Complete solution to record, convert & stream audio/video";
    homepage = http://www.ffmpeg.org/;
    license = (
      if nonfreeLicensing then
        licenses.unfreeRedistributable
      else if version3Licensing then
        licenses.gpl3
      else if gplLicensing then
        licenses.gpl2Plus
      else
        licenses.lgpl21Plus
    );
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
