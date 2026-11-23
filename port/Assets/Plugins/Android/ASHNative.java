package com.juanmote.ashorthike;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.Display;
import android.view.InputDevice;
import android.view.Window;
import android.view.WindowManager;

import com.unity3d.player.UnityPlayer;

// Port Android de A Short Hike: vibración (consola y mando) y frecuencia de la pantalla (30/60/120).
// Lo llaman ASHRumble.cs y ASHDisplay.cs.
public class ASHNative {
    private static Handler sWorker;

    private static synchronized Handler worker() {
        if (sWorker == null) {
            HandlerThread thread = new HandlerThread("ash-native");
            thread.start();
            sWorker = new Handler(thread.getLooper());
        }
        return sWorker;
    }

    // ----- Vibración -----
    public static void rumble(final long ms, final int amplitude) {
        worker().post(new Runnable() {
            @Override
            public void run() {
                Activity a = UnityPlayer.currentActivity;
                if (a == null) return;
                try {
                    vibrateWith((Vibrator) a.getSystemService(Context.VIBRATOR_SERVICE), ms, amplitude);
                } catch (Throwable t) {
                    android.util.Log.w("ASH", "Vibración consola: " + t);
                }
                // Mandos con motor propio (el integrado de algunas consolas se declara como externo).
                try {
                    for (int id : InputDevice.getDeviceIds()) {
                        InputDevice d = InputDevice.getDevice(id);
                        if (d == null || d.isVirtual()) continue;
                        int s = d.getSources();
                        boolean pad = (s & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
                                || (s & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
                        if (!pad) continue;
                        java.util.List<Vibrator> list = padVibrators(d);
                        for (Vibrator v : list) {
                            try {
                                vibrateWith(v, ms, amplitude);
                            } catch (Throwable t) {
                                android.util.Log.w("ASH", "Vibración mando: " + t);
                            }
                        }
                    }
                } catch (Throwable ignored) {
                }
            }
        });
    }

    // Diagnóstico: "permiso=1 consola=1 mandos=1" (lo muestra Opciones › Controles si algo falta).
    public static String status() {
        Activity a = UnityPlayer.currentActivity;
        if (a == null) return "sin actividad";
        int perm = a.checkCallingOrSelfPermission("android.permission.VIBRATE") == android.content.pm.PackageManager.PERMISSION_GRANTED ? 1 : 0;
        int console = 0, pads = 0;
        try {
            Vibrator v = (Vibrator) a.getSystemService(Context.VIBRATOR_SERVICE);
            console = (v != null && v.hasVibrator()) ? 1 : 0;
        } catch (Throwable ignored) {
        }
        try {
            for (int id : InputDevice.getDeviceIds()) {
                InputDevice d = InputDevice.getDevice(id);
                if (d == null || d.isVirtual()) continue;
                for (Vibrator v : padVibrators(d)) {
                    if (v.hasVibrator()) { pads++; break; }
                }
            }
        } catch (Throwable ignored) {
        }
        return "permiso=" + perm + " consola=" + console + " mandos=" + pads;
    }

    // Motores de un mando. En Android 12+ con VibratorManager (por reflexión, compila con cualquier SDK).
    private static java.util.List<Vibrator> padVibrators(InputDevice d) {
        java.util.List<Vibrator> list = new java.util.ArrayList<Vibrator>();
        if (Build.VERSION.SDK_INT >= 31) {
            try {
                Class<?> vmClass = Class.forName("android.os.VibratorManager");
                Object vm = InputDevice.class.getMethod("getVibratorManager").invoke(d);
                int[] ids = (int[]) vmClass.getMethod("getVibratorIds").invoke(vm);
                java.lang.reflect.Method get = vmClass.getMethod("getVibrator", int.class);
                for (int id : ids) list.add((Vibrator) get.invoke(vm, id));
            } catch (Throwable ignored) {
            }
        }
        if (list.isEmpty()) {
            try {
                list.add(d.getVibrator());
            } catch (Throwable ignored) {
            }
        }
        return list;
    }

    private static void vibrateWith(Vibrator v, long ms, int amplitude) {
        if (v == null || !v.hasVibrator()) return;
        if (Build.VERSION.SDK_INT >= 26) {
            int amp = v.hasAmplitudeControl() ? amplitude : VibrationEffect.DEFAULT_AMPLITUDE;
            v.vibrate(VibrationEffect.createOneShot(ms, amp));
        } else {
            v.vibrate(ms);
        }
    }

    // ----- Frecuencia de pantalla -----
    // hz > 60: pide el modo de pantalla más rápido con la misma resolución (120 Hz si lo hay).
    // En otro caso deja que Android elija.
    public static void setRefreshRate(final float hz) {
        final Activity a = UnityPlayer.currentActivity;
        if (a == null || Build.VERSION.SDK_INT < 23) return;
        a.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Window w = a.getWindow();
                    Display display = w.getWindowManager().getDefaultDisplay();
                    Display.Mode cur = display.getMode();
                    int best = 0;
                    float bestHz = 0f;
                    if (hz > 61f) {
                        for (Display.Mode m : display.getSupportedModes()) {
                            if (m.getPhysicalWidth() != cur.getPhysicalWidth() || m.getPhysicalHeight() != cur.getPhysicalHeight()) continue;
                            float r = m.getRefreshRate();
                            // El más cercano a lo pedido sin quedarse corto; si no hay, el más rápido.
                            boolean better;
                            if (bestHz == 0f) better = true;
                            else if (bestHz < hz - 1f) better = r > bestHz;
                            else better = r >= hz - 1f && r < bestHz;
                            if (better) {
                                best = m.getModeId();
                                bestHz = r;
                            }
                        }
                    }
                    WindowManager.LayoutParams lp = w.getAttributes();
                    lp.preferredDisplayModeId = best;
                    lp.preferredRefreshRate = hz > 61f ? bestHz : 0f;
                    w.setAttributes(lp);
                    android.util.Log.i("ASH", "Pantalla: pedido " + hz + " Hz -> modo " + best + " (" + bestHz + " Hz)");
                } catch (Throwable t) {
                    android.util.Log.w("ASH", "Pantalla: " + t);
                }
            }
        });
    }
}
