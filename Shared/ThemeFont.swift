import UIKit
import CoreText

/// 테마 이름에 쓰는 귀여운 글씨체 (주아, SIL Open Font License 무료 폰트)
enum ThemeFont {
    static let name = "Jua-Regular"
    private static var registered = false

    static func register() {
        guard !registered else { return }
        registered = true
        if let url = Bundle.main.url(forResource: "Jua-Theme", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func ui(_ size: CGFloat) -> UIFont {
        register()
        return UIFont(name: name, size: size) ?? .boldSystemFont(ofSize: size)
    }
}
