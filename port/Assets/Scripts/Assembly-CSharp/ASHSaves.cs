// Port Android: exportar e importar la partida de la ranura actual con el selector de archivos de Android
// (ASHSaveActivity.java). Lo usa Opciones › Datos de guardado.
using System;
using System.Collections;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ASHSaves : MonoBehaviour
{
	private const string TempName = "ash_import.tmp";

	private static ASHSaves _runner;

	private static bool _busy;

	public static bool Available => Application.platform == RuntimePlatform.Android;

	public static bool OnTitleScreen => SceneManager.GetActiveScene().name == "TitleScene";

	private static string SlotPath(int slot)
	{
		return Path.Combine(Application.persistentDataPath, GlobalData.GetFilenameForSaveSlot(slot));
	}

	public static bool SlotHasSave(int slot)
	{
		return File.Exists(SlotPath(slot));
	}

	// Exporta la última partida guardada de la ranura. onDone recibe el texto que se muestra al usuario.
	public static void Export(int slot, Action<string> onDone)
	{
		if (_busy)
		{
			return;
		}
		string src = SlotPath(slot);
		if (!File.Exists(src))
		{
			onDone(ASHText.T("no hay partida guardada\nen esta ranura", "there is no saved game\nin this slot"));
			return;
		}
		string name = "AShortHike-" + ASHText.T("ranura", "slot") + (slot + 1) + "-" + DateTime.Now.ToString("yyyy-MM-dd") + ".mountain";
		Run("export", src, name, (string r) =>
		{
			if (r == "ok")
			{
				onDone(ASHText.T("partida exportada", "game exported"));
			}
			else if (r != "cancel")
			{
				onDone(ASHText.T("no se pudo exportar", "could not export") + "\n(" + r + ")");
			}
		});
	}

	// Importa un archivo .mountain a la ranura (solo en la pantalla de título). La partida que hubiera
	// se guarda antes como copia (.bak).
	public static void Import(int slot, Action<string> onDone)
	{
		if (_busy)
		{
			return;
		}
		string tmp = Path.Combine(Application.persistentDataPath, TempName);
		Run("import", tmp, "", (string r) =>
		{
			if (r == "cancel")
			{
				return;
			}
			if (r != "ok")
			{
				onDone(ASHText.T("no se pudo importar", "could not import") + "\n(" + r + ")");
				return;
			}
			try
			{
				if (!IsValidSave(tmp))
				{
					onDone(ASHText.T("ese archivo no es una\npartida de a short hike", "that file is not an\na short hike save"));
					return;
				}
				string dst = SlotPath(slot);
				if (File.Exists(dst))
				{
					File.Copy(dst, dst + ".bak", overwrite: true);
				}
				File.Copy(tmp, dst, overwrite: true);
				if (OnTitleScreen)
				{
					GlobalData.SetSaveSlot(GameSettings.saveSlot);
					TitleScreen titleScreen = UnityEngine.Object.FindObjectOfType<TitleScreen>();
					if ((bool)titleScreen)
					{
						titleScreen.UpdateTitleScreenMenuItems();
					}
				}
				onDone(ASHText.T("partida importada", "game imported"));
			}
			catch (Exception ex)
			{
				Debug.LogWarning("[ASH] Importar: " + ex);
				onDone(ASHText.T("no se pudo importar", "could not import") + "\n(" + ex.GetType().Name + ")");
			}
			finally
			{
				try
				{
					File.Delete(tmp);
				}
				catch
				{
				}
			}
		});
	}

	private static bool IsValidSave(string path)
	{
		try
		{
			using (FileStream fs = File.Open(path, FileMode.Open, FileAccess.Read))
			{
				BinaryFormatter bf = new BinaryFormatter();
				GlobalData.AddSerializationSurrogates(bf);
				return bf.Deserialize(fs) is GameData;
			}
		}
		catch (Exception ex)
		{
			Debug.LogWarning("[ASH] Partida no válida: " + ex.Message);
			return false;
		}
	}

	private static void Run(string mode, string path, string name, Action<string> onResult)
	{
		if (!Available)
		{
			onResult("error:solo android");
			return;
		}
		if (_runner == null)
		{
			GameObject go = new GameObject("ASHSaves");
			UnityEngine.Object.DontDestroyOnLoad(go);
			_runner = go.AddComponent<ASHSaves>();
		}
		try
		{
			using (AndroidJavaClass c = new AndroidJavaClass("com.juanmote.ashorthike.ASHSaveActivity"))
			{
				c.CallStatic("start", mode, path, name);
			}
		}
		catch (Exception ex)
		{
			Debug.LogWarning("[ASH] Selector de archivos: " + ex);
			onResult("error:" + ex.GetType().Name);
			return;
		}
		_busy = true;
		_runner.StartCoroutine(_runner.Wait(onResult));
	}

	private IEnumerator Wait(Action<string> onResult)
	{
		string r = "pending";
		using (AndroidJavaClass c = new AndroidJavaClass("com.juanmote.ashorthike.ASHSaveActivity"))
		{
			while (r == "pending")
			{
				yield return new WaitForSecondsRealtime(0.2f);
				try
				{
					r = c.CallStatic<string>("result");
				}
				catch (Exception ex)
				{
					r = "error:" + ex.GetType().Name;
				}
			}
		}
		_busy = false;
		try
		{
			onResult(r);
		}
		catch (Exception ex)
		{
			Debug.LogWarning("[ASH] Partidas: " + ex);
		}
	}
}
