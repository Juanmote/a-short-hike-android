// Port Android: mando físico para InControl.
// El InControl compilado del juego no tiene perfil para el mando integrado de la consola
// ("Odin Controller") y lo da de alta como "Unknown Device", sin botones asignados.
// Aquí se crea un dispositivo propio que lee el mando con la asignación estándar de Android
// (la misma que usan los perfiles Android de InControl) y se quita el "Unknown Device".
using System.Collections.Generic;
using InControl;
using UnityEngine;

public class AndroidGamepadDevice : InputDevice
{
	private const float DeadZone = 0.2f;

	public AndroidGamepadDevice(string name)
		: base(name)
	{
		AddControl(InputControlType.LeftStickLeft, "Left Stick Left", DeadZone, 0.9f);
		AddControl(InputControlType.LeftStickRight, "Left Stick Right", DeadZone, 0.9f);
		AddControl(InputControlType.LeftStickUp, "Left Stick Up", DeadZone, 0.9f);
		AddControl(InputControlType.LeftStickDown, "Left Stick Down", DeadZone, 0.9f);
		AddControl(InputControlType.RightStickLeft, "Right Stick Left", DeadZone, 0.9f);
		AddControl(InputControlType.RightStickRight, "Right Stick Right", DeadZone, 0.9f);
		AddControl(InputControlType.RightStickUp, "Right Stick Up", DeadZone, 0.9f);
		AddControl(InputControlType.RightStickDown, "Right Stick Down", DeadZone, 0.9f);
		AddControl(InputControlType.DPadUp, "DPad Up");
		AddControl(InputControlType.DPadDown, "DPad Down");
		AddControl(InputControlType.DPadLeft, "DPad Left");
		AddControl(InputControlType.DPadRight, "DPad Right");
		AddControl(InputControlType.Action1, "A");
		AddControl(InputControlType.Action2, "B");
		AddControl(InputControlType.Action3, "X");
		AddControl(InputControlType.Action4, "Y");
		AddControl(InputControlType.LeftBumper, "L1");
		AddControl(InputControlType.RightBumper, "R1");
		AddControl(InputControlType.LeftTrigger, "L2");
		AddControl(InputControlType.RightTrigger, "R2");
		AddControl(InputControlType.LeftStickButton, "L3");
		AddControl(InputControlType.RightStickButton, "R3");
		AddControl(InputControlType.Command, "Start");
		AddControl(InputControlType.Back, "Select");
	}

	private static float Axis(int n)
	{
		try
		{
			return Input.GetAxisRaw("joystick 1 analog " + n);
		}
		catch
		{
			return 0f;
		}
	}

	private static bool Btn(int n)
	{
		return Input.GetKey((KeyCode)((int)KeyCode.Joystick1Button0 + n));
	}

	public override void Update(ulong updateTick, float deltaTime)
	{
		Vector2 left = new Vector2(Axis(0), 0f - Axis(1));
		Vector2 right = new Vector2(Axis(2), 0f - Axis(3));
		UpdateLeftStickWithValue(left, updateTick, deltaTime);
		UpdateRightStickWithValue(right, updateTick, deltaTime);

		float hatX = Axis(4);
		float hatY = 0f - Axis(5);
		UpdateWithState(InputControlType.DPadLeft, hatX < -0.5f, updateTick, deltaTime);
		UpdateWithState(InputControlType.DPadRight, hatX > 0.5f, updateTick, deltaTime);
		UpdateWithState(InputControlType.DPadUp, hatY > 0.5f, updateTick, deltaTime);
		UpdateWithState(InputControlType.DPadDown, hatY < -0.5f, updateTick, deltaTime);

		UpdateWithState(InputControlType.Action1, Btn(0), updateTick, deltaTime);
		UpdateWithState(InputControlType.Action2, Btn(1), updateTick, deltaTime);
		UpdateWithState(InputControlType.Action3, Btn(2), updateTick, deltaTime);
		UpdateWithState(InputControlType.Action4, Btn(3), updateTick, deltaTime);
		UpdateWithState(InputControlType.LeftBumper, Btn(4), updateTick, deltaTime);
		UpdateWithState(InputControlType.RightBumper, Btn(5), updateTick, deltaTime);
		UpdateWithValue(InputControlType.LeftTrigger, Mathf.Max(Mathf.Clamp01(Axis(12)), Btn(6) ? 1f : 0f), updateTick, deltaTime);
		UpdateWithValue(InputControlType.RightTrigger, Mathf.Max(Mathf.Clamp01(Axis(11)), Btn(7) ? 1f : 0f), updateTick, deltaTime);
		UpdateWithState(InputControlType.LeftStickButton, Btn(8), updateTick, deltaTime);
		UpdateWithState(InputControlType.RightStickButton, Btn(9), updateTick, deltaTime);
		UpdateWithState(InputControlType.Command, Btn(10), updateTick, deltaTime);
		UpdateWithState(InputControlType.Back, Btn(11), updateTick, deltaTime);
	}
}

public class AndroidGamepad : MonoBehaviour
{
	private static AndroidGamepadDevice device;

	private float nextCheck;

	[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
	private static void Init()
	{
		if (Application.platform != RuntimePlatform.Android)
		{
			return;
		}
		GameObject go = new GameObject("AndroidGamepad");
		Object.DontDestroyOnLoad(go);
		go.AddComponent<AndroidGamepad>();
	}

	private void Update()
	{
		if (Time.realtimeSinceStartup < nextCheck || !InputManager.IsSetup)
		{
			return;
		}
		nextCheck = Time.realtimeSinceStartup + 1f;
		string padName = null;
		string[] names = Input.GetJoystickNames();
		for (int i = 0; i < names.Length; i++)
		{
			if (!string.IsNullOrEmpty(names[i]))
			{
				padName = names[i];
				break;
			}
		}
		// Quitar los "Unknown Device" que crea InControl para el mando sin perfil.
		List<InputDevice> toDetach = new List<InputDevice>();
		foreach (InputDevice d in InputManager.Devices)
		{
			if (d != null && d != device && d.Name == "Unknown Device")
			{
				toDetach.Add(d);
			}
		}
		foreach (InputDevice d in toDetach)
		{
			InputManager.DetachDevice(d);
			Debug.Log("[ASH] Quitado: " + d.Name);
		}
		if (padName != null && device == null)
		{
			device = new AndroidGamepadDevice(padName);
			InputManager.AttachDevice(device);
			Debug.Log("[ASH] Mando Android activado: " + padName);
		}
		else if (padName == null && device != null)
		{
			InputManager.DetachDevice(device);
			device = null;
			Debug.Log("[ASH] Mando Android desconectado");
		}
	}
}
