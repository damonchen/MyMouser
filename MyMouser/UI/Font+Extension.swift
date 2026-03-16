import SwiftUI

extension Font {
    static func system(size: CGFloat, weight: Font.Weight = .regular, family: String) -> Font {
        return Font.custom(family, size: size).weight(weight)
    }
}
