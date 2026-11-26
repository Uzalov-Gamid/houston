import AppKit

let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let ink = NSColor(srgbRed: 0x35 / 255.0, green: 0x54 / 255.0, blue: 0x68 / 255.0, alpha: 1)

func symbol(_ name: String, size: CGFloat, center: CGPoint) {
    guard let asset = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: size, weight: .medium)) else {
        fatalError("Missing SF Symbol: \(name)")
    }
    let rect = CGRect(x: center.x - asset.size.width / 2, y: center.y - asset.size.height / 2,
                      width: asset.size.width, height: asset.size.height)
    asset.draw(in: rect)
    let context = NSGraphicsContext.current!.cgContext
    context.saveGState()
    context.setBlendMode(.sourceIn)
    context.setFillColor(ink.cgColor)
    context.fill(rect)
    context.restoreGState()
}

func render(_ name: String, _ draw: () -> Void) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 44, pixelsHigh: 36,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current!.cgContext.scaleBy(x: 2, y: 2)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!
        .write(to: directory.appendingPathComponent("facade-\(name).png"))
}

for (state, glyph) in [("wifi", "wifi"), ("wifi-off", "wifi.slash")] {
    try render(state) { symbol(glyph, size: 13, center: CGPoint(x: 11, y: 9)) }
    try render(state + "-locked") {
        symbol(glyph, size: 12, center: CGPoint(x: 8, y: 9))
        symbol("lock.fill", size: 6, center: CGPoint(x: 18.5, y: 6))
    }
}
try render("airpods") { symbol("airpods", size: 14, center: CGPoint(x: 11, y: 9)) }
try render("headphones") { symbol("headphones", size: 13, center: CGPoint(x: 11, y: 9)) }
try render("bluetooth") {
    let path = NSBezierPath()
    path.lineWidth = 1.25
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: CGPoint(x: 11, y: 2))
    path.line(to: CGPoint(x: 11, y: 16))
    path.line(to: CGPoint(x: 14.5, y: 12.5))
    path.line(to: CGPoint(x: 7.5, y: 5.5))
    path.move(to: CGPoint(x: 11, y: 2))
    path.line(to: CGPoint(x: 14.5, y: 5.5))
    path.line(to: CGPoint(x: 7.5, y: 12.5))
    ink.setStroke()
    path.stroke()
}
