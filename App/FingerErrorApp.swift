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

    var body: some View {
        NavigationStack {
            Form {
                Section("키보드 켜는 법") {
                    Text("1. 설정 → 일반 → 키보드 → 키보드")
                    Text("2. 새로운 키보드 추가 → 핑거에러")
                    Text("3. 입력할 때 🌐 버튼으로 핑거에러로 바꾸기")
                    Button("설정 열기") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Section {
                    ForEach(KBTheme.all, id: \.id) { t in
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
                                Image("theme_\(t.id)")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    Text("키보드 테마").font(.custom(ThemeFont.name, size: 15))
                } footer: {
                    Text("색만 바뀌고 학습 기록은 그대로예요. 기본 테마는 다크모드를 따라가요. 키보드를 쓰다가 스페이스바의 팻핑이를 꾹 누르면 바로 바꿀 수 있어요.")
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
            .navigationTitle("핑거에러")
        }
    }
}
