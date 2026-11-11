import UIKit

final class KeyCap: UIView {
    /// 키 윗면 (글자·로고). KeyCap 자체 크기 = 누르는 판정 영역 → 테마가 바뀌어도 그대로
    let face = UIView()
    let label = UILabel()
    /// 키 왼쪽 위 작은 글자 (한/A 키의 '한' 등)
    let hint = UILabel()
    let icon = UIImageView()
    let gloss = UIView()
    /// 젤리 윗면 그라데이션 (위가 밝게)
    private let grad = CAGradientLayer()
    /// 젤리 반짝임 (위에서 아래로 사라짐)
    private let glossGrad = CAGradientLayer()
    /// 동글 타자기 안쪽 테두리
    private let ring = CAShapeLayer()
    /// 가죽 박음질 점선
    private let stitchLayer = CAShapeLayer()
    /// 투명 젤리 물방울 반사광
    private let drop = UIView()
    /// 계절 스티커 (키 모서리에 살짝 걸침, 누르는 영역과 무관)
    let sticker = UIImageView()
    var stickerPos: CGPoint? = nil { didSet { setNeedsLayout() } }
    /// 키 모서리 곳곳의 작은 잎 (가을 테마)
    let sprinkle = UIImageView()
    var sprinklePos: CGPoint? = nil { didSet { setNeedsLayout() } }
    var iconScale: CGFloat = 0.72 { didSet { setNeedsLayout() } }
    var iconRight = false { didSet { setNeedsLayout() } }

    var isSpecial = false { didSet { refreshColor() } }
    var isDown = false { didSet { refreshColor(); setNeedsLayout() } }
    /// 누르면 위로 말풍선이 뜨는 키 (글자 키)
    var pops = false
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
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint = CGPoint(x: 0.5, y: 1)
        face.layer.insertSublayer(grad, at: 0)
        body.isHidden = true
        layer.insertSublayer(body, at: 0)
        ring.fillColor = UIColor.clear.cgColor
        ring.lineWidth = 1
        face.layer.insertSublayer(ring, above: grad)
        stitchLayer.fillColor = UIColor.clear.cgColor
        stitchLayer.lineWidth = 1.1
        stitchLayer.lineDashPattern = [3.5, 2.5]
        face.layer.insertSublayer(stitchLayer, above: ring)
        drop.isUserInteractionEnabled = false
        drop.backgroundColor = UIColor(white: 1, alpha: 0.75)
        drop.isHidden = true
        face.addSubview(drop)
        glossGrad.startPoint = CGPoint(x: 0.5, y: 0)
        glossGrad.endPoint = CGPoint(x: 0.5, y: 1)
        gloss.isUserInteractionEnabled = false
        gloss.backgroundColor = UIColor(white: 1, alpha: 0.35)
        gloss.isHidden = true
        face.addSubview(gloss)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        face.addSubview(label)
        hint.font = .systemFont(ofSize: 10)
        hint.isHidden = true
        face.addSubview(hint)
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

    static let patPad: CGFloat = 8

    static func mix(_ a: UIColor, _ b: UIColor, _ f: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * f, green: g1 + (g2 - g1) * f, blue: b1 + (b2 - b1) * f, alpha: 1)
    }

    static func image(_ name: String) -> UIImage? {
        UIImage(named: name, in: Bundle(for: KeyCap.self), compatibleWith: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        refreshColor()
    }

    /// 키캡 모양별 두께
    private var capDepth: CGFloat {
        guard theme.jelly else { return theme.depth }
        switch theme.cap {
        case "round": return 5
        case "clear": return 3
        case "clay", "sa": return 0
        default: return 4
        }
    }
    private var capRadius: CGFloat {
        guard theme.jelly else { return theme.radius }
        switch theme.cap {
        case "clear", "clay": return max(theme.radius, 12)
        case "sa": return 5
        default: return max(theme.radius, 9)
        }
    }
    /// 레트로 기계식 몸통
    private let body = CAGradientLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        var f = bounds
        let d = capDepth
        if d > 0 {
            f.size.height -= d
            if isDown { f.origin.y += d * (theme.jelly ? 0.75 : 0.6) }
        }
        if theme.jelly && theme.cap == "sa" {
            // 몸통 안쪽 오목한 윗면 (글자는 여기 가운데)
            let push: CGFloat = isDown ? 2 : 0
            f = CGRect(x: 4, y: 2.5 + push, width: bounds.width - 8, height: bounds.height - 9.5)
            CATransaction.begin(); CATransaction.setDisableActions(true)
            body.frame = bounds.offsetBy(dx: 0, dy: push).inset(by: UIEdgeInsets(top: 0, left: 0, bottom: push, right: 0))
            body.cornerRadius = 7
            CATransaction.commit()
        }
        face.frame = f
        // 동글 타자기는 키 칸 안에서 동그랗게(넓은 키는 알약)
        let cr = theme.jelly && theme.cap == "round" ? min(bounds.width, f.height) / 2 : capRadius
        face.layer.cornerRadius = cr
        layer.cornerRadius = theme.jelly && theme.cap == "sa" ? 7 : cr
        CATransaction.begin(); CATransaction.setDisableActions(true)
        grad.frame = face.bounds
        grad.cornerRadius = cr
        ring.frame = face.bounds
        stitchLayer.frame = face.bounds
        stitchLayer.path = UIBezierPath(roundedRect: face.bounds.insetBy(dx: 3.5, dy: 3.5), cornerRadius: 6).cgPath
        ring.path = theme.cap == "round" ? UIBezierPath(roundedRect: face.bounds.insetBy(dx: 2.5, dy: 2.5), cornerRadius: max(cr - 2.5, 0)).cgPath : nil
        CATransaction.commit()
        if theme.jelly {
            let sp: CGRect
            switch theme.cap {
            case "clay": sp = bounds.offsetBy(dx: 0, dy: isDown ? 1 : 3.5).insetBy(dx: -1, dy: 0)
            case "round": sp = bounds.offsetBy(dx: 0, dy: 2).insetBy(dx: 1.5, dy: 0)
            case "sa": sp = bounds.offsetBy(dx: 0, dy: isDown ? 1.5 : 3).insetBy(dx: 1, dy: 0)
            default: sp = bounds.offsetBy(dx: 0, dy: 1.6).insetBy(dx: 0.5, dy: 0)
            }
            layer.shadowPath = UIBezierPath(roundedRect: sp, cornerRadius: theme.cap == "sa" ? 7 : cr).cgPath
        }
        if theme.cap == "clear" {
            let fb = face.bounds
            let ow = min(fb.width * 0.28, 14), oh = fb.height * 0.13
            drop.frame = CGRect(x: fb.width * 0.22 - ow / 2, y: fb.height * 0.2 - oh / 2, width: ow, height: oh)
            drop.layer.cornerRadius = oh / 2
        }
        label.frame = face.bounds.insetBy(dx: 2, dy: 0)
        hint.frame = CGRect(x: 5, y: 2, width: 20, height: 13)
        let s = face.bounds.height * iconScale
        let ix = iconRight ? face.bounds.maxX - KeyCap.patPad - s : face.bounds.midX - s / 2
        icon.frame = CGRect(x: ix, y: face.bounds.midY - s / 2, width: s, height: s)
        let fb = face.bounds
        gloss.frame = theme.jelly
            ? CGRect(x: fb.width * 0.12, y: fb.height * 0.06, width: fb.width * 0.76, height: fb.height * 0.28)
            : CGRect(x: fb.width * 0.12, y: fb.height * 0.08, width: fb.width * 0.76, height: fb.height * 0.22)
        CATransaction.begin(); CATransaction.setDisableActions(true)
        glossGrad.frame = gloss.bounds
        glossGrad.cornerRadius = min(theme.radius * 0.6, gloss.bounds.height / 2)
        CATransaction.commit()
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
        gloss.isHidden = !(t.gloss || t.jelly) || isDown
        gloss.backgroundColor = t.jelly ? .clear : UIColor(white: 1, alpha: 0.35)
        drop.isHidden = true
        ring.isHidden = true
        body.isHidden = true
        stitchLayer.isHidden = t.stitch == nil || isSpecial || isAccent
        stitchLayer.strokeColor = t.stitch?.cgColor
        if t.jelly {
            // 3D 키캡: 아랫단은 윗면보다 진하게, 윗면은 위가 밝은 그라데이션, 바닥에 은은한 그림자
            let top = (face.backgroundColor ?? t.key).resolvedColor(with: traitCollection)
            let fallbackSide = KeyCap.mix(top, .black, (isSpecial || isAccent) ? 0.22 : 0.16)
            backgroundColor = ((isSpecial || isAccent) ? (isAccent ? KeyCap.mix(top, .black, 0.22) : (t.sideSpecial ?? fallbackSide)) : (t.side ?? fallbackSide)).resolvedColor(with: traitCollection)
            CATransaction.begin(); CATransaction.setDisableActions(true)
            grad.isHidden = false
            grad.type = .axial
            grad.startPoint = CGPoint(x: 0.5, y: 0); grad.endPoint = CGPoint(x: 0.5, y: 1)
            var br: CGFloat = 0, bgc: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
            t.bg.resolvedColor(with: traitCollection).getRed(&br, green: &bgc, blue: &bb, alpha: &ba)
            let ga: CGFloat = (br + bgc + bb) * 255 < 120 ? 0.16 : 0.6
            if glossGrad.superlayer == nil { gloss.layer.addSublayer(glossGrad) }
            glossGrad.colors = [UIColor(white: 1, alpha: ga).cgColor, UIColor(white: 1, alpha: 0).cgColor]
            grad.colors = [KeyCap.mix(top, .white, isDown ? 0.10 : 0.42).cgColor, top.cgColor]
            face.layer.shadowOpacity = 0
            layer.shadowColor = KeyCap.mix(backgroundColor ?? .black, .black, 0.66).cgColor
            layer.shadowOpacity = 0.4
            layer.shadowRadius = 1.2
            layer.shadowOffset = .zero
            switch t.cap {
            case "round":
                // 동글 타자기: 둥근 빛 + 안쪽 테두리, 반짝임 띠 없음
                backgroundColor = KeyCap.mix(top, .black, (isSpecial || isAccent) ? 0.26 : 0.18)
                grad.type = .radial
                grad.startPoint = CGPoint(x: 0.4, y: 0.35); grad.endPoint = CGPoint(x: 1.05, y: 1.05)
                grad.colors = [KeyCap.mix(top, .white, isDown ? 0.15 : 0.5).cgColor, top.cgColor]
                ring.isHidden = false
                ring.strokeColor = KeyCap.mix(top, .black, 0.12).withAlphaComponent(0.6).cgColor
                gloss.isHidden = true
                layer.shadowColor = UIColor.black.cgColor
                layer.shadowOpacity = 0.18
                layer.shadowRadius = 1
            case "clear":
                // 투명 젤리: 속이 비치는 윗면 + 흰 테두리 + 물방울 반사광
                face.backgroundColor = top.withAlphaComponent(isDown ? 0.75 : 0.55)
                backgroundColor = top.withAlphaComponent(0.35)
                grad.colors = [KeyCap.mix(top, .white, 0.55).withAlphaComponent(isDown ? 0.86 : 0.75).cgColor, top.withAlphaComponent(0.0).cgColor]
                face.layer.borderWidth = 1.3
                face.layer.borderColor = UIColor(white: 1, alpha: 0.85).cgColor
                gloss.isHidden = true
                drop.isHidden = isDown
                layer.shadowOpacity = 0
            case "sa":
                // 레트로 기계식: 아래로 진해지는 몸통 + 가운데가 살짝 오목한 윗면
                backgroundColor = .clear
                body.isHidden = false
                body.colors = [KeyCap.mix(top, .black, 0.03).cgColor, KeyCap.mix(top, .black, 0.14).cgColor]
                grad.type = .radial
                grad.startPoint = CGPoint(x: 0.5, y: 0.65); grad.endPoint = CGPoint(x: 1.2, y: 1.35)
                grad.colors = [top.cgColor, KeyCap.mix(top, .white, isDown ? 0.12 : 0.3).cgColor]
                gloss.isHidden = true
                layer.shadowColor = UIColor.black.cgColor
                layer.shadowOpacity = isDown ? 0.14 : 0.24
                layer.shadowRadius = 1
            case "clay":
                // 클레이: 무광 점토. 퍼진 그림자, 누르면 그림자가 줄어듦
                backgroundColor = .clear
                grad.colors = [KeyCap.mix(top, .white, isDown ? 0.05 : 0.28).cgColor, KeyCap.mix(top, .black, 0.05).cgColor]
                face.layer.borderWidth = 1.5
                face.layer.borderColor = UIColor(white: 1, alpha: isDown ? 0.16 : 0.43).cgColor
                gloss.isHidden = true
                layer.shadowColor = KeyCap.mix(top, .black, 0.45).cgColor
                layer.shadowOpacity = isDown ? 0.3 : 0.38
                layer.shadowRadius = isDown ? 1.5 : 3.5
            default: break
            }
            CATransaction.commit()
            setNeedsLayout()
        } else {
            grad.isHidden = true
            layer.shadowOpacity = 0
        }
        label.textColor = isAccent ? UIColor(white: 1, alpha: 0.98) : (isSpecial ? t.specialText : t.text)
        hint.textColor = label.textColor.withAlphaComponent(0.6)
    }
}

/// 누른 글자 키 위로 크게 튀어나오는 말풍선 (아이폰 기본 키보드처럼). 맨 윗줄은 키보드 밖으로 못 나가서 위쪽에 붙음
final class KeyPopup: UIView {
    private let shape = CAShapeLayer()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(shape)
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.3
        shape.shadowRadius = 3
        shape.shadowOffset = CGSize(width: 0, height: 1.5)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 아이폰 기본 키보드처럼: 누른 키에서 그대로 위로 넓게 부풀어 오르는 한 덩어리 모양 (키 위치·크기는 그대로)
    func show(key k: CGRect, text: String, theme t: KBTheme, in parent: UIView) {
        let x0 = k.minX, x1 = k.maxX, kt = k.minY, kb = k.maxY
        let kw = k.width, kh = k.height
        let rk = min(max(t.radius, 4), kw / 4)
        let e = max(kw * 0.24, 8)
        let H = min(kh * 2.25, kb - 2)
        let top = kb - H
        let bulbH = min(kh * 1.12, H * 0.56)
        var px0 = x0 - e, px1 = x1 + e
        var sh: CGFloat = 0
        if px0 < 2 { sh = 2 - px0 }
        if px1 + sh > parent.bounds.width - 2 { sh = parent.bounds.width - 2 - px1 }
        px0 += sh; px1 += sh
        let R = min(10, (px1 - px0) / 4)
        let nT = top + bulbH, nB = nT + kh * 0.3, m = (nT + nB) / 2
        let path = UIBezierPath()
        if H < kh * 1.6 || nB > kb - rk {
            // 맨 윗줄: 키보드 밖으로 못 나가서 넓은 모양 그대로 키까지
            path.append(UIBezierPath(roundedRect: CGRect(x: px0, y: top, width: px1 - px0, height: kb - top), cornerRadius: R))
        } else {
            path.move(to: CGPoint(x: x0, y: kb - rk))
            path.addLine(to: CGPoint(x: x0, y: nB))
            path.addCurve(to: CGPoint(x: px0, y: nT), controlPoint1: CGPoint(x: x0, y: m), controlPoint2: CGPoint(x: px0, y: m))
            path.addLine(to: CGPoint(x: px0, y: top + R))
            path.addQuadCurve(to: CGPoint(x: px0 + R, y: top), controlPoint: CGPoint(x: px0, y: top))
            path.addLine(to: CGPoint(x: px1 - R, y: top))
            path.addQuadCurve(to: CGPoint(x: px1, y: top + R), controlPoint: CGPoint(x: px1, y: top))
            path.addLine(to: CGPoint(x: px1, y: nT))
            path.addCurve(to: CGPoint(x: x1, y: nB), controlPoint1: CGPoint(x: px1, y: m), controlPoint2: CGPoint(x: x1, y: m))
            path.addLine(to: CGPoint(x: x1, y: kb - rk))
            path.addQuadCurve(to: CGPoint(x: x1 - rk, y: kb), controlPoint: CGPoint(x: x1, y: kb))
            path.addLine(to: CGPoint(x: x0 + rk, y: kb))
            path.addQuadCurve(to: CGPoint(x: x0, y: kb - rk), controlPoint: CGPoint(x: x0, y: kb))
            path.close()
        }
        frame = parent.bounds
        shape.path = path.cgPath
        shape.fillColor = t.key.cgColor
        shape.strokeColor = t.rim?.cgColor
        shape.lineWidth = t.rim == nil ? 0 : 1
        label.font = .systemFont(ofSize: kh * 0.78)
        label.textColor = t.text
        label.text = text
        label.frame = CGRect(x: px0 + 2, y: top, width: px1 - px0 - 4, height: bulbH)
        if superview !== parent { parent.addSubview(self) }
        isHidden = false
    }

    private func theme_radius(_ t: KBTheme) -> CGFloat { t.radius }
}

@MainActor
protocol KeyboardViewDelegate: AnyObject {
    func keyPressed(_ id: String, at p: CGPoint, raw: String)
    func keyReleased(_ id: String)
    /// 스페이스바를 꾹 누르거나 밀어서 커서 이동 (음수 = 왼쪽)
    func moveCursor(_ by: Int)
}

final class KeyboardView: UIView, UIInputViewAudioFeedback {
    enum Page { case hangul, english, number, symbol }

    // ---- 타격감: 키 소리(아이폰 설정의 '키보드 클릭'을 따름) + 진동 + 말풍선 ----
    var enableInputClicksWhenVisible: Bool { true }
    private let tapHaptic = UIImpactFeedbackGenerator(style: .light)
    private var popups: [ObjectIdentifier: KeyPopup] = [:]
    private static let noPopup: Set<String> = ["SPACE", "RETURN", "BACK", "SHIFT", "MODE", "LANG", "GLOBE", "SYM", "LANG_HOLD"]

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
    var capsLock = false { didSet { refreshLabels() } }
    /// 숫자 화면에서 돌아갈 글자 화면 (한글/영어)
    var letterPage: Page = .hangul
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
    private static let specials: Set<String> = ["SHIFT", "BACK", "MODE", "GLOBE", "RETURN", "SYM", "LANG"]

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
        bottom += [Spec(id: "LANG", weight: 1.3, fill: false),
                   Spec(id: "SPACE", weight: 1, fill: true),
                   Spec(id: "RETURN", weight: 2.4, fill: false)]
        func wide(_ s: String) -> [Spec] { s.map { Spec(id: String($0), weight: 1.4, fill: false) } }
        let punct = [Spec(id: "SYM", weight: 1, fill: true)] + wide(".,?!'") + [Spec(id: "BACK", weight: 1, fill: true)]
        switch page {
        case .hangul:
            return [letters("ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ"),
                    letters("ㅁㄴㅇㄹㅎㅗㅓㅏㅣ"),
                    [Spec(id: "SHIFT", weight: 1, fill: true)] + letters("ㅋㅌㅊㅍㅠㅜㅡ") + [Spec(id: "BACK", weight: 1, fill: true)],
                    bottom]
        case .english:
            // 한글 자판과 키 위치·크기가 완전히 같음 (ㅂ자리=q, ㅁ자리=a, ㅋ자리=z)
            return [letters("qwertyuiop"),
                    letters("asdfghjkl"),
                    [Spec(id: "SHIFT", weight: 1, fill: true)] + letters("zxcvbnm") + [Spec(id: "BACK", weight: 1, fill: true)],
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
                cap.pops = !cap.isSpecial && !KeyboardView.noPopup.contains(s.id)
                cap.theme = theme
                cap.isAccent = s.id == "RETURN" && theme.accent != nil
                let letter = (page == .hangul && (Hangul.isConsonant(s.id) || Hangul.isVowel(s.id)))
                    || (page == .english && KeyboardView.en2ko[s.id] != nil)
                addSubview(cap)
                keys.append(Key(id: s.id, isLetter: letter, row: ri, cap: cap))
            }
        }
        refreshLabels()
        setNeedsLayout()
    }

    private func label(for id: String) -> String {
        switch id {
        case "SHIFT": return capsLock ? "⇪" : "⇧"
        case "LANG": return page == .english || (page != .hangul && letterPage == .english) ? "한" : "A"
        case "BACK": return "⌫"
        case "SPACE": return ""
        case "RETURN": return "⏎"
        case "GLOBE": return "🌐"
        case "MODE":
            if page == .hangul || page == .english { return "123" }
            return letterPage == .english ? "ABC" : "가"
        case "SYM": return page == .symbol ? "123" : "#+="
        default:
            if page == .english { return (shift || capsLock) ? id.uppercased() : id }
            return shift ? (Hangul.shiftMap[id] ?? id) : id
        }
    }

    /// 영어 키 → 같은 자리의 한글 키 (엄지 쏠림 학습을 한글·영어가 함께 씀)
    static let en2ko: [String: String] = {
        var m: [String: String] = [:]
        for (e, k) in zip(["qwertyuiop", "asdfghjkl", "zxcvbnm"], ["ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ", "ㅁㄴㅇㄹㅎㅗㅓㅏㅣ", "ㅋㅌㅊㅍㅠㅜㅡ"]) {
            for (a, b) in zip(e, k) { m[String(a)] = String(b) }
        }
        return m
    }()
    static func posId(_ id: String) -> String { en2ko[id] ?? id }

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
            if k.id == "SHIFT" { k.cap.isSpecial = !(shift || capsLock) }
            if k.id == "LANG" {
                k.cap.hint.text = k.cap.label.text == "A" ? "한" : "A"
                k.cap.hint.isHidden = false
                k.cap.label.font = .systemFont(ofSize: 20)
            }
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
                // 팻핑이는 스페이스바 오른쪽 구석 (팻핑이 꾹 = 메뉴, 나머지 자리 꾹·밀기 = 커서 이동)
                let custom = KeyCap.image("pat_" + theme.id)
                k.cap.icon.image = custom ?? KeyCap.image("space_logo")
                k.cap.iconScale = custom == nil ? 0.72 : 0.84
                k.cap.iconRight = true
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
        guard page == .hangul || page == .english, !letterIdx.isEmpty, let lr = learner, lr.data.fixOn else { return (rawI, raw) }

        // 내 엄지 쏠림 + 흔들림 방향으로 판정
        let t = lr.thumb()
        let sq = CGFloat(sqrt(t.k))
        let scored = letterIdx.map { i -> (Int, CGFloat) in
            let o = lr.data.off[KeyboardView.posId(keys[i].id)] ?? KeyOffset()
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

    // 한/A 꾹 누르기 → 다른 키보드(기본 키보드 등)로
    private var langTouch: ObjectIdentifier?

    @objc private func langHeld() {
        guard let oid = langTouch, let pd = pressed.removeValue(forKey: oid) else { langTouch = nil; return }
        langTouch = nil
        if pd.index < keys.count { keys[pd.index].cap.isDown = false }
        delegate?.keyPressed("LANG_HOLD", at: pd.point, raw: pd.raw)
    }

    private func cancelLang() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(langHeld), object: nil)
        langTouch = nil
    }

    /// 팻핑이 메뉴에 보일 진행 상황 ("고친 오타 412개 · 다음 리포트 500개")
    var menuStatus = ""

    // 기념일 말풍선
    private let toast = ToastView()
    func showToast(_ title: String, _ sub: String) {
        toast.show(in: self, theme: theme, title: title, sub: sub)
    }

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

    // ---- 스페이스바 커서 이동 (팻핑이 밖을 꾹 누르거나, 어디서든 좌우로 밀면) ----
    private var cursorTouch: ObjectIdentifier?
    private var cursorOn = false
    private var cursorLastX: CGFloat = 0
    private let cursorStep: CGFloat = 8        // 한 글자 이동에 필요한 손가락 이동 (기본 키보드와 비슷하게)
    private var cursorT: TimeInterval = 0      // 빠르게 밀면 더 많이 (가속)
    private var cursorPX: CGFloat = 0
    private var cursorFX: CGFloat = 0          // 손가락 위치를 부드럽게 (떨림 거르기)
    private var cursorDir = 0                  // 마지막으로 움직인 방향 (-1 왼쪽, 1 오른쪽)


    /// 스페이스바 오른쪽 구석 팻핑이 자리 (여기를 꾹 누르면 테마·한손 모드 메뉴)
    private func patZone(_ space: CGRect) -> CGRect {
        let s = space.height * 0.84
        return CGRect(x: space.maxX - KeyCap.patPad - s - 8, y: space.minY, width: s + KeyCap.patPad + 8, height: space.height)
    }

    private func startCursorArm(_ t: UITouch, at p: CGPoint) {
        cursorTouch = ObjectIdentifier(t)
        cursorOn = false
        cursorLastX = p.x
        cursorFX = p.x
        cursorDir = 0
        cursorPX = p.x
        cursorT = Date().timeIntervalSince1970
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cursorArmed), object: nil)
        perform(#selector(cursorArmed), with: nil, afterDelay: 0.35)
    }

    /// 커서 모드 시작: 이 스페이스는 띄어쓰기로 넣지 않음
    @objc private func cursorArmed() {
        guard let oid = cursorTouch, !cursorOn else { return }
        cursorOn = true
        cancelHold()
        if let pd = pressed.removeValue(forKey: oid), pd.index < keys.count { keys[pd.index].cap.isDown = false }
        tapHaptic.impactOccurred(intensity: 1.0)
    }

    private func cursorMoved(_ p: CGPoint) {
        if !cursorOn {
            // 글자 치다가 스페이스를 살짝 스친 건 커서 이동이 아님 (확실히 옆으로 밀어야 시작)
            if abs(p.x - cursorLastX) < 28 { return }
            cursorArmed()
            cursorLastX = p.x; cursorFX = p.x; cursorPX = p.x
            cursorT = Date().timeIntervalSince1970
            return
        }
        // 빠르기: 천천히 밀면 한 글자씩 정확하게, 빠르게 밀면 쭉쭉 (아이폰·삼성 기본 키보드처럼)
        let now = Date().timeIntervalSince1970
        let dt = max(now - cursorT, 0.008)
        let v = abs(p.x - cursorPX) / CGFloat(dt * 1000)   // pt/ms
        cursorT = now; cursorPX = p.x
        let accel = v > 1.2 ? 3 : (v > 0.6 ? 2 : 1)
        cursorFX = cursorFX * 0.3 + p.x * 0.7
        let d = cursorFX - cursorLastX
        var n = Int(d / cursorStep)
        if n == 0 { return }
        let dir = n > 0 ? 1 : -1
        cursorLastX += CGFloat(n) * cursorStep
        // 방향을 바꿀 때는 한 칸 더 가야 바뀜 (손을 대고만 있어도 왔다갔다 떨리는 것 막기)
        if cursorDir != 0 && dir != cursorDir { n -= dir }
        cursorDir = dir
        if n != 0 {
            n *= accel
            delegate?.moveCursor(n)
            tapHaptic.impactOccurred(intensity: 0.4)
        }
    }

    private func endCursor() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cursorArmed), object: nil)
        cursorTouch = nil
        cursorOn = false
    }

    @objc private func openMenuFromHold() {
        guard let oid = holdTouch, let pd = pressed.removeValue(forKey: oid) else { cancelHold(); return }
        // 꾹 누른 스페이스는 띄어쓰기로 넣지 않음 (학습에도 안 들어감)
        if pd.index < keys.count { keys[pd.index].cap.isDown = false }
        holdTouch = nil
        menuTouch = oid
        let space = keys.first(where: { $0.id == "SPACE" })?.frame ?? CGRect(x: 0, y: bounds.height - 50, width: bounds.width, height: 46)
        menu.frame = bounds
        menu.show(current: theme.id, tab: KBTheme.tabOf(theme), above: space, status: menuStatus)
        addSubview(menu)
    }

    func closeMenu() {
        menu.removeFromSuperview()
        menuTouch = nil
    }

    /// 팻핑이 메뉴의 📊 를 눌렀을 때 (리포트 화면은 키보드 컨트롤러가 띄움)
    var onReport: (() -> Void)?

    private func choose(_ id: String) {
        if id == "REPORT" { closeMenu(); onReport?(); return }
        if id.hasPrefix("TAB:") { menu.setTab(String(id.dropFirst(4))); return }
        if id == "CAP" {
            // 키캡 모양 돌려 고르기: 젤리 → 동글 → 투명 → 클레이
            let ids = KBTheme.caps.map { $0.id }
            let i = ids.firstIndex(of: ThemeStore.capId()) ?? 0
            ThemeStore.saveCap(ids[(i + 1) % ids.count])
            applyTheme(KBTheme.find(ThemeStore.currentId()))
            menu.setCurrent(theme.id)
            return
        }
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
            // 스페이스를 누른 채 다음 글자를 빨리 치면 커서 이동 대기 취소 (타자 중 커서 튐 방지)
            if id != "SPACE", cursorTouch != nil, !cursorOn {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cursorArmed), object: nil)
                cursorTouch = nil
            }
            let norm = CGPoint(x: p.x / max(bounds.width, 1), y: p.y / max(bounds.height, 1))
            let immediate = KeyboardView.immediateKeys.contains(id)
            pressed[ObjectIdentifier(t)] = Pending(index: i, id: id, point: norm, raw: r.1, immediate: immediate)
            keys[i].cap.isDown = true
            // 누르는 순간: 소리 + 진동(전체 접근을 켠 경우) + 글자 키는 말풍선
            UIDevice.current.playInputClick()
            tapHaptic.impactOccurred(intensity: 0.7)
            tapHaptic.prepare()
            if keys[i].cap.pops, let txt = keys[i].cap.label.text, !txt.isEmpty {
                let pop = KeyPopup()
                pop.show(key: keys[i].frame, text: txt, theme: theme, in: self)
                popups[ObjectIdentifier(t)] = pop
            }
            if id == "SPACE" {
                // 팻핑이 그림을 꾹 = 메뉴, 그 밖을 꾹 = 커서 이동 (어디서든 좌우로 밀면 커서 이동)
                startCursorArm(t, at: p)
                if patZone(keys[i].frame).contains(p) {
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cursorArmed), object: nil)
                    startHold(t, at: p)
                }
            }
            if id == "LANG" {
                cancelLang()
                langTouch = ObjectIdentifier(t)
                perform(#selector(langHeld), with: nil, afterDelay: 0.5)
            }
            if immediate { delegate?.keyPressed(id, at: norm, raw: r.1) }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let oid = ObjectIdentifier(t)
            let p = t.location(in: self)
            if oid == menuTouch {
                menu.highlight(menu.item(at: p))
            } else if oid == cursorTouch {
                if oid == holdTouch, hypot(p.x - holdStart.x, p.y - holdStart.y) > 12 { cancelHold() }   // 팻핑이에서 밀면 메뉴 대신 커서
                if holdTouch == nil { cursorMoved(p) }
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
            if oid == cursorTouch { endCursor() }
            if oid == langTouch { cancelLang() }
            if let pop = popups.removeValue(forKey: oid) { pop.removeFromSuperview() }
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
        // 진행 숫자 + 📊 리포트 버튼 (누르면 키보드 안에서 리포트가 열림)
        status.font = .systemFont(ofSize: 11, weight: .semibold)
        status.textColor = UIColor(red: 46 / 255, green: 90 / 255, blue: 40 / 255, alpha: 1)
        status.backgroundColor = UIColor(red: 228 / 255, green: 242 / 255, blue: 222 / 255, alpha: 1)
        status.textAlignment = .center
        status.adjustsFontSizeToFitWidth = true
        status.minimumScaleFactor = 0.6
        status.layer.cornerRadius = 10
        status.clipsToBounds = true
        panel.addSubview(status)
        // [컬러] [겨울 레트로] 탭 + '키캡: 젤리 ▾'
        for (l, txt) in [(tabColor, "1"), (tabRetro, "2"), (tabWinter, "3"), (tabSpecial, "버건디"), (capBtn, "")] {
            l.text = txt
            l.font = ThemeFont.ui(12.5)
            l.textAlignment = .center
            l.layer.cornerRadius = 11
            l.clipsToBounds = true
            l.adjustsFontSizeToFitWidth = true
            l.minimumScaleFactor = 0.7
            panel.addSubview(l)
        }
    }

    private let tabColor = UILabel()
    private let tabRetro = UILabel()
    private let tabWinter = UILabel()
    private let tabSpecial = UILabel()
    private let capBtn = UILabel()
    private var tab = "0"

    /// 지금 탭의 테마 미리보기 칸 만들기
    private func buildChips() {
        for c in chips { c.box.removeFromSuperview(); c.name.removeFromSuperview() }
        chips = []
        let cap = ThemeStore.capId()
        for t in KBTheme.tabList(tab) {
            let box = UIView()
            box.layer.cornerRadius = 7
            box.layer.borderWidth = 0
            let img = UIImageView(image: KeyCap.image("kprev_" + KBTheme.previewName(t, cap: cap) + ".jpg"))
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

    func setTab(_ t: String) {
        tab = t
        layoutAll()
    }

    func setCurrent(_ id: String) {
        current = id
        layoutAll()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let status = UILabel()

    private var spaceRect = CGRect.zero

    func show(current: String, tab: String, above space: CGRect, status text: String = "") {
        self.current = current
        self.tab = tab
        spaceRect = space
        status.text = "📊 " + (text.isEmpty ? "리포트" : text) + " ›"
        hot = nil
        layoutAll()
    }

    private func layoutAll() {
        buildChips()
        let space = spaceRect
        dim.frame = bounds
        let top: CGFloat = 6
        let bottom = space.minY - 6
        panel.frame = CGRect(x: 8, y: top, width: bounds.width - 16, height: max(120, bottom - top))
        tail.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        tail.center = CGPoint(x: space.midX, y: panel.frame.maxY)
        let pad: CGFloat = 10
        header.frame = CGRect(x: pad + 2, y: 6, width: panel.bounds.width - pad * 2, height: 22)
        status.frame = CGRect(x: panel.bounds.width * 0.36, y: 5, width: panel.bounds.width * 0.64 - pad, height: 22)
        let cols = 5
        let g: CGFloat = 6
        let cw = (panel.bounds.width - pad * 2 - g * CGFloat(cols - 1)) / CGFloat(cols)
        let ty: CGFloat = 32
        // 테마 장 넘기기 [1] [2] [3]
        tabColor.frame = CGRect(x: pad, y: ty, width: 34, height: 22)
        tabRetro.frame = CGRect(x: tabColor.frame.maxX + 5, y: ty, width: 34, height: 22)
        tabWinter.frame = CGRect(x: tabRetro.frame.maxX + 5, y: ty, width: 34, height: 22)
        let np = KBTheme.pages.count
        tabRetro.isHidden = np < 2
        tabWinter.isHidden = np < 3
        let lastTab = [tabColor, tabRetro, tabWinter][min(np, 3) - 1]
        tabSpecial.frame = CGRect(x: lastTab.frame.maxX + 8, y: ty, width: 62, height: 22)
        capBtn.frame = CGRect(x: panel.bounds.width - pad - 112, y: ty, width: 112, height: 22)
        let peach = UIColor(red: 1, green: 160 / 255, blue: 132 / 255, alpha: 1)
        let off = UIColor(red: 238 / 255, green: 234 / 255, blue: 230 / 255, alpha: 1)
        for (l, k) in [(tabColor, "0"), (tabRetro, "1"), (tabWinter, "2"), (tabSpecial, "s")] {
            l.backgroundColor = tab == k ? peach : off
            l.textColor = tab == k ? .white : UIColor(white: 0.35, alpha: 1)
        }
        capBtn.isHidden = false
        capBtn.text = "키캡: " + KBTheme.capName(ThemeStore.capId()) + " ▾"
        capBtn.backgroundColor = UIColor(red: 1, green: 238 / 255, blue: 228 / 255, alpha: 1)
        capBtn.textColor = UIColor(red: 196 / 255, green: 90 / 255, blue: 64 / 255, alpha: 1)
        let rowsTop: CGFloat = ty + 28
        let rowH = (panel.bounds.height - rowsTop - 4) / 2
        let ih = min(cw * 0.6, rowH - 17)
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
        if status.frame.insetBy(dx: -4, dy: -4).contains(q) { return "REPORT" }
        if tabColor.frame.insetBy(dx: -3, dy: -3).contains(q) { return "TAB:0" }
        if !tabRetro.isHidden, tabRetro.frame.insetBy(dx: -3, dy: -3).contains(q) { return "TAB:1" }
        if !tabWinter.isHidden, tabWinter.frame.insetBy(dx: -3, dy: -3).contains(q) { return "TAB:2" }
        if tabSpecial.frame.insetBy(dx: -3, dy: -3).contains(q) { return "TAB:s" }
        if !capBtn.isHidden, capBtn.frame.insetBy(dx: -3, dy: -3).contains(q) { return "CAP" }
        for c in chips where c.box.frame.union(c.name.frame).insetBy(dx: -3, dy: -3).contains(q) { return c.id }
        return nil
    }

    func highlight(_ id: String?) {
        hot = id
        refresh()
    }

    private func refresh() {
        status.layer.borderWidth = hot == "REPORT" ? 2 : 0
        capBtn.layer.borderWidth = hot == "CAP" ? 2 : 0
        capBtn.layer.borderColor = UIColor(red: 1, green: 120 / 255, blue: 90 / 255, alpha: 1).cgColor
        status.layer.borderColor = UIColor(red: 1, green: 120 / 255, blue: 90 / 255, alpha: 1).cgColor
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
