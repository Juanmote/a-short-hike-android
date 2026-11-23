import com.juanmote.ashorthike.ASHBundle;
import com.juanmote.ashorthike.ASHObbBuilder;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.FileChannel;
import java.util.HashMap;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

// Prueba en PC de lo que hace la APK genérica: genera la OBB con el manifiesto de una variante y la
// copia del juego, usando el mismo código Java (ASHObbBuilder, ASHBundle).
// Uso: java ObbTest APK_GENERICA VARIANTE CARPETA_AShortHike_Data SALIDA.obb
public class ObbTest {
    public static void main(String[] a) throws Exception {
        final ZipFile apk = new ZipFile(a[0]);
        final String data = a[2];
        final HashMap<String, FileChannel> open = new HashMap<String, FileChannel>();
        final HashMap<String, Long> base = new HashMap<String, Long>();
        final HashMap<String, File> unpacked = new HashMap<String, File>();
        ASHObbBuilder b = new ASHObbBuilder(true, new ASHObbBuilder.Io() {
            public InputStream molde(String name) throws IOException {
                ZipEntry e = apk.getEntry("assets/ash/molde/" + name);
                return apk.getInputStream(e);
            }
            public FileChannel source(String name) throws IOException {
                FileChannel ch = open.get(name);
                if (ch == null) {
                    String file = name.split("\\|")[0];
                    File f = unpacked.containsKey(file) ? unpacked.get(file) : new File(data, file);
                    ch = new FileInputStream(f).getChannel();
                    open.put(name, ch);
                }
                return ch;
            }
            public long base(String name) { Long v = base.get(name); return v == null ? 0 : v; }
            public void progress(long done, long total) { }
        });
        if (!b.parse(apk.getInputStream(apk.getEntry("assets/ash/manifest-" + a[1] + ".txt")))) throw new Exception("manifiesto");
        int i = 0;
        for (Object o : b.sources()) {
            String name = (String) o;
            if (name.indexOf('|') < 0) continue;
            String file = name.split("\\|")[0];
            if (!unpacked.containsKey(file)) {
                File out = File.createTempFile("bundle" + (i++), ".bin");
                out.deleteOnExit();
                ASHBundle bu = new ASHBundle();
                FileChannel ch = new FileInputStream(new File(data, file)).getChannel();
                bu.unpack(ch, out);
                ch.close();
                unpacked.put(file, out);
                for (Object o2 : b.sources()) {
                    String n2 = (String) o2;
                    if (n2.startsWith(file + "|")) base.put(n2, bu.nodes.get(n2.substring(file.length() + 1))[0]);
                }
            }
        }
        String err = b.writeZip(new File(a[3]));
        System.out.println(err == null ? "OK " + a[1] + " " + b.zipSize() + " bytes" : "ERROR " + err);
        if (err != null) System.exit(1);
    }
}
