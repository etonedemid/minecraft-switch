package org.lwjgl;

// LWJGL 2's Sys for the Pojav compat layer, which returned glfwGetTimerValue() (Pojav's GLFW counts milliseconds) while
// claiming a 1000 Hz resolution; upstream GLFW counts nanoseconds, so Minecraft's clock ran a million times fast and its
// once-a-second debug loop never caught up. Milliseconds from nanoTime, matching the stated resolution.
public final class Sys {
    private Sys() {}
    public static String getVersion() { return Version.getVersion(); }
    public static void initialize() {
        if (!org.lwjgl.glfw.GLFW.glfwInit()) throw new IllegalStateException("Unable to initialize GLFW");
    }
    public static long getTimerResolution() { return 1000; }
    public static long getTime() { return System.nanoTime() / 1_000_000; }
    public static long getNanoTime() { return System.nanoTime(); }
    public static boolean openURL(String url) { return false; }
    public static void alert(String title, String message) { System.err.println(title + ": " + message); }
    public static String getClipboard() { return null; }
}
