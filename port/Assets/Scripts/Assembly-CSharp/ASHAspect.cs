// Port Android: pantallas más estrechas que 16:9 (4:3, 8:7, 1:1...).
// El juego dibuja todo (juego + menús) en una imagen de 384x216 que luego se ajusta al alto de la
// pantalla: en pantallas estrechas se cortaban los lados y con ellos parte de los menús.
// Aquí la imagen base mantiene sus 384 píxeles de ancho y gana alto según la pantalla
// (1:1 -> 384x384, 8:7 -> 384x336, 4:3 -> 384x288), así que menús y juego se ven enteros.
using UnityEngine;
using UnityEngine.SceneManagement;

public class ASHAspect : MonoBehaviour
{
	public const int BaseWidth = 384;

	public const int BaseHeight = 216;

	private const string RenderTextureName = "GBRenderTexture";

	private static int _height = BaseHeight;

	private static ASHAspect _instance;

	private int _screenW;

	private int _screenH;

	private bool _dirty = true;

	// Alto por cada píxel de ancho de la imagen base (9/16 en 16:9).
	public static float HeightPerWidth => (float)_height / (float)BaseWidth;

	// Filas de píxeles del juego con el tamaño de píxel elegido (para el filtro de scanlines).
	public static int PixelHeight => Mathf.Max(1, Mathf.RoundToInt((float)PixelFilterAdjuster.realPixelWidth * HeightPerWidth));

	[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
	private static void Init()
	{
		if (!Application.isMobilePlatform || _instance != null)
		{
			return;
		}
		GameObject go = new GameObject("ASHAspect");
		Object.DontDestroyOnLoad(go);
		_instance = go.AddComponent<ASHAspect>();
		SceneManager.sceneLoaded += (Scene s, LoadSceneMode m) =>
		{
			if (_instance != null)
			{
				// Antes del primer fotograma de la escena: así los menús se colocan ya con el tamaño bueno.
				_instance._dirty = true;
				_instance.LateUpdate();
			}
		};
	}

	private static int TargetHeight()
	{
		float aspect = (float)Screen.width / Mathf.Max(1f, Screen.height);
		if (aspect >= 16f / 9f - 0.01f)
		{
			return BaseHeight;
		}
		return Mathf.Clamp(Mathf.RoundToInt((float)BaseWidth / aspect), BaseHeight, 640);
	}

	private void LateUpdate()
	{
		if (!_dirty && Screen.width == _screenW && Screen.height == _screenH)
		{
			return;
		}
		_dirty = false;
		_screenW = Screen.width;
		_screenH = Screen.height;
		try
		{
			Apply();
		}
		catch (System.Exception e)
		{
			Debug.LogError("[ASH] Aspecto: " + e);
		}
	}

	private void Apply()
	{
		int h = TargetHeight();
		RenderTexture rt = null;
		foreach (RenderTexture t in Resources.FindObjectsOfTypeAll<RenderTexture>())
		{
			if (t != null && t.name == RenderTextureName)
			{
				rt = t;
				break;
			}
		}
		if (rt == null)
		{
			return;
		}
		bool changed = rt.height != h || _height != h;
		if (rt.height != h)
		{
			rt.Release();
			rt.height = h;
			rt.Create();
		}
		// Las cámaras que dibujan en ella se vuelven a enganchar para que recalculen su tamaño
		// (si no, la primera vez el menú de inicio salía con las letras deformadas).
		foreach (Camera cam in Camera.allCameras)
		{
			if (cam.targetTexture == rt)
			{
				cam.targetTexture = null;
				cam.targetTexture = rt;
				cam.ResetAspect();
			}
		}
		foreach (Canvas c in Object.FindObjectsOfType<Canvas>())
		{
			if (c.isRootCanvas && c.renderMode == RenderMode.ScreenSpaceCamera && c.worldCamera != null && c.worldCamera.targetTexture == rt)
			{
				Camera wc = c.worldCamera;
				c.worldCamera = null;
				c.worldCamera = wc;
			}
		}
		Canvas.ForceUpdateCanvases();
		_height = h;
		// Rectángulos que muestran la imagen base: misma proporción que ella.
		foreach (MeshRenderer r in Object.FindObjectsOfType<MeshRenderer>())
		{
			Material m = r.sharedMaterial;
			if (m != null && m.HasProperty("_MainTex") && m.mainTexture == rt)
			{
				Vector3 s = r.transform.localScale;
				r.transform.localScale = new Vector3(s.y * (float)rt.width / (float)rt.height, s.y, s.z);
			}
		}
		// Si el juego usa otro tamaño de píxel, se vuelve a configurar con la nueva proporción.
		if (Object.FindObjectOfType<PixelFilterAdjuster>() != null)
		{
			GameSettings.pixelWidth = GameSettings.pixelWidth;
		}
		if (changed)
		{
			Debug.Log("[ASH] Imagen base " + rt.width + "x" + rt.height + " (pantalla " + Screen.width + "x" + Screen.height + ")");
		}
	}
}
