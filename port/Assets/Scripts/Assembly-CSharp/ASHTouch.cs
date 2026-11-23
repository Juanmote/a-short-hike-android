// Port Android: ajustes de los controles táctiles del juego (Opciones › Controles).
//  - Mostrar: sí / no / automático (se ocultan al usar un mando físico y vuelven al tocar la pantalla).
//  - Tamaño: 75% / 100% / 125% / 150%.
//  - Opacidad en reposo: 20% / 35% / 50% / 75%. Al pulsar, el botón (o la dirección de la cruceta)
//    se ve al 100%.
// Gráficos propios en Resources/ASHTouch: a, b, x, y, thumbpad (cruceta) y pad_up/down/left/right
// (cada brazo de la cruceta, que se ilumina al pulsar esa dirección). Opcional: stick (bola).
using System.Collections.Generic;
using InControl;
using UnityEngine;
using UnityEngine.UI;

public class ASHTouch : MonoBehaviour
{
	private const string ModeKey = "ASH_TOUCH_MODE";

	private const string SizeKey = "ASH_TOUCH_SIZE";

	private const string OpacityKey = "ASH_TOUCH_OPACITY";

	private static readonly float[] Sizes = new float[4] { 0.75f, 1f, 1.25f, 1.5f };

	private static readonly float[] Opacities = new float[4] { 0.2f, 0.35f, 0.5f, 0.75f };

	private static int _mode = -1;

	private static int _size = -1;

	private static int _opacity = -1;

	private static bool _dirty = true;

	// Con modo "no": los botones no responden (los lee TouchScreenButton/TouchScreenStick).
	public static bool InputBlocked => Mode == 1;

	// 0 = sí, 1 = no, 2 = automático
	public static int Mode
	{
		get
		{
			if (_mode < 0)
			{
				_mode = Mathf.Clamp(PlayerPrefs.GetInt(ModeKey, 0), 0, 2);
			}
			return _mode;
		}
		set
		{
			_mode = (value % 3 + 3) % 3;
			Save(ModeKey, _mode);
		}
	}

	public static int Size
	{
		get
		{
			if (_size < 0)
			{
				_size = Mathf.Clamp(PlayerPrefs.GetInt(SizeKey, 1), 0, Sizes.Length - 1);
			}
			return _size;
		}
		set
		{
			_size = (value % Sizes.Length + Sizes.Length) % Sizes.Length;
			Save(SizeKey, _size);
		}
	}

	public static int Opacity
	{
		get
		{
			if (_opacity < 0)
			{
				_opacity = Mathf.Clamp(PlayerPrefs.GetInt(OpacityKey, 1), 0, Opacities.Length - 1);
			}
			return _opacity;
		}
		set
		{
			_opacity = (value % Opacities.Length + Opacities.Length) % Opacities.Length;
			Save(OpacityKey, _opacity);
		}
	}

	public static string ModeName
	{
		get
		{
			switch (Mode)
			{
			case 1:
				return ASHText.T("no", "off");
			case 2:
				return ASHText.T("automático", "auto");
			default:
				return ASHText.T("sí", "on");
			}
		}
	}

	// Transparencia de los botones sin pulsar (la usa TouchScreenButton).
	public static float IdleAlpha => Opacities[Opacity];

	public static string SizeName => Mathf.RoundToInt(Sizes[Size] * 100f) + "%";

	public static string OpacityName => Mathf.RoundToInt(Opacities[Opacity] * 100f) + "%";

	private static void Save(string key, int value)
	{
		PlayerPrefs.SetInt(key, value);
		PlayerPrefs.Save();
		_dirty = true;
	}

	// ----- Aplicar a los controles del juego -----

	private class Original
	{
		public RectTransform rect;

		public Vector2 anchoredPosition;

		public Vector3 scale;
	}

	private TouchScreenControls _controls;

	private Canvas _canvas;

	private CanvasGroup _group;

	private readonly List<Original> _originals = new List<Original>();

	private float _stickMax;

	private float _stickPull;

	private bool _autoVisible = true;

	private bool _shown = true;

	private Image _padImage;

	private Image _knobImage;

	private bool _customPad;

	private bool _customKnob;

	// Brazos de la cruceta: arriba, abajo, izquierda, derecha.
	private readonly Image[] _arms = new Image[4];

	[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
	private static void Init()
	{
		if (!Application.isMobilePlatform)
		{
			return;
		}
		GameObject go = new GameObject("ASHTouch");
		Object.DontDestroyOnLoad(go);
		go.AddComponent<ASHTouch>();
	}

	private void LateUpdate()
	{
		if (_controls == null)
		{
			_controls = Object.FindObjectOfType<TouchScreenControls>();
			if (_controls == null)
			{
				return;
			}
			Setup();
		}
		if (Mode == 2)
		{
			UpdateAuto();
		}
		bool show = Mode == 0 || (Mode == 2 && _autoVisible);
		if (_dirty || show != _shown)
		{
			_dirty = false;
			_shown = show;
			Apply(show);
		}
		UpdateStickVisuals();
	}

	private void UpdateStickVisuals()
	{
		if (_controls.leftStick == null)
		{
			return;
		}
		Vector2 v = _controls.leftStick.value;
		bool touching = v.sqrMagnitude > 0.0001f;
		if (_padImage != null)
		{
			_padImage.color = _padImage.color.SetA(IdleAlpha);
		}
		if (_knobImage != null)
		{
			float a = (_customPad && !_customKnob) ? 0f : (touching ? 1f : IdleAlpha);
			_knobImage.color = _knobImage.color.SetA(a);
		}
		const float t = 0.4f;
		bool[] on = new bool[4] { v.y > t, v.y < -t, v.x < -t, v.x > t };
		for (int i = 0; i < 4; i++)
		{
			if (_arms[i] != null)
			{
				_arms[i].enabled = on[i];
			}
		}
	}

	private void UpdateAuto()
	{
		if (Input.touchCount > 0)
		{
			_autoVisible = true;
			return;
		}
		InputDevice active = InputManager.ActiveDevice;
		if (active != null && !(active is TouchScreenInputDevice) && active.AnyButtonWasPressed)
		{
			_autoVisible = false;
		}
		else if (active != null && !(active is TouchScreenInputDevice) && active.LeftStick.Vector.sqrMagnitude > 0.25f)
		{
			_autoVisible = false;
		}
	}

	private void Setup()
	{
		_canvas = _controls.GetComponentInChildren<Canvas>(includeInactive: true);
		if (_canvas == null)
		{
			_canvas = _controls.GetComponent<Canvas>();
		}
		GameObject root = (_canvas != null) ? _canvas.gameObject : _controls.gameObject;
		_group = root.GetComponent<CanvasGroup>();
		if (_group == null)
		{
			_group = root.AddComponent<CanvasGroup>();
		}
		_group.interactable = false;
		_group.blocksRaycasts = false;
		foreach (TouchScreenButton b in _controls.buttons)
		{
			if (b != null)
			{
				Remember(b.transform as RectTransform);
			}
		}
		if (_controls.leftStick != null)
		{
			Remember(_controls.leftStick.transform as RectTransform);
			Remember(_controls.leftStick.stick);
			_stickMax = _controls.leftStick.localMaxRadius;
			_stickPull = _controls.leftStick.localPullRadius;
		}
		ApplyCustomSprites();
		_dirty = true;
		Debug.Log("[ASH] Controles táctiles: " + _controls.buttons.Count + " botones");
	}

	private void Remember(RectTransform rect)
	{
		if (rect == null)
		{
			return;
		}
		_originals.Add(new Original
		{
			rect = rect,
			anchoredPosition = rect.anchoredPosition,
			scale = rect.localScale
		});
	}

	private void Apply(bool show)
	{
		float size = Sizes[Size];
		_group.alpha = show ? 1f : 0f;
		foreach (Original o in _originals)
		{
			if (o.rect == null)
			{
				continue;
			}
			o.rect.localScale = o.scale * size;
			// Botones (anclados a una esquina): se separan del borde en proporción al tamaño.
			if (_controls.leftStick == null || (o.rect != _controls.leftStick.transform && o.rect != _controls.leftStick.stick))
			{
				o.rect.anchoredPosition = o.anchoredPosition * size;
			}
		}
		if (_controls.leftStick != null)
		{
			_controls.leftStick.localMaxRadius = _stickMax * size;
			_controls.leftStick.localPullRadius = _stickPull * size;
		}
	}

	private void ApplyCustomSprites()
	{
		Dictionary<string, Sprite> sprites = new Dictionary<string, Sprite>();
		foreach (string n in new string[10] { "stick", "thumbpad", "a", "b", "x", "y", "pad_up", "pad_down", "pad_left", "pad_right" })
		{
			Texture2D tex = Resources.Load<Texture2D>("ASHTouch/" + n);
			if (tex != null)
			{
				tex.filterMode = FilterMode.Bilinear;
				sprites[n] = Sprite.Create(tex, new Rect(0f, 0f, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100f);
			}
		}
		if (_controls.leftStick != null)
		{
			_padImage = _controls.leftStick.GetComponent<Image>();
			_knobImage = (_controls.leftStick.stick != null) ? _controls.leftStick.stick.GetComponent<Image>() : null;
		}
		if (sprites.Count == 0)
		{
			return;
		}
		foreach (TouchScreenButton b in _controls.buttons)
		{
			if (b == null)
			{
				continue;
			}
			Text label = b.GetComponentInChildren<Text>(includeInactive: true);
			string key = (label != null) ? label.text.Trim().ToLowerInvariant() : "";
			if (sprites.TryGetValue(key, out Sprite sp))
			{
				Image img = b.GetComponentInChildren<Image>(includeInactive: true);
				if (img != null)
				{
					img.sprite = sp;
					img.color = new Color(1f, 1f, 1f, img.color.a);
					img.preserveAspect = true;
				}
				// La letra se queda (TouchScreenInputDevice usa su texto como nombre), pero invisible.
				if (label != null)
				{
					label.color = new Color(0f, 0f, 0f, 0f);
				}
			}
		}
		if (_controls.leftStick != null)
		{
			Image pad = _padImage;
			if (pad != null && sprites.TryGetValue("thumbpad", out Sprite sp2))
			{
				_customPad = true;
				pad.sprite = sp2;
				pad.color = new Color(1f, 1f, 1f, pad.color.a);
				pad.preserveAspect = true;
				string[] arms = new string[4] { "pad_up", "pad_down", "pad_left", "pad_right" };
				for (int i = 0; i < 4; i++)
				{
					if (!sprites.TryGetValue(arms[i], out Sprite armSprite))
					{
						continue;
					}
					GameObject go = new GameObject("ASH_" + arms[i], typeof(RectTransform));
					RectTransform r = go.transform as RectTransform;
					r.SetParent(pad.transform, worldPositionStays: false);
					r.anchorMin = Vector2.zero;
					r.anchorMax = Vector2.one;
					r.offsetMin = Vector2.zero;
					r.offsetMax = Vector2.zero;
					Image img = go.AddComponent<Image>();
					img.sprite = armSprite;
					img.preserveAspect = true;
					img.raycastTarget = false;
					img.enabled = false;
					_arms[i] = img;
				}
			}
			Image knob = _knobImage;
			if (knob != null && sprites.TryGetValue("stick", out Sprite sp3))
			{
				_customKnob = true;
				knob.sprite = sp3;
				knob.color = new Color(1f, 1f, 1f, knob.color.a);
				knob.preserveAspect = true;
			}
		}
		Debug.Log("[ASH] Gráficos táctiles propios: " + sprites.Count);
	}
}
