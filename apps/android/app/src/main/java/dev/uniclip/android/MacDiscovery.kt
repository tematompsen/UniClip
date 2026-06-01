package dev.uniclip.android

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo

class MacDiscovery(context: Context) {
    private val nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    private var discoveryListener: NsdManager.DiscoveryListener? = null

    fun start(onFound: (DiscoveredComputer) -> Unit, onError: (String) -> Unit) {
        stop()

        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) = Unit

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                if (serviceInfo.serviceType != "_uniclip._tcp.") return
                nsdManager.resolveService(serviceInfo, object : NsdManager.ResolveListener {
                    override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                        onError("Resolve failed: $errorCode")
                    }

                    override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                        val host = serviceInfo.host?.hostAddress ?: return
                        val port = serviceInfo.port
                        if (port <= 0) return
                        onFound(
                            DiscoveredComputer(
                                name = serviceInfo.serviceName,
                                host = host,
                                port = port,
                            )
                        )
                    }
                })
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) = Unit

            override fun onDiscoveryStopped(serviceType: String) = Unit

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                onError("Discovery start failed: $errorCode")
                stop()
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                onError("Discovery stop failed: $errorCode")
                stop()
            }
        }

        discoveryListener = listener
        nsdManager.discoverServices("_uniclip._tcp.", NsdManager.PROTOCOL_DNS_SD, listener)
    }

    fun stop() {
        discoveryListener?.let {
            runCatching { nsdManager.stopServiceDiscovery(it) }
        }
        discoveryListener = null
    }
}
