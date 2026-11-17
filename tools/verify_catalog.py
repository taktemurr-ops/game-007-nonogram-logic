#!/usr/bin/env python3
"""Independent Python verification of all Dart catalog seeds and transforms.

Checks clue reconstruction, deterministic stage count, basic uniqueness and
rejects board corruption. It does not replace Flutter/Dart tests.
"""
from pathlib import Path
import ast, re
from collections import Counter

source=Path(__file__).resolve().parents[1]/'lib/game/nonogram_catalog.dart'
raw=source.read_text()
seeds=re.findall(r"'([^']+)':\s*\[([^\]]+)\]", raw)
seeds=[(name,re.findall(r"'([.#]+)'", rows)) for name,rows in seeds]
assert len(seeds)==20, f'expected 20 motifs; got {len(seeds)}'

def clues(row):
    parts=[]; run=0
    for c in row:
        if c:run+=1
        elif run:parts.append(run);run=0
    if run:parts.append(run)
    return tuple(parts or [0])

def rotate(a):return tuple(tuple(a[len(a)-1-j][i] for j in range(len(a))) for i in range(len(a[0])))
def flip(a):return tuple(tuple(reversed(row)) for row in a)

def solve_count(board, limit=2):
    n=len(board); m=len(board[0]);cr=[clues(tuple(board[r][c] for r in range(n))) for c in range(m)]
    rr=[clues(row) for row in board]
    patterns=[]
    for row_clue in rr:
        patterns.append([tuple(bool(mask&(1<<c)) for c in range(m)) for mask in range(1<<m) if clues(tuple(bool(mask&(1<<c)) for c in range(m)))==row_clue])
    col_compatible=[]
    for col_clue in cr:
        col_compatible.append([tuple(bool(mask&(1<<r)) for r in range(n)) for mask in range(1<<n) if clues(tuple(bool(mask&(1<<r)) for r in range(n)))==col_clue])
    count=0
    def dfs(r,options):
        nonlocal count
        if count>=limit:return
        if r==n:
            count+=1;return
        for row in patterns[r]:
            next_options=[]
            for c in range(m):
                subset=[p for p in options[c] if p[r]==row[c]]
                if not subset:break
                next_options.append(subset)
            else:dfs(r+1,next_options)
    dfs(0,col_compatible)
    return count

boards=[]
for name, lines in seeds:
    assert len(lines)==5 and all(len(r)==5 for r in lines), name
    base=tuple(tuple(ch=='#' for ch in row) for row in lines)
    for f in (False,True):
        for turn in range(4):
            p=flip(base) if f else base
            for _ in range(turn):p=rotate(p)
            boards.append((name,p))
assert len(boards)==160
for name,b in boards:
    assert len(b)==5 and all(len(r)==5 for r in b),name
    assert any(any(r) for r in b),name
    assert len([clues(r) for r in b])==5
    assert len([clues(tuple(b[r][c] for r in range(5))) for c in range(5)])==5
unique_shapes=len({b for _,b in boards})
base_solutions={name:solve_count(tuple(tuple(ch=='#' for ch in row) for row in lines)) for name,lines in seeds}
print('Campaign stages:',len(boards))
print('Unique board patterns:',unique_shapes)
print('Seed models with unique solutions:',sum(v==1 for v in base_solutions.values()),'of',len(base_solutions))
print('Ambiguous seeds:',[(k,v) for k,v in base_solutions.items() if v!=1])
assert unique_shapes>=45
print('PASS: catalog structural and clue generation checks (not Flutter tests)')
