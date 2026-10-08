#!/bin/bash
# build-x64.sh [native-image flags...] - desktop native image of MC 1.12.2 + OptiFine (validation before the Switch build)
cd "$(dirname "$0")"
CP=mc-optifine.jar:lwjgl3/pojav-noglfw.jar:lwjgl3/lwjgl-glfw-3.3.3.jar:$(find game/libraries -name '*.jar' | sort | tr '\n' ':')
mkdir -p build-x64
exec ~/graalvm-25/x64/bin/native-image -cp "$CP" -H:ConfigurationFileDirectories=$PWD/config,$PWD/config-gen --no-fallback -J-Xmx24g \
  --enable-native-access=ALL-UNNAMED --enable-url-protocols=http,https -H:+ReportExceptionStackTraces -H:+AddAllCharsets "$@" \
  -o build-x64/mc net.minecraft.client.main.Main
