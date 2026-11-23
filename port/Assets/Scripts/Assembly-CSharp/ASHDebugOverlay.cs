// Port Android: muestra en pantalla los errores de Unity y las marcas [ASH] para poder
// diagnosticar en la consola sin cable ni adb (el usuario hace una captura).
// Se desactiva poniendo SHOW = false cuando el port esté estable.
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ASHDebugOverlay : MonoBehaviour
{
	public static bool SHOW = false;

	private const int MaxLines = 28;

	private static readonly List<string> lines = new List<string>();

	private static readonly HashSet<string> seen = new HashSet<string>();

	private static readonly object lockObj = new object();

	private static GUIStyle style;

	private static float startTime;

	[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
	private static void Init()
	{
		startTime = Time.realtimeSinceStartup;
		Application.logMessageReceivedThreaded += OnLog;
		SceneManager.sceneLoaded += (Scene scene, LoadSceneMode mode) => Debug.Log("[ASH] Escena cargada: " + scene.name);
		SceneManager.activeSceneChanged += (Scene a, Scene b) => Debug.Log("[ASH] Escena activa: " + b.name);
		if (SHOW)
		{
			GameObject go = new GameObject("ASHDebugOverlay");
			Object.DontDestroyOnLoad(go);
			go.AddComponent<ASHDebugOverlay>();
		}
		InControl.InputManager.OnDeviceAttached += (InControl.InputDevice d) => Debug.Log("[ASH] Mando conectado: " + d.Name + " (" + d.DeviceClass + ")");
		InControl.InputManager.OnSetup += () => Debug.Log("[ASH] InControl listo. Mandos: " + InControl.InputManager.Devices.Count + " / Unity: " + string.Join(", ", Input.GetJoystickNames()));
		Debug.Log("[ASH] Inicio. Unity " + Application.unityVersion + " / " + SystemInfo.graphicsDeviceType + " / " + SystemInfo.deviceModel);
	}

	private static void OnLog(string condition, string stackTrace, LogType type)
	{
		bool isAsh = condition != null && condition.StartsWith("[ASH]");
		if (!isAsh && type != LogType.Error && type != LogType.Exception && type != LogType.Assert)
		{
			return;
		}
		lock (lockObj)
		{
			if (!isAsh && !seen.Add(condition))
			{
				return;
			}
			string t = (Time.realtimeSinceStartup - startTime).ToString("0.0");
			string line = t + "s " + (isAsh ? "" : (type + ": ")) + condition;
			if (!isAsh && !string.IsNullOrEmpty(stackTrace))
			{
				string[] st = stackTrace.Split('\n');
				for (int i = 0; i < st.Length && i < 3; i++)
				{
					if (st[i].Trim().Length > 0)
					{
						line += "\n      " + st[i].Trim();
					}
				}
			}
			lines.Add(line);
			while (lines.Count > MaxLines)
			{
				lines.RemoveAt(0);
			}
		}
	}

	private void OnGUI()
	{
		if (!SHOW)
		{
			return;
		}
		if (style == null)
		{
			style = new GUIStyle(GUI.skin.label);
			style.fontSize = Mathf.Max(12, Screen.height / 55);
			style.normal.textColor = Color.yellow;
			style.wordWrap = true;
		}
		string text;
		lock (lockObj)
		{
			text = string.Join("\n", lines);
		}
		GUI.depth = -1000;
		Color old = GUI.color;
		GUI.color = new Color(0f, 0f, 0f, 0.6f);
		GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height * 0.6f), Texture2D.whiteTexture);
		GUI.color = old;
		GUI.Label(new Rect(8f, 8f, Screen.width - 16, Screen.height * 0.6f - 16f), text, style);
	}
}
