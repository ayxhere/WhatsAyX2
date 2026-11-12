package com.wa.ayx

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicBoolean
import java.util.zip.ZipInputStream

/**
 * Owns the single embedded node process: extracts the bundled node project on
 * first run (or after an app update), sets the env node needs on Android, and
 * starts it exactly once per OS process.
 *
 * v195 lesson (from the original AyXWhatsapp app — copied here verbatim in
 * spirit): the once-per-process rule is load-bearing, not aspirational.
 * Embedded node::Start asserts (SIGABRT, whole app dies) if called twice in
 * one OS process — V8/platform globals from the first Start are still live.
 * So the start gate below is NEVER reset once nativeStart has been invoked.
 * After a node exit the gateway stays down until a FRESH process starts it
 * (app relaunch). A dead gateway is recoverable; a SIGABRT is not.
 *
 * Gateway entry point: the bundled backend's package.json main is
 * src/server.js (npm start = `node src/server.js`) — there is no main.js
 * at the project root, so node is started with src/server.js.
 */
object NodeRuntime {
    private const val TAG = "NodeRuntime"
    private val started = AtomicBoolean(false)
    // Permanent per-process gate for nativeStart. Set by CAS on the first
    // ensureStarted(); reset ONLY if setup throws before nativeStart ever
    // runs (V8 never initialized, so a retry is safe). Never reset after
    // nativeStart has been invoked.
    private val startAttempted = AtomicBoolean(false)

    const val PORT = 8765

    /** True while the embedded Node thread is believed alive. */
    fun isStarted(): Boolean = started.get()

    fun ensureStarted(ctx: Context) {
        // Permanent gate: once nativeStart has been invoked, every later
        // ensureStarted() in this process is a no-op. A second nativeStart
        // in one process asserts inside node::Start and SIGABRTs the app.
        if (!startAttempted.compareAndSet(false, true)) return

        // Setup may throw (extraction). If it throws BEFORE nativeStart
        // runs, V8 was never initialized, so reset the gate and let a later
        // ensureStarted() retry. projectDir/entryJs are pure path
        // constructions and stay outside the try.
        val projectDir = File(ctx.filesDir, "nodejs-project")
        try {
            extractIfNeeded(ctx, projectDir)

            // Android has no /tmp and no HOME — node/npm code assumes both exist.
            val authDir = File(ctx.noBackupFilesDir, "auth").apply { mkdirs() }
            val compileCache = File(ctx.cacheDir, "node-compile-cache").apply { mkdirs() }

            NodeBridge.nativeSetenv("TMPDIR", ctx.cacheDir.absolutePath)
            NodeBridge.nativeSetenv("HOME", ctx.filesDir.absolutePath)
            NodeBridge.nativeSetenv("NODE_COMPILE_CACHE", compileCache.absolutePath)
            // V8 sizes old-space from total RAM; cap it so the OS doesn't OOM-kill the app.
            NodeBridge.nativeSetenv("NODE_OPTIONS", "--max-old-space-size-percentage=50")
            // The v2 gateway (backend/src/server.js) reads PORT and AUTH_DIR.
            NodeBridge.nativeSetenv("PORT", PORT.toString())
            NodeBridge.nativeSetenv("AUTH_DIR", authDir.absolutePath)
            // Aliases kept for parity with the original gateway's env names.
            NodeBridge.nativeSetenv("WAGW_PORT", PORT.toString())
            NodeBridge.nativeSetenv("WAGW_AUTH_DIR", authDir.absolutePath)
        } catch (e: Exception) {
            startAttempted.set(false)
            Log.w(TAG, "node setup failed before start, will retry on next ensureStarted(): ${e.message}")
            return
        }

        val entryJs = File(projectDir, "src/server.js").absolutePath
        started.set(true)
        Thread({
            Log.i(TAG, "starting node: $entryJs")
            val rc = NodeBridge.nativeStart(arrayOf("node", entryJs), projectDir.absolutePath)
            // Do NOT reset startAttempted here. A second nativeStart in this
            // process asserts inside node::Start and SIGABRTs the app.
            // `started` is liveness only, so it still drops — but the
            // gateway only comes back in a FRESH process (app relaunch).
            started.set(false)
            Log.w(TAG, "node exited rc=$rc — gateway stays down until a fresh process starts it again (app relaunch)")
        }, "nodejs").start()
    }

    private fun extractIfNeeded(ctx: Context, projectDir: File) {
        val marker = File(projectDir, ".version")
        val current = ctx.packageManager.getPackageInfo(ctx.packageName, 0).lastUpdateTime.toString()
        if (marker.exists() && marker.readText() == current) return

        Log.i(TAG, "extracting nodejs-project.zip (v=$current)")
        projectDir.deleteRecursively()
        projectDir.mkdirs()

        ctx.assets.open("nodejs-project.zip").use { raw ->
            ZipInputStream(raw).use { zip ->
                var e = zip.nextEntry
                val buf = ByteArray(64 * 1024)
                while (e != null) {
                    val out = File(projectDir, e.name)
                    if (e.isDirectory) {
                        out.mkdirs()
                    } else {
                        out.parentFile?.mkdirs()
                        FileOutputStream(out).use { fos ->
                            var n = zip.read(buf)
                            while (n >= 0) { fos.write(buf, 0, n); n = zip.read(buf) }
                        }
                    }
                    zip.closeEntry()
                    e = zip.nextEntry
                }
            }
        }
        marker.writeText(current)
        Log.i(TAG, "extraction done")
    }
}
