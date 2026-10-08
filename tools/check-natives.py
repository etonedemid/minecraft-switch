#!/usr/bin/env python3
"""check-natives.py OBJ... -- JAR... : native methods of org.lwjgl classes in the jars with no JNI symbol in the objects"""
import struct, subprocess, sys, zipfile
src = open('/home/etonedemid/pz-switch/gen-natives.py').read()
ns = {}; exec('import struct\n' + src[src.index('def natives'):src.index('# symbols already provided')], ns)
objs = sys.argv[1:sys.argv.index('--')]; jars = sys.argv[sys.argv.index('--') + 1:]
have = set()
for o in objs:
    have |= set(l.split()[-1] for l in subprocess.run(['aarch64-linux-gnu-nm', '--defined-only', o], capture_output=True, text=True).stdout.splitlines() if l.strip())
need = {}
for j in jars:
    z = zipfile.ZipFile(j)
    for n in z.namelist():
        if not (n.endswith('.class') and n.startswith('org/lwjgl/')): continue
        try: cls, ms = ns['natives'](z.read(n))
        except Exception: continue
        for name, desc in ms:
            base = 'Java_' + ns['mangle'](cls) + '_' + ns['mangle'](name)
            need.setdefault(cls.split('/')[2], set()).add((base, base + '__' + ns['mangle'](desc[1:desc.index(')')])))
for mod, s in sorted(need.items()):
    miss = sorted(a for a, b in s if a not in have and b not in have)
    print(f'{mod}: {len(s)} natives, {len(miss)} missing', miss[:5])
