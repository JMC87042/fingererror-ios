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
