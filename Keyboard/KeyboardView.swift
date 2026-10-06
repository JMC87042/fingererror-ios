import UIKit

enum Palette {
    static let key = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.42, alpha: 1) : UIColor.white }
    static let special = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.27, alpha: 1) : UIColor(red: 0.67, green: 0.70, blue: 0.74, alpha: 1) }
    static let board = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.87, alpha: 1) }
}

final class KeyCap: UIView {
    let label = UILabel()
    let icon = UIImageView()
    var isSpecial = false { didSet { refreshColor() } }
    var isDown = false { didSet { refreshColor() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.cornerRadius = 6
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0
        label.textAlignment = .center
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        addSubview(label)
        icon.contentMode = .scaleAspectFit
        icon.isHidden = true
        addSubview(icon)
        refreshColor()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.insetBy(dx: 2, dy: 0)
        let s = bounds.height * 0.72
        icon.frame = CGRect(x: bounds.midX - s / 2, y: bounds.midY - s / 2, width: s, height: s)
    }

    func refreshColor() {
        let normal = isSpecial ? Palette.special : Palette.key
        let down = isSpecial ? Palette.key : Palette.special
        backgroundColor = isDown ? down : normal
    }
}

@MainActor
protocol KeyboardViewDelegate: AnyObject {
    func keyPressed(_ id: String, at p: CGPoint, raw: String)
    func keyReleased(_ id: String)
}

final class KeyboardView: UIView {
    enum Page { case hangul, number }

    struct Key {
        let id: String
        let isLetter: Bool
        let row: Int
        let cap: KeyCap
        var frame: CGRect = .zero
    }

    private struct Spec {
        let id: String
        let weight: CGFloat
        let fill: Bool
    }

    weak var delegate: KeyboardViewDelegate?
    weak var learner: Learner?

    var page: Page = .hangul { didSet { rebuild() } }
    var shift = false { didSet { refreshLabels() } }
    var showGlobe = true { didSet { if oldValue != showGlobe { rebuild() } } }

    private(set) var keys: [Key] = []
    private var specRows: [[Spec]] = []
    private struct Pending {
        let index: Int
        let id: String
        let point: CGPoint
        let raw: String
        let immediate: Bool
    }
    private var pressed: [ObjectIdentifier: Pending] = [:]
    /// 누르는 순간 바로 처리하는 키 (나머지는 손 뗄 때 입력: 아이폰 기본 키보드와 같은 순서)
    private static let immediateKeys: Set<String> = ["BACK", "SHIFT", "MODE", "GLOBE"]

    private let gap: CGFloat = 6
    private let vgap: CGFloat = 11
    private let side: CGFloat = 3
    private let topPad: CGFloat = 8
    private let bottomPad: CGFloat = 4
    private static let specials: Set<String> = ["SHIFT", "BACK", "MODE", "GLOBE", "RETURN"]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = Palette.board
        rebuild()
    }

    private func rows() -> [[Spec]] {
        func letters(_ s: String) -> [Spec] { s.map { Spec(id: String($0), weight: 1, fill: false) } }
        var bottom: [Spec] = [Spec(id: "MODE", weight: 1.3, fill: false)]
        if showGlobe { bottom.append(Spec(id: "GLOBE", weight: 1.3, fill: false)) }
        bottom += [Spec(id: "SPACE", weight: 1, fill: true),
                   Spec(id: ".", weight: 1, fill: false),
                   Spec(id: "RETURN", weight: 2, fill: false)]
        switch page {
        case .hangul:
            return [letters("ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ"),
                    letters("ㅁㄴㅇㄹㅎㅗㅓㅏㅣ"),
                    [Spec(id: "SHIFT", weight: 1, fill: true)] + letters("ㅋㅌㅊㅍㅠㅜㅡ") + [Spec(id: "BACK", weight: 1, fill: true)],
                    bottom]
        case .number:
            return [letters("1234567890"),
                    letters("-/:;()₩&@\""),
                    letters("=,?!'~%") + [Spec(id: "BACK", weight: 1, fill: true)],
                    bottom]
        }
    }

    func rebuild() {
        keys.forEach { $0.cap.removeFromSuperview() }
        keys = []
        let r = rows()
        specRows = r
        for (ri, row) in r.enumerated() {
            for s in row {
                let cap = KeyCap()
                cap.isSpecial = KeyboardView.specials.contains(s.id)
                let letter = page == .hangul && (Hangul.isConsonant(s.id) || Hangul.isVowel(s.id))
                addSubview(cap)
                keys.append(Key(id: s.id, isLetter: letter, row: ri, cap: cap))
            }
        }
        refreshLabels()
        setNeedsLayout()
    }

    private func label(for id: String) -> String {
        switch id {
        case "SHIFT": return "⇧"
        case "BACK": return "⌫"
        case "SPACE": return ""
        case "RETURN": return "⏎"
        case "GLOBE": return "🌐"
        case "MODE": return page == .hangul ? "123" : "가"
        default: return shift ? (Hangul.shiftMap[id] ?? id) : id
        }
    }

    func refreshLabels() {
        for k in keys {
            k.cap.label.text = label(for: k.id)
            let big = k.id.count == 1 || k.id == "SHIFT" || k.id == "BACK" || k.id == "RETURN"
            k.cap.label.font = .systemFont(ofSize: big ? 22 : 16)
            if k.id == "SHIFT" { k.cap.isSpecial = !shift }
            // 핑거에러 표시: 스페이스바에 분홍 로고
            if k.id == "SPACE" {
                // 스페이스바에 엄지 로고
                k.cap.icon.image = UIImage(named: "space_logo", in: Bundle(for: KeyCap.self), compatibleWith: nil)
                k.cap.icon.isHidden = false
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !specRows.isEmpty else { return }
        let W = bounds.width - side * 2
        let u = (W - 9 * gap) / 10
        let n = CGFloat(specRows.count)
        let rowH = max(30, (bounds.height - topPad - bottomPad - vgap * (n - 1)) / n)
        var idx = 0
        for (ri, row) in specRows.enumerated() {
            let fixed = row.filter { !$0.fill }.reduce(CGFloat(0)) { $0 + $1.weight * u }
            let fills = CGFloat(row.filter { $0.fill }.count)
            let gaps = gap * CGFloat(row.count - 1)
            let fillW = fills > 0 ? max(u, (W - fixed - gaps) / fills) : 0
            let total = fixed + fills * fillW + gaps
            var x = side + max(0, (W - total) / 2)
            let y = topPad + CGFloat(ri) * (rowH + vgap)
            for s in row where idx < keys.count {
                let w = s.fill ? fillW : s.weight * u
                let f = CGRect(x: x, y: y, width: w, height: rowH)
                keys[idx].frame = f
                keys[idx].cap.frame = f
                x += w + gap
                idx += 1
            }
        }
    }

    func frameOf(_ id: String) -> CGRect? { keys.first(where: { $0.id == id && $0.isLetter })?.frame }
    func rowOf(_ id: String) -> Int? { keys.first(where: { $0.id == id })?.row }

    /// 터치 위치 → (입력할 키 번호, 손가락 바로 아래 키)
    private func pick(_ p: CGPoint) -> (Int, String)? {
        for (i, k) in keys.enumerated() where !k.isLetter {
            if k.frame.insetBy(dx: -gap / 2, dy: -vgap / 2).contains(p) { return (i, k.id) }
        }
        let letterIdx = keys.indices.filter { keys[$0].isLetter }
        let pool = letterIdx.isEmpty ? Array(keys.indices) : letterIdx

        func dist(_ i: Int, _ dx: CGFloat, _ dy: CGFloat, _ sq: CGFloat) -> CGFloat {
            let f = keys[i].frame
            guard f.width > 0, f.height > 0 else { return .greatestFiniteMagnitude }
            let ex = (p.x - (f.midX + dx * f.width)) / f.width
            let ey = (p.y - (f.midY + dy * f.height)) / f.height
            return hypot(ex * sq, ey / sq)
        }

        guard let rawI = pool.min(by: { dist($0, 0, 0, 1) < dist($1, 0, 0, 1) }) else { return nil }
        let raw = keys[rawI].id
        guard page == .hangul, !letterIdx.isEmpty, let lr = learner, lr.data.fixOn else { return (rawI, raw) }

        // 내 엄지 쏠림 + 흔들림 방향으로 판정
        let t = lr.thumb()
        let sq = CGFloat(sqrt(t.k))
        let scored = letterIdx.map { i -> (Int, CGFloat) in
            let o = lr.data.off[keys[i].id] ?? KeyOffset()
            return (i, dist(i, CGFloat(o.dx), CGFloat(o.dy), sq))
        }.sorted { $0.1 < $1.1 }
        var chosen = scored[0].0
        if scored.count > 1, scored[1].1 / max(scored[0].1, 0.01) < 1.25 {
            let a = keys[scored[0].0], b = keys[scored[1].0]
            let lean = (lr.data.conf["\(a.id)>\(b.id)"] ?? 0) - (lr.data.conf["\(b.id)>\(a.id)"] ?? 0)
            let vertical = a.row != b.row
            let need = ((vertical && t.type == .vertical) || (!vertical && t.type == .horizontal)) ? 2 : 3
            if lean >= need { chosen = scored[1].0 }
        }
        return (chosen, raw)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)
            guard let r = pick(p) else { continue }
            let i = r.0
            let id = keys[i].id
            let norm = CGPoint(x: p.x / max(bounds.width, 1), y: p.y / max(bounds.height, 1))
            let immediate = KeyboardView.immediateKeys.contains(id)
            pressed[ObjectIdentifier(t)] = Pending(index: i, id: id, point: norm, raw: r.1, immediate: immediate)
            keys[i].cap.isDown = true
            if immediate { delegate?.keyPressed(id, at: norm, raw: r.1) }
        }
    }

    private func end(_ touches: Set<UITouch>) {
        for t in touches {
            guard let pd = pressed.removeValue(forKey: ObjectIdentifier(t)) else { continue }
            if !pd.immediate { delegate?.keyPressed(pd.id, at: pd.point, raw: pd.raw) }
            if pd.index < keys.count { keys[pd.index].cap.isDown = false }
            delegate?.keyReleased(pd.id)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }
}
