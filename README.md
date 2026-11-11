# 핑거에러 키보드 (iOS)

쓸수록 내 엄지에 맞춰지는 한글 두벌식 키보드.
틀린 글자를 ⌫로 지우고 다시 치면 그 실수를 배워서, 같은 실수를 자동으로 바꿔줍니다.
학습 기록은 폰 안에만 저장되고 인터넷을 쓰지 않습니다 (전체 접근 허용 불필요).

## 1. GitHub에서 빌드 (upload.bat 더블클릭으로 자동 업로드 가능)
1. github.com에서 새 저장소 만들기 (Public 추천: 빌드 시간 무제한 무료)
2. "uploading an existing file"로 이 폴더 안의 내용 전체를 끌어다 올리기 (.github 폴더 포함)
3. Actions 탭에서 "Build IPA"가 끝날 때까지 기다리기 (5~10분)
4. 완료된 실행을 눌러 아래 Artifacts의 FingerError-ipa 다운로드 → 압축 풀면 FingerError.ipa

## 2. 윈도우에서 설치 (Sideloadly)
1. 애플 홈페이지 버전 iTunes, iCloud 설치 (Microsoft Store 버전 X)
2. sideloadly.io에서 Sideloadly 설치
3. 아이폰을 USB로 연결하고 "이 컴퓨터 신뢰"
4. Sideloadly에 FingerError.ipa를 끌어다 놓고 Apple ID 입력 → Start

## 3. 아이폰 설정
1. 설정 → 개인정보 보호 및 보안 → 개발자 모드 켜기 (재시동)
2. 설정 → 일반 → VPN 및 기기 관리 → 내 Apple ID 신뢰
3. 설정 → 일반 → 키보드 → 키보드 → 새로운 키보드 추가 → 핑거에러
4. 입력할 때 🌐로 핑거에러 선택

무료 Apple ID는 7일마다 다시 설치해야 합니다 (Sideloadly 자동 갱신 사용 가능).
