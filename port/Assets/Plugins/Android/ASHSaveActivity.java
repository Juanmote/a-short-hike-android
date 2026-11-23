package com.juanmote.ashorthike;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

// Port Android de A Short Hike: exportar / importar partidas con el selector de archivos de Android.
// Actividad transparente sin interfaz: abre el selector, copia el archivo y se cierra.
// La llama ASHSaves.cs y consulta el resultado con result():
//   "pending" mientras trabaja, "ok", "cancel" o "error:<motivo>".
public class ASHSaveActivity extends Activity {
    static final int REQ = 4321;
    static volatile String sResult = "idle";

    String mMode;   // "export" o "import"
    String mPath;   // export: archivo de origen; import: archivo temporal de destino

    public static void start(String mode, String path, String suggestedName) {
        Activity a = com.unity3d.player.UnityPlayer.currentActivity;
        if (a == null) { sResult = "error:sin actividad"; return; }
        sResult = "pending";
        Intent i = new Intent(a, ASHSaveActivity.class);
        i.putExtra("mode", mode);
        i.putExtra("path", path);
        i.putExtra("name", suggestedName);
        a.startActivity(i);
    }

    public static String result() { return sResult; }

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        mMode = getIntent().getStringExtra("mode");
        mPath = getIntent().getStringExtra("path");
        if (b != null) return; // recreada: el selector ya está abierto
        try {
            Intent i;
            if ("export".equals(mMode)) {
                i = new Intent(Intent.ACTION_CREATE_DOCUMENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                i.setType("application/octet-stream");
                i.putExtra(Intent.EXTRA_TITLE, getIntent().getStringExtra("name"));
            } else {
                i = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                i.setType("*/*");
            }
            startActivityForResult(i, REQ);
        } catch (Throwable t) {
            finishWith("error:" + t.getClass().getSimpleName());
        }
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        if (req != REQ) return;
        if (res != RESULT_OK || data == null || data.getData() == null) { finishWith("cancel"); return; }
        final Uri uri = data.getData();
        new Thread(new Runnable() {
            @Override
            public void run() {
                String r;
                try {
                    if ("export".equals(mMode)) {
                        copy(new FileInputStream(new File(mPath)), getContentResolver().openOutputStream(uri, "wt"));
                    } else {
                        File tmp = new File(mPath);
                        if (tmp.exists()) tmp.delete();
                        copy(getContentResolver().openInputStream(uri), new FileOutputStream(tmp));
                    }
                    r = "ok";
                } catch (Throwable t) {
                    android.util.Log.w("ASH", "Partidas: " + t);
                    r = "error:" + t.getClass().getSimpleName();
                }
                final String fr = r;
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() { finishWith(fr); }
                });
            }
        }).start();
    }

    static void copy(InputStream in, OutputStream out) throws Exception {
        if (in == null || out == null) throw new java.io.IOException("no se puede abrir");
        try {
            byte[] buf = new byte[65536];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            out.flush();
        } finally {
            try { in.close(); } catch (Throwable ignored) { }
            try { out.close(); } catch (Throwable ignored) { }
        }
    }

    void finishWith(String r) {
        sResult = r;
        finish();
        overridePendingTransition(0, 0);
    }
}
