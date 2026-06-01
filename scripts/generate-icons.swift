#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let macResources = root.appendingPathComponent("apps/macos/Resources")
let androidRes = root.appendingPathComponent("apps/android/app/src/main/res")
let androidDrawable = androidRes.appendingPathComponent("drawable")
let androidMipmap = androidRes.appendingPathComponent("mipmap-anydpi-v26")
let androidValues = androidRes.appendingPathComponent("values")
let iconset = root.appendingPathComponent("apps/macos/Resources/UniClip.iconset")

for directory in [macResources, androidDrawable, androidMipmap, androidValues, iconset] {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
}

func writeText(_ text: String, to url: URL) throws {
    try text.data(using: .utf8)!.write(to: url)
}

func image(size: CGFloat, statusBar: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    if statusBar {
        NSColor.black.setStroke()
        let stroke = NSBezierPath()
        stroke.lineWidth = max(1.7, size * 0.075)
        stroke.lineCapStyle = .round
        stroke.lineJoinStyle = .round

        let clipRect = NSRect(x: size * 0.27, y: size * 0.18, width: size * 0.46, height: size * 0.58)
        stroke.appendRoundedRect(clipRect, xRadius: size * 0.06, yRadius: size * 0.06)
        stroke.move(to: NSPoint(x: size * 0.40, y: size * 0.78))
        stroke.line(to: NSPoint(x: size * 0.60, y: size * 0.78))
        stroke.move(to: NSPoint(x: size * 0.37, y: size * 0.54))
        stroke.line(to: NSPoint(x: size * 0.63, y: size * 0.54))
        stroke.move(to: NSPoint(x: size * 0.37, y: size * 0.40))
        stroke.line(to: NSPoint(x: size * 0.63, y: size * 0.40))
        stroke.stroke()

        let arrow = NSBezierPath()
        arrow.lineWidth = max(1.7, size * 0.075)
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .round
        arrow.move(to: NSPoint(x: size * 0.18, y: size * 0.40))
        arrow.line(to: NSPoint(x: size * 0.08, y: size * 0.50))
        arrow.line(to: NSPoint(x: size * 0.18, y: size * 0.60))
        arrow.move(to: NSPoint(x: size * 0.82, y: size * 0.40))
        arrow.line(to: NSPoint(x: size * 0.92, y: size * 0.50))
        arrow.line(to: NSPoint(x: size * 0.82, y: size * 0.60))
        arrow.stroke()

        image.unlockFocus()
        return image
    }

    let rounded = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.055, dy: size * 0.055), xRadius: size * 0.22, yRadius: size * 0.22)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.10, green: 0.43, blue: 0.78, alpha: 1.0),
        NSColor(calibratedRed: 0.19, green: 0.78, blue: 0.66, alpha: 1.0)
    ])!.draw(in: rounded, angle: 35)

    NSColor(calibratedWhite: 1.0, alpha: 0.18).setStroke()
    rounded.lineWidth = size * 0.015
    rounded.stroke()

    NSColor.white.setFill()
    let board = NSBezierPath(roundedRect: NSRect(x: size * 0.30, y: size * 0.20, width: size * 0.40, height: size * 0.57), xRadius: size * 0.045, yRadius: size * 0.045)
    board.fill()

    NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.40, alpha: 1).setFill()
    let paper = NSBezierPath(roundedRect: NSRect(x: size * 0.35, y: size * 0.28, width: size * 0.30, height: size * 0.37), xRadius: size * 0.025, yRadius: size * 0.025)
    paper.fill()

    NSColor.white.withAlphaComponent(0.88).setStroke()
    for y in [0.39, 0.50, 0.61] {
        let line = NSBezierPath()
        line.lineWidth = size * 0.023
        line.lineCapStyle = .round
        line.move(to: NSPoint(x: size * 0.39, y: size * y))
        line.line(to: NSPoint(x: size * 0.61, y: size * y))
        line.stroke()
    }

    NSColor.white.setFill()
    let tab = NSBezierPath(roundedRect: NSRect(x: size * 0.40, y: size * 0.70, width: size * 0.20, height: size * 0.08), xRadius: size * 0.035, yRadius: size * 0.035)
    tab.fill()

    NSColor(calibratedRed: 0.03, green: 0.18, blue: 0.29, alpha: 0.38).setStroke()
    let link = NSBezierPath()
    link.lineWidth = size * 0.055
    link.lineCapStyle = .round
    link.move(to: NSPoint(x: size * 0.18, y: size * 0.50))
    link.line(to: NSPoint(x: size * 0.30, y: size * 0.50))
    link.move(to: NSPoint(x: size * 0.70, y: size * 0.50))
    link.line(to: NSPoint(x: size * 0.82, y: size * 0.50))
    link.stroke()

    image.unlockFocus()
    return image
}

func pngData(_ image: NSImage, size: CGFloat) throws -> Data {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "UniClipIcon", code: 1)
    }
    bitmap.size = NSSize(width: size, height: size)
    return data
}

let appIcon1024 = image(size: 1024)
try pngData(appIcon1024, size: 1024).write(to: macResources.appendingPathComponent("UniClip-1024.png"))
try pngData(image(size: 36, statusBar: true), size: 36).write(to: macResources.appendingPathComponent("StatusBarIconTemplate.png"))

let iconSizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconSizes {
    try pngData(image(size: size), size: size).write(to: iconset.appendingPathComponent(name))
}

let foreground = """
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FFFFFF" android:pathData="M35,26h38a6,6 0,0 1,6 6v54a6,6 0,0 1,-6 6H35a6,6 0,0 1,-6 -6V32a6,6 0,0 1,6 -6z"/>
    <path android:fillColor="#123D60" android:pathData="M40,38h28a4,4 0,0 1,4 4v35a4,4 0,0 1,-4 4H40a4,4 0,0 1,-4 -4V42a4,4 0,0 1,4 -4z"/>
    <path android:fillColor="#FFFFFF" android:pathData="M45,50h18a2,2 0,0 1,0 4H45a2,2 0,0 1,0 -4zM45,60h18a2,2 0,0 1,0 4H45a2,2 0,0 1,0 -4zM45,70h18a2,2 0,0 1,0 4H45a2,2 0,0 1,0 -4z"/>
    <path android:fillColor="#FFFFFF" android:pathData="M45,18h18a5,5 0,0 1,5 5v7H40v-7a5,5 0,0 1,5 -5z"/>
    <path android:strokeColor="#113A5C" android:strokeWidth="5" android:strokeLineCap="round" android:fillColor="@android:color/transparent" android:pathData="M17,55h12M79,55h12"/>
</vector>
"""

let monochrome = """
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#000000" android:pathData="M35,26h38a6,6 0,0 1,6 6v54a6,6 0,0 1,-6 6H35a6,6 0,0 1,-6 -6V32a6,6 0,0 1,6 -6zM40,38v43h28V38zM45,18h18a5,5 0,0 1,5 5v7H40v-7a5,5 0,0 1,5 -5z"/>
    <path android:strokeColor="#000000" android:strokeWidth="5" android:strokeLineCap="round" android:fillColor="@android:color/transparent" android:pathData="M17,55h12M79,55h12"/>
</vector>
"""

let adaptiveIcon = """
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
"""

try writeText(foreground, to: androidDrawable.appendingPathComponent("ic_launcher_foreground.xml"))
try writeText(monochrome, to: androidDrawable.appendingPathComponent("ic_launcher_monochrome.xml"))
try writeText(adaptiveIcon, to: androidMipmap.appendingPathComponent("ic_launcher.xml"))
try writeText(adaptiveIcon, to: androidMipmap.appendingPathComponent("ic_launcher_round.xml"))

let colorsPath = androidValues.appendingPathComponent("colors.xml")
if !FileManager.default.fileExists(atPath: colorsPath.path) {
    try writeText("""
<resources>
    <color name="ic_launcher_background">#1A6DC7</color>
</resources>
""", to: colorsPath)
}

print("Generated UniClip icons")
