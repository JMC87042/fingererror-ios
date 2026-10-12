import Foundation

struct KeyOffset: Codable {
    var dx: Double = 0
    var dy: Double = 0
    var n: Int = 0
}

struct Spread: Codable {
    var vx: Double = 0.06
    var vy: Double = 0.06
    var n: Int = 0
}

/// 한 사람의 엄지 습관 (이 폰 안에만 저장)
struct LearnData: Codable {
    var off: [String: KeyOffset] = [:]   // 키별 엄지 쏠림 (키 크기 대비 비율)
    var conf: [String: Int] = [:]        // "실제로 눌린 키>치려던 키" 횟수
    var spread = Spread()                // 가로/세로 흔들림
    var dirH: Int = 0                    // 양옆 실수 횟수
    var dirV: Int = 0                    // 위아래 실수 횟수
    var taps: Int = 0
    var learned: Int = 0
    var fixes: Int = 0
    var fixOn: Bool = true
    // 아래는 나중에 추가된 기록 (예전 기록을 읽을 때 없어도 되도록 옵셔널)
    var daily: [String: [Int]]? = nil     // "2026-10-12": [한글 타수, 한글 고침, 영어 타수, 영어 고침]
    var tapsEn: Int? = nil
    var fixesEn: Int? = nil
    var installDay: String? = nil         // 처음 쓴 날 (날짜 기념일 기준)
    var countDone: Int? = nil             // 마지막으로 보여준 오타 기념일
    var dayDone: Int? = nil               // 마지막으로 보여준 날짜 기념일
    var reached: [String]? = nil          // 받은 기념일 기록 ("c22", "d100" …)
}

enum ThumbType { case vertical, horizontal, even, unknown }

final class Learner {
    var data = LearnData()
    private let storeKey = "fingererror.learn.v1"
    private var pending: DispatchWorkItem?

    init() {
        if let d = UserDefaults.standard.data(forKey: storeKey),
           let v = try? JSONDecoder().decode(LearnData.self, from: d) {
            data = v
        }
    }

    func saveSoon() {
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.saveNow() }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    func saveNow() {
        if let d = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(d, forKey: storeKey)
        }
        if let r = reportData() { ThemeStore.saveReport(r) }
    }

    // 어미 자리 기록 (초성 기록과 따로)
    var endConf: [String: Int] {
        get { (UserDefaults.standard.dictionary(forKey: "fingererror.endConf") as? [String: Int]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "fingererror.endConf") }
    }
    var endNo: [String: Bool] {
        get { (UserDefaults.standard.dictionary(forKey: "fingererror.endNo") as? [String: Bool]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "fingererror.endNo") }
    }

    // MARK: - 기록 (친 글은 저장하지 않고, 횟수만)

    static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    static func today() -> String { dayFmt.string(from: Date()) }

    private func bumpDay(_ slot: Int) {
        var d = data.daily ?? [:]
        let k = Learner.today()
        var row = d[k] ?? [0, 0, 0, 0]
        row[slot] += 1
        d[k] = row
        if d.count > 70 { for old in d.keys.sorted().prefix(d.count - 70) { d.removeValue(forKey: old) } }
        data.daily = d
    }

    func countTap(english: Bool) {
        if english { data.tapsEn = (data.tapsEn ?? 0) + 1 } else { data.taps += 1 }
        bumpDay(english ? 2 : 0)
    }

    func countFix(english: Bool) {
        if english { data.fixesEn = (data.fixesEn ?? 0) + 1 } else { data.fixes += 1 }
        bumpDay(english ? 3 : 1)
    }

    var totalFixes: Int { data.fixes + (data.fixesEn ?? 0) }

    /// 오타 기념일: 22 · 100 · 200 · 300 · 365 · 500 · 1000 → 이후 1000개마다
    static func countMilestones(upTo n: Int) -> [Int] {
        var m = [22, 100, 200, 300, 365, 500, 1000]
        var k = 2000
        while k <= n { m.append(k); k += 1000 }
        return m.filter { $0 <= n }
    }

    /// 새로 도달한 오타 기념일 (없으면 nil)
    func newCountMilestone() -> Int? {
        let n = totalFixes
        let done = data.countDone ?? 0
        guard let m = Learner.countMilestones(upTo: n).last, m > done else { return nil }
        data.countDone = m
        data.reached = (data.reached ?? []) + ["c\(m)"]
        return m
    }

    /// 새로 도달한 날짜 기념일 (만난 지 22·100·200·300·365·500·1000일), 지난 지 3일 넘었으면 조용히 넘김
    func newDayMilestone() -> Int? {
        if data.installDay == nil { data.installDay = Learner.today(); return nil }
        guard let start = Learner.dayFmt.date(from: data.installDay!) else { return nil }
        let days = (Calendar(identifier: .gregorian).dateComponents([.day], from: start, to: Date()).day ?? 0) + 1
        let done = data.dayDone ?? 0
        guard let m = [22, 100, 200, 300, 365, 500, 1000].filter({ $0 <= days }).last, m > done else { return nil }
        data.dayDone = m
        if days - m > 3 { return nil }
        data.reached = (data.reached ?? []) + ["d\(m)"]
        return m
    }

    /// 앱 리포트용 요약 (글자 내용 없이 횟수·키 위치만)
    func reportData() -> Data? {
        var r: [String: Any] = [:]
        r["taps"] = [data.taps, data.tapsEn ?? 0]
        r["fixes"] = [data.fixes, data.fixesEn ?? 0]
        r["daily"] = data.daily ?? [:]
        r["conf"] = data.conf
        var off: [String: [Double]] = [:]
        for (k, v) in data.off where v.n >= 5 { off[k] = [v.dx, v.dy, Double(v.n)] }
        r["off"] = off
        r["reached"] = data.reached ?? []
        r["install"] = data.installDay ?? ""
        return try? JSONSerialization.data(withJSONObject: r)
    }

    func reset() {
        endConf = [:]; endNo = [:]
        data = LearnData()
        saveNow()
    }

    static func clamp(_ v: Double, _ a: Double) -> Double { max(-a, min(a, v)) }

    /// ox, oy: 의도한 키 중심 기준 터치 위치 (키 크기 대비 비율)
    func learn(_ id: String, ox rawX: Double, oy rawY: Double, rate: Double) {
        let ox = Learner.clamp(rawX, 0.9)
        let oy = Learner.clamp(rawY, 0.9)
        var o = data.off[id] ?? KeyOffset()
        let r2 = rate > 0.1 ? 0.1 : 0.04
        data.spread.vx += r2 * (min((ox - o.dx) * (ox - o.dx), 0.5) - data.spread.vx)
        data.spread.vy += r2 * (min((oy - o.dy) * (oy - o.dy), 0.5) - data.spread.vy)
        data.spread.n += 1
        o.dx = Learner.clamp(o.dx + rate * (ox - o.dx), 0.35)
        o.dy = Learner.clamp(o.dy + rate * (oy - o.dy), 0.35)
        o.n += 1
        data.off[id] = o
    }

    /// 엄지 타입과 판정 영역 비율 (k > 1 이면 세로로 긴 판정)
    func thumb() -> (type: ThumbType, k: Double) {
        let sp = data.spread
        let total = data.dirH + data.dirV
        if sp.n < 30 && total < 20 { return (.unknown, 1) }
        let vx = max(sp.vx, 0.0001), vy = max(sp.vy, 0.0001)
        var score = 0.0, w = 0.0
        if sp.n >= 30 { score += log(vy / vx); w += 1 }
        if total >= 20 { score += log(Double(data.dirV + 1) / Double(data.dirH + 1)); w += 1 }
        score /= w
        let k = sp.n >= 30 ? Learner.clamp(sqrt(vy / vx) - 1, 0.4) + 1 : 1
        let t: ThumbType = score > 0.25 ? .vertical : (score < -0.25 ? .horizontal : .even)
        return (t, k)
    }
}
