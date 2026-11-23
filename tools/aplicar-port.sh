#!/bin/bash
# Convierte el proyecto extraído con AssetRipper (UnityProject/) en el port de Android.
# Se ejecuta desde la raíz del repositorio, después de extraer el proyecto.
set -euo pipefail
cd "$(dirname "$0")/.."
A=UnityProject/Assets

if [ ! -d "$A" ]; then
  echo "No existe UnityProject/Assets: primero hay que extraer el proyecto del juego." >&2
  exit 1
fi

if [ -f "$A/Scripts/Assembly-CSharp/SteamAchievements.cs" ]; then
  echo "1/5 Copia de Steam: igualando el código con el de la versión de itch.io"
  if ! git apply --whitespace=nowarn patches/steam-a-itch.patch; then
    echo "El parche de Steam no encaja. ¿Es la versión 1.10.2 de Steam y se extrajo con AssetRipper 2.0.0?" >&2
    exit 1
  fi
else
  echo "1/5 Copia de itch.io"
fi

echo "2/5 Aplicando los cambios del port al código del juego"
if ! git apply --whitespace=nowarn patches/ash-android.patch; then
  echo "El parche no encaja. ¿Es la versión 1.10.2 del juego (itch.io Linux o Steam Windows) y se extrajo con AssetRipper 2.0.0?" >&2
  exit 1
fi

echo "3/5 Copiando los archivos propios del port"
cp -r port/. UnityProject/

echo "4/5 Textos del juego como .txt (Unity no importa .yarn)"
for f in "$A"/Resources/languages/*.yarn_lines "$A"/Resources/languages/*.yarn; do
  [ -e "$f" ] || continue
  mv "$f" "${f%.*}.txt"
  [ -f "$f.meta" ] && mv "$f.meta" "${f%.*}.txt.meta"
done

echo "5/5 Música y fuentes fuera de los bundles de Addressables"
python3 tools/extract_aa.py "$A"
rm -rf "$A/StreamingAssets/aa" "$A/StreamingAssets/aa.meta"

echo "Port aplicado."
