#!/bin/bash
# build-a64.sh [flags...] - aarch64 relocatable native image of MC 1.12.2 + OptiFine for the Horizon link (prelink-j.sh /
# build-nro.sh in ~/pz-switch). Same settings as PZ: glibc target linked against musl-nx, no isolates (image heap used
# in place), no mremap, CAP cache from qemu.
cd "$(dirname "$0")"
CP=$PWD/mc-optifine.jar:$PWD/lwjgl3/pojav-noglfw.jar:$PWD/lwjgl3/lwjgl-glfw-3.3.3.jar:$(find $PWD/game/libraries -name '*.jar' | sort | tr '\n' ':')
mkdir -p build-a64 && cd build-a64
rm -rf tmp mc.o
~/graalvm-25/x64/bin/native-image -cp "$CP" \
  -H:ConfigurationFileDirectories=$OLDPWD/config,$OLDPWD/config-gen --no-fallback -J-Xmx24g \
  --enable-native-access=ALL-UNNAMED --enable-url-protocols=http,https -H:+ReportExceptionStackTraces -H:+AddAllCharsets \
  "$@" --target=linux-aarch64 -march=compatibility -H:+UnlockExperimentalVMOptions -H:-ForeignAPISupport \
  -H:-MremapImageHeap -H:-SpawnIsolates -H:+UseCAPCache -H:CAPCacheDir=$HOME/pz-switch/cap-a64 \
  -H:CCompilerPath=/usr/bin/aarch64-linux-gnu-gcc -H:+ExitAfterRelocatableImageWrite -H:TempDirectory=$PWD/tmp -o mc net.minecraft.client.main.Main
# the relocatable object stays in the SVM temp directory
cp tmp/SVM-*/mc.o mc.o && ls -la mc.o
