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
    private var lastEditAt = Date.distantPast
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
        countFix(english: false)
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
        autoCap()
        // 앱에서 '데이터 초기화'를 눌렀으면 여기서 엄지 기록을 처음부터
        let rs = ThemeStore.resetStamp()
        if rs > UserDefaults.standard.double(forKey: "fe.resetDone") {
            learner.reset()
            UserDefaults.standard.set(rs, forKey: "fe.resetDone")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.kv.showToast("기록을 비웠어요", "팻핑이가 처음부터 다시 배울게요")
            }
        }
        // 예전부터 쌓인 기록이 이미 100개를 넘었으면 키보드를 열 때 바로 리포트를 올림
        if let r = learner.publishReportIfDue() {
            learner.saveNow()
            if !ThemeStore.bool("fe.toastOff") {
                let t = Anniversary.reportText(r)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.kv.showToast(t.0, t.1) }
            }
        }
        updateMenuStatus()
        // 날짜 기념일 (만난 지 22·100일 …): 그날 키보드를 처음 열 때 한 번
        if let d = learner.newDayMilestone() {
            learner.saveSoon()
            if !ThemeStore.bool("fe.toastOff") {
                let t = Anniversary.dayText(d)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.kv.showToast(t.0, t.1) }
            }
        }
    }

    /// 오타 기념일 확인 (고친 개수가 22·100·200… 에 닿으면 말풍선)
    /// 오타 기념일 + 100개마다 리포트 올리기. 팻핑이가 키보드에서 알려줌
    private func checkCountMilestone() {
        let m = learner.newCountMilestone()
        let r = learner.publishReportIfDue()
        guard m != nil || r != nil else { return }
        learner.saveNow()
        if ThemeStore.bool("fe.toastOff") { return }
        if let m = m {
            var t = Anniversary.countText(theme: kv.theme.id, n: m)
            if r != nil { t.1 = "📊 " + Anniversary.reportSub }
            kv.showToast(t.0, t.1)
        } else if let r = r {
            let t = Anniversary.reportText(r)
            kv.showToast(t.0, t.1)
        }
    }

    private func countFix(english: Bool) {
        learner.countFix(english: english)
        checkCountMilestone()
        updateMenuStatus()
    }

    private func updateMenuStatus() {
        let n = learner.totalFixes
        kv.menuStatus = "고친 오타 \(n) · 다음 리포트 \((n / 100 + 1) * 100)"
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRepeat()
        kv.closeMenu()
        commitComposition()
        learner.saveNow()
    }

    // MARK: - 키 입력

    func keyPressed(_ id: String, at p: CGPoint, raw: String) {
        switch id {
        case "SHIFT":
            if kv.page == .english {
                // 한 번: 다음 글자만 대문자 / 빠르게 두 번: 계속 대문자
                if kv.capsLock { kv.capsLock = false; kv.shift = false }
                else if kv.shift && Date().timeIntervalSince(lastShiftAt) < 0.35 { kv.capsLock = true }
                else { kv.shift.toggle() }
                lastShiftAt = Date()
            } else {
                kv.shift.toggle()
            }
        case "LANG":
            commitComposition()
            let toEnglish = !(kv.page == .english || (kv.page != .hangul && kv.letterPage == .english))
            kv.shift = false
            kv.capsLock = false
            kv.letterPage = toEnglish ? .english : .hangul
            kv.page = kv.letterPage
            autoCap()
        case "LANG_HOLD":
            // 한/A 꾹: 다른 키보드(아이폰 기본 키보드 등)로 바꾸기
            commitComposition()
            advanceToNextInputMode()
        case "BACK": backspace(); autoCap(); startRepeat()
        case "SPACE": typeSpace()
        case "RETURN": typeChar("\n")
        case "MODE":
            kv.shift = false
            if kv.page == .hangul || kv.page == .english {
                kv.letterPage = kv.page
                kv.page = .number
            } else {
                kv.page = kv.letterPage
                autoCap()
            }
        case "SYM":
            kv.page = kv.page == .symbol ? .number : .symbol
        case "GLOBE": advanceToNextInputMode()
        default:
            if kv.page == .hangul && (Hangul.isConsonant(id) || Hangul.isVowel(id)) {
                typeLetter(id, p, raw)
            } else if kv.page == .english && KeyboardView.en2ko[id] != nil {
                typeEnglish(id, p, raw)
            } else {
                typeChar(id)
            }
        }
    }

    func keyReleased(_ id: String) {
        if id == "BACK" { stopRepeat() }
    }

    private var lastShiftAt = Date.distantPast

    /// 영어: 문장 첫 글자는 자동 대문자
    private func autoCap() {
        guard kv.page == .english, !kv.capsLock else { return }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let t = before.trimmingCharacters(in: .whitespaces)
        let start = before.isEmpty || before.hasSuffix("\n") || (before.hasSuffix(" ") && (t.hasSuffix(".") || t.hasSuffix("!") || t.hasSuffix("?")))
        if start && !kv.shift { kv.shift = true }
    }

    /// 영어 한 글자 (조합 없이 바로 입력, 엄지 학습은 한글과 같은 자리로 공유)
    private func typeEnglish(_ id: String, _ p: CGPoint, _ raw: String) {
        retypeLearn(id)
        confirmPrev()
        commitComposition()
        var ch = id
        if kv.shift || kv.capsLock {
            ch = id.uppercased()
            if !kv.capsLock { kv.shift = false }
        }
        lastAuto = nil
        textDocumentProxy.insertText(ch)
        lastEditAt = Date()
        pushHistory(TapMeta(id: id, fx: p.x, fy: p.y, ok: false))
        if raw != id { countFix(english: true) }
        learner.saveSoon()
    }

    /// 지우고 다시 친 경우: 같은 자리끼리 비교해서 배움 (한글·영어 공통)
    private func retypeLearn(_ id: String) {
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
    }

    private func typeLetter(_ id: String, _ p: CGPoint, _ raw: String) {
        checkExternalChange()   // 화면에서 사라진 옛 단어를 붙잡고 있지 않게
        wholeSyllable = false
        retypeLearn(id)
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
        if raw != id { countFix(english: false) }
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
        lastEditAt = Date()
        pushHistory(nil)
        learner.saveSoon()
        autoCap()
    }

    /// ⌫가 앞 글자로 넘어갔는지 (아이폰·삼성 기본 키보드처럼: 지금 쓰던 글자만 자모 단위, 그 앞 글자는 통째로)
    private var wholeSyllable = false

    /// 지운 만큼 친 기록을 '지운 것들'로 옮김 (다시 치면 같은 자리끼리 비교해서 배움)
    private func moveToDelBuf(_ n: Int) {
        if reIdx > 0 { clearDel() }
        for _ in 0..<max(n, 1) {
            let m: TapMeta? = history.isEmpty ? nil : history.removeLast()
            delBuf.insert(m, at: 0)
        }
        while delBuf.count > 12 { delBuf.removeLast() }
        delT = Date()
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
        checkExternalChange()   // 화면엔 '다'만 있는데 옛 단어(습니다)를 지우는 일 방지

        if !tokens.isEmpty {
            let before = Hangul.assemble(tokens)
            if wholeSyllable {
                // 앞 글자는 통째로: 마지막 글자 하나가 사라질 만큼 자모를 덜어냄
                let target = String(before.dropLast())
                var k = 1
                while k < tokens.count && Hangul.assemble(Array(tokens.prefix(tokens.count - k))) != target { k += 1 }
                moveToDelBuf(k)
                tokens.removeLast(k)
            } else {
                // 지금 쓰던 글자는 자모 하나씩 (습니다 → 습니ㄷ → 습니)
                moveToDelBuf(1)
                tokens.removeLast()
                if Hangul.assemble(tokens).count < before.count { wholeSyllable = true }
            }
            applyTokens()
            return
        }
        // 이미 확정된 글자(띄어쓰기 뒤 등)는 기본 키보드처럼 한 글자씩 통째로 지움
        var n = 1
        if Date().timeIntervalSince(lastEditAt) > 0.4, repeatTimer == nil,
           let last = textDocumentProxy.documentContextBeforeInput?.last, let j = Hangul.decompose(last) {
            n = j.count
        }
        moveToDelBuf(n)
        textDocumentProxy.deleteBackward()
        lastEditAt = Date()
    }

    // MARK: - 한글 조합

    /// 조합 결과를 화면에 반영 (바뀐 글자만 지우고 다시 넣음, 밑줄·하이라이트 없음)
    private func applyTokens() {
        composing = true
        lastEditAt = Date()
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
        wholeSyllable = false
        tokens = []
        shown = ""
    }

    private func checkExternalChange() {
        // 방금 내가 글자를 바꾼 직후에는 앱이 화면 글자를 늦게 알려줄 수 있음.
        // 그때 잘못 판단해서 조합을 끊으면 "ㅇㅏㄴ"처럼 갈라지므로 무시.
        guard !composing, !shown.isEmpty, Date().timeIntervalSince(lastEditAt) > 0.35 else { return }
        // 앱이 앞 글자를 nil로 알려주는 경우가 있음 (카톡 등에서 잠깐씩).
        // nil이라고 바로 놓아주면 쓰던 글자를 자모로 못 지우고 통째로 지워짐 → 입력창이 정말 비었을 때만 놓아줌
        guard let before = textDocumentProxy.documentContextBeforeInput else {
            if !textDocumentProxy.hasText { commitComposition() }   // 카톡 전송 등으로 입력창이 비었음
            return
        }
        if !before.hasSuffix(shown) {
            // 사용자가 커서를 옮겼거나 앱이 글을 비움 → 들고 있던 단어는 놓아줌
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
        learner.countTap(english: KeyboardView.en2ko[m.id] != nil)
    }

    private func clearDel() {
        delBuf = []
        reIdx = 0
    }

    private func learnAt(_ id: String, _ fx: CGFloat, _ fy: CGFloat, _ rate: Double) {
        guard let f = kv.frameOf(id), f.width > 0, f.height > 0 else { return }
        let x = fx * kv.bounds.width, y = fy * kv.bounds.height
        learner.learn(KeyboardView.posId(id), ox: Double((x - f.midX) / f.width), oy: Double((y - f.midY) / f.height), rate: rate)
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
