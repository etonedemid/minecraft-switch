#!/bin/bash
# build-nro.sh - Horizon link of MC 1.12.2 + OptiFine: natives glue + prelink of the Java side + NRO, with the PZ port's
# runtime (~/pz-switch/horizon: lxnx personality, GLFW/EGL shim, musl-nx). Needs build-a64.sh and build-natives.sh outputs.
set -e
cd ~/mc-switch
P=~/pz-switch; N=natives-out; M=$P/deps/musl-aarch64/bin/musl-gcc; S=~/graalvm-25/x64/lib/static/linux-aarch64/glibc
# JDK AWT family (ImageIO/Java2D for textures), one object per "library" so lx_dl's dlsym finds each JNI_OnLoad_<lib>
for l in awt awt_headless mlib_image javajpeg lcms; do
  aarch64-linux-gnu-ld -r --whole-archive $S/lib$l.a -o $N/jdk_$l.o
done
# both AWT and LWJGL define a global `jvm`; LWJGL only needs its own
aarch64-linux-gnu-objcopy --localize-symbol=jvm $N/lwjgl.o   # AWT shares its own between libawt and libawt_headless
JDK="$N/jdk_awt.o $N/jdk_awt_headless.o $N/jdk_mlib_image.o $N/jdk_javajpeg.o $N/jdk_lcms.o"
$M -c -O2 -fPIE $P/horizon/jside/lx_compat.c -o $N/lx_compat.o
# every jar of the classpath in one for gen-natives' native-method scan
rm -rf $N/alljar && mkdir -p $N/alljar
for j in mc-optifine.jar lwjgl3/pojav-noglfw.jar lwjgl3/lwjgl-glfw-3.3.3.jar $(find game/libraries -name '*.jar'); do
  (cd $N/alljar && unzip -qo ../../$j -x 'META-INF/*' 2>/dev/null || true)
done
(cd $N/alljar && rm -f ../all.jar && zip -qr ../all.jar .)
python3 $P/gen-natives.py $N/all.jar $N $N/lwjgl.o $N/lwjgl_opengl.o $N/lwjgl_stb.o $JDK $N/lx_compat.o --libc=$P/deps/musl-nx-out/lib/libc.a
$M -c -O2 -fPIE $N/jni_stubs.S -o $N/jni_stubs.o
$M -c -O2 -fPIE -w $N/dltab.c -o $N/dltab.o
$M -c -O2 -fPIE $P/horizon/jside/lx_dl.c -o $N/lx_dl.o
EXTRA_J_LIBS="$N/lx_dl.o $N/dltab.o $N/jni_stubs.o $N/lwjgl.o $N/lwjgl_opengl.o $N/lwjgl_stb.o $JDK" $P/prelink-j.sh build-a64/mc.o build-a64/j.o
cd $P/horizon/app && rm -f mc.elf mc.nro
make NAME=mc TITLE="Minecraft" BUILD=build-mc GL=1 J_OBJ=$HOME/mc-switch/build-a64/j.o DEFINES='-DLX_ROOT=\"sdmc:/mc\"' \
  EXTRA_LDFLAGS="-Wl,-z,notext -Wl,--wrap=fatalThrow,--wrap=diagAbortWithResult" -j8 2>&1 | grep -E 'error|undefined|built'
mv mc.nro mc.elf ~/mc-switch/ 2>/dev/null; ls -la ~/mc-switch/mc.nro
