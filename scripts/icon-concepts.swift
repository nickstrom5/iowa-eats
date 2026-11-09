// Iowa Plates icon concepts (2026-11-06), drawn in the shared Eats Ranked style (state-prompts/ICON-STYLE.md): one flat, level, centred
// food on field green #2F5D34 (the prompt's landscape palette), no backing shape, no text or texture, no team marks.
// Food hexes: breading #D9A04A, bun #F2D29A; corn #F2B705, husk #9CC46B; loose meat #6E3B1F.
//   A  a breaded pork tenderloin twice the width of its bun, side elevation
//   B  an ear of sweet corn with the husk peeled back, upright
//   C  a loose-meat sandwich, side elevation
// Usage, from ia-eats/: swift scripts/icon-concepts.swift <out dir>   -> concept-{a,b,c}-1024.png
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let GREEN: UInt32 = 0x2F5D34, BREADING: UInt32 = 0xD9A04A, BUN: UInt32 = 0xF2D29A, CORN: UInt32 = 0xF2B705, HUSK: UInt32 = 0x9CC46B
let MEAT: UInt32 = 0x6E3B1F

func R(_ s: CGFloat, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(roundedRect: CGRect(x: x * s, y: y * s, width: w * s, height: h * s), cornerWidth: r * s, cornerHeight: r * s, transform: nil)
}

/// A: the tenderloin, a wide breaded cutlet hanging far past a small bun. CoreGraphics y-up. Identical to make-brand.swift's tenderloin().
func tenderloin(_ c: CGContext, _ s: CGFloat) {
    c.setFillColor(rgb(BUN)); c.addPath(R(s, 0.31, 0.31, 0.38, 0.12, 0.05)); c.fillPath()          // the bottom bun
    c.setFillColor(rgb(BREADING)); c.addPath(R(s, 0.14, 0.41, 0.72, 0.16, 0.08)); c.fillPath()     // the breaded cutlet, twice the bun's width
    c.setFillColor(rgb(BUN)); c.addPath(R(s, 0.31, 0.55, 0.38, 0.15, 0.07)); c.fillPath()          // the top bun
}

/// B: an ear of sweet corn, upright, the husk peeled back on both sides.
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

/// C: a loose-meat sandwich: a bun with a thick layer of crumbled beef.
func loosemeat(_ c: CGContext, _ s: CGFloat) {
    c.setFillColor(rgb(BUN)); c.addPath(R(s, 0.14, 0.26, 0.72, 0.13, 0.06)); c.fillPath()
    c.setFillColor(rgb(MEAT)); c.addPath(R(s, 0.17, 0.37, 0.66, 0.17, 0.06)); c.fillPath()
    c.setFillColor(rgb(BUN)); c.addPath(R(s, 0.14, 0.52, 0.72, 0.24, 0.12)); c.fillPath()
    c.fill(CGRect(x: 0.14 * s, y: 0.52 * s, width: 0.72 * s, height: 0.10 * s))
}

func render(_ n: Int, _ path: String, _ draw: (CGContext, CGFloat) -> Void) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(GREEN)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n))
    draw(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "playbook/brand"
render(1024, out + "/concept-a-1024.png", tenderloin)
render(1024, out + "/concept-b-1024.png", corn)
render(1024, out + "/concept-c-1024.png", loosemeat)
