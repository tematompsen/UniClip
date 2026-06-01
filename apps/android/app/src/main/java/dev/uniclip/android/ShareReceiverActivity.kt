package dev.uniclip.android

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Base64
import android.widget.Toast

class ShareReceiverActivity : Activity() {
    private val maxImageBytes = 12 * 1024 * 1024

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val type = intent.type.orEmpty()
        when {
            type == "text/plain" -> sendText()
            type.startsWith("image/") -> sendImage(type)
            else -> finishWithToast("Unsupported share type: ${type.ifBlank { "unknown" }}")
        }
    }

    private fun sendText() {
        val text = intent.getStringExtra(Intent.EXTRA_TEXT).orEmpty()
        if (text.isBlank()) {
            Toast.makeText(this, "No text to send", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        ClipSender().sendTextToAll(TrustRepository(this).list(), text, ::showToast)

        finish()
    }

    private fun sendImage(intentType: String) {
        val uri = extractImageUri()
        if (uri == null) {
            finishWithToast("No image to send")
            return
        }

        val result = runCatching {
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Cannot open image" }
                val bytes = input.readBytes()
                require(bytes.isNotEmpty()) { "Image is empty" }
                require(bytes.size <= maxImageBytes) { "Image is larger than 12 MB" }

                val contentType = contentResolver.getType(uri) ?: intentType
                val base64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
                ClipSender().sendImageToAll(TrustRepository(this).list(), contentType, base64, ::showToast)
            }
        }

        result.onFailure {
            finishWithToast(it.message ?: "Image send failed")
            return
        }

        finish()
    }

    @Suppress("DEPRECATION")
    private fun extractImageUri(): Uri? {
        return when (intent.action) {
            Intent.ACTION_SEND_MULTIPLE -> {
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.firstOrNull()
            }
            else -> intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun showToast(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
    }

    private fun finishWithToast(message: String) {
        showToast(message)
        finish()
    }
}
