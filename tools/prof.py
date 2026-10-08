#!/usr/bin/env python3
"""prof.py PROF.TXT ELF [TID] - read the runtime's sampling profile (lx_thread.c): per thread, the hottest stacks and
the functions that are on the stack most often (inclusive), symbolized against the ELF (nearest symbol from nm, so
asm functions without debug info resolve too)."""
import bisect, collections, re, subprocess, sys

prof, elf = sys.argv[1], sys.argv[2]
want = sys.argv[3] if len(sys.argv) > 3 else None
syms = []
for line in subprocess.run(['aarch64-none-elf-nm', '-n', elf], capture_output=True, text=True).stdout.splitlines():
    p = line.split()
    if len(p) == 3 and p[1] in 'TtWw': syms.append((int(p[0], 16), p[2]))
addrs = [a for a, _ in syms]
link = dict((n, a) for a, n in syms)

head = open(prof).readline()
base = int(re.search(r'lx_prof_start=(0x[0-9a-f]+)', head).group(1), 16) - link['lx_prof_start']

def name(a):
    o = a - base
    i = bisect.bisect_right(addrs, o) - 1
    if i < 0 or o > 0x10000000: return hex(a)
    n = syms[i][1]
    n = re.sub(r'_[A-Za-z0-9]{22}$', '', n)   # SVM's hash suffix
    return n

rows = []
for line in open(prof):
    if line.startswith('#'): continue
    p = line.split()
    rows.append((int(p[0]), p[1], [int(x, 16) for x in p[2:]]))
print(head.strip())
threads = collections.Counter()
for c, t, _ in rows: threads[t] += c
for t, tot in threads.most_common():
    if want and t != want: continue
    if not want and tot < threads.most_common(1)[0][1] * 0.2: continue
    print(f'\n=== tid {t}: {tot} samples')
    incl = collections.Counter()
    for c, tt, st in rows:
        if tt != t: continue
        for n in set(name(a) for a in st): incl[n] += c
    print(' on stack (inclusive):')
    for n, c in incl.most_common(25): print(f'  {100 * c / tot:5.1f}%  {n[:100]}')
    print(' top stacks:')
    for c, tt, st in sorted((r for r in rows if r[1] == t), key=lambda r: -r[0])[:8]:
        print(f'  {100 * c / tot:5.1f}%  ' + ' < '.join(name(a)[:45] for a in st))
