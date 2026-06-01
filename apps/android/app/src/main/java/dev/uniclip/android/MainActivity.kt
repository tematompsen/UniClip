package dev.uniclip.android

import android.app.Activity
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
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
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            MaterialTheme {
                Surface {
                    UniClipScreen(this)
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
            .padding(20.dp),
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
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(discovered) { computer ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Column {
                        Text(computer.name)
                        Text("${computer.host}:${computer.port}", style = MaterialTheme.typography.bodySmall)
                    }
                    Button(
                        onClick = {
                            val trustedComputer = TrustedComputer(computer.name, computer.host, computer.port)
                            repository.add(trustedComputer)
                            trusted.clear()
                            trusted.addAll(repository.list())
                            status.value = "Added ${computer.name}"
                        }
                    ) {
                        Text("Add")
                    }
                }
            }
        }

        SectionTitle("Trusted Macs")
        LazyColumn(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(trusted) { computer ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Column {
                        Text(computer.name)
                        Text("${computer.host}:${computer.port}", style = MaterialTheme.typography.bodySmall)
                    }
                    OutlinedButton(
                        onClick = {
                            repository.remove(computer)
                            trusted.clear()
                            trusted.addAll(repository.list())
                            status.value = "Removed ${computer.name}"
                        }
                    ) {
                        Text("Remove")
                    }
                }
            }
        }

        Spacer(modifier = Modifier.weight(1f))
        Text("Selected text and share sheet send to all trusted Macs.", style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text, style = MaterialTheme.typography.titleMedium)
}
