import UIKit

/// 기념일 말풍선 문구 (테마마다 팻핑이 말투가 달라짐)
enum Anniversary {
    /// 오타 기념일 이름표
    static func tag(_ n: Int) -> String {
        switch n {
        case 22: return "투투"
        case 365: return "1주년"
        case 1000: return "천일"
        default: return n < 1000 ? "\(n)일" : "\(n)개"
        }
    }

    /// (제목, 부제) – {t}: 이름표, {n}: 개수
    private static let countCopy: [String: (String, String)] = [
        "default": ("{t}! 오타 {n}개 기념일", "팻핑이랑 같이 고쳤어요"),
        "oled": ("{t}. 오타 {n}개", "조용히, 확실하게 고쳤어요"),
        "mint": ("{t}~ 오타 {n}개", "레트로하게 고쳐드렸어요"),
        "navy": ("{t}! 오타 {n}개 홈런", "팻핑이가 다 받아냈어요"),
        "lime": ("{t}! 오타 {n}개", "새싹처럼 쑥쑥 맞춰지는 중"),
        "lavender": ("{t}♡ 오타 {n}개", "향기롭게 고쳐줬어요"),
        "coral": ("{t}! 밤 {n}톨 모았다", "오타 {n}개 고쳤어요"),
        "yellow": ("{t}! 은행잎 {n}장", "오타 {n}개 고쳤어요"),
        "winter": ("{t}! 눈송이 {n}개", "오타 {n}개 고쳤어요"),
        "red": ("{t}! 메리 오타마스", "오타 {n}개 고쳤어요"),
    ]

    static func countText(theme: String, n: Int) -> (String, String) {
        let c = countCopy[theme] ?? countCopy["default"]!
        func fill(_ s: String) -> String {
            s.replacingOccurrences(of: "{t}", with: tag(n)).replacingOccurrences(of: "{n}", with: "\(n)")
        }
        return (fill(c.0), fill(c.1))
    }

    static let reportSub = "팻핑이 꾹 → 📊에서 볼 수 있어요"

    /// 100개마다 리포트 도착 알림
    static func reportText(_ n: Int) -> (String, String) {
        ("📊 오타 \(n)개 리포트 도착!", "팻핑이를 꾹 누르고 위쪽 📊를 눌러 보세요")
    }

    static func dayText(_ d: Int) -> (String, String) {
        (d == 365 ? "팻핑이와 만난 지 1년" : "팻핑이와 만난 지 \(d)일", "오늘도 네 엄지 편이야")
    }
}

/// 키보드 위에 잠깐 떴다 사라지는 말풍선 (터치를 막지 않음)
final class ToastView: UIView {
    private let pill = UIView()
    private let face = UIImageView()
    private let faceBg = UIView()
    private let title = UILabel()
    private let sub = UILabel()
    private let deco = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        alpha = 0
        pill.backgroundColor = UIColor(white: 1, alpha: 0.98)
        pill.layer.borderWidth = 1.5
        pill.layer.shadowColor = UIColor.black.cgColor
        pill.layer.shadowOpacity = 0.22
        pill.layer.shadowRadius = 6
        pill.layer.shadowOffset = CGSize(width: 0, height: 3)
        addSubview(pill)
        faceBg.layer.masksToBounds = true
        pill.addSubview(faceBg)
        face.contentMode = .scaleAspectFit
        pill.addSubview(face)
        title.font = ThemeFont.ui(16)
        title.textColor = UIColor(red: 54 / 255, green: 40 / 255, blue: 44 / 255, alpha: 1)
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.7
        sub.font = ThemeFont.ui(12)
        sub.textColor = UIColor(red: 130 / 255, green: 118 / 255, blue: 122 / 255, alpha: 1)
        sub.adjustsFontSizeToFitWidth = true
        sub.minimumScaleFactor = 0.7
        pill.addSubview(title)
        pill.addSubview(sub)
        deco.contentMode = .scaleAspectFit
        pill.addSubview(deco)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(in parent: UIView, theme: KBTheme, title t: String, sub s: String) {
        let accent = theme.accent ?? theme.special
        let w = min(parent.bounds.width - 30, 340)
        let h: CGFloat = 50
        frame = parent.bounds
        pill.frame = CGRect(x: (parent.bounds.width - w) / 2, y: 3, width: w, height: h)
        pill.layer.cornerRadius = h / 2
        pill.layer.borderColor = accent.cgColor
        let r = h * 0.4
        faceBg.frame = CGRect(x: h * 0.52 - r, y: h / 2 - r, width: r * 2, height: r * 2)
        faceBg.layer.cornerRadius = r
        faceBg.backgroundColor = accent.withAlphaComponent(0.22)
        let fs = r * 1.6
        face.frame = CGRect(x: h * 0.52 - fs / 2, y: h / 2 - fs / 2, width: fs, height: fs)
        face.image = KeyCap.image("pat_" + theme.id) ?? KeyCap.image("space_logo")
        let tx = h * 1.05
        title.frame = CGRect(x: tx, y: 6, width: w - tx - h, height: 22)
        sub.frame = CGRect(x: tx, y: 27, width: w - tx - h, height: 17)
        title.text = t
        sub.text = s
        deco.image = KeyCap.image("deco_" + theme.id)
        deco.frame = CGRect(x: w - h * 0.95, y: h / 2 - 18, width: 36, height: 36)
        parent.addSubview(self)
        layer.removeAllAnimations()
        UIView.animate(withDuration: 0.25, animations: { self.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.35, delay: 2.2, options: [], animations: { self.alpha = 0 }) { done in
                if done { self.removeFromSuperview() }
            }
        }
    }
}
