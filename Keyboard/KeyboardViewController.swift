import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardViewDelegate {
    struct TapMeta {
        let id: String
        let fx: CGFloat
        let fy: CGFloat
        var ok: Bool
    }

    private let learner = Learner()
    private let kv = KeyboardView()

    private var tokens: [String] = []   // 조합 중인 자모
    private var shown = ""               // 화면에 넣어둔 조합 결과
    private var history: [TapMeta?] = [] // 친 순서대로 (스택)
    private var delBuf: [TapMeta?] = []  // 지운 것들 (원래 순서)
    private var reIdx = 0
    private var delT = Date.distantPast
    private var repeatTimer: Timer?
    private var composing = false
    private var lastAuto: (idx: Int, orig: String, key: String)? = nil

    // MARK: - 어미 교정 (밥먹었어료 → 밥먹었어요)
    private static let endPrev: Set<String> = Set("어아에세네해여워와예래게데줘봐돼써가거서져려대케레셔쳐펴혀까떠냐니지시".map { String($0) })
    private static let endBase: Set<String> = ["ㄹ", "ㅌ", "ㄷ", "ㅊ"]

    private func prevSyllable(_ arr: [String]) -> String? {
        guard let last = arr.last, Hangul.isVowel(last) else { return nil }
        let w = Hangul.assemble(arr)
        return w.last.map { String($0) }
    }

    private func isEndSlot() -> Bool {
        guard let p = prevSyllable(tokens) else { return false }
        return KeyboardViewController.endPrev.contains(p)
    }

    private func endCheck() {
        let n = tokens.count
        guard n >= 3, tokens[n - 1] == "ㅛ" else { return }
        let c = tokens[n - 2]
        guard Hangul.isConsonant(c), c != "ㅇ" else { return }
        guard let p = prevSyllable(Array(tokens[0..<(n - 2)])), KeyboardViewController.endPrev.contains(p) else { return }
        if learner.endNo[p + c] == true { return }
        let learned = (learner.endConf["\(c)>ㅇ"] ?? 0) >= 2
        guard KeyboardViewController.endBase.contains(c) || (learned && adjacent(c, "ㅇ")) else { return }
        tokens[n - 2] = "ㅇ"
        lastAuto = (n - 2, c, p + c)
        learner.data.fixes += 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        kv.translatesAutoresizingMaskIntoConstraints = false
        kv.learner = learner
        kv.delegate = self
        view.addSubview(kv)
        let h = kv.heightAnchor.constraint(equalToConstant: 236)
        h.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            kv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            kv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            kv.topAnchor.constraint(equalTo: view.topAnchor),
            kv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            h
        ])
    }

    override func viewWillLayoutSubviews() {
        kv.showGlobe = needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 화면 가장자리 터치가 늦게 들어오는 문제 방지
        view.window?.gestureRecognizers?.forEach { $0.delaysTouchesBegan = false }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        kv.applyTheme(ThemeStore.current())   // 앱에서 고른 테마
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRepeat()
        kv.closeMenu()
        learner.saveNow()
    }

    // MARK: - 키 입력

    func keyPressed(_ id: String, at p: CGPoint, raw: String) {
        switch id {
        case "SHIFT":
            kv.shift.toggle()
        case "BACK": backspace(); startRepeat()
        case "SPACE": typeSpace()
        case "RETURN": typeChar("\n")
        case "MODE":
            kv.shift = false
            kv.page = kv.page == .hangul ? .number : .hangul
        case "SYM":
            kv.page = kv.page == .symbol ? .number : .symbol
        case "GLOBE": advanceToNextInputMode()
        default:
            if kv.page == .hangul && (Hangul.isConsonant(id) || Hangul.isVowel(id)) {
                typeLetter(id, p, raw)
            } else {
                typeChar(id)
            }
        }
    }

    func keyReleased(_ id: String) {
        if id == "BACK" { stopRepeat() }
    }

    private func typeLetter(_ id: String, _ p: CGPoint, _ raw: String) {
        // 지우고 다시 친 경우: 같은 자리끼리 비교해서 배움
        if !delBuf.isEmpty && reIdx < delBuf.count && Date().timeIntervalSince(delT) < 10 {
            if let orig = delBuf[reIdx], orig.id != id, adjacent(orig.id, id), id == "ㅇ", isEndSlot() {
                // 어미 자리 실수는 따로 저장 (라면·타요의 ㄹ·ㅌ은 건드리지 않게)
                var ec = learner.endConf
                ec["\(orig.id)>\(id)", default: 0] += 1
                learner.endConf = ec
                learner.data.learned += 1
            } else if let orig = delBuf[reIdx], orig.id != id, adjacent(orig.id, id) {
                learnAt(id, orig.fx, orig.fy, 0.12)
                learner.data.conf["\(orig.id)>\(id)", default: 0] += 1
                learner.data.learned += 1
                if kv.rowOf(orig.id) == kv.rowOf(id) { learner.data.dirH += 1 } else { learner.data.dirV += 1 }
            }
            reIdx += 1
            if reIdx >= delBuf.count { clearDel() }
        } else if !delBuf.isEmpty {
            clearDel()
        }
        confirmPrev()

        var ch = id
        if kv.shift {
            ch = Hangul.shiftMap[id] ?? id
            kv.shift = false
        }
        lastAuto = nil
        tokens.append(ch)
        if learner.data.fixOn { endCheck() }
        applyTokens()
        pushHistory(TapMeta(id: id, fx: p.x, fy: p.y, ok: false))
        if raw != id { learner.data.fixes += 1 }
        learner.saveSoon()
    }

    /// 스페이스 두 번 빠르게 → ". " (아이폰 기본 키보드의 마침표 단축키)
    private var lastSpaceAt = Date.distantPast
    private func typeSpace() {
        commitComposition()
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        if Date().timeIntervalSince(lastSpaceAt) < 0.6, before.hasSuffix(" "),
           let prev = before.dropLast().last, !prev.isWhitespace, !".,?!".contains(prev) {
            textDocumentProxy.deleteBackward()
            typeChar(". ")
            lastSpaceAt = .distantPast
            return
        }
        typeChar(" ")
        lastSpaceAt = Date()
    }

    private func typeChar(_ s: String) {
        confirmPrev()
        lastAuto = nil
        if !delBuf.isEmpty {
            reIdx += 1
            if reIdx >= delBuf.count { clearDel() }
        }
        commitComposition()
        textDocumentProxy.insertText(s)
        pushHistory(nil)
        learner.saveSoon()
    }

    private func backspace() {
        // 자동 어미 교정 직후 ⌫ → 원래대로 되돌리고 이 조합은 다시 안 고침
        if let la = lastAuto, tokens.count == la.idx + 2 {
            tokens[la.idx] = la.orig
            var no = learner.endNo
            no[la.key] = true
            learner.endNo = no
            lastAuto = nil
            applyTokens()
            return
        }
        lastAuto = nil
        let m: TapMeta? = history.isEmpty ? nil : history.removeLast()
        if reIdx > 0 { clearDel() }
        delBuf.insert(m, at: 0)
        if delBuf.count > 12 { delBuf.removeLast() }
        delT = Date()

        if !tokens.isEmpty {
            tokens.removeLast()
            applyTokens()
            return
        }
        // 조합 중이 아니면, 앞 글자를 자모로 풀어서 한 자모만 지움
        if let before = textDocumentProxy.documentContextBeforeInput, let last = before.last,
           let jamo = Hangul.decompose(last), jamo.count > 1 {
            composing = true
            textDocumentProxy.deleteBackward()
            tokens = Array(jamo.dropLast())
            shown = ""
            composing = false
            applyTokens()
        } else {
            textDocumentProxy.deleteBackward()
        }
    }

    // MARK: - 한글 조합

    private func applyTokens() {
        composing = true
        let new = Hangul.assemble(tokens)
        let o = Array(shown), n = Array(new)
        var i = 0
        while i < o.count && i < n.count && o[i] == n[i] { i += 1 }
        for _ in i..<o.count { textDocumentProxy.deleteBackward() }
        if i < n.count { textDocumentProxy.insertText(String(n[i...])) }
        shown = new
        // 길게 이어 치면 마지막 글자만 조합 중으로 남김
        if tokens.count > 30, let lastCh = n.last, let j = Hangul.decompose(lastCh) {
            tokens = j
            lastAuto = nil
            shown = String(lastCh)
        }
        composing = false
    }

    private func commitComposition() {
        tokens = []
        shown = ""
    }

    private func checkExternalChange() {
        guard !composing, !shown.isEmpty else { return }
        if let before = textDocumentProxy.documentContextBeforeInput, !before.hasSuffix(shown) {
            commitComposition()
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        checkExternalChange()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        checkExternalChange()
    }

    // MARK: - 학습

    private func pushHistory(_ m: TapMeta?) {
        history.append(m)
        if history.count > 80 { history.removeFirst() }
    }

    private func confirmPrev() {
        guard let last = history.last, var m = last, !m.ok else { return }
        learnAt(m.id, m.fx, m.fy, 0.04)
        m.ok = true
        history[history.count - 1] = m
        learner.data.taps += 1
    }

    private func clearDel() {
        delBuf = []
        reIdx = 0
    }

    private func learnAt(_ id: String, _ fx: CGFloat, _ fy: CGFloat, _ rate: Double) {
        guard let f = kv.frameOf(id), f.width > 0, f.height > 0 else { return }
        let x = fx * kv.bounds.width, y = fy * kv.bounds.height
        learner.learn(id, ox: Double((x - f.midX) / f.width), oy: Double((y - f.midY) / f.height), rate: rate)
    }

    private func adjacent(_ a: String, _ b: String) -> Bool {
        guard let fa = kv.frameOf(a), let fb = kv.frameOf(b), fa.width > 0, fa.height > 0 else { return false }
        return hypot((fa.midX - fb.midX) / fa.width, (fa.midY - fb.midY) / fa.height) < 1.7
    }

    // MARK: - 길게 눌러 지우기

    private func startRepeat() {
        stopRepeat()
        perform(#selector(beginRepeat), with: nil, afterDelay: 0.42)
    }

    @objc private func beginRepeat() {
        repeatTimer = Timer.scheduledTimer(timeInterval: 0.07, target: self, selector: #selector(repeatTick), userInfo: nil, repeats: true)
    }

    @objc private func repeatTick() { backspace() }

    private func stopRepeat() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(beginRepeat), object: nil)
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}
