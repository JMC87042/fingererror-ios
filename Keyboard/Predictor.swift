import Foundation

/// 예측 단어 (키보드 위 후보 3칸).
/// 인터넷 없이 폰 안에서만: 기본 단어장 + 내가 쓴 말을 배워서 자주 쓰는 순으로 추천.
/// - 쓰는 중인 단어: 자모 단위로 앞부분이 맞는 단어 ("안녕핫" → 안녕하세요)
/// - 아무것도 안 쓴 때: 앞 단어 다음에 자주 쓴 단어 ("감사" 다음 → 합니다)
final class Predictor {
    private var uni: [String: Int] = [:]
    private var bi: [String: [String: Int]] = [:]
    private var seed: [String] = []
    private var seedSet = Set<String>()
    private var dirty = false
    private var jamoCache: [String: String] = [:]

    private var file: URL? {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("predict.txt")
    }

    init() {
        if let u = Bundle.main.url(forResource: "words_ko", withExtension: "txt"),
           let s = try? String(contentsOf: u, encoding: .utf8) {
            for w in s.split(whereSeparator: { $0.isWhitespace }) where !seedSet.contains(String(w)) {
                seed.append(String(w)); seedSet.insert(String(w))
            }
        }
        load()
    }

    private func load() {
        guard let f = file, let s = try? String(contentsOf: f, encoding: .utf8) else { return }
        for line in s.split(separator: "\n") {
            let p = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            if p.count == 2 { uni[p[0]] = Int(p[1]) ?? 1 }
            else if p.count == 3 { bi[p[0], default: [:]][p[1]] = Int(p[2]) ?? 1 }
        }
    }

    func save() {
        guard dirty, let f = file else { return }
        var out = ""
        // 너무 커지지 않게: 자주 쓴 단어 3000개, 이어지는 말 4000개까지만
        for (w, n) in uni.sorted(by: { $0.value > $1.value }).prefix(3000) { out += "\(w)\t\(n)\n" }
        var pairs: [(String, String, Int)] = []
        for (a, m) in bi { for (b, n) in m { pairs.append((a, b, n)) } }
        for (a, b, n) in pairs.sorted(by: { $0.2 > $1.2 }).prefix(4000) { out += "\(a)\t\(b)\t\(n)\n" }
        try? out.write(to: f, atomically: true, encoding: .utf8)
        dirty = false
    }

    func clear() { uni.removeAll(); bi.removeAll(); dirty = true; save() }

    /// 단어 하나를 다 쓰고 띄었을 때 배우기
    func learn(_ prev: String?, _ word: String) {
        guard let w = clean(word) else { return }
        uni[w, default: 0] += 1
        if let p = clean(prev) { bi[p, default: [:]][w, default: 0] += 1 }
        dirty = true
    }

    /// 후보 단어를 지우기 (후보를 꾹 누르면)
    func forget(_ word: String) {
        uni[word] = nil
        for k in bi.keys { bi[k]?[word] = nil }
        if seedSet.remove(word) != nil { seed.removeAll { $0 == word } }
        dirty = true
    }

    /// 후보 3개
    func suggest(_ prev: String?, _ cur: String) -> [String] {
        if cur.isEmpty {
            guard let p = clean(prev), let m = bi[p] else { return [] }
            return Array(m.sorted(by: { $0.value > $1.value }).prefix(3).map { $0.key })
        }
        let cj = jamo(cur)
        var scored: [String: Int] = [:]
        for (w, n) in uni where w != cur && w.count >= cur.count && jamo(w).hasPrefix(cj) { scored[w] = n * 10 }
        if let p = clean(prev), let m = bi[p] {
            for (w, n) in m where w != cur && jamo(w).hasPrefix(cj) { scored[w, default: 0] += n * 30 }
        }
        for w in seed where w != cur && w.count >= cur.count && jamo(w).hasPrefix(cj) { scored[w, default: 0] += 1 }
        return Array(scored.sorted { a, b in a.value != b.value ? a.value > b.value : a.key.count < b.key.count }.prefix(3).map { $0.key })
    }

    private func clean(_ w: String?) -> String? {
        guard var t = w?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        while let l = t.last, ".,!?~)\"'".contains(l) { t.removeLast() }
        if t.isEmpty || t.count > 20 || t.contains(where: { $0.isNumber }) || t.contains("http") { return nil }
        return t
    }

    private static let CHO = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
    private static let JUNG = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅗㅏ","ㅗㅐ","ㅗㅣ","ㅛ","ㅜ","ㅜㅓ","ㅜㅔ","ㅜㅣ","ㅠ","ㅡ","ㅡㅣ","ㅣ"]
    private static let JONG = ["","ㄱ","ㄲ","ㄱㅅ","ㄴ","ㄴㅈ","ㄴㅎ","ㄷ","ㄹ","ㄹㄱ","ㄹㅁ","ㄹㅂ","ㄹㅅ","ㄹㅌ","ㄹㅍ","ㄹㅎ","ㅁ","ㅂ","ㅂㅅ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
    private static let SPLIT: [String: String] = ["ㄳ":"ㄱㅅ","ㄵ":"ㄴㅈ","ㄶ":"ㄴㅎ","ㄺ":"ㄹㄱ","ㄻ":"ㄹㅁ","ㄼ":"ㄹㅂ","ㄽ":"ㄹㅅ","ㄾ":"ㄹㅌ","ㄿ":"ㄹㅍ","ㅀ":"ㄹㅎ","ㅄ":"ㅂㅅ",
        "ㅘ":"ㅗㅏ","ㅙ":"ㅗㅐ","ㅚ":"ㅗㅣ","ㅝ":"ㅜㅓ","ㅞ":"ㅜㅔ","ㅟ":"ㅜㅣ","ㅢ":"ㅡㅣ"]

    /// 한글을 자모로 풀기 (겹받침·겹모음도 낱자로) — 쓰는 중인 글자도 앞부분 비교가 되게
    func jamo(_ s: String) -> String {
        if let c = jamoCache[s] { return c }
        var out = ""
        for u in s.unicodeScalars {
            let v = Int(u.value)
            if v >= 0xAC00 && v <= 0xD7A3 {
                let i = v - 0xAC00
                out += Predictor.CHO[i / 588] + Predictor.JUNG[(i % 588) / 28] + Predictor.JONG[i % 28]
            } else {
                let t = String(u)
                out += Predictor.SPLIT[t] ?? t.lowercased()
            }
        }
        if jamoCache.count > 6000 { jamoCache.removeAll() }
        jamoCache[s] = out
        return out
    }
}
