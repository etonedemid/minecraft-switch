#!/bin/bash
# build-natives.sh - LWJGL 3.3.3 natives (the version the Pojav LWJGL2 compat classes are built on) against musl, one
# relocatable object per Linux .so name: natives-out/lwjgl.o (+libffi with lx_ffi closures), lwjgl_opengl.o, lwjgl_stb.o.
# JNI_OnLoad in each becomes lxonload_<lib> for lx_dl. Toolchain, libffi and lx_ffi.c come from the PZ port.
set -e
P=~/pz-switch; D=$P/deps; L=~/mc-switch/deps/lwjgl3-333/modules/lwjgl; O=~/mc-switch/natives-out; G=~/graalvm-25/x64
CC="$D/musl-aarch64/bin/musl-gcc"
CFLAGS="-c -std=gnu11 -O2 -fPIE -pthread -DNDEBUG -DLWJGL_LINUX -DLWJGL_arm64 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 \
  -I$G/include -I$G/include/linux -I$L/core/src/main/c -I$L/core/src/main/c/linux -w"
mkdir -p $O && rm -rf $O/tmp && mkdir -p $O/tmp
build() {  # build <lib> <extra flags> <files...>
  local lib=$1 fl=$2; shift 2; local objs=()
  mkdir -p $O/tmp/$lib
  for f in "$@"; do o=$O/tmp/$lib/$(basename "$f" .c).o; $CC $CFLAGS $fl "$f" -o $o & objs+=($o); done
  wait
  aarch64-linux-gnu-ld -r -o $O/$lib.o "${objs[@]}" ${EXTRA_OBJS}
  aarch64-linux-gnu-objcopy --redefine-sym JNI_OnLoad=lxonload_$lib --redefine-sym JNI_OnUnload=lxonunload_$lib $O/$lib.o
  echo "$lib.o: ${#objs[@]} files, undefined: $(aarch64-linux-gnu-nm -u $O/$lib.o | awk '{print $2}' | tr '\n' ' ' | cut -c1-400)"
}
FFI=$D/libffi-3.5.2/aarch64-unknown-linux-gnu
$CC -c -O2 -fPIE $P/horizon/jside/lx_ffi.c -o $O/tmp/lx_ffi.o
mkdir -p $O/tmp/ffi && (cd $O/tmp/ffi && ar x $FFI/.libs/libffi.a && rm -f closures.o tramp.o)
EXTRA_OBJS="$O/tmp/lx_ffi.o $(ls $O/tmp/ffi/*.o | tr '\n' ' ')" build lwjgl "-I$L/core/src/main/c/libffi -I$L/core/src/main/c/libffi/aarch64 -I$FFI/include" \
  $L/core/src/main/c/*.c $(ls $L/core/src/generated/c/*.c) $(ls $L/core/src/generated/c/linux/*.c | grep -v liburing)
EXTRA_OBJS= build lwjgl_opengl "-I$L/opengl/src/main/c" $(ls $L/opengl/src/generated/c/*.c | grep -vE 'GLX|WGL')
EXTRA_OBJS= build lwjgl_stb "-include string.h -I$L/stb/src/main/c -isystem$L/stb/src/main/c" $L/stb/src/generated/c/*.c
