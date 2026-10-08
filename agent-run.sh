#!/bin/bash
# agent-run.sh start|stop|click X Y|key K|type TEXT|shot FILE - MC on the desktop JVM under the native-image tracing agent,
# on Xvfb :77, to collect reflection/JNI/resource metadata (into config/) while it is driven through menus and a world.
cd "$(dirname "$0")"
export DISPLAY=:77
case "$1" in
start)
    pgrep -x Xvfb >/dev/null || { rm -f /tmp/.X77-lock /tmp/.X11-unix/X77; setsid Xvfb :77 -screen 0 1280x720x24 >/dev/null 2>&1 & }
    for i in $(seq 20); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.5; done
    CP=mc-optifine.jar:lwjgl3/pojav-noglfw.jar:lwjgl3/lwjgl-glfw-3.3.3.jar:$(find game/libraries -name '*.jar' | sort | tr '\n' ':')
    mkdir -p run config
    nohup ~/graalvm-25/x64/bin/java -agentlib:native-image-agent=config-merge-dir=config -Xmx1g \
      -Dorg.lwjgl.librarypath=$PWD/natives-x64 -cp "$CP" net.minecraft.client.main.Main --username etonedemid --version 1.12.2 \
      --gameDir run --assetsDir game/assets --assetIndex 1.12 --uuid 00000000000000000000000000000000 --accessToken 0 \
      --userType legacy --versionType release --width 1280 --height 720 > agent.log 2>&1 &
    ;;
stop) pkill -x java; sleep 3 ;;   # Xvfb stays up for the next start
click) xdotool mousemove "$2" "$3" click 1 ;;
key) xdotool key "$2" ;;
type) xdotool type --delay 80 "$2" ;;
shot) import -window root "$2" ;;
esac
