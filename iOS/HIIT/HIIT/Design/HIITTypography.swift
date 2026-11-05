import SwiftUI

enum HIITTypography {
    static func text(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black:
            name = "Barlow-SemiBold"
        case .medium:
            name = "Barlow-Medium"
        default:
            name = "Barlow-Regular"
        }
        return .custom(name, size: pointSize(for: style), relativeTo: style)
    }

    static func display(
        _ style: Font.TextStyle,
        weight: Font.Weight = .bold
    ) -> Font {
        let name: String
        switch weight {
        case .heavy, .black:
            name = "BarlowCondensed-ExtraBold"
        case .bold:
            name = "BarlowCondensed-Bold"
        default:
            name = "BarlowCondensed-SemiBold"
        }
        return .custom(name, size: pointSize(for: style), relativeTo: style)
    }

    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let name = weight == .heavy || weight == .black
            ? "BarlowCondensed-ExtraBold"
            : weight == .bold
                ? "BarlowCondensed-Bold"
                : "BarlowCondensed-SemiBold"
        return .custom(name, fixedSize: size)
    }

    private static func pointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 44
        case .title: 34
        case .title2: 26
        case .title3: 22
        case .headline: 17
        case .subheadline: 15
        case .callout: 16
        case .caption: 13
        case .caption2: 12
        case .footnote: 13
        default: 17
        }
    }
}
