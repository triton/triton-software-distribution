{ stdenv
, autoreconfHook
, bison
, fetchTritonPatch
, fetchurl
, flex
, intltool
, python2
, python2Packages
, substituteAll

#, libxml2Python

, expat
, file
, libclc
, libdrm
, libelf
, libffi
, libomxil-bellagio
#, libva
, libvdpau
, llvm
, systemd_lib
, wayland
, xorg

, grsecEnabled
# Texture floats are patented, see docs/patents.txt
, enableTextureFloats ? false
}:

/* Packaging design:
 * - The basic mesa ($out) contains headers and libraries (GLU is in mesa_glu now).
 *   This or the mesa attribute (which also contains GLU) are small (~ 2 MB,
 *   mostly headers) and are designed to be the buildInput of other packages.
 * - DRI drivers are compiled into $drivers output, which is much bigger and
 *   depends on LLVM. These should be searched at runtime in
 *   "/run/opengl-driver-${stdenv.targetSystem}/lib/*" and so are kind-of impure (given by NixOS).
 *   (I suppose on non-NixOS one would create the appropriate symlinks from there.)
 * - libOSMesa is in $osmesa (~4 MB)
 */

let
  inherit (stdenv.lib)
    enFlag
    head
    optional
    optionals
    optionalString
    splitString;
in

let
  # this is the default search path for DRI drivers
  driverSearchPath = "/run/opengl-driver-${stdenv.targetSystem}";
in

stdenv.mkDerivation rec {
  name = "mesa-noglu-${version}";
  version = "11.2.1";

  src =  fetchurl {
    urls = [
      "ftp://ftp.freedesktop.org/pub/mesa/${version}/mesa-${version}.tar.xz"
      # Tarballs for old releases are moved to another directory
      ("ftp://ftp.freedesktop.org/pub/mesa/older-versions/"
        + head (splitString "." version)
        + ".x/${version}/mesa-${version}.tar.xz")
      "https://launchpad.net/mesa/trunk/${version}/+download/mesa-${version}.tar.xz"
    ];
    allowHashOutput = false;  # Provided by upstream directly
    sha256 = "a65207e9ae5c5f1c29f863c6a2cc98a7ab99762a24b82a248337f0ea9cfce01b";
  };

  nativeBuildInputs = [
    autoreconfHook
    bison
    file
    flex
    intltool
    python2
    python2Packages.Mako
    xorg.makedepend
  ];

  buildInputs = [
    expat
    libclc
    libdrm
    libelf
    libffi
    libomxil-bellagio
    # FIXME: recursive dependency
    #libva
    libvdpau
    #libxml2Python
    llvm
    systemd_lib
    wayland
    xorg.dri2proto
    xorg.dri3proto
    xorg.glproto
    xorg.libX11
    xorg.libxcb
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libxshmfence
    xorg.libXt
    xorg.libXvMC
    xorg.libXxf86vm
    xorg.presentproto
  ];

  patches = [
    # fix for grsecurity/PaX
    (fetchTritonPatch {
      rev = "02cecd54589d7a77a38e4c183c24ffd30efdc9a7";
      file = "mesa/glx_ro_text_segm.patch";
      sha256 = "3f91c181307f7275f3c53ec172450b3b51129d796bacbca92f91e45acbbc861e";
    })
    (fetchTritonPatch {
      rev = "02cecd54589d7a77a38e4c183c24ffd30efdc9a7";
      file = "mesa/dlopen-absolute-paths.patch";
      sha256 = "aee62e3fcb535af73ba152c56c389d573efd6271f9aae702c0be98584643c518";
    })
  ];

  postPatch = ''
    patchShebangs .
  '' +
  /* Set runtime driver search path */ ''
    sed -i src/egl/main/egldriver.c \
      -e 's,_EGL_DRIVER_SEARCH_DIR,"${driverSearchPath}",'

  '' +
  /* Substitute the path to udev */ ''
    grep -q '@udev@' src/loader/loader.c
    sed -i 's,@udev@,${systemd_lib},g' src/loader/loader.c
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--enable-largefile"
    "--disable-debug"
    # slight performance degradation, enable only for grsec
    (enFlag "glx-rts" grsecEnabled null)
    "--disable-mangling"
    (enFlag "texture-float" enableTextureFloats null)
    "--enable-asm"
    # TODO: add selinux support
    "--disable-selinux"
    "--enable-opengl"
    "--enable-gles1"
    "--enable-gles2"
    "--enable-dri"
    "--enable-dri3"
    "--enable-glx"
    "--disable-osmesa"
    "--enable-gallium-osmesa" # used by wine
    "--enable-egl"
    "--enable-xa" # used in vmware driver
    "--enable-gbm"
    "--enable-nine" # Direct3D in Wine
    "--enable-xvmc"
    "--enable-vdpau"
    "--enable-omx"
    #"--enable-va"
    # TODO: Figure out how to enable opencl without having a
    #       runtime dependency on clang
    # FIXME: fix opencl
    #        llvm/invocation.cpp:25:45: fatal error: \
    #        clang/Frontend/CompilerInstance.h: No such file
    "--disable-opencl"
    "--disable-opencl-icd"
    "--disable-xlib-glx"
    "--disable-r600-llvm-compiler"
    "--disable-gallium-tests"
    "--enable-shared-glapi"
    "--enable-sysfs"
    "--enable-driglx-direct" # seems enabled anyway
    "--enable-glx-tls"
    "--disable-glx-read-only-text"
    "--enable-gallium-llvm"
    "--disable-llvm-shared-libs"

    #gl-lib-name=GL
    #osmesa-libname=OSMesa
    "--with-gallium-drivers=svga,i915,ilo,r300,r600,radeonsi,nouveau,freedreno,swrast"
    "--with-dri-driverdir=$(drivers)/lib/dri"
    "--with-dri-searchpath=${driverSearchPath}/lib/dri"
    "--with-dri-drivers=i915,i965,nouveau,radeon,r200,swrast"
    #osmesa-bits=8
    #"--with-clang-libdir=${llvm}/lib"
    "--with-egl-platforms=x11,wayland,drm"
    #llvm-prefix
    #xvmc-libdir
    #vdpau-libdir
    #omx-libdir
    #va-libdir
    #d3d-libdir
  ];

  installFlags = [
    "sysconfdir=\${out}/etc"
    "localstatedir=\${TMPDIR}"
  ];

  # move gallium-related stuff to $drivers, so $out doesn't depend on LLVM;
  #   also move libOSMesa to $osmesa, as it's relatively big
  # ToDo: probably not all .la files are completely fixed, but it shouldn't matter
  postInstall = ''
    mv -t "$drivers/lib/" \
      $out/lib/libXvMC* \
      $out/lib/d3d \
      $out/lib/vdpau \
      $out/lib/libxatracker*

    mkdir -p {$osmesa,$drivers}/lib/pkgconfig
    mv -t $osmesa/lib/ \
      $out/lib/libOSMesa*

    mv -t $drivers/lib/pkgconfig/ \
      $out/lib/pkgconfig/xatracker.pc

    mv -t $osmesa/lib/pkgconfig/ \
      $out/lib/pkgconfig/osmesa.pc

  '' + /* fix references in .la files */ ''
    sed "/^libdir=/s,$out,$osmesa," -i \
      $osmesa/lib/libOSMesa*.la

  '' + /* work around bug #529, but maybe $drivers should also be patchelf'd */ ''
    find $drivers/ $osmesa/ -type f -executable -print0 | xargs -0 strip -S || true

  '' + /* add RPATH so the drivers can find the moved libgallium and libdricore9 */ ''
    for lib in $drivers/lib/*.so* $drivers/lib/*/*.so*; do
      if [[ ! -L "$lib" ]]; then
        patchelf --set-rpath "$(patchelf --print-rpath $lib):$drivers/lib" "$lib"
      fi
    done
  '' + /* set the default search path for DRI drivers; used e.g. by X server */ ''
    substituteInPlace "$out/lib/pkgconfig/dri.pc" --replace '$(drivers)' "${driverSearchPath}"
  '';

  outputs = [ "out" "drivers" "osmesa" ];

  doCheck = false;

  # This breaks driver loading
  bindnow = false;

  passthru = {
    inherit driverSearchPath;
    srcVerified = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyId = "2CEB490D";
      pgpKeyFingerprint = "8703 B670 0E7E E06D 7A39  B8D6 EDAE 37B0 2CEB 490D";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "An open source implementation of OpenGL";
    homepage = http://www.mesa3d.org/;
    license = licenses.mit;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
