import UIKit

/// 키보드 위 예측 단어 줄: 왼쪽 작은 팻핑이 + 후보 3칸 (테마 색을 따름)
final class SuggestBar: UIView {
    static let height: CGFloat = 38
    var onPick: ((String) -> Void)?
    var onForget: ((String) -> Void)?

    private let pat = UIImageView()
    private var buttons: [UIButton] = []
    private var dividers: [UIView] = []
    private var words: [String] = []
    private var fg: UIColor = .label

    override init(frame: CGRect) {
        super.init(frame: frame)
        pat.image = KeyCap.image("space_logo")
        pat.contentMode = .scaleAspectFit
        addSubview(pat)
        for i in 0..<3 {
            let b = UIButton(type: .custom)
            b.tag = i
            b.titleLabel?.font = .systemFont(ofSize: 16, weight: i == 0 ? .semibold : .regular)
            b.titleLabel?.lineBreakMode = .byTruncatingTail
            b.layer.cornerRadius = 9
            b.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
            b.addTarget(self, action: #selector(down(_:)), for: [.touchDown, .touchDragEnter])
            b.addTarget(self, action: #selector(up(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(hold(_:)))
            lp.minimumPressDuration = 0.65
            b.addGestureRecognizer(lp)
            addSubview(b)
            buttons.append(b)
            if i > 0 { let d = UIView(); addSubview(d); dividers.append(d) }
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func setTheme(_ t: KBTheme) {
        backgroundColor = t.bg
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        t.bg.getRed(&r, green: &g, blue: &b, alpha: &a)
        let dark = r * 0.3 + g * 0.59 + b * 0.11 < 0.5
        fg = dark ? UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1) : UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1)
        for d in dividers { d.backgroundColor = fg.withAlphaComponent(0.28) }
        for b in buttons { b.setTitleColor(fg, for: .normal) }
    }

    func setWords(_ w: [String]) {
        guard w != words else { return }
        words = w
        for (i, b) in buttons.enumerated() { b.setTitle(i < w.count ? w[i] : nil, for: .normal); b.isEnabled = i < w.count }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height, ps: CGFloat = 26
        pat.frame = CGRect(x: 8, y: (h - ps) / 2, width: ps, height: ps)
        let left = pat.frame.maxX + 6
        let w = (bounds.width - left - 6) / 3
        for (i, b) in buttons.enumerated() {
            b.frame = CGRect(x: left + w * CGFloat(i), y: 3, width: w, height: h - 6)
            b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        }
        for (i, d) in dividers.enumerated() {
            d.frame = CGRect(x: left + w * CGFloat(i + 1), y: h * 0.28, width: 1, height: h * 0.44)
        }
    }

    @objc private func down(_ b: UIButton) { if b.tag < words.count { b.backgroundColor = fg.withAlphaComponent(0.22) } }
    @objc private func up(_ b: UIButton) { b.backgroundColor = .clear }
    @objc private func tap(_ b: UIButton) {
        guard b.tag < words.count else { return }
        UIDevice.current.playInputClick()
        onPick?(words[b.tag])
    }
    @objc private func hold(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began, let b = g.view as? UIButton, b.tag < words.count else { return }
        b.backgroundColor = .clear
        // 길게 누르면 탭은 취소됨 (cancelsTouchesInView)
        onForget?(words[b.tag])
    }
}
