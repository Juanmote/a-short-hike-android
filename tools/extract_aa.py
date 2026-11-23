#!/usr/bin/env python3
"""Saca la música y las fuentes de los bundles de Addressables de la copia del usuario
(UnityProject/Assets/StreamingAssets/aa) a Resources/aa, que es de donde las carga el port.
La música se guarda en WAV (Unity la vuelve a comprimir al compilar); las fuentes, en TTF.
Uso: extract_aa.py UnityProject/Assets"""
import glob
import os
import re
import sys

import UnityPy

assets = sys.argv[1]
amap = open(os.path.join(assets, "Scripts/Assembly-CSharp/AndroidAssetMap.cs"), encoding="utf-8").read()
music = {os.path.basename(p): p for p in re.findall(r'"(aa/Sounds/[^"]+)"', amap)}  # "Boat 1" -> aa/Sounds/Music/Boat/Boat 1
fonts = set(re.findall(r'"aa/Fonts/([^"]+)"', amap)) or {"Japanese", "Chinese", "Korean", "CyrillicNew"}
bundles = sorted(glob.glob(os.path.join(assets, "StreamingAssets", "aa", "**", "*.bundle"), recursive=True))
if not bundles:
    sys.exit("No encuentro los bundles en StreamingAssets/aa. ¿Es la versión 1.10.2 del juego?")
n_music = n_fonts = 0
for b in bundles:
    for o in UnityPy.load(b).objects:
        if o.type.name == "AudioClip":
            clip = o.read()
            dest = music.get(clip.m_Name)
            if dest is None:
                print("  (sin usar)", clip.m_Name)
                continue
            for _, data in clip.samples.items():
                out = os.path.join(assets, "Resources", dest + ".wav")
                os.makedirs(os.path.dirname(out), exist_ok=True)
                with open(out, "wb") as fh:
                    fh.write(data)
                n_music += 1
                break
        elif o.type.name == "Font":
            f = o.read()
            if f.m_Name in fonts and f.m_FontData:
                out = os.path.join(assets, "Resources", "aa", "Fonts", f.m_Name + ".ttf")
                os.makedirs(os.path.dirname(out), exist_ok=True)
                with open(out, "wb") as fh:
                    fh.write(bytes(bytearray(f.m_FontData)))
                n_fonts += 1
print("Música: %d de %d, fuentes: %d" % (n_music, len(music), n_fonts))
if n_music < len(music):
    sys.exit("Falta música: ¿es la versión 1.10.2 del juego?")
