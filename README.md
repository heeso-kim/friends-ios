# VroongFriends iOS

[![Swift Version](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS Version](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Xcode Version](https://img.shields.io/badge/Xcode-16.2-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

## 📱 프로젝트 소개

VroongFriends는 배송 기사를 위한 종합 물류 관리 iOS 애플리케이션입니다. Flutter에서 iOS Native로 마이그레이션하여 더 나은 성능과 사용자 경험을 제공합니다.

### 주요 기능
- 🚚 실시간 주문 관리
- 🗺️ 네이버/카카오 맵 통합 내비게이션
- 📍 백그라운드 위치 추적
- 💬 실시간 채팅 (Sendbird)
- 💰 M캐시 및 정산 관리
- 🔔 푸시 알림

## 🛠 기술 스택

### Core
- **Language**: Swift 5.10
- **Minimum iOS**: 17.0
- **UI Framework**: SwiftUI + UIKit
- **Architecture**: Clean Architecture + MVVM + @Observable

### Dependencies
- **Networking**: Alamofire + Moya
- **DI**: Swinject
- **Database**: SwiftData
- **Maps**: Naver Map SDK, Kakao Map SDK
- **Chat**: Sendbird SDK
- **Analytics**: Firebase

## 📋 요구사항

- Xcode 16.2
- iOS 17.0+
- CocoaPods 1.12+
- Swift 5.10

## 🚀 시작하기

### 1. 레포지토리 클론
```bash
git clone https://github.com/vroong/friends-ios.git
cd friends-ios
```

### 2. 의존성 설치

#### SPM 패키지
SPM 패키지는 Xcode에서 자동으로 해결됩니다.

#### CocoaPods (맵 SDK)
```bash
pod install
```

### 3. 환경 설정
```bash
cp .env.example .env
# .env 파일을 편집하여 필요한 키 설정
```

### 4. 프로젝트 열기
```bash
open VroongFriends.xcworkspace
```

⚠️ **주의**: `.xcodeproj` 파일이 아닌 `.xcworkspace` 파일을 열어야 합니다.

## 🏗 프로젝트 구조

```
VroongFriends/
├── App/                    # 앱 진입점 및 설정
├── Core/                   # 공통 유틸리티 및 확장
├── Domain/                 # 비즈니스 로직
│   ├── Entities/          # 도메인 모델
│   ├── UseCases/          # 비즈니스 유스케이스
│   └── Repositories/      # 레포지토리 프로토콜
├── Data/                   # 데이터 레이어
│   ├── Repositories/      # 레포지토리 구현
│   ├── DataSources/       # 로컬/리모트 데이터소스
│   └── DTOs/              # Data Transfer Objects
├── Presentation/          # UI 레이어
│   ├── Features/          # 기능별 UI
│   ├── Common/            # 공통 UI 컴포넌트
│   └── Navigation/        # 네비게이션 관리
└── Infrastructure/        # 인프라 서비스
    ├── Network/           # 네트워킹
    ├── Location/          # 위치 서비스
    └── Push/              # 푸시 알림
```

## 📱 환경별 설정

### Development
```bash
fastlane ios test
```

### Beta (TestFlight)
```bash
fastlane ios beta
```

### Production (App Store)
```bash
fastlane ios release
```

## 🧪 테스트

### Unit Tests
```bash
fastlane ios test
```

### UI Tests
```bash
xcodebuild test -workspace VroongFriends.xcworkspace \
  -scheme VroongFriends \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Code Coverage
테스트 실행 후 Xcode에서 확인하거나:
```bash
open build/reports/coverage/index.html
```

## 🔍 코드 품질

### SwiftLint
```bash
swiftlint
```

### SwiftFormat
```bash
swiftformat .
```

## 🚢 배포

### TestFlight
1. 빌드 번호 증가
2. 아카이브 생성
3. TestFlight 업로드

```bash
fastlane ios beta
```

### App Store
```bash
fastlane ios release
```

## 📖 개발 가이드

### 브랜치 전략
- `main`: 프로덕션 릴리스
- `develop`: 개발 브랜치
- `feature/*`: 기능 개발
- `bugfix/*`: 버그 수정
- `release/*`: 릴리스 준비

### 커밋 메시지 컨벤션
```
type(scope): subject

body

footer
```

Types:
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 수정
- `style`: 코드 스타일 변경
- `refactor`: 리팩토링
- `test`: 테스트 추가/수정
- `chore`: 빌드 프로세스 등 기타 변경

### 코드 리뷰 체크리스트
- [ ] 코드가 컴파일되는가?
- [ ] 테스트가 통과하는가?
- [ ] SwiftLint 규칙을 준수하는가?
- [ ] 적절한 문서화가 되어있는가?
- [ ] 성능 이슈가 없는가?

## 🐛 디버깅

### Charles Proxy 설정
```swift
// AppDelegate.swift
#if DEBUG
setenv("CHARLES_PROXY_IP", "YOUR_IP:8888", 1)
#endif
```

### 로그 레벨 설정
```swift
Logger.shared.level = .debug
```

## 📱 지원 디바이스

- iPhone (iOS 17.0+)
- iPad 지원 예정

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이센스

This project is proprietary and confidential.

## 📞 연락처

- 개발팀: ios-team@vroong.com
- 프로젝트 매니저: pm@vroong.com

## 🔗 관련 링크

- [API 문서](https://api-docs.vroong.com)
- [디자인 시스템](https://design.vroong.com)
- [Jira 프로젝트](https://vroong.atlassian.net)
- [Confluence 문서](https://vroong.confluence.com)

---

Made with ❤️ by Vroong iOS Team