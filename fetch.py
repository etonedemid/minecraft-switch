#!/usr/bin/env python3
"""fetch.py VERSION - client jar, libraries (no natives) and assets from Mojang's manifest into ./game"""
import concurrent.futures, hashlib, json, os, sys, urllib.request

V = sys.argv[1] if len(sys.argv) > 1 else '1.12.2'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'game')

def get(url, path=None, sha1=None):
    if path and os.path.exists(path) and (not sha1 or hashlib.sha1(open(path, 'rb').read()).hexdigest() == sha1):
        return open(path, 'rb').read()
    data = urllib.request.urlopen(url, timeout=60).read()
    if sha1 and hashlib.sha1(data).hexdigest() != sha1:
        raise SystemExit('sha1 mismatch: ' + url)
    if path:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path + '.part', 'wb').write(data); os.replace(path + '.part', path)
    return data

man = json.loads(get('https://piston-meta.mojang.com/mc/game/version_manifest_v2.json'))
ver = json.loads(get(next(v['url'] for v in man['versions'] if v['id'] == V), f'{OUT}/{V}.json'))
c = ver['downloads']['client']
get(c['url'], f'{OUT}/{V}.jar', c['sha1'])
libs = []
for l in ver['libraries']:
    a = l.get('downloads', {}).get('artifact')
    if a and 'natives' not in l and all(r.get('action') == 'allow' and r.get('os', {}).get('name', 'linux') == 'linux' for r in l.get('rules', [])):
        libs.append((a['url'], f"{OUT}/libraries/{a['path']}", a['sha1']))
ai = ver['assetIndex']
idx = json.loads(get(ai['url'], f"{OUT}/assets/indexes/{ai['id']}.json", ai['sha1']))
objs = [(f"https://resources.download.minecraft.net/{o['hash'][:2]}/{o['hash']}", f"{OUT}/assets/objects/{o['hash'][:2]}/{o['hash']}", o['hash'])
        for o in idx['objects'].values()]
with concurrent.futures.ThreadPoolExecutor(16) as ex:
    list(ex.map(lambda t: get(*t), libs + objs))
print(f'{V}: {len(libs)} libraries, {len(objs)} asset objects, main {ver["mainClass"]}')
print('args:', ver.get('minecraftArguments'))
