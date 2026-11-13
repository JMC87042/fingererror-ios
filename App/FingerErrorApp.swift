import SwiftUI

@main
struct FingerErrorApp: App {
    init() { ThemeFont.register() }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var text = ""
    @State private var themeId = ThemeStore.currentId()
    @State private var predictOn = ThemeStore.bool("fe.predict")
    @State private var capId = KBTheme.caps.contains { $0.id == ThemeStore.capId() } ? ThemeStore.capId() : "jelly"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        ReportView()
                    } label: {
                        HStack(spacing: 12) {
                            Text("📊").font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("내 엄지 리포트").font(.custom(ThemeFont.name, size: 19))
                                Text("고친 오타 · 자주 헷갈리는 키 · 받은 기념일").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("키보드 켜는 법") {
                    Text("1. 설정 → 일반 → 키보드 → 키보드")
                    Text("2. 새로운 키보드 추가 → 핑거에러")
                    Text("3. 입력할 때 🌐 버튼으로 핑거에러로 바꾸기")
                    Text("한/A 키: 한글↔영어 · 꾹 누르면 다른 키보드로")
                    Button("설정 열기") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Section {
                    Toggle("예측 단어 (키보드 위 후보 3칸)", isOn: $predictOn)
                        .onChange(of: predictOn) { v in ThemeStore.setBool("fe.predict", v) }
                } header: {
                    Text("자동 단어").font(.custom(ThemeFont.name, size: 15))
                } footer: {
                    Text("켜면 치는 중인 단어와 다음에 올 말을 추천해요. 후보를 꾹 누르면 지워져요. 기록은 이 폰 안에만 저장돼요.")
                }
                Section {
                    Picker("키캡 모양", selection: $capId) {
                        ForEach(KBTheme.caps, id: \.id) { c in Text(c.name).tag(c.id) }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: capId) { v in ThemeStore.saveCap(v) }
                } header: {
                    Text("키캡 모양 · 모든 테마에 적용").font(.custom(ThemeFont.name, size: 15))
                }
                ForEach([("color", "테마 \(KBTheme.mainList.count)가지 · 키캡 모양 적용"), ("special", "버건디 스페셜")], id: \.0) { g in
                    Section {
                        ForEach(KBTheme.all.filter { $0.group == g.0 }, id: \.id) { t in
                            Button {
                                ThemeStore.save(t.id)
                                themeId = t.id
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(t.name).font(.custom(ThemeFont.name, size: 19)).foregroundStyle(.primary)
                                        Spacer()
                                        if themeId == t.id {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        }
                                    }
                                    Image("theme_" + KBTheme.previewName(t, cap: capId))
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(themeId == t.id ? Color.green : Color.clear, lineWidth: 3)
                                        )
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(g.1).font(.custom(ThemeFont.name, size: 15))
                    } footer: {
                        if g.0 == "color" {
                            Text("색만 바뀌고 학습 기록은 그대로예요. 키보드를 쓰다가 스페이스바 오른쪽 팻핑이를 꾹 누르면 바로 바꿀 수 있어요.")
                        }
                    }
                }
                Section("여기서 바로 연습") {
                    TextField("핑거에러로 쳐보세요", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section("학습 방식") {
                    Text("틀린 글자를 ⌫로 지우고 바로 다시 치면 그 실수를 배워요. 같은 실수가 쌓이면 자동으로 바꿔줘요. 기록은 이 폰 안에만 저장돼요.")
                        .font(.footnote)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("버전 2026.11.13 (예측 단어 켜고 끄기) · 트랙패드 커서 · 100개마다 리포트 · 한/A 영어 · 테마별 팻핑이 · 기념일").font(.caption2).foregroundStyle(.secondary).padding(4)
            }
            .navigationTitle("핑거에러")
            // 3D 젤리: 크림 배경 + 복숭아 포인트
            .scrollContentBackground(.hidden)
            .background(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.08, alpha: 1) : UIColor(red: 250/255, green: 242/255, blue: 234/255, alpha: 1) }))
            .tint(Color(red: 1, green: 0.54, blue: 0.42))
        }
    }
}
