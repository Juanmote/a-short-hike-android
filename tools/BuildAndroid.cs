// Script de compilación para Android (lo llama el workflow 2).
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.Android;
using UnityEditor.SceneManagement;
using UnityEngine;

public static class BuildAndroid
{
    // Icono del port (pendiente)
    static void SetIcon()
    {
        Texture2D icon = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/PortAndroid/icon.png");
        Texture2D bg = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/PortAndroid/icon_adaptive_bg.png");
        Texture2D fg = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/PortAndroid/icon_transparent.png");
        if (icon == null) { Debug.LogWarning("[ASH] Sin icono"); return; }
        PlayerSettings.SetIconsForTargetGroup(BuildTargetGroup.Unknown, new[] { icon });
        foreach (PlatformIconKind kind in new PlatformIconKind[] { AndroidPlatformIconKind.Legacy, AndroidPlatformIconKind.Round, AndroidPlatformIconKind.Adaptive })
        {
            PlatformIcon[] icons = PlayerSettings.GetPlatformIcons(BuildTargetGroup.Android, kind);
            foreach (PlatformIcon pi in icons)
            {
                if (kind == AndroidPlatformIconKind.Adaptive) pi.SetTextures(bg, fg);
                else pi.SetTexture(icon);
            }
            PlayerSettings.SetPlatformIcons(BuildTargetGroup.Android, kind, icons);
        }
        Debug.Log("[ASH] Icono aplicado");
    }

    // ---- APK genérica (ASH_GENERIC=1): sin datos del juego, los genera la propia APK con la copia del usuario ----
    const string BootScene = "Assets/PortAndroid/ASHBoot.unity";

    // Escena vacía en el índice 0 que solo carga LogoScene: es lo único que queda dentro de la APK.
    static void MakeBootScene()
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var cam = new GameObject("Camera").AddComponent<Camera>();
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Color.black;
        Type boot = AppDomain.CurrentDomain.GetAssemblies().Select(a => a.GetType("ASHBoot")).FirstOrDefault(t => t != null);
        if (boot == null) throw new Exception("No se encuentra ASHBoot");
        new GameObject("ASHBoot").AddComponent(boot);
        EditorSceneManager.SaveScene(scene, BootScene);
        AssetDatabase.Refresh();
        Debug.Log("[ASH] Escena de arranque creada");
    }

    // Cada textura del juego en Android con el mismo formato que en PC (las DXT, sin comprimir),
    // para que la APK pueda rellenarla después con los datos de la copia del usuario.
    static void ApplyPcTextureFormats()
    {
        string tsv = Path.GetFullPath(Path.Combine(Application.dataPath, "../../tools/texformats.tsv"));
        int n = 0;
        foreach (string line in File.ReadAllLines(tsv))
        {
            if (line.Length == 0 || line[0] == '#') continue;
            string[] p = line.Split('\t');
            var imp = AssetImporter.GetAtPath(p[0]) as TextureImporter;
            if (imp == null) { Debug.LogWarning("[ASH] Textura no encontrada: " + p[0]); continue; }
            var fmt = (TextureImporterFormat)Enum.Parse(typeof(TextureImporterFormat), p[1]);
            var ps = imp.GetPlatformTextureSettings("Android");
            ps.overridden = true;
            ps.format = fmt;
            ps.maxTextureSize = 8192;
            ps.textureCompression = TextureImporterCompression.Uncompressed;
            imp.SetPlatformTextureSettings(ps);
            imp.mipmapEnabled = p[2] == "1";
            imp.npotScale = TextureImporterNPOTScale.None;
            imp.SaveAndReimport();
            n++;
        }
        Debug.Log("[ASH] Formatos de PC aplicados a " + n + " texturas");
    }

    public static void Build()
    {
        try
        {
            EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Android, BuildTarget.Android);
            PlayerSettings.companyName = "adamgryu";
            PlayerSettings.productName = "A Short Hike";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.juanmote.ashorthike");
            string ver = Environment.GetEnvironmentVariable("APK_VERSION") ?? "1";
            int code; if (!int.TryParse(ver, out code)) code = 1;
            string name = Environment.GetEnvironmentVariable("APK_VERSION_NAME");
            PlayerSettings.bundleVersion = string.IsNullOrEmpty(name) ? "1.0." + code : name;
            PlayerSettings.Android.bundleVersionCode = code;

            PlayerSettings.SetScriptingBackend(BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.SetApiCompatibilityLevel(BuildTargetGroup.Android, ApiCompatibilityLevel.NET_4_6);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel24;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
            PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { UnityEngine.Rendering.GraphicsDeviceType.OpenGLES3 });
            PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.Android.androidIsGame = true;
            PlayerSettings.Android.androidTVCompatibility = true;
            PlayerSettings.Android.startInFullscreen = true;
            PlayerSettings.Android.renderOutsideSafeArea = true;
            PlayerSettings.SplashScreen.show = false;
            EditorUserBuildSettings.buildAppBundle = false;

            // Firma fija opcional (secretos del repo). Sin ella Unity usa una firma de depuración.
            string ks = Environment.GetEnvironmentVariable("ANDROID_KEYSTORE_PATH");
            string kp = Environment.GetEnvironmentVariable("ANDROID_KEYSTORE_PASS");
            if (!string.IsNullOrEmpty(ks) && File.Exists(ks) && !string.IsNullOrEmpty(kp))
            {
                PlayerSettings.Android.useCustomKeystore = true;
                PlayerSettings.Android.keystoreName = ks;
                PlayerSettings.Android.keystorePass = kp;
                PlayerSettings.Android.keyaliasName = Environment.GetEnvironmentVariable("ANDROID_KEY_ALIAS") ?? "ash";
                PlayerSettings.Android.keyaliasPass = kp;
                Debug.Log("[ASH] Firmando con keystore propio");
            }

            SetIcon();

            string[] scenes = EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray();
            bool generic = Environment.GetEnvironmentVariable("ASH_GENERIC") == "1";
            PlayerSettings.Android.useAPKExpansionFiles = generic;
            if (generic)
            {
                ApplyPcTextureFormats();
                MakeBootScene();
                scenes = new[] { BootScene }.Concat(scenes).ToArray();
                Debug.Log("[ASH] Modo APK genérica (split binary)");
            }
            Debug.Log("[ASH] Escenas: " + scenes.Length);
            string outPath = Path.GetFullPath(Path.Combine(Application.dataPath, "../../build/AShortHike.apk"));
            Directory.CreateDirectory(Path.GetDirectoryName(outPath));
            BuildReport r = BuildPipeline.BuildPlayer(scenes, outPath, BuildTarget.Android, BuildOptions.None);
            Debug.Log("[ASH] Resultado: " + r.summary.result + " errores=" + r.summary.totalErrors + " tamaño=" + r.summary.totalSize);
            EditorApplication.Exit(r.summary.result == BuildResult.Succeeded ? 0 : 1);
        }
        catch (Exception e)
        {
            Debug.LogError("[ASH] Excepción: " + e);
            EditorApplication.Exit(1);
        }
    }
}

// Añade al manifiesto los permisos que necesita el port (vibración de consola y mando).
public class ASHManifestPermissions : IPostGenerateGradleAndroidProject
{
    public int callbackOrder => 999;

    public void OnPostGenerateGradleAndroidProject(string path)
    {
        string manifest = Path.Combine(path, "src", "main", "AndroidManifest.xml");
        if (!File.Exists(manifest)) { Debug.LogWarning("[ASH] Manifiesto no encontrado: " + manifest); return; }
        string xml = File.ReadAllText(manifest);
        if (!xml.Contains("android.permission.VIBRATE"))
        {
            int i = xml.IndexOf("<application", StringComparison.Ordinal);
            xml = xml.Insert(i, "<uses-permission android:name=\"android.permission.VIBRATE\" />\n  ");
            File.WriteAllText(manifest, xml);
            Debug.Log("[ASH] Permiso VIBRATE añadido al manifiesto");
        }
        else Debug.Log("[ASH] Permiso VIBRATE ya estaba en el manifiesto");
    }
}
