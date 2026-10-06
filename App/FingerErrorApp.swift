import SwiftUI

@main
struct FingerErrorApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var text = ""

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
