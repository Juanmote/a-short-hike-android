using UnityEngine;
using UnityEngine.SceneManagement;

// Escena de arranque de la APK genérica: no lleva nada del juego y solo carga la primera escena real.
// Así la APK contiene únicamente esta escena; el resto va en la OBB que se genera con la copia del usuario.
public class ASHBoot : MonoBehaviour
{
	private void Start()
	{
		SceneManager.LoadScene("LogoScene");
	}
}
