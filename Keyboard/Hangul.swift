import Foundation

/// 두벌식 자모 → 완성형 한글 조합
enum Hangul {
    static let choList: [String] = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
    static let jungList: [String] = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅘ","ㅙ","ㅚ","ㅛ","ㅜ","ㅝ","ㅞ","ㅟ","ㅠ","ㅡ","ㅢ","ㅣ"]
    static let jongList: [String] = ["","ㄱ","ㄲ","ㄳ","ㄴ","ㄵ","ㄶ","ㄷ","ㄹ","ㄺ","ㄻ","ㄼ","ㄽ","ㄾ","ㄿ","ㅀ","ㅁ","ㅂ","ㅄ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
    static let vComb: [String: String] = ["ㅗㅏ":"ㅘ","ㅗㅐ":"ㅙ","ㅗㅣ":"ㅚ","ㅜㅓ":"ㅝ","ㅜㅔ":"ㅞ","ㅜㅣ":"ㅟ","ㅡㅣ":"ㅢ"]
    static let jComb: [String: String] = ["ㄱㅅ":"ㄳ","ㄴㅈ":"ㄵ","ㄴㅎ":"ㄶ","ㄹㄱ":"ㄺ","ㄹㅁ":"ㄻ","ㄹㅂ":"ㄼ","ㄹㅅ":"ㄽ","ㄹㅌ":"ㄾ","ㄹㅍ":"ㄿ","ㄹㅎ":"ㅀ","ㅂㅅ":"ㅄ"]
    static let vSplit: [String: [String]] = Dictionary(uniqueKeysWithValues: vComb.map { ($0.value, $0.key.map { String($0) }) })
    static let jSplit: [String: [String]] = Dictionary(uniqueKeysWithValues: jComb.map { ($0.value, $0.key.map { String($0) }) })
    static let simpleVowels: Set<String> = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅛ","ㅜ","ㅠ","ㅡ","ㅣ"]
    static let shiftMap: [String: String] = ["ㅂ":"ㅃ","ㅈ":"ㅉ","ㄷ":"ㄸ","ㄱ":"ㄲ","ㅅ":"ㅆ","ㅐ":"ㅒ","ㅔ":"ㅖ"]

    static func isConsonant(_ s: String) -> Bool { choList.contains(s) }
    static func isVowel(_ s: String) -> Bool { simpleVowels.contains(s) }

    static func assemble(_ tokens: [String]) -> String {
        var out = ""
        var cho: String? = nil
        var jung: String? = nil
        var jong: String? = nil

        func flush() {
            if let c = cho, let v = jung,
               let ci = choList.firstIndex(of: c), let vi = jungList.firstIndex(of: v) {
                let ji = jongList.firstIndex(of: jong ?? "") ?? 0
                if let scalar = Unicode.Scalar(UInt32(0xAC00 + (ci * 21 + vi) * 28 + ji)) {
                    out.unicodeScalars.append(scalar)
                }
            } else {
                if let c = cho { out += c }
                if let v = jung { out += v }
            }
            cho = nil; jung = nil; jong = nil
        }

        for t in tokens {
            if isConsonant(t) {
                if cho == nil && jung == nil {
                    cho = t
                } else if cho != nil && jung == nil {
                    flush(); cho = t
                } else if jung != nil && jong == nil {
                    if cho != nil && jongList.contains(t) { jong = t } else { flush(); cho = t }
                } else if let j = jong {
                    if let c = jComb[j + t] { jong = c } else { flush(); cho = t }
                } else {
                    flush(); cho = t
                }
            } else if isVowel(t) {
                if let j = jong {
                    var move = j
                    if let parts = jSplit[j] { jong = parts[0]; move = parts[1] } else { jong = nil }
                    flush(); cho = move; jung = t
                } else if let v = jung {
                    if let c = vComb[v + t] { jung = c } else { flush(); jung = t }
                } else {
                    jung = t
                }
            } else {
                flush(); out += t
            }
        }
        flush()
        return out
    }

    /// 완성형 한 글자를 자모로 분해 (지우기를 자모 단위로 하기 위해)
    static func decompose(_ ch: Character) -> [String]? {
        guard ch.unicodeScalars.count == 1, let s = ch.unicodeScalars.first else { return nil }
        let v = Int(s.value)
        if v >= 0xAC00 && v <= 0xD7A3 {
            let idx = v - 0xAC00
            let ci = idx / (21 * 28), vi = (idx % (21 * 28)) / 28, ji = idx % 28
            var r = [choList[ci]]
            r += vSplit[jungList[vi]] ?? [jungList[vi]]
            if ji > 0 { r += jSplit[jongList[ji]] ?? [jongList[ji]] }
            return r
        }
        let str = String(ch)
        if isConsonant(str) || isVowel(str) { return [str] }
        if let parts = vSplit[str] { return parts }
        return nil
    }
}
