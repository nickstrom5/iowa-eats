// Iowa Plates brand (Nick's decision, 2026-11-07: the name, the palette, and icon B, since a tenderloin was Indiana's): the app icon is
// concept B of scripts/icon-concepts.swift, an ear of sweet corn with the husk peeled back, upright, on field green; the shared Eats Ranked icon style,
// state-prompts/ICON-STYLE.md, no backing shape. No team or school marks, no state seal, no "This Is Iowa" lines.
// Usage, from ia-eats/: swift scripts/make-brand.swift   -> IowaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png,
// docs/ favicons and touch icons, docs/og.png. scripts/make-site.py draws the same mark as its inline SVG: change both together.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let GREEN: UInt32 = 0x2F5D34, BREADING: UInt32 = 0xD9A04A, BUN: UInt32 = 0xF2D29A, CORN: UInt32 = 0xF2B705, HUSK: UInt32 = 0x9CC46B
let GREEN2: UInt32 = 0x3F7A45, CREAM: UInt32 = 0xF7F1E3

func R(_ s: CGFloat, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(roundedRect: CGRect(x: x * s, y: y * s, width: w * s, height: h * s), cornerWidth: r * s, cornerHeight: r * s, transform: nil)
}

/// B: an ear of sweet corn, upright, the husk peeled back on both sides. CoreGraphics y-up, s = canvas size. Identical to
/// icon-concepts.swift's concept B and make-site.py's LOGO.
func corn(_ c: CGContext, _ s: CGFloat) {
    c.setFillColor(rgb(HUSK))
    for side in [-1.0, 1.0] as [CGFloat] {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0.5 * s, y: 0.14 * s))
        p.addQuadCurve(to: CGPoint(x: (0.5 + side * 0.20) * s, y: 0.60 * s), control: CGPoint(x: (0.5 + side * 0.26) * s, y: 0.22 * s))
        p.addQuadCurve(to: CGPoint(x: 0.5 * s, y: 0.30 * s), control: CGPoint(x: (0.5 + side * 0.06) * s, y: 0.40 * s))
        p.closeSubpath(); c.addPath(p); c.fillPath()
    }
    c.setFillColor(rgb(CORN)); c.addPath(R(s, 0.40, 0.28, 0.20, 0.58, 0.10)); c.fillPath()          // the ear
}

func render(_ n: Int, _ path: String, background: Bool) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: background ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setShouldAntialias(true)
    if background { ctx.setFillColor(rgb(GREEN)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n)) }
    corn(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
render(1024, "IowaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png", background: true)
try? FileManager.default.createDirectory(atPath: "docs", withIntermediateDirectories: true)
for (n, name) in [(512, "icon-512.png"), (192, "icon-192.png"), (180, "apple-touch-icon.png"), (32, "favicon-32.png")] {
    render(n, "docs/" + name, background: true)
}

/// The share image (1200 x 630): field green, the ear of corn at the left, the name and tagline at the right, and the app's header band along
/// the bottom: contour-plowed crop rows (Theme.swift's Stripes).
func og(_ path: String) {
    let W = 1200, H = 630
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(GREEN)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    let band: CGFloat = 70
    ctx.setFillColor(rgb(CREAM)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: Int(band)))
    for (i, col) in [GREEN, CORN, GREEN2, GREEN, CORN, GREEN2].enumerated() {
        let y0 = band * CGFloat(i) / 6, y1 = band * CGFloat(i + 1) / 6, bend: CGFloat = 6
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: y0 - bend)); p.addQuadCurve(to: CGPoint(x: CGFloat(W), y: y0 - bend), control: CGPoint(x: CGFloat(W) / 2, y: y0 + bend))
        p.addLine(to: CGPoint(x: CGFloat(W), y: y1 - bend)); p.addQuadCurve(to: CGPoint(x: 0, y: y1 - bend), control: CGPoint(x: CGFloat(W) / 2, y: y1 + bend))
        p.closeSubpath(); ctx.setFillColor(rgb(col)); ctx.addPath(p); ctx.fillPath()
    }
    ctx.saveGState(); ctx.translateBy(x: 40, y: 90); corn(ctx, 500); ctx.restoreGState()
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
    let title = NSFont(name: "AvenirNextCondensed-Heavy", size: 80) ?? NSFont.boldSystemFont(ofSize: 70)
    let sub = NSFont(name: "AvenirNextCondensed-DemiBold", size: 34) ?? NSFont.boldSystemFont(ofSize: 30)
    NSAttributedString(string: "IOWA", attributes: [.font: title, .foregroundColor: NSColor.white]).draw(at: NSPoint(x: 560, y: 380))
    NSAttributedString(string: "PLATES", attributes: [.font: title, .foregroundColor: NSColor.white]).draw(at: NSPoint(x: 560, y: 296))
    NSAttributedString(string: "TENDERLOINS, LOOSE MEATS & PIZZA", attributes: [.font: sub, .foregroundColor: NSColor(srgbRed: 0.949, green: 0.718, blue: 0.020, alpha: 1)]).draw(at: NSPoint(x: 564, y: 246))
    NSGraphicsContext.restoreGraphicsState()
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
og("docs/og.png")
