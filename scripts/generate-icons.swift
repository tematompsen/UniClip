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

func pngData(_ image: NSImage, pixels: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "UniClipIcon", code: 1)
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(
        in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
        from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
        operation: .copy,
        fraction: 1,
        respectFlipped: false,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
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

    let scale = size / 24.0
    let inset = size * 0.12

    func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: inset + x * scale * 0.76, y: size - inset - y * scale * 0.76)
    }

    NSColor.black.setStroke()
    let path = NSBezierPath()
    path.lineWidth = max(1.5, size * 0.065)
    path.lineCapStyle = .round
    path.lineJoinStyle = .round

    path.move(to: point(16.964, 8.982))
    path.curve(to: point(16.058, 3.458), controlPoint1: point(16.961, 6.032), controlPoint2: point(16.917, 4.504))
    path.curve(to: point(15.505, 2.904), controlPoint1: point(15.892, 3.256), controlPoint2: point(15.707, 3.070))
    path.curve(to: point(9.480, 2.000), controlPoint1: point(14.400, 2.000), controlPoint2: point(12.760, 2.000))
    path.curve(to: point(3.456, 2.905), controlPoint1: point(6.200, 2.000), controlPoint2: point(4.560, 2.000))
    path.curve(to: point(2.903, 3.459), controlPoint1: point(3.254, 3.071), controlPoint2: point(3.069, 3.257))
    path.curve(to: point(1.998, 9.480), controlPoint1: point(1.998, 4.560), controlPoint2: point(1.998, 6.200))
    path.curve(to: point(2.904, 15.503), controlPoint1: point(1.998, 12.760), controlPoint2: point(1.998, 14.400))
    path.curve(to: point(3.457, 16.056), controlPoint1: point(3.071, 15.706), controlPoint2: point(3.255, 15.890))
    path.curve(to: point(8.982, 16.962), controlPoint1: point(4.503, 16.916), controlPoint2: point(6.032, 16.960))

    path.move(to: point(14.028, 9.025))
    path.line(to: point(16.994, 8.982))
    path.move(to: point(14.014, 22.002))
    path.line(to: point(16.980, 21.959))
    path.move(to: point(21.972, 14.022))
    path.line(to: point(21.944, 16.982))
    path.move(to: point(9.010, 14.036))
    path.line(to: point(8.982, 16.996))
    path.move(to: point(11.487, 9.025))
    path.curve(to: point(9.010, 11.049), controlPoint1: point(10.655, 9.174), controlPoint2: point(9.317, 9.327))
    path.move(to: point(19.495, 21.959))
    path.curve(to: point(22.003, 19.973), controlPoint1: point(20.330, 21.822), controlPoint2: point(21.669, 21.689))
    path.move(to: point(19.495, 9.025))
    path.curve(to: point(21.972, 11.049), controlPoint1: point(20.327, 9.174), controlPoint2: point(21.665, 9.327))
    path.move(to: point(11.500, 21.957))
    path.curve(to: point(9.022, 19.934), controlPoint1: point(10.667, 21.809), controlPoint2: point(9.330, 21.656))

    path.stroke()
    image.unlockFocus()
    return image
}

let statusSvg = """
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M16.964 8.982C16.961 6.032 16.917 4.504 16.058 3.458C15.8923 3.2557 15.707 3.07014 15.505 2.904C14.4 2 12.76 2 9.48005 2C6.20005 2 4.56005 2 3.45605 2.905C3.25404 3.07114 3.06882 3.2567 2.90305 3.459C1.99805 4.56 1.99805 6.2 1.99805 9.48C1.99805 12.76 1.99805 14.4 2.90405 15.503C3.07071 15.7057 3.25505 15.89 3.45705 16.056C4.50305 16.916 6.03205 16.96 8.98205 16.962" stroke="black" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M14.0284 9.02542L16.9944 8.98242M14.0144 22.0024L16.9804 21.9594M21.9724 14.0224L21.9444 16.9824M9.01042 14.0364L8.98242 16.9964M11.4874 9.02542C10.6554 9.17442 9.31742 9.32742 9.01042 11.0494M19.4954 21.9594C20.3304 21.8224 21.6694 21.6894 22.0034 19.9734M19.4954 9.02542C20.3274 9.17442 21.6654 9.32742 21.9724 11.0494M11.5004 21.9574C10.6674 21.8094 9.33042 21.6564 9.02242 19.9344" stroke="black" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
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
    try pngData(try squareIcon(size: size), pixels: Int(size)).write(to: iconset.appendingPathComponent(name))
}

try pngData(try squareIcon(size: 1024), pixels: 1024).write(to: macResources.appendingPathComponent("UniClip-1024.png"))
try pngData(statusBarImage(size: 36), pixels: 36).write(to: macResources.appendingPathComponent("StatusBarIconTemplate.png"))
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

try pngData(try squareIcon(size: 432), pixels: 432).write(to: androidDrawable.appendingPathComponent("ic_launcher_foreground.png"))
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
    try pngData(image, pixels: Int(size)).write(to: dir.appendingPathComponent("ic_launcher.png"))
    try pngData(image, pixels: Int(size)).write(to: dir.appendingPathComponent("ic_launcher_round.png"))
}

print("Generated UniClip icons from icons/app-icon.png")
