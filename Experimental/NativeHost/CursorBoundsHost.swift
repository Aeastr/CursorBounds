#!/usr/bin/env swift
//
// CursorBoundsHost.swift
// Native Messaging Host for CursorBounds Chrome Extension
//
// This receives cursor position data from the Chrome extension
// and makes it available to other apps via a local file/socket.
//

import Foundation

struct CursorPosition: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let isSelection: Bool
    let charOffset: Int?
    let tabId: Int?
    let url: String?
    let timestamp: Int64
}

struct Message: Codable {
    let type: String
    let data: CursorPosition?
}

// Path to store the latest cursor position
let positionFilePath = "/tmp/cursorbounds_position.json"

// Read a message from stdin (Chrome native messaging format)
func readMessage() -> Data? {
    // First 4 bytes are message length (little-endian)
    var lengthBytes = [UInt8](repeating: 0, count: 4)
    let bytesRead = fread(&lengthBytes, 1, 4, stdin)

    if bytesRead < 4 {
        return nil
    }

    let length = UInt32(lengthBytes[0]) |
                 (UInt32(lengthBytes[1]) << 8) |
                 (UInt32(lengthBytes[2]) << 16) |
                 (UInt32(lengthBytes[3]) << 24)

    if length == 0 || length > 1024 * 1024 {
        return nil
    }

    var messageBytes = [UInt8](repeating: 0, count: Int(length))
    let messageRead = fread(&messageBytes, 1, Int(length), stdin)

    if messageRead < Int(length) {
        return nil
    }

    return Data(messageBytes)
}

// Write a message to stdout (Chrome native messaging format)
func writeMessage(_ message: [String: Any]) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        return
    }

    let length = UInt32(jsonData.count)
    var lengthBytes = [UInt8](repeating: 0, count: 4)
    lengthBytes[0] = UInt8(length & 0xFF)
    lengthBytes[1] = UInt8((length >> 8) & 0xFF)
    lengthBytes[2] = UInt8((length >> 16) & 0xFF)
    lengthBytes[3] = UInt8((length >> 24) & 0xFF)

    fwrite(lengthBytes, 1, 4, stdout)
    fwrite(jsonString, 1, jsonData.count, stdout)
    fflush(stdout)
}

// Save position to file for other apps to read
func savePosition(_ position: CursorPosition) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    if let data = try? encoder.encode(position),
       let jsonString = String(data: data, encoding: .utf8) {
        try? jsonString.write(toFile: positionFilePath, atomically: true, encoding: .utf8)
    }
}

// Log to stderr (for debugging)
func log(_ message: String) {
    fputs("[CursorBoundsHost] \(message)\n", stderr)
}

// Main loop
func main() {
    log("Native host started")

    // Send ready message
    writeMessage(["type": "READY", "version": "1.0.0"])

    while true {
        guard let data = readMessage() else {
            log("No more messages, exiting")
            break
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let messageType = json["type"] as? String ?? ""

                log("Received message: \(messageType)")

                if messageType == "CURSOR_POSITION" {
                    if let positionData = json["data"] as? [String: Any] {
                        let position = CursorPosition(
                            x: positionData["x"] as? Double ?? 0,
                            y: positionData["y"] as? Double ?? 0,
                            width: positionData["width"] as? Double ?? 0,
                            height: positionData["height"] as? Double ?? 0,
                            isSelection: positionData["isSelection"] as? Bool ?? false,
                            charOffset: positionData["charOffset"] as? Int,
                            tabId: positionData["tabId"] as? Int,
                            url: positionData["url"] as? String,
                            timestamp: positionData["timestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
                        )

                        savePosition(position)
                        log("Position saved: (\(position.x), \(position.y))")

                        // Acknowledge
                        writeMessage(["type": "ACK", "received": true])
                    }
                }
            }
        } catch {
            log("Error parsing message: \(error)")
        }
    }

    log("Native host exiting")
}

main()
