package dev.uniclip.android

import org.json.JSONObject
import java.time.Instant
import java.util.UUID

data class TrustedComputer(
    val name: String,
    val host: String,
    val port: Int,
)

data class DiscoveredComputer(
    val name: String,
    val host: String,
    val port: Int,
)

data class ClipMessage(
    val protocolVersion: Int = 1,
    val clipId: String = UUID.randomUUID().toString(),
    val sourceDeviceId: String,
    val sourceDeviceName: String,
    val contentType: String,
    val createdAt: String = Instant.now().toString(),
    val ttlSeconds: Int = 300,
    val payload: String,
) {
    fun toJson(): String {
        return JSONObject()
            .put("protocolVersion", protocolVersion)
            .put("clipId", clipId)
            .put("sourceDeviceId", sourceDeviceId)
            .put("sourceDeviceName", sourceDeviceName)
            .put("contentType", contentType)
            .put("createdAt", createdAt)
            .put("ttlSeconds", ttlSeconds)
            .put("payload", payload)
            .toString()
    }
}
