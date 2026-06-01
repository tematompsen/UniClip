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

    let viewWidth: CGFloat = 607
    let viewHeight: CGFloat = 693
    let scale = size * 0.88 / viewHeight
    let xOffset = (size - viewWidth * scale) / 2
    let yOffset = (size - viewHeight * scale) / 2

    func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: xOffset + x * scale, y: size - yOffset - y * scale)
    }

    NSColor.black.setFill()
    let path = NSBezierPath()
    path.windingRule = .evenOdd

    path.move(to: point(216.5, 86.6))
    path.curve(to: point(124.647, 124.647), controlPoint1: point(182.048, 86.6), controlPoint2: point(149.008, 100.286))
    path.curve(to: point(86.6, 216.5), controlPoint1: point(100.286, 149.008), controlPoint2: point(86.6, 182.048))
    path.line(to: point(86.6, 389.7))
    path.curve(to: point(150.011, 542.789), controlPoint1: point(86.6, 447.119), controlPoint2: point(109.41, 502.187))
    path.curve(to: point(303.1, 606.2), controlPoint1: point(190.613, 583.39), controlPoint2: point(245.681, 606.2))
    path.curve(to: point(456.189, 542.789), controlPoint1: point(360.519, 606.2), controlPoint2: point(415.587, 583.39))
    path.curve(to: point(519.6, 389.7), controlPoint1: point(496.79, 502.187), controlPoint2: point(519.6, 447.119))
    path.line(to: point(519.6, 216.5))
    path.curve(to: point(532.282, 185.882), controlPoint1: point(519.6, 205.016), controlPoint2: point(524.162, 194.003))
    path.curve(to: point(562.9, 173.2), controlPoint1: point(540.403, 177.762), controlPoint2: point(551.416, 173.2))
    path.curve(to: point(593.518, 185.882), controlPoint1: point(574.384, 173.2), controlPoint2: point(585.397, 177.762))
    path.curve(to: point(606.2, 216.5), controlPoint1: point(601.638, 194.003), controlPoint2: point(606.2, 205.016))
    path.line(to: point(606.2, 389.7))
    path.curve(to: point(583.128, 505.691), controlPoint1: point(606.2, 429.504), controlPoint2: point(598.36, 468.918))
    path.curve(to: point(517.424, 604.024), controlPoint1: point(567.896, 542.465), controlPoint2: point(545.57, 575.879))
    path.curve(to: point(419.091, 669.728), controlPoint1: point(489.279, 632.169), controlPoint2: point(455.865, 654.496))
    path.curve(to: point(303.1, 692.8), controlPoint1: point(382.318, 684.96), controlPoint2: point(342.904, 692.8))
    path.curve(to: point(187.109, 669.728), controlPoint1: point(263.296, 692.8), controlPoint2: point(223.882, 684.96))
    path.curve(to: point(88.7759, 604.024), controlPoint1: point(150.335, 654.496), controlPoint2: point(116.921, 632.169))
    path.curve(to: point(23.0721, 505.691), controlPoint1: point(60.6305, 575.879), controlPoint2: point(38.3043, 542.465))
    path.curve(to: point(0, 389.7), controlPoint1: point(7.83992, 468.918), controlPoint2: point(0, 429.504))
    path.line(to: point(0, 216.5))
    path.curve(to: point(63.4114, 63.4114), controlPoint1: point(0, 159.081), controlPoint2: point(22.8098, 104.013))
    path.curve(to: point(216.5, 0), controlPoint1: point(104.013, 22.8098), controlPoint2: point(159.081, 0))
    path.curve(to: point(369.589, 63.4114), controlPoint1: point(273.919, 0), controlPoint2: point(328.987, 22.8098))
    path.curve(to: point(433, 216.5), controlPoint1: point(410.19, 104.013), controlPoint2: point(433, 159.081))
    path.line(to: point(433, 389.7))
    path.curve(to: point(394.953, 481.553), controlPoint1: point(433, 424.152), controlPoint2: point(419.314, 457.192))
    path.curve(to: point(303.1, 519.6), controlPoint1: point(370.592, 505.914), controlPoint2: point(337.552, 519.6))
    path.curve(to: point(211.247, 481.553), controlPoint1: point(268.648, 519.6), controlPoint2: point(235.608, 505.914))
    path.curve(to: point(173.2, 389.7), controlPoint1: point(186.886, 457.192), controlPoint2: point(173.2, 424.152))
    path.line(to: point(173.2, 216.5))
    path.curve(to: point(185.882, 185.882), controlPoint1: point(173.2, 205.016), controlPoint2: point(177.762, 194.003))
    path.curve(to: point(216.5, 173.2), controlPoint1: point(194.003, 177.762), controlPoint2: point(205.016, 173.2))
    path.curve(to: point(247.118, 185.882), controlPoint1: point(227.984, 173.2), controlPoint2: point(238.997, 177.762))
    path.curve(to: point(259.8, 216.5), controlPoint1: point(255.238, 194.003), controlPoint2: point(259.8, 205.016))
    path.line(to: point(259.8, 389.7))
    path.curve(to: point(272.482, 420.318), controlPoint1: point(259.8, 401.184), controlPoint2: point(264.362, 412.197))
    path.curve(to: point(303.1, 433), controlPoint1: point(280.603, 428.438), controlPoint2: point(291.616, 433))
    path.curve(to: point(333.718, 420.318), controlPoint1: point(314.584, 433), controlPoint2: point(325.597, 428.438))
    path.curve(to: point(346.4, 389.7), controlPoint1: point(341.838, 412.197), controlPoint2: point(346.4, 401.184))
    path.line(to: point(346.4, 216.5))
    path.curve(to: point(308.353, 124.647), controlPoint1: point(346.4, 182.048), controlPoint2: point(332.714, 149.008))
    path.curve(to: point(216.5, 86.6), controlPoint1: point(283.992, 100.286), controlPoint2: point(250.952, 86.6))
    path.close()

    path.fill()
    image.unlockFocus()
    return image
}

let statusSvg = """
<svg width="607" height="693" viewBox="0 0 607 693" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M216.5 86.6C182.048 86.6 149.008 100.286 124.647 124.647C100.286 149.008 86.6 182.048 86.6 216.5V389.7C86.6 447.119 109.41 502.187 150.011 542.789C190.613 583.39 245.681 606.2 303.1 606.2C360.519 606.2 415.587 583.39 456.189 542.789C496.79 502.187 519.6 447.119 519.6 389.7V216.5C519.6 205.016 524.162 194.003 532.282 185.882C540.403 177.762 551.416 173.2 562.9 173.2C574.384 173.2 585.397 177.762 593.518 185.882C601.638 194.003 606.2 205.016 606.2 216.5V389.7C606.2 429.504 598.36 468.918 583.128 505.691C567.896 542.465 545.57 575.879 517.424 604.024C489.279 632.169 455.865 654.496 419.091 669.728C382.318 684.96 342.904 692.8 303.1 692.8C263.296 692.8 223.882 684.96 187.109 669.728C150.335 654.496 116.921 632.169 88.7759 604.024C60.6305 575.879 38.3043 542.465 23.0721 505.691C7.83992 468.918 -5.9312e-07 429.504 0 389.7V216.5C0 159.081 22.8098 104.013 63.4114 63.4114C104.013 22.8098 159.081 0 216.5 0C273.919 0 328.987 22.8098 369.589 63.4114C410.19 104.013 433 159.081 433 216.5V389.7C433 424.152 419.314 457.192 394.953 481.553C370.592 505.914 337.552 519.6 303.1 519.6C268.648 519.6 235.608 505.914 211.247 481.553C186.886 457.192 173.2 424.152 173.2 389.7V216.5C173.2 205.016 177.762 194.003 185.882 185.882C194.003 177.762 205.016 173.2 216.5 173.2C227.984 173.2 238.997 177.762 247.118 185.882C255.238 194.003 259.8 205.016 259.8 216.5V389.7C259.8 401.184 264.362 412.197 272.482 420.318C280.603 428.438 291.616 433 303.1 433C314.584 433 325.597 428.438 333.718 420.318C341.838 412.197 346.4 401.184 346.4 389.7V216.5C346.4 182.048 332.714 149.008 308.353 124.647C283.992 100.286 250.952 86.6 216.5 86.6Z" fill="black"/>
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
