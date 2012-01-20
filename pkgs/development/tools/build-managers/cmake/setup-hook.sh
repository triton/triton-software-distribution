addCMakeParams() {
    addToSearchPath CMAKE_PREFIX_PATH $1
}

fixCmakeFiles() {
    echo "fixing cmake files..."
    find "$1" \( -type f -name "*.cmake" -o -name "*.cmake.in" -o -name CMakeLists.txt \) -print |
        while read fn; do
            sed -e 's|/usr|/var/empty|g' -e 's|/opt|/var/empty|g' < "$fn" > "$fn.tmp"
            mv "$fn.tmp" "$fn"
        done
}

cmakeConfigurePhase() {
    eval "$preConfigure"

    if [ -z "$dontFixCmake" ]; then
        fixCmakeFiles .
    fi

    if [ -z "$dontUseCmakeBuildDir" ]; then
        mkdir -p build
        cd build
        cmakeDir=..
    fi

    if [ -z "$dontAddPrefix" ]; then
        cmakeFlags="-DCMAKE_INSTALL_PREFIX=$prefix $cmakeFlags"
    fi

    if [ -n "$crossConfig" ]; then
        # By now it supports linux builds only. We should set the proper
        # CMAKE_SYSTEM_NAME otherwise.
        # http://www.cmake.org/Wiki/CMake_Cross_Compiling
        cmakeFlags="-DCMAKE_CXX_COMPILER=$crossConfig-g++ -DCMAKE_C_COMPILER=$crossConfig-gcc $cmakeFlags"
    fi

    # Avoid cmake resetting the rpath of binaries, on make install
    cmakeFlags="-DCMAKE_SKIP_BUILD_RPATH=ON $cmakeFlags"

    echo "cmake flags: $cmakeFlags ${cmakeFlagsArray[@]}"

    cmake ${cmakeDir:-.} $cmakeFlags ${cmakeFlagsArray[@]}

    eval "$postConfigure"
}

if [ -z "$dontUseCmakeConfigure" ]; then
    configurePhase=cmakeConfigurePhase
fi

if [ -n "$crossConfig" ]; then
    crossEnvHooks+=(addCMakeParams)
else
    envHooks+=(addCMakeParams)
fi
