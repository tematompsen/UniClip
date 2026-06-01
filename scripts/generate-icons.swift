#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceIcon = root.appendingPathComponent("icons/app-icon.png")
let macResources = root.appendingPathComponent("apps/macos/Resources")
let androidRes = root.appendingPathComponent("apps/android/app/src/main/res")
let androidDrawable = androidRes.appendingPathComponent("drawable")
let androidAnyDpi = androidRes.appendingPathComponent("mipmap-anydpi-v26")
let androidValues = androidRes.appendingPathComponent("values")
let iconset = macResources.appendingPathComponent("UniClip.iconset")

for directory in [
    macResources,
    androidDrawable,
    androidAnyDpi,
    androidValues,
    iconset,
    androidRes.appendingPathComponent("mipmap-mdpi"),
    androidRes.appendingPathComponent("mipmap-hdpi"),
    androidRes.appendingPathComponent("mipmap-xhdpi"),
    androidRes.appendingPathComponent("mipmap-xxhdpi"),
    androidRes.appendingPathComponent("mipmap-xxxhdpi")
] {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
}

func writeText(_ text: String, to url: URL) throws {
    try text.data(using: .utf8)!.write(to: url)
}

func pngData(_ image: NSImage) throws -> Data {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "UniClipIcon", code: 1)
    }
    return data
}

func squareIcon(size: CGFloat) throws -> NSImage {
    guard let source = NSImage(contentsOf: sourceIcon) else {
        throw NSError(domain: "UniClipIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing icons/app-icon.png"])
    }

    let output = NSImage(size: NSSize(width: size, height: size))
    output.lockFocus()
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let sourceSize = source.size
    let sourceSide = min(sourceSize.width, sourceSize.height)
    let crop = NSRect(
        x: (sourceSize.width - sourceSide) / 2,
        y: (sourceSize.height - sourceSide) / 2,
        width: sourceSide,
        height: sourceSide
    )
    source.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: crop,
        operation: .copy,
        fraction: 1,
        respectFlipped: false,
        hints: [.interpolation: NSImageInterpolation.high]
    )

    output.unlockFocus()
    return output
}

func statusBarImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    NSColor.black.setFill()
    let back = NSBezierPath(roundedRect: NSRect(x: size * 0.17, y: size * 0.35, width: size * 0.43, height: size * 0.46), xRadius: size * 0.11, yRadius: size * 0.11)
    back.fill()
    let front = NSBezierPath(roundedRect: NSRect(x: size * 0.40, y: size * 0.16, width: size * 0.43, height: size * 0.46), xRadius: size * 0.11, yRadius: size * 0.11)
    front.fill()

    let bridge = NSBezierPath()
    bridge.move(to: NSPoint(x: size * 0.40, y: size * 0.40))
    bridge.curve(to: NSPoint(x: size * 0.60, y: size * 0.59), controlPoint1: NSPoint(x: size * 0.45, y: size * 0.50), controlPoint2: NSPoint(x: size * 0.54, y: size * 0.47))
    bridge.line(to: NSPoint(x: size * 0.65, y: size * 0.55))
    bridge.curve(to: NSPoint(x: size * 0.45, y: size * 0.36), controlPoint1: NSPoint(x: size * 0.58, y: size * 0.44), controlPoint2: NSPoint(x: size * 0.50, y: size * 0.46))
    bridge.close()
    bridge.fill()

    NSColor.clear.setFill()
    NSColor.clear.setStroke()
    image.unlockFocus()
    return image
}

let statusSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <path fill="black" d="M16 22c0-7 5-12 12-12h20c7 0 12 5 12 12v20c0 7-5 12-12 12H28c-7 0-12-5-12-12V22Z" opacity=".82"/>
  <path fill="black" d="M4 10C4 4 8 0 14 0h20c6 0 10 4 10 10v20c0 6-4 10-10 10H14C8 40 4 36 4 30V10Z"/>
  <path fill="black" d="M28 35c6-13 16-5 22-18l6 5c-6 14-17 7-23 20l-5-7Z"/>
  <rect x="16" y="7" width="16" height="5" rx="2.5" fill="white"/>
  <rect x="36" y="52" width="16" height="5" rx="2.5" fill="white"/>
</svg>
"""

let macIconSizes: [(String, CGFloat)] = [
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

for (name, size) in macIconSizes {
    try pngData(try squareIcon(size: size)).write(to: iconset.appendingPathComponent(name))
}

try pngData(try squareIcon(size: 1024)).write(to: macResources.appendingPathComponent("UniClip-1024.png"))
try pngData(statusBarImage(size: 36)).write(to: macResources.appendingPathComponent("StatusBarIconTemplate.png"))
try writeText(statusSvg, to: macResources.appendingPathComponent("StatusBarIcon.svg"))

let adaptiveIcon = """
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
"""

let monochrome = """
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#000000" android:pathData="M27,24c0,-8 6,-14 14,-14h30c8,0 14,6 14,14v30c0,8 -6,14 -14,14H41c-8,0 -14,-6 -14,-14V24z"/>
    <path android:fillColor="#000000" android:pathData="M47,47c8,-18 23,-8 31,-25l8,7c-8,18 -23,9 -31,26z"/>
    <path android:fillColor="#000000" android:pathData="M23,38c0,-8 6,-14 14,-14h30c8,0 14,6 14,14v30c0,8 -6,14 -14,14H37c-8,0 -14,-6 -14,-14V38z"/>
</vector>
"""

let oldVectorForeground = androidDrawable.appendingPathComponent("ic_launcher_foreground.xml")
if FileManager.default.fileExists(atPath: oldVectorForeground.path) {
    try FileManager.default.removeItem(at: oldVectorForeground)
}

try pngData(try squareIcon(size: 432)).write(to: androidDrawable.appendingPathComponent("ic_launcher_foreground.png"))
try writeText(monochrome, to: androidDrawable.appendingPathComponent("ic_launcher_monochrome.xml"))
try writeText(adaptiveIcon, to: androidAnyDpi.appendingPathComponent("ic_launcher.xml"))
try writeText(adaptiveIcon, to: androidAnyDpi.appendingPathComponent("ic_launcher_round.xml"))
try writeText("""
<resources>
    <color name="ic_launcher_background">#081733</color>
</resources>
""", to: androidValues.appendingPathComponent("colors.xml"))

let androidSizes: [(String, CGFloat)] = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192)
]

for (directory, size) in androidSizes {
    let image = try squareIcon(size: size)
    let dir = androidRes.appendingPathComponent(directory)
    try pngData(image).write(to: dir.appendingPathComponent("ic_launcher.png"))
    try pngData(image).write(to: dir.appendingPathComponent("ic_launcher_round.png"))
}

print("Generated UniClip icons from icons/app-icon.png")
