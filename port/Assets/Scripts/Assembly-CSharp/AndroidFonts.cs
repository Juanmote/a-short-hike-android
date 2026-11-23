// Port Android: crea en tiempo de ejecución los TMP_FontAsset de los idiomas con fuente propia
// (japonés, chino, coreano, cirílico), que en el original venían en bundles de Addressables.
// Ajustes copiados del Japanese_TMP.asset original: 16 pt, padding 2, atlas 1024, raster con hinting
// y material "TextMeshPro/Mobile/Distance Field".
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.TextCore.LowLevel;

public static class AndroidFonts
{
	private static readonly Dictionary<string, TMP_FontAsset> cache = new Dictionary<string, TMP_FontAsset>();

	public static TMP_FontAsset GetTMP(string key, Font font)
	{
		if (cache.TryGetValue(key, out var cached) && cached != null)
		{
			return cached;
		}
		TMP_FontAsset asset = TMP_FontAsset.CreateFontAsset(font, 16, 2, GlyphRenderMode.RASTER_HINTED, 1024, 1024, AtlasPopulationMode.Dynamic);
		if (asset == null)
		{
			return null;
		}
		asset.name = key + "_TMP";
		Shader shader = Shader.Find("TextMeshPro/Mobile/Distance Field");
		if (shader != null && asset.material != null)
		{
			asset.material.shader = shader;
		}
		cache[key] = asset;
		return asset;
	}
}
