// Port Android: aviso en pantalla al conseguir un logro (como el de Steam o las consolas).
// Los logros ya se guardaban en local (Opciones › Logros); esto solo enseña el aviso.
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ASHAchievementToast : MonoBehaviour
{
	private static ASHAchievementToast _instance;

	private readonly Queue<string> _pending = new Queue<string>();

	private bool _showing;

	public static void Show(string achievementName)
	{
		if (_instance == null)
		{
			GameObject go = new GameObject("ASHAchievementToast");
			Object.DontDestroyOnLoad(go);
			_instance = go.AddComponent<ASHAchievementToast>();
		}
		_instance._pending.Enqueue(achievementName);
		if (!_instance._showing)
		{
			_instance.StartCoroutine(_instance.Run());
		}
	}

	private IEnumerator Run()
	{
		_showing = true;
		while (_pending.Count > 0)
		{
			string name = _pending.Dequeue();
			GameObject box = null;
			try
			{
				box = Build(name);
			}
			catch (System.Exception e)
			{
				Debug.LogWarning("[ASH] Aviso de logro: " + e.Message);
			}
			if (box != null)
			{
				ASHRumble.Pulse(0.2f, 0.7f);
				RectTransform rt = box.transform.GetChild(0) as RectTransform;
				CanvasGroup group = box.GetComponent<CanvasGroup>();
				float t = 0f;
				while (t < 4f)
				{
					t += Time.unscaledDeltaTime;
					float inT = Mathf.Clamp01(t / 0.35f);
					float outT = Mathf.Clamp01((4f - t) / 0.5f);
					group.alpha = Mathf.Min(inT, outT);
					rt.anchoredPosition = new Vector2(0f, Mathf.Lerp(30f, -6f, Mathf.SmoothStep(0f, 1f, inT)));
					yield return null;
				}
				Object.Destroy(box);
				yield return new WaitForSecondsRealtime(0.3f);
			}
		}
		_showing = false;
	}

	private static TMP_FontAsset FindFont()
	{
		TMP_FontAsset font = Resources.Load<TMP_FontAsset>("fonts/Pixellari_TMP");
		if (font == null)
		{
			font = TMP_Settings.defaultFontAsset;
		}
		return font;
	}

	private GameObject Build(string name)
	{
		AchievementData data = null;
		if (System.Enum.TryParse(name, out Achievement achievement))
		{
			data = achievement.GetData();
		}
		string title = (data != null) ? I18n.Localize(data.title) : name;
		GameObject root = new GameObject("Toast", typeof(RectTransform));
		root.transform.SetParent(base.transform, worldPositionStays: false);
		Canvas canvas = root.AddComponent<Canvas>();
		canvas.renderMode = RenderMode.ScreenSpaceOverlay;
		canvas.sortingOrder = 32000;
		CanvasScaler scaler = root.AddComponent<CanvasScaler>();
		scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
		scaler.referenceResolution = new Vector2(384f, 216f);
		scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.Expand;
		CanvasGroup group = root.AddComponent<CanvasGroup>();
		group.alpha = 0f;
		group.blocksRaycasts = false;
		group.interactable = false;
		// Caja
		GameObject panel = new GameObject("Box", typeof(RectTransform));
		panel.transform.SetParent(root.transform, worldPositionStays: false);
		RectTransform prt = panel.transform as RectTransform;
		prt.anchorMin = new Vector2(0.5f, 1f);
		prt.anchorMax = new Vector2(0.5f, 1f);
		prt.pivot = new Vector2(0.5f, 1f);
		prt.sizeDelta = new Vector2(190f, 34f);
		Image bg = panel.AddComponent<Image>();
		bg.color = new Color(0.12f, 0.1f, 0.18f, 0.92f);
		Outline outline = panel.AddComponent<Outline>();
		outline.effectColor = new Color(1f, 0.8f, 0.27f, 1f);
		outline.effectDistance = new Vector2(1f, -1f);
		// Icono
		float textLeft = 6f;
		if (data != null && data.sprite != null)
		{
			GameObject icon = new GameObject("Icon", typeof(RectTransform));
			icon.transform.SetParent(panel.transform, worldPositionStays: false);
			RectTransform irt = icon.transform as RectTransform;
			irt.anchorMin = new Vector2(0f, 0.5f);
			irt.anchorMax = new Vector2(0f, 0.5f);
			irt.pivot = new Vector2(0f, 0.5f);
			irt.anchoredPosition = new Vector2(4f, 0f);
			irt.sizeDelta = new Vector2(26f, 26f);
			Image img = icon.AddComponent<Image>();
			img.sprite = data.sprite;
			img.preserveAspect = true;
			textLeft = 34f;
		}
		// Texto
		GameObject textGo = new GameObject("Text", typeof(RectTransform));
		textGo.transform.SetParent(panel.transform, worldPositionStays: false);
		RectTransform trt = textGo.transform as RectTransform;
		trt.anchorMin = Vector2.zero;
		trt.anchorMax = Vector2.one;
		trt.offsetMin = new Vector2(textLeft, 2f);
		trt.offsetMax = new Vector2(-4f, -2f);
		TextMeshProUGUI text = textGo.AddComponent<TextMeshProUGUI>();
		TMP_FontAsset font = FindFont();
		if (font != null)
		{
			text.font = font;
		}
		text.fontSize = 12f;
		text.enableWordWrapping = true;
		text.alignment = TextAlignmentOptions.MidlineLeft;
		text.color = Color.white;
		text.richText = true;
		text.text = "<color=#FC4>" + ASHText.T("¡logro conseguido!", "achievement unlocked!") + "</color>\n" + title;
		return root;
	}
}
