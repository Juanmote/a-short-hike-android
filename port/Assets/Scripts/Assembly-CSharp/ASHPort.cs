// Port Android: ajustes propios del port (textos, vibración, FPS y frecuencia de pantalla).
using System;
using UnityEngine;

public static class ASHText
{
	public static bool Spanish
	{
		get
		{
			string lang = GameSettings.language;
			if (string.IsNullOrEmpty(lang))
			{
				return Application.systemLanguage == SystemLanguage.Spanish;
			}
			return lang == "Spanish";
		}
	}

	public static string T(string es, string en)
	{
		return Spanish ? es : en;
	}
}

public static class ASHRumble
{
	private const string Key = "ASH_VIBRATION";

	private static int _enabled = -1;

	private static AndroidJavaClass _native;

	private static bool _broken;

	private static float _busyUntil;

	private static int _logged;

	public static bool Enabled
	{
		get
		{
			if (_enabled < 0)
			{
				_enabled = PlayerPrefs.GetInt(Key, 1);
			}
			return _enabled == 1;
		}
		set
		{
			_enabled = value ? 1 : 0;
			PlayerPrefs.SetInt(Key, _enabled);
			PlayerPrefs.Save();
			if (value)
			{
				Pulse(0.15f, 0.8f);
			}
		}
	}

	// Aviso para el menú si falta el permiso o no hay ningún motor ("" si todo está bien).
	public static string Problem
	{
		get
		{
			if (Application.platform != RuntimePlatform.Android)
			{
				return "";
			}
			try
			{
				using (AndroidJavaClass c = new AndroidJavaClass("com.juanmote.ashorthike.ASHNative"))
				{
					string st = c.CallStatic<string>("status");
					Debug.Log("[ASH] Vibración: " + st);
					if (st.Contains("permiso=0"))
					{
						return ASHText.T("sin permiso", "no permission");
					}
					if (st.Contains("consola=0") && st.Contains("mandos=0"))
					{
						return ASHText.T("sin motor", "no motor");
					}
					return "";
				}
			}
			catch (Exception e)
			{
				return e.GetType().Name;
			}
		}
	}

	// seconds: duración; strength: 0..1. No corta una vibración más larga que siga en marcha.
	public static void Pulse(float seconds, float strength)
	{
		if (!Enabled || _broken || Application.platform != RuntimePlatform.Android)
		{
			return;
		}
		float now = Time.unscaledTime;
		seconds = Mathf.Max(seconds, 0.06f);
		if (now + seconds < _busyUntil)
		{
			return;
		}
		_busyUntil = now + seconds;
		if (_logged < 5)
		{
			_logged++;
			Debug.Log("[ASH] Vibración " + seconds + " s, fuerza " + strength);
		}
		try
		{
			if (_native == null)
			{
				_native = new AndroidJavaClass("com.juanmote.ashorthike.ASHNative");
			}
			// Los motores de las consolas no notan pulsos muy cortos o flojos: mínimo 60 ms y fuerza alta.
			long ms = (long)Mathf.Clamp(seconds * 1000f, 60f, 1500f);
			int amp = Mathf.Clamp(Mathf.RoundToInt(170f + 85f * Mathf.Clamp01(strength)), 1, 255);
			_native.CallStatic("rumble", ms, amp);
		}
		catch (Exception e)
		{
			_broken = true;
			Debug.LogWarning("[ASH] Vibración: " + e.Message);
		}
	}

	// Nunca se llama: solo sirve para que Unity añada el permiso VIBRATE al manifiesto.
	private static void KeepVibratePermission()
	{
		Handheld.Vibrate();
	}
}

public static class ASHDisplay
{
	public static readonly int[] FPS_OPTIONS = new int[3] { 30, 60, 120 };

	// Valor guardado del juego (-1 = sin elegir) -> FPS reales en Android (30 por defecto).
	public static int Normalize(int fps)
	{
		if (fps <= 0)
		{
			return 30;
		}
		if (fps <= 30)
		{
			return 30;
		}
		if (fps <= 60)
		{
			return 60;
		}
		return 120;
	}

	public static int Next(int fps)
	{
		int cur = Normalize(fps);
		for (int i = 0; i < FPS_OPTIONS.Length; i++)
		{
			if (FPS_OPTIONS[i] == cur)
			{
				return FPS_OPTIONS[(i + 1) % FPS_OPTIONS.Length];
			}
		}
		return 30;
	}

	public static void Apply(int fps)
	{
		int real = Normalize(fps);
		QualitySettings.vSyncCount = 0;
		Application.targetFrameRate = real;
		if (Application.platform != RuntimePlatform.Android)
		{
			return;
		}
		try
		{
			using (AndroidJavaClass c = new AndroidJavaClass("com.juanmote.ashorthike.ASHNative"))
			{
				c.CallStatic("setRefreshRate", (float)real);
			}
		}
		catch (Exception e)
		{
			Debug.LogWarning("[ASH] Frecuencia de pantalla: " + e.Message);
		}
	}
}
