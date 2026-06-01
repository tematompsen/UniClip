package dev.uniclip.android

import android.os.Build
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.Executors

class ClipSender {
    private val executor = Executors.newSingleThreadExecutor()

    fun sendTextToAll(
        computers: List<TrustedComputer>,
        text: String,
        onResult: (String) -> Unit,
    ) {
        if (computers.isEmpty()) {
            onResult("No trusted Macs")
            return
        }

        sendToAll(computers, "text/plain", text, onResult)
    }

    fun sendImageToAll(
        computers: List<TrustedComputer>,
        contentType: String,
        base64Payload: String,
        onResult: (String) -> Unit,
    ) {
        sendToAll(computers, contentType, base64Payload, onResult)
    }

    private fun sendToAll(
        computers: List<TrustedComputer>,
        contentType: String,
        payload: String,
        onResult: (String) -> Unit,
    ) {
        if (computers.isEmpty()) {
            onResult("No trusted Macs")
            return
        }

        val deviceName = "${Build.MANUFACTURER} ${Build.MODEL}".trim()
        val message = ClipMessage(
            sourceDeviceId = "android-${Build.ID}",
            sourceDeviceName = deviceName,
            contentType = contentType,
            payload = payload,
        )

        computers.forEach { computer ->
            executor.execute {
                runCatching {
                    Socket().use { socket ->
                        socket.connect(InetSocketAddress(computer.host, computer.port), 3000)
                        val output = socket.getOutputStream()
                        output.write(message.toJson().toByteArray(Charsets.UTF_8))
                        output.write('\n'.code)
                        output.flush()
                        val ack = BufferedReader(InputStreamReader(socket.getInputStream())).readLine()
                        onResult(formatResult(computer, ack))
                    }
                }.onFailure {
                    onResult("${computer.name}: ${it.message ?: "send failed"}")
                }
            }
        }
    }

    private fun formatResult(computer: TrustedComputer, ack: String?): String {
        if (ack.isNullOrBlank()) return "✅"

        return runCatching {
            val json = JSONObject(ack)
            val status = json.optString("status")
            val detail = json.optString("detail")
            when (status) {
                "ok", "duplicate" -> "✅"
                "error" -> "${computer.name}: ${detail.ifBlank { "send failed" }}"
                else -> "${computer.name}: send failed"
            }
        }.getOrElse {
            "${computer.name}: send failed"
        }
    }
}
