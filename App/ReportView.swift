import SwiftUI

/// 내 엄지 리포트 (키보드가 남긴 횟수·키 위치만 보여줌, 친 글은 없음)
struct ReportView: View {
    @State private var english = false
    @State private var toastOn = !ThemeStore.bool("fe.toastOff")
    @State private var r: [String: Any]? = ReportView.load()

    /// 100개마다 올라온 리포트만 씀 (예전 방식 기록은 무시)
    static func load() -> [String: Any]? {
        guard let v = ThemeStore.loadReport(), v["at"] != nil else { return nil }
        return v
    }

    private let koRows = ["ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ", "ㅁㄴㅇㄹㅎㅗㅓㅏㅣ", "ㅋㅌㅊㅍㅠㅜㅡ"]
    private let enRows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]

    var body: some View {
        Form {
            if r == nil {
                Section {
                    Text("첫 리포트를 기다리는 중이에요").font(.custom(ThemeFont.name, size: 18))
                    Text("핑거에러가 오타를 100개 고칠 때마다 리포트가 여기에 올라와요. 올라오면 키보드에서 팻핑이가 알려줄게요.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                Section {
                    let at = r?["at"] as? Int ?? 0
                    Text("📊 오타 \(at)개 리포트 · \(r?["date"] as? String ?? "")").font(.custom(ThemeFont.name, size: 16))
                    Text("다음 리포트는 오타 \(at + 100)개 때 올라와요").font(.footnote).foregroundStyle(.secondary)
                    Picker("", selection: $english) {
                        Text("한글").tag(false)
                        Text("영어").tag(true)
                    }.pickerStyle(.segmented)
                }
                Section(header: header("리포트 직전 7일 동안 고친 오타")) {
                    let w = weekFixes()
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(w.0)개").font(.custom(ThemeFont.name, size: 34))
                        Spacer()
                        Text("그 전 7일 \(w.1)개").foregroundStyle(.secondary)
                    }
                    Text("전체 고친 오타 \(total("fixes"))개 · 전체 타수 \(total("taps"))")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section(header: header("자주 헷갈리는 키")) {
                    let top = topConf()
                    if top.isEmpty {
                        Text("조금 더 써보면 보여요").foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(top.enumerated()), id: \.offset) { _, c in
                            HStack {
                                Text("\(c.0) 치려다 \(c.1)").font(.system(size: 17, weight: .medium))
                                Spacer()
                                Text("\(c.2)번").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section(header: header("내 엄지 지도")) {
                    VStack(spacing: 6) {
                        ForEach(Array((english ? enRows : koRows).enumerated()), id: \.offset) { ri, row in
                            HStack(spacing: 4) {
                                ForEach(Array(row.enumerated()), id: \.offset) { ci, ch in
                                    let pos = Array(koRows[ri])[ci]
                                    VStack(spacing: 0) {
                                        Text(String(ch)).font(.system(size: 13)).foregroundStyle(.secondary)
                                        Text(arrow(String(pos))).font(.system(size: 17, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemBackground)))
                                }
                            }
                            .padding(.horizontal, ri == 1 ? 14 : 0)
                        }
                    }
                    Text("화살표는 그 키를 누를 때 엄지가 대략 쏠리는 쪽이에요.").font(.footnote).foregroundStyle(.secondary)
                }
                Section(header: header("받은 기념일")) {
                    let list = reached()
                    if list.isEmpty {
                        Text("첫 기념일은 오타 22개 (투투)!").foregroundStyle(.secondary)
                    } else {
                        ForEach(list, id: \.self) { Text($0) }
                    }
                }
            }
            Section {
                Toggle("기념일 알림", isOn: $toastOn)
                    .onChange(of: toastOn) { v in ThemeStore.setBool("fe.toastOff", !v) }
            } footer: {
                Text("이 기록은 폰 안에만 있고, 친 글은 저장하지 않아요.")
            }
        }
        .navigationTitle("내 엄지 리포트")
        .onAppear { r = ReportView.load() }
        .refreshable { r = ReportView.load() }
    }

    private func header(_ s: String) -> some View { Text(s).font(.custom(ThemeFont.name, size: 15)) }

    private func total(_ key: String) -> Int {
        let a = r?[key] as? [Int] ?? [0, 0]
        return english ? (a.count > 1 ? a[1] : 0) : (a.first ?? 0)
    }

    private func weekFixes() -> (Int, Int) {
        let daily = r?["daily"] as? [String: [Int]] ?? [:]
        let slot = english ? 3 : 1
        let cal = Calendar(identifier: .gregorian)
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        var thisW = 0, lastW = 0
        let base = (r?["date"] as? String).flatMap { f.date(from: $0) } ?? Date()
        for i in 0..<14 {
            guard let d = cal.date(byAdding: .day, value: -i, to: base) else { continue }
            let v = daily[f.string(from: d)].map { $0.count > slot ? $0[slot] : 0 } ?? 0
            if i < 7 { thisW += v } else { lastW += v }
        }
        return (thisW, lastW)
    }

    /// (치려던 키, 실제 눌린 키, 횟수) 상위 5개
    private func topConf() -> [(String, String, Int)] {
        let conf = r?["conf"] as? [String: Int] ?? [:]
        return conf.compactMap { k, n -> (String, String, Int)? in
            let p = k.components(separatedBy: ">")
            guard p.count == 2, n > 0 else { return nil }
            let isEn = p[0].unicodeScalars.allSatisfy { $0.isASCII }
            guard isEn == english else { return nil }
            return (p[1], p[0], n)
        }.sorted { $0.2 > $1.2 }.prefix(5).map { $0 }
    }

    private func arrow(_ pos: String) -> String {
        let off = r?["off"] as? [String: [Double]] ?? [:]
        guard let o = off[pos], o.count >= 2 else { return "·" }
        let dx = o[0], dy = o[1]
        if hypot(dx, dy) < 0.06 { return "·" }
        let a = atan2(-dy, dx) * 180 / .pi
        let arrows = ["→", "↗", "↑", "↖", "←", "↙", "↓", "↘"]
        let i = Int(((a + 360 + 22.5).truncatingRemainder(dividingBy: 360)) / 45)
        return arrows[i % 8]
    }

    private func reached() -> [String] {
        let list = r?["reached"] as? [String] ?? []
        return list.reversed().map { s in
            let n = Int(s.dropFirst()) ?? 0
            if s.hasPrefix("d") { return n == 365 ? "팻핑이와 만난 지 1년" : "팻핑이와 만난 지 \(n)일" }
            let tag: String = n == 22 ? "투투" : (n == 365 ? "1주년" : (n == 1000 ? "천일" : ""))
            return tag.isEmpty ? "오타 \(n)개" : "오타 \(n)개 (\(tag))"
        }
    }
}
