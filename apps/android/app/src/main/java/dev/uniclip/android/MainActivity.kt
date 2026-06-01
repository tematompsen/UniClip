package dev.uniclip.android

import android.app.Activity
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val activity = this

        setContent {
            MaterialTheme {
                Surface {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .systemBarsPadding()
                            .navigationBarsPadding()
                    ) {
                        UniClipScreen(activity)
                    }
                }
            }
        }
    }
}

@Composable
private fun UniClipScreen(activity: Activity) {
    val repository = remember { TrustRepository(activity) }
    val discovery = remember { MacDiscovery(activity) }
    val trusted = remember { mutableStateListOf<TrustedComputer>().also { it.addAll(repository.list()) } }
    val discovered = remember { mutableStateListOf<DiscoveredComputer>() }
    val status = remember { mutableStateOf("Ready") }

    DisposableEffect(Unit) {
        onDispose { discovery.stop() }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("UniClip", style = MaterialTheme.typography.headlineMedium)
        Text(status.value, style = MaterialTheme.typography.bodyMedium)

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(
                onClick = {
                    discovered.clear()
                    status.value = "Scanning LAN"
                    discovery.start(
                        onFound = { computer ->
                            activity.runOnUiThread {
                                if (discovered.none { it.host == computer.host && it.port == computer.port }) {
                                    discovered.add(computer)
                                }
                                status.value = "Found ${discovered.size} Mac receiver(s)"
                            }
                        },
                        onError = { error ->
                            activity.runOnUiThread { status.value = error }
                        },
                    )
                }
            ) {
                Text("Scan")
            }
            OutlinedButton(
                onClick = {
                    discovery.stop()
                    status.value = "Scan stopped"
                }
            ) {
                Text("Stop")
            }
        }

        SectionTitle("Available Macs")
        if (discovered.isEmpty()) {
            EmptyText("Tap Scan to find Macs on this Wi-Fi.")
        } else {
            discovered.forEach { computer ->
                ComputerCard(
                    name = computer.name,
                    endpoint = "${computer.host}:${computer.port}",
                    actionText = if (trusted.any { it.host == computer.host && it.port == computer.port }) {
                        "Added"
                    } else {
                        "Add"
                    },
                    enabled = trusted.none { it.host == computer.host && it.port == computer.port },
                    outlined = false,
                    onAction = {
                        val trustedComputer = TrustedComputer(computer.name, computer.host, computer.port)
                        repository.add(trustedComputer)
                        trusted.clear()
                        trusted.addAll(repository.list())
                        status.value = "Added ${computer.name}"
                    }
                )
            }
        }

        SectionTitle("Trusted Macs")
        if (trusted.isEmpty()) {
            EmptyText("Added Macs appear here.")
        } else {
            trusted.forEach { computer ->
                ComputerCard(
                    name = computer.name,
                    endpoint = "${computer.host}:${computer.port}",
                    actionText = "Remove",
                    enabled = true,
                    outlined = true,
                    onAction = {
                        repository.remove(computer)
                        trusted.clear()
                        trusted.addAll(repository.list())
                        status.value = "Removed ${computer.name}"
                    }
                )
            }
        }

        Spacer(modifier = Modifier.size(8.dp))
        Text("Selected text and share sheet send to all trusted Macs.", style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
}

@Composable
private fun EmptyText(text: String) {
    Text(text, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
}

@Composable
private fun ComputerCard(
    name: String,
    endpoint: String,
    actionText: String,
    enabled: Boolean,
    outlined: Boolean,
    onAction: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(modifier = Modifier.weight(1f).padding(end = 12.dp)) {
                Text(name, style = MaterialTheme.typography.titleMedium)
                Text(endpoint, style = MaterialTheme.typography.bodySmall)
            }

            if (outlined) {
                OutlinedButton(onClick = onAction, enabled = enabled) {
                    Text(actionText)
                }
            } else {
                Button(onClick = onAction, enabled = enabled) {
                    Text(actionText)
                }
            }
        }
    }
}
