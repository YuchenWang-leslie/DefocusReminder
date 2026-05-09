#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let buildDir = root.appendingPathComponent(".build")
let sourceIcon = root.appendingPathComponent("Assets/AppIconSource.png")
let iconset = buildDir.appendingPathComponent("AppIcon.iconset")
let icns = buildDir.appendingPathComponent("AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

struct IconSize {
    let points: Int
    let scale: Int

    var pixels: Int { points * scale }
    var fileName: String {
        scale == 1
            ? "icon_\(points)x\(points).png"
            : "icon_\(points)x\(points)@\(scale)x.png"
    }
}

let sizes = [
    IconSize(points: 16, scale: 1),
    IconSize(points: 16, scale: 2),
    IconSize(points: 32, scale: 1),
    IconSize(points: 32, scale: 2),
    IconSize(points: 128, scale: 1),
    IconSize(points: 128, scale: 2),
    IconSize(points: 256, scale: 1),
    IconSize(points: 256, scale: 2),
    IconSize(points: 512, scale: 1),
    IconSize(points: 512, scale: 2),
]

func setShadow(color: NSColor, offset: NSSize, blurRadius: CGFloat) {
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowOffset = offset
    shadow.shadowBlurRadius = blurRadius
    shadow.set()
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let inset = size * 0.055
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let radius = size * 0.205
    let background = NSBezierPath(roundedRect: iconRect, xRadius: radius, yRadius: radius)

    NSGraphicsContext.current?.saveGraphicsState()
    background.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.74, green: 0.96, blue: 0.88, alpha: 1.0),
        NSColor(calibratedRed: 0.21, green: 0.76, blue: 0.90, alpha: 1.0),
        NSColor(calibratedRed: 0.12, green: 0.50, blue: 0.93, alpha: 1.0),
    ])
    gradient?.draw(in: iconRect, angle: -42)

    NSColor.white.withAlphaComponent(0.23).setFill()
    NSBezierPath(ovalIn: CGRect(
        x: iconRect.minX + size * 0.06,
        y: iconRect.maxY - size * 0.34,
        width: size * 0.44,
        height: size * 0.25
    )).fill()

    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.current?.saveGraphicsState()
    setShadow(
        color: NSColor.black.withAlphaComponent(0.16),
        offset: NSSize(width: 0, height: -size * 0.018),
        blurRadius: size * 0.045
    )
    background.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.current?.saveGraphicsState()
    background.addClip()
    gradient?.draw(in: iconRect, angle: -42)
    NSGraphicsContext.current?.restoreGraphicsState()

    let cx = size * 0.5
    let cy = size * 0.505
    let eyeWidth = size * 0.66
    let eyeHeight = size * 0.34
    let eye = NSBezierPath()
    eye.move(to: CGPoint(x: cx - eyeWidth / 2, y: cy))
    eye.curve(
        to: CGPoint(x: cx, y: cy + eyeHeight / 2),
        controlPoint1: CGPoint(x: cx - eyeWidth * 0.25, y: cy + eyeHeight * 0.42),
        controlPoint2: CGPoint(x: cx - eyeWidth * 0.14, y: cy + eyeHeight / 2)
    )
    eye.curve(
        to: CGPoint(x: cx + eyeWidth / 2, y: cy),
        controlPoint1: CGPoint(x: cx + eyeWidth * 0.14, y: cy + eyeHeight / 2),
        controlPoint2: CGPoint(x: cx + eyeWidth * 0.25, y: cy + eyeHeight * 0.42)
    )
    eye.curve(
        to: CGPoint(x: cx, y: cy - eyeHeight / 2),
        controlPoint1: CGPoint(x: cx + eyeWidth * 0.25, y: cy - eyeHeight * 0.42),
        controlPoint2: CGPoint(x: cx + eyeWidth * 0.14, y: cy - eyeHeight / 2)
    )
    eye.curve(
        to: CGPoint(x: cx - eyeWidth / 2, y: cy),
        controlPoint1: CGPoint(x: cx - eyeWidth * 0.14, y: cy - eyeHeight / 2),
        controlPoint2: CGPoint(x: cx - eyeWidth * 0.25, y: cy - eyeHeight * 0.42)
    )
    eye.close()

    NSGraphicsContext.current?.saveGraphicsState()
    setShadow(
        color: NSColor.white.withAlphaComponent(0.55),
        offset: NSSize(width: 0, height: size * 0.012),
        blurRadius: size * 0.025
    )
    NSColor.white.withAlphaComponent(0.9).setFill()
    eye.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    let pupil = NSBezierPath(ovalIn: CGRect(
        x: cx - size * 0.15,
        y: cy - size * 0.15,
        width: size * 0.3,
        height: size * 0.3
    ))
    NSColor(calibratedRed: 0.22, green: 0.73, blue: 0.84, alpha: 0.86).setFill()
    pupil.fill()

    NSGraphicsContext.current?.saveGraphicsState()
    setShadow(
        color: NSColor.black.withAlphaComponent(0.18),
        offset: NSSize(width: 0, height: -size * 0.008),
        blurRadius: size * 0.014
    )
    NSColor.white.setFill()
    let barWidth = size * 0.052
    let barHeight = size * 0.18
    let barRadius = barWidth / 2
    for offset in [-size * 0.055, size * 0.055] {
        let bar = NSBezierPath(roundedRect: CGRect(
            x: cx + offset - barWidth / 2,
            y: cy - barHeight / 2,
            width: barWidth,
            height: barHeight
        ), xRadius: barRadius, yRadius: barRadius)
        bar.fill()
    }
    NSGraphicsContext.current?.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.35).setStroke()
    background.lineWidth = max(1, size * 0.006)
    background.stroke()

    return image
}

func writePNG(image: NSImage, pixels: Int, to url: URL) throws {
    let rect = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    guard
        let rep = NSBitmapImageRep(
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
        )
    else {
        throw NSError(domain: "IconGeneration", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 2)
    }
    try data.write(to: url)
}

let master = NSImage(contentsOf: sourceIcon) ?? drawIcon(size: 1024)
for size in sizes {
    try writePNG(
        image: master,
        pixels: size.pixels,
        to: iconset.appendingPathComponent(size.fileName)
    )
}

try? FileManager.default.removeItem(at: icns)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    throw NSError(domain: "IconGeneration", code: Int(process.terminationStatus))
}

print("Generated \(icns.path)")
