# minecraft-switch

Minecraft Java 1.12.2 + OptiFine compiled ahead-of-time with GraalVM `native-image` and linked into a Nintendo Switch homebrew app (`mc.nro`).

## Using a prebuilt `mc.nro`

1. Copy `mc.nro` to `sdmc:/switch/`.
2. Create `sdmc:/mc/` on the SD card
3. Copy in your own files from a PC install of 1.12.2 (`.minecraft/`):
   - `saves/` → `sdmc:/mc/saves/`
   - `resourcepacks/` → `sdmc:/mc/resourcepacks/`
   - `assets/` (`indexes/1.12.json` + `objects/`) → `sdmc:/mc/assets/`. These hold sounds and languages

Notes:
- Only 1.12.2 data works. Mods, other versions, and a different `minecraft.jar` won't load: the game code is compiled into the NRO and can't be swapped at runtime.
- Online servers need a real account login; offline play and LAN work without one.


## Requirements for building

**Sources under `deps/`:**
- `deps/lwjgl3-333`: LWJGL 3.3.3 source
- `deps/openal-soft-1.18.2`: openal-soft 1.18.2 source

**You supply these :**
- `mc-optifine.jar`: the 1.12.2 client jar with OptiFine merged in as a jar mod, `compat/org/lwjgl/Sys.java` compiled in, and recipe/advancement classes patched with `tools/LdcPatch.java` (`jar` → `resource`)
- `lwjgl3/pojav-noglfw.jar` (PojavLauncher's LWJGL2-on-3 compat layer) and `lwjgl3/lwjgl-glfw-3.3.3.jar`
- `natives-x64/`: desktop LWJGL 3.3.3 natives (desktop runs only)

You also need a legitimate Minecraft copy. `fetch.py` downloads the game from Mojang.

## Build

```sh
python3 fetch.py 1.12.2          # client, libraries, assets -> game/
# make mc-optifine.jar and lwjgl3/ (see above)

./run-host.sh                    # optional: run on the desktop JVM
./build-x64.sh                   # optional: desktop native image -> build-x64/mc

./build-natives.sh               # LWJGL natives (musl, aarch64) -> natives-out/
./build-openal.sh                # OpenAL -> natives-out/openal.o
./build-a64.sh                   # aarch64 relocatable image -> build-a64/mc.o
./build-nro.sh                   # link -> mc.nro

