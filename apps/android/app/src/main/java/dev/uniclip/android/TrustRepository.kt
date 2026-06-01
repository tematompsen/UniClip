package dev.uniclip.android

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class TrustRepository(context: Context) {
    private val preferences = context.getSharedPreferences("trusted_computers", Context.MODE_PRIVATE)

    fun list(): List<TrustedComputer> {
        val raw = preferences.getString("computers", "[]") ?: "[]"
        val items = JSONArray(raw)
        return buildList {
            for (index in 0 until items.length()) {
                val item = items.getJSONObject(index)
                add(
                    TrustedComputer(
                        name = item.getString("name"),
                        host = item.getString("host"),
                        port = item.getInt("port"),
                    )
                )
            }
        }
    }

    fun add(computer: TrustedComputer) {
        val next = list()
            .filterNot { it.host == computer.host && it.port == computer.port }
            .plus(computer)

        val json = JSONArray()
        next.forEach {
            json.put(
                JSONObject()
                    .put("name", it.name)
                    .put("host", it.host)
                    .put("port", it.port)
            )
        }

        preferences.edit().putString("computers", json.toString()).apply()
    }

    fun remove(computer: TrustedComputer) {
        val next = list().filterNot { it.host == computer.host && it.port == computer.port }
        val json = JSONArray()
        next.forEach {
            json.put(
                JSONObject()
                    .put("name", it.name)
                    .put("host", it.host)
                    .put("port", it.port)
            )
        }

        preferences.edit().putString("computers", json.toString()).apply()
    }
}
