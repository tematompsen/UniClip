package dev.uniclip.android

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

class ShareReceiverActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        when (intent.type) {
            "text/plain" -> sendText()
            else -> {
                Toast.makeText(this, "Image/file transfer is next phase", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun sendText() {
        val text = intent.getStringExtra(Intent.EXTRA_TEXT).orEmpty()
        if (text.isBlank()) {
            Toast.makeText(this, "No text to send", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        val computers = TrustRepository(this).list()
        ClipSender().sendTextToAll(computers, text) { result ->
            runOnUiThread {
                Toast.makeText(this, result, Toast.LENGTH_SHORT).show()
            }
        }

        finish()
    }
}
