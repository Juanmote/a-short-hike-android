#!/usr/bin/env python3
"""Genera tools/texformats.tsv: para cada textura del proyecto, el formato que tiene en la versión de PC.
Las DXT pasan a RGBA32 (la APK genérica las descomprime de la copia del usuario).
Uso: gen_texformats.py UnityProject/Assets  CARPETA_AShortHike_Data  salida.tsv"""
import os, re, sys
from collections import defaultdict
import UnityPy
from UnityPy.enums import TextureFormat

assets, data, out = sys.argv[1:4]
MAP = {"DXT1": "RGBA32", "DXT5": "RGBA32", "RGBA32": "RGBA32", "ARGB32": "ARGB32", "RGB24": "RGB24", "Alpha8": "Alpha8"}
env = UnityPy.load(data)
top = set(os.listdir(data))
pc = defaultdict(list)
for o in env.objects:
    if o.type.name != "Texture2D" or o.assets_file is None or os.path.basename(o.assets_file.name) not in top:
        continue
    t = o.read()
    if t.m_Width == 0:
        continue
    mips = getattr(t, "m_MipCount", 1) or 1
    pc[t.m_Name].append((TextureFormat(t.m_TextureFormat).name, mips > 1))
import glob
for b in glob.glob(os.path.join(data, "StreamingAssets", "aa", "**", "*.bundle"), recursive=True):
    for o in UnityPy.load(b).objects:
        if o.type.name != "Texture2D":
            continue
        t = o.read()
        if t.m_Width == 0:
            continue
        mips = getattr(t, "m_MipCount", 1) or 1
        pc[t.m_Name].append((TextureFormat(t.m_TextureFormat).name, mips > 1))
rows, missing = [], []
for root, _, files in os.walk(assets):
    if "/Resources/ASHTouch" in root or "/PortAndroid" in root or "/Cubemap" in root:
        continue
    for f in files:
        if not f.lower().endswith((".png", ".tga", ".exr")):
            continue
        stem = os.path.splitext(f)[0]
        cands = pc.get(stem) or pc.get(re.sub(r"_\d+$", "", stem))
        rel = os.path.relpath(os.path.join(root, f), os.path.dirname(assets))
        if not cands:
            missing.append(rel)
            continue
        fmt, mip = cands[0]
        if fmt not in MAP:
            missing.append(rel + " (" + fmt + ")")
            continue
        rows.append("%s\t%s\t%d" % (rel, MAP[fmt], 1 if mip else 0))
rows.sort()
with open(out, "w") as fh:
    fh.write("# ruta\tformato en Android\tmipmaps  (generado por tools/gen_texformats.py)\n" + "\n".join(rows) + "\n")
print("texturas:", len(rows), "sin pareja:", len(missing))
for m in missing:
    print("  ", m)
