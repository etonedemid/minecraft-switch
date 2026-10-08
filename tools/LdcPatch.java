import java.lang.classfile.*;
import java.lang.classfile.instruction.ConstantInstruction;
import java.lang.constant.ConstantDesc;
import java.nio.file.*;

// java LdcPatch.java CLASSFILE OLD NEW [CLASSPATH] - replace string constant OLD by NEW in every ldc of the class, in place.
// Used for Minecraft's recipe/advancement listing, which accepts only file: and jar: URLs, while resources inside a native
// image are resource: URLs (whose filesystem provider GraalVM ships), so "jar" becomes "resource".
public class LdcPatch {
    public static void main(String[] a) throws Exception {
        Path p = Path.of(a[0]);
        int[] n = {0};
        // stack maps get regenerated, which needs the class hierarchy: resolve against the game classpath
        java.net.URL[] cp = a.length > 3 ? java.util.Arrays.stream(a[3].split(":")).filter(x -> !x.isEmpty())
            .map(x -> { try { return Path.of(x).toUri().toURL(); } catch (Exception ex) { throw new RuntimeException(ex); } })
            .toArray(java.net.URL[]::new) : new java.net.URL[0];
        ClassLoader cl = new java.net.URLClassLoader(cp, null);
        ClassFile cf = ClassFile.of(ClassFile.ClassHierarchyResolverOption.of(
            ClassHierarchyResolver.defaultResolver().orElse(ClassHierarchyResolver.ofResourceParsing(cl))));
        byte[] out = cf.transformClass(cf.parse(p), ClassTransform.transformingMethodBodies((cb, e) -> {
            if (e instanceof ConstantInstruction.LoadConstantInstruction ldc && a[1].equals(ldc.constantValue())) {
                cb.loadConstant((ConstantDesc) a[2]);
                n[0]++;
            } else cb.with(e);
        }));
        Files.write(p, out);
        System.out.println(p + ": " + n[0] + " replaced");
        if (n[0] == 0) System.exit(1);
    }
}
