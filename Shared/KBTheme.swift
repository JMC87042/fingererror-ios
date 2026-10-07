import UIKit

/// 키보드 테마. 색만 바뀌고 키 위치·크기는 모든 테마가 같음 (학습 기록 유지)
struct KBTheme {
    let id: String
    let name: String
    let bg: UIColor
    let key: UIColor
    let special: UIColor
    let pressKey: UIColor
    let pressSpecial: UIColor
    let text: UIColor
    let specialText: UIColor
    var side: UIColor? = nil          // 레트로: 키 아랫단 색
    var sideSpecial: UIColor? = nil
    var rim: UIColor? = nil           // OLED: 키 테두리
    var accent: UIColor? = nil        // 줄바꿈 키 포인트 색
    var depth: CGFloat = 0            // 레트로 입체 두께
    var radius: CGFloat = 6
    var shadow: Bool = false
    var bgImage: String? = nil        // 계절: 배경 그림
    var enterIcon: String? = nil      // 계절: 줄바꿈 키 그림 (단풍·눈사람)
    var sticker: String? = nil        // 계절: 키 모서리 스티커
    var gloss: Bool = false           // 계절: 키 윗부분 반짝임
    var shadowColor: UIColor? = nil
    var short: String? = nil          // 테마 메뉴에 보일 짧은 이름
    var spaceIcon: String? = nil      // 스페이스바 팻핑이 (밤 모자 등)
    var sprinkle: String? = nil       // 키 모서리 곳곳의 작은 잎 (그림 이름 앞부분)

    var menuName: String { short ?? name }

    private static func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
    private static func dyn(_ light: UIColor, _ dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    /// 기본 테마는 폰의 다크모드를 따라감
    static let standard = KBTheme(
        id: "default", name: "기본",
        bg: dyn(c(209, 213, 219), UIColor(white: 0.12, alpha: 1)),
        key: dyn(.white, UIColor(white: 0.42, alpha: 1)),
        special: dyn(c(171, 178, 189), UIColor(white: 0.27, alpha: 1)),
        pressKey: dyn(c(171, 178, 189), UIColor(white: 0.27, alpha: 1)),
        pressSpecial: dyn(.white, UIColor(white: 0.42, alpha: 1)),
        text: .label, specialText: .label,
        shadow: true)

    static let all: [KBTheme] = [
        standard,
        KBTheme(id: "oled", name: "OLED 매트 블랙",
                bg: .black, key: c(26, 26, 28), special: c(14, 14, 16,
                short: "OLED 블랙"),
                pressKey: c(52, 52, 56), pressSpecial: c(40, 40, 44),
                text: c(214, 214, 210), specialText: c(150, 150, 146),
                rim: c(38, 38, 42), radius: 7),
        KBTheme(id: "mint", name: "레트로 민트 & 크림",
                bg: c(38, 92, 88), key: c(244, 238, 222), special: c(120, 196, 184,
                short: "민트 & 크림"),
                pressKey: c(226, 218, 198), pressSpecial: c(104, 180, 168),
                text: c(40, 64, 60), specialText: c(24, 60, 56),
                side: c(190, 180, 156), sideSpecial: c(76, 150, 138), accent: c(238, 98, 74),
                depth: 5, radius: 5),
        KBTheme(id: "navy", name: "레트로 네이비 & 오렌지",
                bg: c(28, 38, 64), key: c(236, 232, 222), special: c(64, 82, 124,
                short: "네이비 & 오렌지"),
                pressKey: c(216, 210, 196), pressSpecial: c(54, 70, 108),
                text: c(30, 40, 66), specialText: c(236, 232, 222),
                side: c(178, 172, 158), sideSpecial: c(40, 54, 90), accent: c(240, 128, 40),
                depth: 5, radius: 5),
        KBTheme(id: "lime", name: "레트로 연두 & 그레이",
                bg: c(70, 76, 72), key: c(238, 240, 232), special: c(170, 214, 96,
                short: "연두 & 그레이"),
                pressKey: c(220, 224, 212), pressSpecial: c(152, 196, 80),
                text: c(48, 58, 44), specialText: c(40, 70, 30),
                side: c(182, 186, 174), sideSpecial: c(120, 166, 60), accent: c(40, 70, 30),
                depth: 5, radius: 5),
        KBTheme(id: "lavender", name: "레트로 파스텔 라벤더",
                bg: c(186, 176, 214), key: c(250, 246, 252), special: c(232, 196, 214,
                short: "파스텔 라벤더"),
                pressKey: c(232, 226, 238), pressSpecial: c(216, 178, 198),
                text: c(84, 72, 110), specialText: c(110, 60, 88),
                side: c(206, 196, 222), sideSpecial: c(206, 160, 184), accent: c(150, 120, 200),
                depth: 5, radius: 5),
        KBTheme(id: "coral", name: "가을 코랄",
                bg: c(250, 160, 130), key: c(255, 251, 247), special: c(238, 104, 80),
                pressKey: c(255, 234, 224), pressSpecial: c(214, 88, 66),
                text: c(196, 64, 52), specialText: .white,
                accent: c(218, 52, 52), radius: 11, shadow: true,
                bgImage: "bg_coral", enterIcon: "enter_chestnut", sticker: "sticker_chestnut",
                gloss: true, shadowColor: c(200, 80, 60),
                spaceIcon: "space_logo_chestnut", sprinkle: "sprinkle_maple_"),
        KBTheme(id: "yellow", name: "가을 옐로우",
                bg: c(252, 204, 80), key: c(255, 253, 244), special: c(246, 166, 40),
                pressKey: c(255, 240, 200), pressSpecial: c(226, 146, 30),
                text: c(170, 100, 20), specialText: .white,
                accent: c(232, 92, 40), radius: 11, shadow: true,
                bgImage: "bg_yellow", enterIcon: "enter_chestnut", sticker: "sticker_chestnut",
                gloss: true, shadowColor: c(200, 140, 30),
                spaceIcon: "space_logo_chestnut", sprinkle: "sprinkle_ginkgo_"),
        KBTheme(id: "winter", name: "겨울 눈사람",
                bg: c(170, 200, 240), key: c(252, 254, 255), special: c(196, 218, 248),
                pressKey: c(226, 238, 252), pressSpecial: c(176, 202, 240),
                text: c(70, 110, 180), specialText: c(50, 90, 160),
                accent: c(120, 160, 230), radius: 12, shadow: true,
                bgImage: "bg_winter", enterIcon: "enter_snowman", sticker: "sticker_snow",
                gloss: true, shadowColor: c(100, 140, 200)),
        KBTheme(id: "red", name: "겨울 레드",
                bg: c(118, 14, 24), key: c(255, 250, 242), special: c(214, 52, 58),
                pressKey: c(240, 226, 214), pressSpecial: c(190, 40, 48),
                text: c(30, 112, 64), specialText: c(255, 246, 236),
                accent: c(34, 112, 66), radius: 12, shadow: true,
                bgImage: "bg_red", enterIcon: "enter_snowman_red", sticker: "sticker_holly",
                gloss: true, shadowColor: c(40, 0, 0)),
    ]

    static func find(_ id: String) -> KBTheme { all.first { $0.id == id } ?? standard }
}

/// 앱과 키보드가 같은 테마 설정을 보도록 저장.
/// 설치 방식(AltStore 등)에 따라 그룹 이름이 바뀔 수 있어서 후보 여러 곳에 쓰고, 가장 최근 것을 읽음.
enum ThemeStore {
    static let baseGroup = "group.com.jmc.fingererror"

    private static func suites() -> [UserDefaults] {
        var names = [baseGroup]
        if var bid = Bundle.main.bundleIdentifier {
            if bid.hasSuffix(".keyboard") { bid = String(bid.dropLast(".keyboard".count)) }
            names.append("group." + bid)
            if bid.hasPrefix("com.jmc.fingererror.") {
                let team = bid.dropFirst("com.jmc.fingererror.".count)
                names.append(baseGroup + "." + team)
            }
        }
        var out: [UserDefaults] = [UserDefaults.standard]
        for n in Set(names) { if let d = UserDefaults(suiteName: n) { out.append(d) } }
        return out
    }

    static func currentId() -> String {
        var best = "default"
        var bestTs = -1.0
        for d in suites() {
            let ts = d.double(forKey: "fe.themeTS")
            if let id = d.string(forKey: "fe.theme"), ts > bestTs { best = id; bestTs = ts }
        }
        return best
    }

    static func current() -> KBTheme { KBTheme.find(currentId()) }

    static func save(_ id: String) {
        let ts = Date().timeIntervalSince1970
        for d in suites() {
            d.set(id, forKey: "fe.theme")
            d.set(ts, forKey: "fe.themeTS")
        }
    }
}
