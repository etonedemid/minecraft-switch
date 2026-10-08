#!/usr/bin/env python3
"""gen-config.py JAR OUTDIR - reflection metadata for every class in the game jar: all declared constructors (entities,
tile entities, packets and GUI screens are instantiated reflectively, and a tracing run only meets the ones it happened
to spawn), plus all declared fields and methods for OptiFine's Reflector, which probes vanilla members by name."""
import json, os, sys, zipfile

jar, out = sys.argv[1], sys.argv[2]
names = sorted(n[:-6].replace('/', '.') for n in zipfile.ZipFile(jar).namelist()
               if n.endswith('.class') and not n.startswith('META-INF/') and n != 'module-info.class')
refl = [{'type': n, 'allDeclaredConstructors': True, 'allDeclaredFields': True, 'allDeclaredMethods': True} for n in names]
os.makedirs(out, exist_ok=True)
# every asset and root resource: a tracing run only embeds what it happened to load (unseen mobs came out purple/black)
res = [{'glob': 'assets/**'}, {'glob': '*'}]
json.dump({'reflection': refl, 'resources': res}, open(os.path.join(out, 'reachability-metadata.json'), 'w'), indent=1)
print(f'{len(refl)} classes')
