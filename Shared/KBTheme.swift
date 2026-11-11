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
    var cap: String = "jelly"         // 키캡 모양: jelly 젤리 · round 동글 타자기 · clear 투명 젤리 · clay 클레이 · sa 레트로 기계식
    var stitch: UIColor? = nil        // 가죽 박음질 색 (글자 키 안쪽 점선)
    var group: String = "color"       // color: 컬러 · retro: 레트로 (둘 다 키캡 모양 고르기) · winter: 겨울 (기계식 고정)

    var menuName: String { short ?? name }

    private static func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
    private static func dyn(_ light: UIColor, _ dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    /// 1. 블랙 퍼플 (기본) — 위는 블랙, 아래로 갈수록 보라 그라데이션 + 골드 포인트
    static let standard = KBTheme(
        id: "default", name: "블랙 퍼플",
        bg: c(40, 30, 80), key: c(36, 32, 56), special: c(112, 82, 204),
        pressKey: c(56, 50, 84), pressSpecial: c(96, 68, 184),
        text: c(226, 218, 255), specialText: .white,
        accent: c(196, 152, 64), depth: 4, radius: 10, bgImage: "bg_kit")

    static let all: [KBTheme] = [
        standard,
        KBTheme(id: "redblue", name: "레드 블루",
                bg: c(30, 40, 110), key: c(250, 248, 244), special: c(170, 20, 72),
                pressKey: c(232, 228, 222), pressSpecial: c(150, 14, 60),
                text: c(0, 62, 146), specialText: .white,
                accent: c(200, 156, 60), depth: 4, radius: 10, bgImage: "bg_stripe"),
        KBTheme(id: "race", name: "레이싱 레드",
                bg: c(16, 18, 24), key: c(30, 30, 33), special: c(190, 18, 28),
                pressKey: c(46, 46, 50), pressSpecial: c(160, 12, 22),
                text: c(236, 236, 238), specialText: .white,
                accent: c(214, 22, 32), depth: 4, radius: 10),

        // ---- 레트로 10색 (키캡 모양 고르기),
        KBTheme(id: "rt_rose", name: "블랙 & 로즈 골드",
                bg: c(14, 12, 14), key: c(42, 38, 40), special: c(28, 25, 27),
                pressKey: c(60, 55, 57), pressSpecial: c(46, 42, 44),
                text: c(246, 172, 142), specialText: c(246, 172, 142),
                depth: 4, radius: 10, short: "로즈 골드"),
        KBTheme(id: "rosegold", name: "블랙 & 화이트 레드",
                bg: c(12, 11, 13), key: .white, special: c(252, 226, 226),
                pressKey: c(240, 234, 234), pressSpecial: c(240, 206, 206),
                text: c(214, 26, 42), specialText: c(204, 22, 38),
                accent: c(220, 30, 44), depth: 4, radius: 10, short: "화이트 레드"),
        KBTheme(id: "rt_mono", name: "블랙",
                bg: c(30, 30, 34), key: c(70, 70, 76), special: c(50, 50, 55),
                pressKey: c(92, 92, 98), pressSpecial: c(70, 70, 76),
                text: c(246, 246, 242), specialText: c(246, 246, 242),
                depth: 4, radius: 10, short: "블랙"),
        KBTheme(id: "pin", name: "핀스트라이프",
                bg: c(250, 250, 251), key: .white, special: c(30, 30, 34),
                pressKey: c(236, 236, 238), pressSpecial: c(54, 54, 58),
                text: c(24, 24, 28), specialText: .white,
                accent: c(204, 24, 44), depth: 4, radius: 10, bgImage: "bg_pin"),
        KBTheme(id: "rt_navy", name: "네이비 & 오렌지",
                bg: c(36, 52, 92), key: c(246, 242, 232), special: c(72, 98, 156),
                pressKey: c(231, 227, 218), pressSpecial: c(66, 90, 143),
                text: c(34, 46, 76), specialText: c(255, 248, 236),
                accent: c(250, 152, 40), depth: 4, radius: 10, short: "네이비"),
        KBTheme(id: "rt_royal", name: "로열 블루 & 골드",
                bg: c(46, 84, 176), key: c(80, 124, 220), special: c(255, 204, 64),
                pressKey: c(75, 116, 206), pressSpecial: c(234, 187, 58),
                text: c(255, 255, 255), specialText: c(90, 60, 10),
                accent: c(255, 204, 64), depth: 4, radius: 10, short: "로열 블루"),
        KBTheme(id: "aurora", name: "오로라",
                bg: c(40, 44, 100), key: c(214, 240, 250), special: c(140, 110, 230),
                pressKey: c(190, 222, 238), pressSpecial: c(120, 92, 210),
                text: c(50, 70, 130), specialText: .white,
                accent: c(70, 206, 170)),
        KBTheme(id: "rt_sky", name: "하늘 & 핑크",
                bg: c(204, 228, 252), key: c(255, 255, 255), special: c(118, 180, 244),
                pressKey: c(239, 239, 239), pressSpecial: c(108, 165, 224),
                text: c(60, 110, 170), specialText: .white,
                accent: c(255, 128, 170), depth: 4, radius: 10, short: "하늘 핑크"),
        KBTheme(id: "winter", name: "눈사람",
                bg: c(170, 200, 240), key: c(252, 254, 255), special: c(150, 190, 240),
                pressKey: c(226, 238, 252), pressSpecial: c(130, 172, 228),
                text: c(60, 100, 170), specialText: .white,
                accent: c(110, 160, 232),
                bgImage: "bg_winter", enterIcon: "enter_snowman", sticker: "sticker_snow",
                cap: "sa"),
        KBTheme(id: "mint", name: "민트 소다",
                bg: c(132, 222, 206), key: c(236, 252, 248), special: c(90, 200, 186),
                pressKey: c(212, 240, 234), pressSpecial: c(74, 184, 170),
                text: c(30, 96, 92), specialText: .white,
                accent: c(44, 170, 190), depth: 4, radius: 10),
        KBTheme(id: "holly", name: "홀리 그린",
                bg: c(30, 110, 70), key: c(255, 250, 240), special: c(220, 50, 56),
                pressKey: c(240, 232, 218), pressSpecial: c(196, 40, 48),
                text: c(30, 100, 60), specialText: .white,
                accent: c(220, 50, 56), short: "홀리"),
        KBTheme(id: "peach", name: "피치",
                bg: c(255, 214, 204), key: c(255, 251, 249), special: c(255, 140, 130),
                pressKey: c(246, 234, 230), pressSpecial: c(236, 116, 106),
                text: c(150, 50, 46), specialText: .white,
                accent: c(255, 110, 110), depth: 4, radius: 12),
        KBTheme(id: "luxbeige", name: "럭셔리 베이지",
                bg: c(205, 187, 167), key: c(251, 246, 239), special: c(228, 214, 198),
                pressKey: c(238, 230, 220), pressSpecial: c(214, 198, 180),
                text: c(116, 92, 72), specialText: c(116, 92, 72),
                accent: c(196, 162, 108), depth: 4, radius: 10, bgImage: "bg_beige", short: "럭셔리 베이지"),
        KBTheme(id: "rt_cherry", name: "체리 & 크림",
                bg: c(214, 44, 72), key: c(255, 242, 228), special: c(255, 90, 110),
                pressKey: c(239, 227, 214), pressSpecial: c(234, 82, 101),
                text: c(170, 40, 60), specialText: .white,
                accent: c(255, 196, 90), depth: 4, radius: 10, short: "체리"),
        KBTheme(id: "rt_milk", name: "딸기 우유",
                bg: c(255, 206, 220), key: c(255, 255, 255), special: c(255, 116, 156),
                pressKey: c(239, 239, 239), pressSpecial: c(234, 106, 143),
                text: c(200, 70, 110), specialText: .white,
                accent: c(255, 72, 124), depth: 4, radius: 10, short: "딸기 우유"),
        KBTheme(id: "red", name: "크리스마스",
                bg: c(150, 20, 32), key: c(255, 248, 238), special: c(214, 52, 58),
                pressKey: c(240, 226, 214), pressSpecial: c(190, 40, 48),
                text: c(40, 120, 70), specialText: .white,
                accent: c(34, 130, 70),
                bgImage: "bg_red", enterIcon: "enter_snowman_red", sticker: "sticker_holly",
                cap: "sa"),
        KBTheme(id: "lavender", name: "라벤더",
                bg: c(232, 224, 248), key: c(242, 235, 253), special: c(198, 180, 240),
                pressKey: c(226, 216, 246), pressSpecial: c(180, 160, 230),
                text: c(100, 80, 150), specialText: .white,
                accent: c(160, 130, 232), depth: 4, radius: 12),
        KBTheme(id: "rt_lavender", name: "라벤더 드림",
                bg: c(178, 148, 244), key: c(250, 246, 255), special: c(196, 156, 255),
                pressKey: c(235, 231, 239), pressSpecial: c(180, 143, 234),
                text: c(110, 70, 190), specialText: .white,
                accent: c(136, 86, 250), depth: 4, radius: 10, short: "라벤더"),

        // ---- 겨울 (레트로 기계식 키캡: 오목한 윗면 + 도톰한 몸통),
        // ---- 버건디 스페셜 ----
        KBTheme(id: "bur_key", name: "버건디 키",
                bg: c(150, 150, 156), key: c(118, 26, 44), special: c(70, 70, 76),
                pressKey: c(106, 23, 39), pressSpecial: c(61, 61, 66),
                text: .white, specialText: .white,
                accent: c(150, 34, 56), depth: 4, radius: 10, short: "버건디 키", group: "special"),
        KBTheme(id: "bur_silver", name: "버건디 실버",
                bg: c(110, 22, 40), key: c(206, 206, 210), special: c(150, 150, 156),
                pressKey: c(185, 185, 189), pressSpecial: c(132, 132, 137),
                text: c(110, 22, 40), specialText: .white,
                accent: c(70, 70, 76), depth: 4, radius: 10, short: "버건디 실버", group: "special"),
        KBTheme(id: "bur_charcoal", name: "버건디 차콜",
                bg: c(72, 72, 78), key: c(120, 28, 48), special: c(40, 40, 44),
                pressKey: c(108, 25, 43), pressSpecial: c(35, 35, 38),
                text: c(236, 226, 228), specialText: c(210, 210, 216),
                accent: c(150, 150, 158), depth: 4, radius: 10, short: "버건디 차콜", group: "special"),
        KBTheme(id: "bur_gold", name: "버건디 골드",
                bg: c(70, 12, 26), key: c(128, 24, 46), special: c(92, 16, 32),
                pressKey: c(115, 21, 41), pressSpecial: c(80, 14, 28),
                text: c(232, 192, 118), specialText: c(232, 192, 118),
                accent: c(214, 170, 86), depth: 4, radius: 10, short: "버건디 골드", group: "special"),
    ]

    static var colors: [KBTheme] { all.filter { $0.group == "color" } }
    static var retro: [KBTheme] { all.filter { $0.group == "retro" } }
    static func group(_ g: String) -> [KBTheme] { all.filter { $0.group == g } }
    /// 키캡 모양을 고를 수 있는 테마
    static func capped(_ t: KBTheme) -> Bool { true }
    /// 메뉴 한 장에 10개씩
    static var mainList: [KBTheme] { all.filter { $0.group == "color" } }
    static var pages: [[KBTheme]] { let m = mainList; return stride(from: 0, to: m.count, by: 10).map { Array(m[$0..<min($0 + 10, m.count)]) } }
    static var special: [KBTheme] { all.filter { $0.group == "special" } }
    /// 메뉴 탭: 숫자는 장, "s"는 버건디 스페셜
    static func tabList(_ tab: String) -> [KBTheme] { tab == "s" ? special : page(Int(tab) ?? 0) }
    static func tabOf(_ t: KBTheme) -> String { t.group == "special" ? "s" : String(pageOf(t.id)) }
    static func page(_ i: Int) -> [KBTheme] { i < pages.count ? pages[i] : pages[0] }
    static func pageOf(_ id: String) -> Int { pages.firstIndex { $0.contains { $0.id == id } } ?? 0 }

    /// 컬러 테마의 키캡 모양 (드롭다운)
    static let caps: [(id: String, name: String)] = [("jelly", "젤리"), ("round", "동글 타자기"), ("clear", "투명 젤리"), ("clay", "클레이"), ("sa", "레트로 기계식")]
    static func capName(_ id: String) -> String { caps.first { $0.id == id }?.name ?? "젤리" }

    /// 미리보기 그림 이름 (컬러 테마는 키캡 모양마다 따로)
    static func previewName(_ t: KBTheme, cap: String) -> String { capped(t) ? "\(t.id)_\(cap)" : t.id }

    /// 컬러 테마는 고른 키캡 모양으로
    static func find(_ id: String) -> KBTheme {
        var t = all.first { $0.id == id } ?? standard
        if capped(t) { t.cap = ThemeStore.capId() }
        return t
    }
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

    static func capId() -> String {
        var best = "jelly", bestTs = -1.0
        for d in suites() {
            let ts = d.double(forKey: "fe.capTS")
            if let v = d.string(forKey: "fe.cap"), ts > bestTs { best = v; bestTs = ts }
        }
        return best
    }

    static func saveCap(_ id: String) {
        let ts = Date().timeIntervalSince1970
        for d in suites() { d.set(id, forKey: "fe.cap"); d.set(ts, forKey: "fe.capTS") }
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
