import SwiftUI

enum Theme {
    static let cream = Color(hex: Pal.cream)
    static let amber = Color(hex: Pal.amber)
    static let amberLight = Color(hex: Pal.amberLight)
    static let rust = Color(hex: Pal.rust)
    static let rustDark = Color(hex: Pal.rustDark)
    static let forest = Color(hex: Pal.forest)
    static let green = Color(hex: 0x7AC07A)
    static let blue = Color(hex: Pal.blue)
    static let blueDark = Color(hex: Pal.blueDark)
    static let gray = Color(hex: Pal.gray)
    static let dim = Color(hex: 0x9A9488)
    static let red = Color(hex: 0xD06050)
    static let panel = Color(hex: 0x1A1C22)
    static let panelLight = Color(hex: 0x262A32)
    static let border = Color(hex: 0x5A4A3A)
    static let night = Color(hex: Pal.night)

    /// Retro terminal-style labels and titles.
    static func font(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .monospaced) }
    /// Readable running text.
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .default) }
    static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .monospaced) }

    /// Minimum touch target.
    static let touch: CGFloat = 44
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: alpha)
    }
}

/// Dark panel with a chunky pixel-style double border.
struct RetroPanel<Content: View>: View {
    var padding: CGFloat = 12
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Theme.panel.opacity(0.96))
            .overlay(Rectangle().strokeBorder(Theme.border, lineWidth: 3))
            .overlay(Rectangle().strokeBorder(Color.black.opacity(0.6), lineWidth: 1).padding(3))
    }
}

struct RetroButtonStyle: ButtonStyle {
    var accent: Color = Theme.amber
    var compact = false
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(compact ? 13 : 15))
            .foregroundStyle(enabled ? Theme.cream : Theme.dim)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, compact ? 10 : 14)
            .frame(minHeight: compact ? 36 : Theme.touch)
            .background(configuration.isPressed ? accent.opacity(0.45) : Theme.panelLight)
            .overlay(Rectangle().strokeBorder(enabled ? accent.opacity(0.9) : Theme.border, lineWidth: 2))
            .contentShape(Rectangle())
    }
}

/// Square icon button for HUD bars (SF Symbol + optional caption).
struct IconButton: View {
    let symbol: String
    var label: String?
    /// Spoken/identifier label when there is no visible caption.
    var a11y: String?
    var enabled = true
    var highlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 18, weight: .bold))
                if let label { Text(label).font(Theme.font(10)).lineLimit(1).minimumScaleFactor(0.7) }
            }
            .foregroundStyle(enabled ? Theme.cream : Theme.dim.opacity(0.6))
            .frame(minWidth: Theme.touch, minHeight: Theme.touch)
            .padding(.horizontal, label == nil ? 0 : 4)
            .background(Color.black.opacity(0.55))
            .overlay(Rectangle().strokeBorder(enabled ? Theme.amber.opacity(0.7) : Theme.border, lineWidth: 2))
            .tutorialPulse(highlighted)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label ?? a11y ?? symbol)
    }
}

/// Full-screen landscape panel with a header and a large close button.
struct PhonePanel<Content: View>: View {
    let title: String
    var closeTitle = "Stäng"
    let close: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture {}   // swallow taps so the world underneath does not react
            VStack(spacing: 8) {
                HStack {
                    Text(title.uppercased())
                        .font(Theme.font(18))
                        .foregroundStyle(Theme.amberLight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Button(action: { Haptics.tap(); close() }) {
                        Image(systemName: "xmark").font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Theme.cream)
                            .frame(width: Theme.touch, height: Theme.touch)
                            .background(Theme.panelLight)
                            .overlay(Rectangle().strokeBorder(Theme.amber.opacity(0.8), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(closeTitle)
                }
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(10)
            .background(Theme.panel.opacity(0.97))
            .overlay(Rectangle().strokeBorder(Theme.border, lineWidth: 3))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .transition(.opacity)
    }
}

/// Small centered panel for confirmations and short choices.
struct CompactPanel<Content: View>: View {
    var width: CGFloat = 420
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture {}
            RetroPanel(padding: 16) { content() }
                .frame(maxWidth: width)
                .padding(12)
        }
        .transition(.opacity)
    }
}

struct PixelIcon: View {
    let image: UIImage
    var size: CGFloat = 24

    var body: some View {
        Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
    }
}

struct Bar: View {
    let value: Double
    let max: Double
    var color: Color = Theme.amber
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.6))
                Rectangle().fill(color).frame(width: geo.size.width * CGFloat(Swift.max(0, Swift.min(1, value / Swift.max(max, 0.0001)))))
                Rectangle().strokeBorder(Theme.border, lineWidth: 1.5)
            }
        }
        .frame(height: height)
    }
}

struct CostRow: View {
    let cost: ResourceCost
    let state: GameState

    var body: some View {
        HStack(spacing: 10) {
            ForEach(cost.sorted { $0.key.rawValue < $1.key.rawValue }, id: \.key) { type, need in
                let have = state.inventory.total(type)
                HStack(spacing: 3) {
                    PixelIcon(image: IconSprites.resource(type), size: 22)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(have)/\(need)")
                            .font(Theme.font(13))
                            .foregroundStyle(have >= need ? Theme.green : Theme.red)
                        Text(ResourceCatalog.name(type)).font(Theme.body(9)).foregroundStyle(Theme.dim)
                    }
                }
            }
        }
    }
}

/// Pulsing amber ring used by tutorial hints.
struct TutorialPulse: ViewModifier {
    let active: Bool
    @State private var phase = false

    func body(content: Content) -> some View {
        content.overlay {
            if active {
                Rectangle()
                    .strokeBorder(Theme.amberLight, lineWidth: 3)
                    .padding(-4)
                    .opacity(phase ? 0.2 : 1)
                    .scaleEffect(phase ? 1.12 : 1)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: phase)
                    .onAppear { phase = true }
                    .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func tutorialPulse(_ active: Bool) -> some View { modifier(TutorialPulse(active: active)) }
}
