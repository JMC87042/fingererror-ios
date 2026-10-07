import UIKit

final class KeyCap: UIView {
    /// 키 윗면 (글자·로고). KeyCap 자체 크기 = 누르는 판정 영역 → 테마가 바뀌어도 그대로
    let face = UIView()
    let label = UILabel()
    let icon = UIImageView()
    let gloss = UIView()
    /// 계절 스티커 (키 모서리에 살짝 걸침, 누르는 영역과 무관)
    let sticker = UIImageView()
    var stickerPos: CGPoint? = nil { didSet { setNeedsLayout() } }
    /// 키 모서리 곳곳의 작은 잎 (가을 테마)
    let sprinkle = UIImageView()
    var sprinklePos: CGPoint? = nil { didSet { setNeedsLayout() } }
    var iconScale: CGFloat = 0.72 { didSet { setNeedsLayout() } }
    var isSpecial = false { didSet { refreshColor() } }
    var isDown = false { didSet { refreshColor(); setNeedsLayout() } }
    var isAccent = false { didSet { refreshColor() } }
    var theme: KBTheme = .standard { didSet { refreshColor(); setNeedsLayout() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        face.isUserInteractionEnabled = false
        face.layer.shadowColor = UIColor.black.cgColor
        face.layer.shadowOffset = CGSize(width: 0, height: 1)
        face.layer.shadowRadius = 0
        addSubview(face)
        gloss.isUserInteractionEnabled = false
        gloss.backgroundColor = UIColor(white: 1, alpha: 0.35)
        gloss.isHidden = true
        face.addSubview(gloss)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        face.addSubview(label)
        icon.contentMode = .scaleAspectFit
        icon.isHidden = true
        face.addSubview(icon)
        sticker.contentMode = .scaleAspectFit
        sticker.isHidden = true
        addSubview(sticker)
        sprinkle.contentMode = .scaleAspectFit
        sprinkle.isHidden = true
        addSubview(sprinkle)
        refreshColor()
    }

    static func image(_ name: String) -> UIImage? {
        UIImage(named: name, in: Bundle(for: KeyCap.self), compatibleWith: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        var f = bounds
        let d = theme.depth
        if d > 0 {
            f.size.height -= d
            if isDown { f.origin.y += d * 0.6 }
        }
        face.frame = f
        face.layer.cornerRadius = theme.radius
        layer.cornerRadius = theme.radius
        label.frame = face.bounds.insetBy(dx: 2, dy: 0)
        let s = face.bounds.height * iconScale
        icon.frame = CGRect(x: face.bounds.midX - s / 2, y: face.bounds.midY - s / 2, width: s, height: s)
        let fb = face.bounds
        gloss.frame = CGRect(x: fb.width * 0.12, y: fb.height * 0.08, width: fb.width * 0.76, height: fb.height * 0.22)
        gloss.layer.cornerRadius = min(theme.radius * 0.7, gloss.frame.height / 2)
        if let p = stickerPos {
            let ss: CGFloat = 15
            sticker.frame = CGRect(x: bounds.width * p.x - ss / 2, y: bounds.height * p.y - ss / 2, width: ss, height: ss)
        }
        if let p = sprinklePos {
            let ss: CGFloat = 11
            sprinkle.frame = CGRect(x: bounds.width * p.x - ss / 2, y: bounds.height * p.y - ss / 2, width: ss, height: ss)
        }
    }

    func refreshColor() {
        let t = theme
        if isAccent, let a = t.accent {
            face.backgroundColor = a
        } else if isDown {
            face.backgroundColor = isSpecial ? t.pressSpecial : t.pressKey
        } else {
            face.backgroundColor = isSpecial ? t.special : t.key
        }
        if t.depth > 0 {
            backgroundColor = (isSpecial || isAccent) ? (t.sideSpecial ?? t.special) : (t.side ?? t.key)
        } else {
            backgroundColor = .clear
        }
        face.layer.borderWidth = t.rim == nil ? 0 : 1
        face.layer.borderColor = t.rim?.cgColor
        face.layer.shadowOpacity = t.shadow ? (t.shadowColor == nil ? 0.3 : 0.45) : 0
        face.layer.shadowColor = (t.shadowColor ?? .black).cgColor
        face.layer.shadowRadius = t.shadowColor == nil ? 0 : 2.5
        face.layer.shadowOffset = CGSize(width: 0, height: t.shadowColor == nil ? 1 : 2.5)
        gloss.isHidden = !t.gloss || isDown
        label.textColor = isAccent ? UIColor(white: 1, alpha: 0.98) : (isSpecial ? t.specialText : t.text)
    }
}

@MainActor
protocol KeyboardViewDelegate: AnyObject {
    func keyPressed(_ id: String, at p: CGPoint, raw: String)
    func keyReleased(_ id: String)
}

final class KeyboardView: UIView {
    enum Page { case hangul, number, symbol }

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
    private(set) var theme: KBTheme = .standard

    private let bgView = UIImageView()

    func applyTheme(_ t: KBTheme) {
        theme = t
        backgroundColor = t.bg
        bgView.image = t.bgImage.flatMap { KeyCap.image($0) }
        bgView.isHidden = bgView.image == nil
        for k in keys {
            k.cap.theme = t
            k.cap.isAccent = k.id == "RETURN" && t.accent != nil
        }
        refreshLabels()
    }
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
    private static let immediateKeys: Set<String> = ["BACK", "SHIFT", "MODE", "GLOBE", "SYM"]

    private let gap: CGFloat = 6
    private let vgap: CGFloat = 11
    private let side: CGFloat = 3
    private let topPad: CGFloat = 8
    private let bottomPad: CGFloat = 4
    private static let specials: Set<String> = ["SHIFT", "BACK", "MODE", "GLOBE", "RETURN", "SYM"]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = theme.bg
        bgView.contentMode = .scaleAspectFill
        bgView.clipsToBounds = true
        bgView.isHidden = true
        bgView.isUserInteractionEnabled = false
        addSubview(bgView)
        rebuild()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func rows() -> [[Spec]] {
        func letters(_ s: String) -> [Spec] { s.map { Spec(id: String($0), weight: 1, fill: false) } }
        // 아이폰 기본 한국어 키보드와 같은 배열 (글자 키 위치·크기는 그대로)
        var bottom: [Spec] = [Spec(id: "MODE", weight: 1.3, fill: false)]
        if showGlobe { bottom.append(Spec(id: "GLOBE", weight: 1.3, fill: false)) }
        bottom += [Spec(id: "SPACE", weight: 1, fill: true),
                   Spec(id: "RETURN", weight: 2.4, fill: false)]
        func wide(_ s: String) -> [Spec] { s.map { Spec(id: String($0), weight: 1.4, fill: false) } }
        let punct = [Spec(id: "SYM", weight: 1, fill: true)] + wide(".,?!'") + [Spec(id: "BACK", weight: 1, fill: true)]
        switch page {
        case .hangul:
            return [letters("ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ"),
                    letters("ㅁㄴㅇㄹㅎㅗㅓㅏㅣ"),
                    [Spec(id: "SHIFT", weight: 1, fill: true)] + letters("ㅋㅌㅊㅍㅠㅜㅡ") + [Spec(id: "BACK", weight: 1, fill: true)],
                    bottom]
        case .number:
            return [letters("1234567890"),
                    letters("-/:;()₩&@\""),
                    punct,
                    bottom]
        case .symbol:
            return [letters("[]{}#%^*+="),
                    letters("_\\|~<>$£¥•"),
                    punct,
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
                cap.theme = theme
                cap.isAccent = s.id == "RETURN" && theme.accent != nil
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
        case "SYM": return page == .symbol ? "123" : "#+="
        default: return shift ? (Hangul.shiftMap[id] ?? id) : id
        }
    }

    /// 작은 잎이 앉는 자리: 키 → (가로 비율, 세로 비율, 그림 번호). 글자는 안 가림
    static let sprinkleSpots: [String: (CGFloat, CGFloat, Int)] = [
        "ㅈ": (0.86, 0.84, 0), "ㄱ": (0.14, 0.16, 1), "ㅛ": (0.86, 0.16, 2), "ㅑ": (0.14, 0.84, 0), "ㅐ": (0.86, 0.84, 1),
        "ㄴ": (0.86, 0.16, 2), "ㄹ": (0.14, 0.84, 0), "ㅗ": (0.86, 0.84, 1), "ㅏ": (0.14, 0.16, 2), "ㅋ": (0.14, 0.84, 1),
        "ㅊ": (0.86, 0.16, 0), "ㅠ": (0.14, 0.16, 2), "ㅡ": (0.86, 0.84, 0), "ㅇ": (0.14, 0.84, 2)]

    func refreshLabels() {
        for k in keys {
            k.cap.label.text = label(for: k.id)
            let big = k.id.count == 1 || k.id == "SHIFT" || k.id == "BACK" || k.id == "RETURN"
            k.cap.label.font = .systemFont(ofSize: big ? 22 : 16)
            if k.id == "SHIFT" { k.cap.isSpecial = !shift }
            // 핑거에러 표시: 스페이스바에 분홍 로고
            if k.id == "RETURN" {
                if let n = theme.enterIcon, let img = KeyCap.image(n) {
                    k.cap.label.text = ""
                    k.cap.icon.image = img
                    k.cap.icon.isHidden = false
                } else {
                    k.cap.icon.isHidden = true
                }
            }
            // 계절 스티커 자리
            let spots: [String: CGPoint] = ["ㅂ": CGPoint(x: 0.08, y: 0.12), "ㅔ": CGPoint(x: 0.92, y: 0.12),
                                            "SHIFT": CGPoint(x: 0.10, y: 0.15), "BACK": CGPoint(x: 0.90, y: 0.15),
                                            "SPACE": CGPoint(x: 0.96, y: 0.20)]
            if let n = theme.sticker, let p = spots[k.id], let img = KeyCap.image(n) {
                k.cap.sticker.image = img
                k.cap.sticker.isHidden = false
                k.cap.stickerPos = p
            } else {
                k.cap.sticker.isHidden = true
            }
            if k.id == "SPACE" {
                // 스페이스바에 팻핑이 (테마에 따라 밤 모자 등)
                let custom = theme.spaceIcon.flatMap { KeyCap.image($0) }
                k.cap.icon.image = custom ?? KeyCap.image("space_logo")
                k.cap.iconScale = custom == nil ? 0.72 : 0.86
                k.cap.icon.isHidden = false
            }
            if let pre = theme.sprinkle, let sp = KeyboardView.sprinkleSpots[k.id], let img = KeyCap.image(pre + String(sp.2)) {
                k.cap.sprinkle.image = img
                k.cap.sprinkle.isHidden = false
                k.cap.sprinklePos = CGPoint(x: sp.0, y: sp.1)
            } else {
                k.cap.sprinkle.isHidden = true
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.frame = bounds
        sendSubviewToBack(bgView)
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

    // MARK: - 팻핑이 꾹 누르기 → 테마 메뉴

    private let menu = ThemeMenuView()
    private var holdTouch: ObjectIdentifier?
    private var holdStart: CGPoint = .zero
    private var menuTouch: ObjectIdentifier?
    var menuOpen: Bool { menu.superview != nil }

    private func startHold(_ t: UITouch, at p: CGPoint) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(openMenuFromHold), object: nil)
        holdTouch = ObjectIdentifier(t)
        holdStart = p
        perform(#selector(openMenuFromHold), with: nil, afterDelay: 0.6)
    }

    private func cancelHold() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(openMenuFromHold), object: nil)
        holdTouch = nil
    }

    @objc private func openMenuFromHold() {
        guard let oid = holdTouch, let pd = pressed.removeValue(forKey: oid) else { cancelHold(); return }
        // 꾹 누른 스페이스는 띄어쓰기로 넣지 않음 (학습에도 안 들어감)
        if pd.index < keys.count { keys[pd.index].cap.isDown = false }
        holdTouch = nil
        menuTouch = oid
        let space = keys.first(where: { $0.id == "SPACE" })?.frame ?? CGRect(x: 0, y: bounds.height - 50, width: bounds.width, height: 46)
        menu.frame = bounds
        menu.show(current: theme.id, above: space)
        addSubview(menu)
    }

    func closeMenu() {
        menu.removeFromSuperview()
        menuTouch = nil
    }

    private func choose(_ id: String) {
        ThemeStore.save(id)
        applyTheme(KBTheme.find(id))
        closeMenu()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)
            if menuOpen {
                // 메뉴가 떠 있는 동안의 터치는 글자 입력·학습과 무관
                if menu.panelFrame.contains(p) {
                    menuTouch = ObjectIdentifier(t)
                    menu.highlight(menu.item(at: p))
                } else {
                    closeMenu()
                }
                continue
            }
            guard let r = pick(p) else { continue }
            let i = r.0
            let id = keys[i].id
            let norm = CGPoint(x: p.x / max(bounds.width, 1), y: p.y / max(bounds.height, 1))
            let immediate = KeyboardView.immediateKeys.contains(id)
            pressed[ObjectIdentifier(t)] = Pending(index: i, id: id, point: norm, raw: r.1, immediate: immediate)
            keys[i].cap.isDown = true
            if id == "SPACE" { startHold(t, at: p) }
            if immediate { delegate?.keyPressed(id, at: norm, raw: r.1) }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let oid = ObjectIdentifier(t)
            let p = t.location(in: self)
            if oid == menuTouch {
                menu.highlight(menu.item(at: p))
            } else if oid == holdTouch, hypot(p.x - holdStart.x, p.y - holdStart.y) > 12 {
                // 밀면 메뉴 대신 (나중에) 커서 이동용으로 남겨둠
                cancelHold()
            }
        }
    }

    private func end(_ touches: Set<UITouch>) {
        for t in touches {
            let oid = ObjectIdentifier(t)
            if oid == menuTouch {
                menuTouch = nil
                if let id = menu.item(at: t.location(in: self)) { choose(id) } else { menu.highlight(nil) }
                continue
            }
            if oid == holdTouch { cancelHold() }
            guard let pd = pressed.removeValue(forKey: oid) else { continue }
            if !pd.immediate { delegate?.keyPressed(pd.id, at: pd.point, raw: pd.raw) }
            if pd.index < keys.count { keys[pd.index].cap.isDown = false }
            delegate?.keyReleased(pd.id)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }
}

/// 팻핑이를 꾹 누르면 위로 펼쳐지는 테마 고르기 메뉴 (키 위치·크기는 그대로, 잠깐 덮기만 함)
final class ThemeMenuView: UIView {
    private let dim = UIView()
    private let panel = UIView()
    private let tail = UIView()
    private let header = UILabel()
    private var chips: [(id: String, box: UIView, img: UIImageView, name: UILabel)] = []
    private var current = ""
    private var hot: String?
    var panelFrame: CGRect { panel.frame }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false   // 터치는 키보드 화면이 직접 처리
        dim.backgroundColor = UIColor(white: 0, alpha: 0.35)
        addSubview(dim)
        panel.backgroundColor = UIColor(red: 250 / 255, green: 250 / 255, blue: 252 / 255, alpha: 1)
        panel.layer.cornerRadius = 16
        panel.layer.shadowColor = UIColor.black.cgColor
        panel.layer.shadowOpacity = 0.25
        panel.layer.shadowRadius = 8
        panel.layer.shadowOffset = CGSize(width: 0, height: 3)
        tail.backgroundColor = panel.backgroundColor
        tail.transform = CGAffineTransform(rotationAngle: .pi / 4)
        addSubview(tail)
        addSubview(panel)
        header.text = "테마 바꾸기"
        header.font = ThemeFont.ui(16)
        header.textColor = UIColor(red: 30 / 255, green: 32 / 255, blue: 40 / 255, alpha: 1)
        panel.addSubview(header)
        for t in KBTheme.all {
            let box = UIView()
            box.layer.cornerRadius = 7
            box.layer.borderWidth = 0
            let img = UIImageView(image: KeyCap.image("kprev_" + t.id))
            img.contentMode = .scaleAspectFill
            img.clipsToBounds = true
            img.layer.cornerRadius = 6
            let name = UILabel()
            name.text = t.menuName
            name.font = ThemeFont.ui(11)
            name.textAlignment = .center
            name.adjustsFontSizeToFitWidth = true
            name.minimumScaleFactor = 0.7
            name.textColor = UIColor(red: 60 / 255, green: 62 / 255, blue: 70 / 255, alpha: 1)
            box.addSubview(img)
            panel.addSubview(box)
            panel.addSubview(name)
            chips.append((t.id, box, img, name))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(current: String, above space: CGRect) {
        self.current = current
        hot = nil
        dim.frame = bounds
        let top: CGFloat = 6
        let bottom = space.minY - 6
        panel.frame = CGRect(x: 8, y: top, width: bounds.width - 16, height: max(120, bottom - top))
        tail.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        tail.center = CGPoint(x: space.midX, y: panel.frame.maxY)
        let pad: CGFloat = 10
        header.frame = CGRect(x: pad + 2, y: 6, width: panel.bounds.width - pad * 2, height: 22)
        let cols = 5
        let g: CGFloat = 6
        let cw = (panel.bounds.width - pad * 2 - g * CGFloat(cols - 1)) / CGFloat(cols)
        let rowsTop: CGFloat = 32
        let rowH = (panel.bounds.height - rowsTop - 6) / 2
        let ih = min(cw * 0.6, rowH - 18)
        for (i, c) in chips.enumerated() {
            let x = pad + CGFloat(i % cols) * (cw + g)
            let y = rowsTop + CGFloat(i / cols) * rowH
            c.box.frame = CGRect(x: x - 2, y: y - 2, width: cw + 4, height: ih + 4)
            c.img.frame = CGRect(x: 2, y: 2, width: cw, height: ih)
            c.name.frame = CGRect(x: x - 2, y: y + ih + 3, width: cw + 4, height: 14)
        }
        refresh()
    }

    /// 손가락 위치 → 테마 id
    func item(at p: CGPoint) -> String? {
        let q = convert(p, to: panel)
        for c in chips where c.box.frame.union(c.name.frame).insetBy(dx: -3, dy: -3).contains(q) { return c.id }
        return nil
    }

    func highlight(_ id: String?) {
        hot = id
        refresh()
    }

    private func refresh() {
        for c in chips {
            if c.id == hot {
                c.box.layer.borderWidth = 2.5
                c.box.layer.borderColor = UIColor(red: 1, green: 120 / 255, blue: 90 / 255, alpha: 1).cgColor
            } else if c.id == current {
                c.box.layer.borderWidth = 2
                c.box.layer.borderColor = UIColor(red: 52 / 255, green: 199 / 255, blue: 89 / 255, alpha: 1).cgColor
            } else {
                c.box.layer.borderWidth = 0
            }
        }
    }
}
