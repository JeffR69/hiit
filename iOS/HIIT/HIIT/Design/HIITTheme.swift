import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum HIITTheme {
    static let red = Color(light: 0xD12F2F, dark: 0xFF5C57)
    static let blue = Color(light: 0x1F4FCF, dark: 0x6B9BFF)
    static let green = Color(light: 0x0B8C68, dark: 0x38DBAB)
    static let violet = Color(light: 0x7A3FC4, dark: 0xB98CFF)
    static let background = Color(light: 0xE9ECEF, dark: 0x0E1114)
    static let board = Color(light: 0xFCFCFA, dark: 0x171B21)
    static let ink = Color(light: 0x18202E, dark: 0xF2F3EF)
    static let muted = Color(light: 0x5E6878, dark: 0x9AA3B0)
    static let line = Color(light: 0xCFD5DD, dark: 0x2B323C)

    static func exerciseColor(_ index: Int) -> Color {
        [red, blue, green][index % 3]
    }
}

private extension Color {
    init(light: UInt, dark: UInt) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            Self.platformColor(
                traits.userInterfaceStyle == .dark ? dark : light
            )
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return Self.platformColor(isDark ? dark : light)
        })
        #endif
    }

    #if canImport(UIKit)
    static func platformColor(_ value: UInt) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
    #elseif canImport(AppKit)
    static func platformColor(_ value: UInt) -> NSColor {
        NSColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
    #endif
}
