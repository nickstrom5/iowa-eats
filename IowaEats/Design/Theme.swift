import SwiftUI
import UIKit
import CoreText

/// Iowa palette, a landscape one (provisional, 2026-11-06; Nick decides, playbook/05-naming.md), light only. Fans split three ways
/// (Hawkeyes black and gold, Cyclones cardinal and gold, UNI purple and gold), so the colors come from the land and the flag
/// (state-prompts/IOWA_PROMPT.md): field green #2F5D34 (7.7:1 on white) for titles, tint, the honors and oldest cards; flag blue #1D3F8C
/// (white on it 9.8:1) for the hand-checked guide cards and chips; corn gold #F2B705 only as a pin and card fill under ink (#1A1A1A on
/// it 10.3:1; as text on white it's 1.8:1); cream #F7F1E3 pages. No black-and-gold or cardinal-and-gold blocks. The names `green`/`gold`
/// are kept from Wisconsin Eats so the shared views read the same; here `green` is field green and `gold` is flag blue.
enum Theme {
    static let green = Color(hex: 0x2F5D34)      // field green: titles, tint, primary text accents
    static let green2 = Color(hex: 0x3F7A45)
    static let gold = Color(hex: 0x1D3F8C)       // flag blue: card fills under white text, chips
    static let goldSoft = Color(hex: 0xDCE4F3)   // soft blue
    static let lime = Color(hex: 0xF2B705)       // corn gold, fills only (hand-checked pins, the title shadow), under ink
    static let limeSoft = Color(hex: 0xFCEDB8)
    static let sand = Color(hex: 0xF7F1E3)       // the Home background, cream
    static let red = Color(hex: 0x1D3F8C)        // honors chips (blue)
    static let sandstone = Color(hex: 0x15306B)  // a darker blue accent
    static let teal = Color(hex: 0x6B4F2A)       // soil brown (7.4:1 on white)
    static let ink = Color(hex: 0x1A1A1A)
    static let ink2 = Color(hex: 0x2E3440)
    static let muted = Color(hex: 0x5B6270)
    static let surface = Color.white
    static let surface2 = Color(hex: 0xF0EBDD)
    static let surface3 = Color(hex: 0xE4DCC8)
    static let rule = Color(hex: 0xE4DCC8)
    static let rule2 = Color(hex: 0xCBC1A8)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A small uppercase label: "STONE CRAB", "1 MICHELIN STAR".
struct Chip: View {
    enum Style { case gold, green, red, plain, dashed }
    let text: String
    var style: Style = .plain

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .foregroundStyle(style == .green || style == .red ? Color.white : style == .dashed ? Theme.muted : style == .gold ? Theme.ink : Theme.green)
            .background {
                RoundedRectangle(cornerRadius: 5).fill(style == .gold ? Theme.goldSoft : style == .green ? Theme.green : style == .red ? Theme.red
                                                       : style == .dashed ? .clear : Theme.surface2)
            }
            .overlay {
                if style == .dashed { RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.rule2, style: StrokeStyle(lineWidth: 1, dash: [3, 2])) }
            }
            .accessibilityLabel(text)
    }
}

/// Iowa Plates' lettering: the system face drawn compressed and heavy for titles and guide names (like a show poster), and the
/// system monospaced face for numbers, dates and small labels. No bundled fonts.
struct DisplayFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .black
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight).width(.compressed))
    }
}

/// Numbers, dates and small labels in the system monospaced face, scaled like DisplayFont.
struct MonoFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .semibold
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight, design: .monospaced))
    }
}

extension View {
    func displayFont(_ size: CGFloat, weight: Font.Weight = .black) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }

    func monoFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> some View {
        modifier(MonoFont(size: size, weight: weight))
    }
}

/// The header band: contour-plowed crop rows seen from above, alternating greens and corn gold, curving gently across the band.
struct Stripes: View {
    var height: CGFloat = 6

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, rows = 6
            for i in 0..<rows {
                let y0 = h * CGFloat(i) / CGFloat(rows), y1 = h * CGFloat(i + 1) / CGFloat(rows), bend = h * 0.18
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y0 + bend))
                p.addQuadCurve(to: CGPoint(x: w, y: y0 + bend), control: CGPoint(x: w / 2, y: y0 - bend))
                p.addLine(to: CGPoint(x: w, y: y1 + bend))
                p.addQuadCurve(to: CGPoint(x: 0, y: y1 + bend), control: CGPoint(x: w / 2, y: y1 - bend))
                p.closeSubpath()
                ctx.fill(p, with: .color([Theme.green, Theme.lime, Theme.green2, Theme.green, Theme.lime, Theme.green2][i]))
            }
        }
        .frame(height: height * 2.4)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .accessibilityHidden(true)
    }
}

extension View {
    /// An inline navigation title in the display type. UINavigationBar.appearance() didn't reach every SwiftUI bar on iOS 27
    /// (the Map title went from compressed blue to plain black after a push and pop; place titles were always plain), so the
    /// title is our own view in the bar. The navigation title is still set, for the back button and VoiceOver.
    func inlineTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).displayFont(19, weight: .heavy).foregroundStyle(Theme.green)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}
