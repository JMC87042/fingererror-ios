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
    var jelly: Bool = true            // 3D 키캡 (아래 cap 모양으로 그림)
    var cap: String = "jelly"         // 키캡 모양: jelly 젤리 · round 동글 타자기 · clear 투명 젤리 · clay 클레이

    var menuName: String { short ?? name }

    private static func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
    private static func dyn(_ light: UIColor, _ dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    /// 1. 크림 젤리 (기본) — 말랑한 크림색 키캡, 복숭아 포인트. 폰이 다크모드면 그레이 젤리
    static let standard = KBTheme(
        id: "default", name: "크림 젤리",
        bg: dyn(c(246, 232, 218), c(26, 26, 30)),
        key: dyn(c(255, 250, 242), c(92, 92, 100)),
        special: dyn(c(255, 204, 182), c(62, 62, 70)),
        pressKey: dyn(c(244, 234, 220), c(72, 72, 80)),
        pressSpecial: dyn(c(246, 184, 160), c(84, 84, 92)),
        text: dyn(c(112, 78, 60), .white), specialText: dyn(c(156, 72, 50), .white),
        side: dyn(c(226, 202, 180), c(52, 52, 58)), sideSpecial: dyn(c(228, 152, 124), c(36, 36, 42)),
        accent: c(255, 138, 108), depth: 4, radius: 10)

    static let all: [KBTheme] = [
        standard,
        KBTheme(id: "oled", name: "블랙 젤리",
                bg: .black, key: c(40, 40, 46), special: c(26, 26, 30),
                pressKey: c(62, 62, 68), pressSpecial: c(46, 46, 52),
                text: c(226, 226, 222), specialText: c(160, 160, 156),
                side: c(18, 18, 22), sideSpecial: c(10, 10, 12), depth: 4, radius: 10),
        KBTheme(id: "mint", name: "민트 소다",
                bg: c(132, 222, 206), key: c(236, 252, 248), special: c(90, 200, 186),
                pressKey: c(212, 240, 234), pressSpecial: c(74, 184, 170),
                text: c(30, 96, 92), specialText: .white,
                accent: c(44, 170, 190), depth: 5, radius: 10, short: "동글 민트", cap: "round"),
        KBTheme(id: "peach", name: "투명 피치 젤리",
                bg: c(255, 214, 204), key: c(255, 176, 160), special: c(255, 140, 130),
                pressKey: c(250, 150, 134), pressSpecial: c(236, 116, 106),
                text: c(150, 50, 46), specialText: .white,
                accent: c(255, 110, 110), depth: 3, radius: 12, short: "투명 피치", cap: "clear"),
        KBTheme(id: "lime", name: "라임 젤리",
                bg: c(214, 236, 190), key: c(249, 252, 241), special: c(176, 220, 110),
                pressKey: c(232, 242, 218), pressSpecial: c(156, 204, 90),
                text: c(60, 90, 40), specialText: c(40, 70, 24),
                side: c(196, 214, 168), sideSpecial: c(116, 166, 56), accent: c(110, 172, 52),
                depth: 4, radius: 10),
        KBTheme(id: "lavender", name: "라벤더 클레이",
                bg: c(232, 224, 248), key: c(242, 235, 253), special: c(198, 180, 240),
                pressKey: c(226, 216, 246), pressSpecial: c(180, 160, 230),
                text: c(100, 80, 150), specialText: .white,
                accent: c(160, 130, 232), depth: 0, radius: 12, short: "라벤더 클레이", cap: "clay"),
        KBTheme(id: "coral", name: "가을 코랄",
                bg: c(250, 160, 130), key: c(255, 251, 247), special: c(238, 104, 80),
                pressKey: c(255, 234, 224), pressSpecial: c(214, 88, 66),
                text: c(196, 64, 52), specialText: .white,
                accent: c(218, 52, 52), depth: 4, radius: 11,
                bgImage: "bg_coral", enterIcon: "enter_chestnut", sticker: "sticker_chestnut",
                gloss: true, shadowColor: c(200, 80, 60), sprinkle: "sprinkle_maple_"),
        KBTheme(id: "yellow", name: "가을 옐로우",
                bg: c(252, 204, 80), key: c(255, 253, 244), special: c(246, 166, 40),
                pressKey: c(255, 240, 200), pressSpecial: c(226, 146, 30),
                text: c(170, 100, 20), specialText: .white,
                accent: c(232, 92, 40), depth: 4, radius: 11,
                bgImage: "bg_yellow", enterIcon: "enter_chestnut", sticker: "sticker_chestnut",
                gloss: true, shadowColor: c(200, 140, 30), sprinkle: "sprinkle_ginkgo_"),
        KBTheme(id: "winter", name: "겨울 눈사람",
                bg: c(170, 200, 240), key: c(252, 254, 255), special: c(196, 218, 248),
                pressKey: c(226, 238, 252), pressSpecial: c(176, 202, 240),
                text: c(70, 110, 180), specialText: c(50, 90, 160),
                accent: c(120, 160, 230), depth: 4, radius: 12,
                bgImage: "bg_winter", enterIcon: "enter_snowman", sticker: "sticker_snow",
                gloss: true, shadowColor: c(100, 140, 200)),
        KBTheme(id: "red", name: "겨울 레드",
                bg: c(118, 14, 24), key: c(255, 250, 242), special: c(214, 52, 58),
                pressKey: c(240, 226, 214), pressSpecial: c(190, 40, 48),
                text: c(30, 112, 64), specialText: c(255, 246, 236),
                accent: c(34, 112, 66), depth: 4, radius: 12,
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

    // MARK: - 앱과 키보드가 함께 보는 설정·리포트

    static func bool(_ key: String) -> Bool {
        var best = false, bestTs = -1.0
        for d in suites() {
            let ts = d.double(forKey: key + "TS")
            if d.object(forKey: key) != nil, ts > bestTs { best = d.bool(forKey: key); bestTs = ts }
        }
        return best
    }

    static func setBool(_ key: String, _ v: Bool) {
        let ts = Date().timeIntervalSince1970
        for d in suites() { d.set(v, forKey: key); d.set(ts, forKey: key + "TS") }
    }

    static func saveReport(_ data: Data) {
        let ts = Date().timeIntervalSince1970
        for d in suites() { d.set(data, forKey: "fe.report"); d.set(ts, forKey: "fe.reportTS") }
    }

    // MARK: - 데이터 초기화 (앱에서 누르면 키보드가 다음에 열릴 때 지움)

    static func requestReset() {
        let ts = Date().timeIntervalSince1970
        for d in suites() {
            d.set(ts, forKey: "fe.resetAt")
            d.removeObject(forKey: "fe.report")
            d.set(ts, forKey: "fe.reportTS")
        }
    }

    static func resetStamp() -> Double {
        suites().map { $0.double(forKey: "fe.resetAt") }.max() ?? 0
    }

    static func loadReport() -> [String: Any]? {
        var best: Data?, bestTs = -1.0
        for d in suites() {
            let ts = d.double(forKey: "fe.reportTS")
            if let v = d.data(forKey: "fe.report"), ts > bestTs { best = v; bestTs = ts }
        }
        guard let b = best else { return nil }
        return (try? JSONSerialization.jsonObject(with: b)) as? [String: Any]
    }
}
