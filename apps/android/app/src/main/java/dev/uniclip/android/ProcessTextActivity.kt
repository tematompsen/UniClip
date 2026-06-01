package dev.uniclip.android

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

class ProcessTextActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString().orEmpty()
        if (text.isBlank()) {
            Toast.makeText(this, "No text selected", Toast.LENGTH_SHORT).show()
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
