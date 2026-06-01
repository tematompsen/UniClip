#!/usr/bin/env swift

import Foundation
import Network

let host = NWEndpoint.Host(ProcessInfo.processInfo.environment["UNICLIP_HOST"] ?? "127.0.0.1")
let port = NWEndpoint.Port(ProcessInfo.processInfo.environment["UNICLIP_PORT"] ?? "47191")!
let text = CommandLine.arguments.dropFirst().joined(separator: " ")

guard !text.isEmpty else {
    fputs("Usage: scripts/send-test-clip.swift \"text to send\"\n", stderr)
    exit(2)
}

let payload: [String: Any] = [
    "protocolVersion": 1,
    "clipId": UUID().uuidString,
    "sourceDeviceId": "local-test",
    "sourceDeviceName": "Local Test",
    "contentType": "text/plain",
    "createdAt": ISO8601DateFormatter().string(from: Date()),
    "ttlSeconds": 300,
    "payload": text
]

var data = try JSONSerialization.data(withJSONObject: payload)
data.append(0x0A)
let connection = NWConnection(host: host, port: port, using: .tcp)
let queue = DispatchQueue(label: "dev.uniclip.test-sender")
let semaphore = DispatchSemaphore(value: 0)

connection.stateUpdateHandler = { state in
    switch state {
    case .ready:
        connection.send(content: data, completion: .contentProcessed { error in
            if let error {
                fputs("Send failed: \(error)\n", stderr)
                semaphore.signal()
                return
            }

            connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { ack, _, _, _ in
                if let ack, let text = String(data: ack, encoding: .utf8) {
                    print(text)
                }
                semaphore.signal()
            }
        })
    case .failed(let error):
        fputs("Connection failed: \(error)\n", stderr)
        semaphore.signal()
    default:
        break
    }
}

connection.start(queue: queue)
_ = semaphore.wait(timeout: .now() + 5)
connection.cancel()
