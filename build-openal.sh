#!/bin/bash
# build-openal.sh - openal-soft 1.18.2 (the last C release; later ones are C++17 and the Java side has no C++ runtime)
# against musl, OSS backend only: /dev/dsp is emulated by the Horizon side on audout (lx_fs.c / lx_alsa.c).
# Result: natives-out/openal.o, one relocatable object for lx_dl's "libopenal.so".
set -e
cd ~/mc-switch
S=deps/openal-soft-1.18.2; B=deps/openal-build; O=natives-out; M=~/pz-switch/deps/musl-aarch64/bin/musl-gcc
# kernel UAPI headers musl's sys/soundcard.h needs (arch-independent; this musl toolchain has none)
K=deps/kinc; mkdir -p $K/linux $K/asm $K/asm-generic
cp /usr/include/linux/{soundcard,ioctl,patchkey}.h $K/linux/; cp /usr/include/asm-generic/ioctl.h $K/asm-generic/
echo "#include <asm-generic/ioctl.h>" > $K/asm/ioctl.h
cat > deps/musl-toolchain.cmake <<EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER $M)
set(CMAKE_C_FLAGS "-fPIE -O2 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -isystem /home/etonedemid/mc-switch/deps/kinc")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF
rm -rf $B && mkdir -p $B
cmake -S $S -B $B -DCMAKE_TOOLCHAIN_FILE=$PWD/deps/musl-toolchain.cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DLIBTYPE=STATIC \
  -DALSOFT_UTILS=OFF -DALSOFT_EXAMPLES=OFF -DALSOFT_TESTS=OFF -DALSOFT_CONFIG=OFF -DALSOFT_HRTF_DEFS=OFF -DALSOFT_AMBDEC_PRESETS=OFF \
  -DALSOFT_NO_CONFIG_UTIL=ON -DALSOFT_DLOPEN=OFF -DALSOFT_REQUIRE_OSS=ON -DALSOFT_BACKEND_ALSA=OFF -DALSOFT_BACKEND_PULSEAUDIO=OFF \
  -DALSOFT_BACKEND_JACK=OFF -DALSOFT_BACKEND_PORTAUDIO=OFF -DALSOFT_BACKEND_SNDIO=OFF -DALSOFT_BACKEND_SOLARIS=OFF \
  -DALSOFT_BACKEND_QSA=OFF -DALSOFT_BACKEND_WAVE=OFF -DALSOFT_CPUEXT_NEON=ON -DOSS_INCLUDE_DIR=$HOME/pz-switch/deps/musl-aarch64/include > $B/configure.log
make -C $B -j$(nproc) OpenAL 2>&1 | grep -E "error" | head
aarch64-linux-gnu-ld -r --whole-archive $B/libopenal.a -o $O/openal.o
echo "openal.o: $(aarch64-linux-gnu-nm --defined-only $O/openal.o | grep -c ' T al') al* functions; undefined: $(aarch64-linux-gnu-nm -u $O/openal.o | awk '{print $2}' | tr '\n' ' ' | cut -c1-300)"
