#!/bin/bash
# run-host.sh [java args...] - MC 1.12.2 + OptiFine on the desktop JVM through the Pojav LWJGL2-on-LWJGL3 layer,
# off-screen (xvfb, software GL). Same classpath the native image is built from.
cd "$(dirname "$0")"
CP=mc-optifine.jar:lwjgl3/pojav-noglfw.jar:lwjgl3/lwjgl-glfw-3.3.3.jar:$(find game/libraries -name '*.jar' | sort | tr '\n' ':')
mkdir -p run
exec xvfb-run -a -s "-screen 0 1280x720x24" ~/graalvm-25/x64/bin/java -Xmx1g -Dorg.lwjgl.librarypath=$PWD/natives-x64 "$@" \
  -cp "$CP" net.minecraft.client.main.Main --username etonedemid --version 1.12.2 --gameDir run --assetsDir game/assets \
  --assetIndex 1.12 --uuid 00000000000000000000000000000000 --accessToken 0 --userType legacy --versionType release --width 1280 --height 720
