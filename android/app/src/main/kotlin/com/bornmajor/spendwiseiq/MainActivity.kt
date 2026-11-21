package com.bornmajor.spendwiseiq

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth for the biometric prompt.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "save") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val name = call.argument<String>("name")
                val mimeType = call.argument<String>("mimeType")
                val bytes = call.argument<ByteArray>("bytes")
                if (name == null || mimeType == null || bytes == null) {
                    result.error("bad_arguments", "Missing name, mimeType or bytes", null)
                    return@setMethodCallHandler
                }
                // Before Android 10 writing to Downloads needs a storage
                // permission this app does not ask for; Dart falls back to the
                // share sheet.
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    result.error("unsupported", "Needs Android 10 or newer", null)
                    return@setMethodCallHandler
                }
                try {
                    saveToDownloads(name, mimeType, bytes)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("failed", e.message, null)
                }
            }
    }

    /** Writes a file into the public Downloads folder. No permission needed. */
    private fun saveToDownloads(name: String, mimeType: String, bytes: ByteArray) {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Could not create the file")
        try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Could not open the file")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    private companion object {
        const val DOWNLOADS_CHANNEL = "com.bornmajor.spendwiseiq/downloads"
    }
}
