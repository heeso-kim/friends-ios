# Vroong Friends iOS 마이그레이션 로드맵

## 📅 전체 일정

**프로젝트 기간**: 16주 (4개월)
**예상 시작일**: 2024년 12월
**MVP 출시**: 2025년 3월
**정식 출시**: 2025년 4월
**최소 iOS 버전**: iOS 17.0+ 🎯

## 🚀 iOS 17+ 선택 이유

### 기술적 이점
- **@Observable 매크로**: 상태 관리 코드 90% 감소
- **SwiftData**: Core Data 대체, 모던 데이터 저장소
- **NavigationStack**: 완벽히 안정화된 네비게이션
- **SwiftUI 5.0**: 프로덕션 레벨 안정성
- **async/await**: 완전한 동시성 지원

### 시장 점유율
- 2024년 12월: 70% 커버리지
- 2025년 3월 (MVP): 80-85% 예상
- 2025년 iOS 26 출시 후: 자연스러운 마이그레이션

## 👥 팀 구성

| 역할 | 인원 | 주요 책임 |
|------|------|-----------|
| iOS 시니어 개발자 | 2명 | 아키텍처, 코어 기능 |
| iOS 주니어 개발자 | 1명 | UI 구현, 테스트 |
| QA 엔지니어 | 1명 | 테스트 계획 및 실행 |
| DevOps 엔지니어 | 1명 | CI/CD, 배포 |
| 프로젝트 매니저 | 1명 | 일정 관리, 조율 |

## 🏗️ Phase 1: 기반 구축 (2주)

### Week 1-2: 프로젝트 초기화

#### 개발 환경 설정
- [ ] Xcode 프로젝트 생성 (iOS 17.0 minimum)
- [ ] Git 레포지토리 초기화
- [ ] 브랜치 전략 수립
- [ ] Swift 코딩 컨벤션 문서화

#### 아키텍처 구축
- [ ] Clean Architecture 레이어 구성
- [ ] @Observable 기반 상태 관리
- [ ] SwiftData 스키마 설계
- [ ] 네트워크 레이어 (async/await)

#### CI/CD 설정
- [ ] Fastlane 설정
- [ ] Jenkins 파이프라인 구성
- [ ] 코드 서명 설정
- [ ] TestFlight 연동

### 핵심 기술 스택
```swift
// iOS 17+ 전용 기능 활용
@Observable class AppState
SwiftData for persistence
NavigationStack for navigation
async/await throughout
```

### 산출물
- ✅ 기본 프로젝트 구조
- ✅ CI/CD 파이프라인
- ✅ 개발 문서

## 🔐 Phase 2: 인증 시스템 (2주)

### Week 3-4: 인증 및 사용자 관리

#### 인증 기능 (iOS 17+ 구현)
```swift
@Observable
class AuthStore {
    var user: User?
    var isAuthenticated = false

    func login(username: String, password: String) async throws {
        // async/await 기반 인증
    }
}
```

- [ ] 로그인/로그아웃 구현
- [ ] JWT 토큰 관리 (Keychain)
- [ ] 자동 로그인
- [ ] 생체 인증 (Face ID/Touch ID)

#### 사용자 관리
- [ ] 회원가입 플로우
- [ ] 비밀번호 재설정
- [ ] 프로필 관리 (SwiftData)
- [ ] 운전면허 인증

### 테스트
- [ ] Unit 테스트 (90% 커버리지)
- [ ] UI 테스트 (XCTest)
- [ ] 보안 취약점 스캔

## 📦 Phase 3: 주문 관리 (3주)

### Week 5-7: 핵심 비즈니스 로직

#### 주문 관리 (SwiftData + @Observable)
```swift
@Model
class Order {
    @Attribute(.unique) var id: UUID
    var status: OrderStatus
    var items: [OrderItem]
    var createdAt: Date
}

@Observable
class OrderStore {
    var orders: [Order] = []
    var currentOrder: Order?

    func loadOrders() async {
        // SwiftData 쿼리
    }
}
```

#### 기능 구현
- [ ] 진행중 주문 조회
- [ ] 완료 주문 이력
- [ ] 실시간 업데이트 (WebSocket)
- [ ] 주문 수락/거절
- [ ] 배송 완료 처리

#### 상태 관리 (Simplified)
- [ ] @Observable 활용
- [ ] SwiftData 영속성
- [ ] 오프라인 동기화

### 산출물
- ✅ 주문 관리 시스템
- ✅ 실시간 동기화
- ✅ 오프라인 지원

## 🗺️ Phase 4: 지도 및 위치 (3주)

### Week 8-10: 위치 기반 서비스

#### 지도 통합 (iOS 17 MapKit)
```swift
Map(position: $cameraPosition) {
    ForEach(orders) { order in
        Marker(order.address, coordinate: order.location)
    }
    UserLocation()
}
.mapStyle(.standard(elevation: .realistic))
.mapControls {
    MapUserLocationButton()
    MapCompass()
}
```

#### 구현 사항
- [ ] Naver Map SDK 통합
- [ ] Kakao Map SDK 통합 (Fallback)
- [ ] 실시간 위치 추적
- [ ] 백그라운드 위치 업데이트
- [ ] 경로 안내
- [ ] 배터리 최적화

### 테스트
- [ ] 시뮬레이터 테스트
- [ ] 실제 디바이스 필드 테스트
- [ ] 배터리 소모 측정

## 💬 Phase 5: 채팅 시스템 (2주)

### Week 11-12: Sendbird 통합

#### 채팅 기능 (SwiftUI 5.0)
```swift
struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var newMessage = ""

    var body: some View {
        ScrollView {
            ForEach(messages) { message in
                MessageBubble(message: message)
            }
        }
        .scrollPosition(id: $scrolledID)  // iOS 17+
        .safeAreaInset(edge: .bottom) {
            MessageInput(text: $newMessage)
        }
    }
}
```

#### 기능 구현
- [ ] Sendbird SDK 통합
- [ ] 실시간 메시징
- [ ] 이미지 전송
- [ ] 읽음 상태
- [ ] 푸시 알림 연동

## 🔔 Phase 6: 푸시 알림 (1주)

### Week 13: 알림 시스템

#### FCM 통합
- [ ] Firebase 설정
- [ ] APNs 인증서
- [ ] 토픽 구독
- [ ] 알림 핸들링

#### TipKit 활용 (iOS 17+)
```swift
struct OrderTip: Tip {
    var title: Text {
        Text("새로운 주문 알림")
    }
    var message: Text? {
        Text("스와이프하여 주문을 수락하세요")
    }
}
```

## 💰 Phase 7: 금융 기능 (2주)

### Week 14-15: M캐시 및 결제

#### 금융 데이터 (SwiftData)
```swift
@Model
class Transaction {
    var id: UUID
    var amount: Decimal
    var type: TransactionType
    var timestamp: Date
}

@Observable
class WalletStore {
    var balance: Decimal = 0
    var transactions: [Transaction] = []
}
```

#### 구현 사항
- [ ] M캐시 잔액 조회
- [ ] 거래 내역 (SwiftData)
- [ ] 출금 신청
- [ ] 은행 계좌 연동
- [ ] 정산 리포트

## 🚀 Phase 8: 최적화 및 배포 (1주)

### Week 16: 마무리

#### 성능 최적화
- [ ] 앱 크기 최적화 (<80MB)
- [ ] 로딩 시간 개선 (<1.5초)
- [ ] 메모리 사용 최적화
- [ ] SwiftUI 렌더링 최적화

#### 품질 보증
- [ ] 전체 회귀 테스트
- [ ] 성능 테스트 (Instruments)
- [ ] 접근성 검증
- [ ] iOS 17 특화 기능 테스트

#### 배포 준비
- [ ] App Store 메타데이터
- [ ] 스크린샷 (iOS 17 UI)
- [ ] 릴리스 노트
- [ ] TestFlight 배포

## 📊 마일스톤

| 마일스톤 | 완료일 | 주요 기능 | iOS 17 특징 |
|----------|--------|-----------|-------------|
| **M1: 기반** | Week 2 | 프로젝트 설정 | @Observable, SwiftData |
| **M2: 인증** | Week 4 | 로그인 가능 | Keychain, 생체인증 |
| **M3: MVP** | Week 10 | 주문+지도 | NavigationStack, MapKit |
| **M4: Beta** | Week 15 | 전체 기능 | TipKit, WidgetKit |
| **M5: Release** | Week 16 | App Store | iOS 17 최적화 |

## ⚠️ 리스크 관리

### 기술적 리스크

| 리스크 | 확률 | 영향 | 대응 방안 |
|--------|------|------|-----------|
| iOS 17 채택률 | 중간 | 중간 | 2025년 3월 80%+ 예상 |
| SwiftData 성숙도 | 낮음 | 중간 | Core Data 폴백 준비 |
| @Observable 학습 | 낮음 | 낮음 | 팀 교육, 간단한 API |
| iOS 26 호환성 | 낮음 | 중간 | 베타 테스트 참여 |

### 일정 리스크

| 리스크 | 대응 방안 |
|--------|-----------|
| SwiftUI 100% 구현 | 필요시 UIKit 부분 사용 |
| SwiftData 마이그레이션 | 단계적 적용 |
| iOS 26 대응 | 2025 Q2 베타 테스트 |

## 🎯 성공 지표

### 기술 지표
- ✅ 테스트 커버리지 > 90%
- ✅ 크래시율 < 0.1%
- ✅ 앱 크기 < 80MB
- ✅ 콜드 스타트 < 1.5초
- ✅ SwiftUI 비중 > 95%

### 비즈니스 지표
- ✅ 기존 Flutter 앱 기능 100% 구현
- ✅ 성능 30% 향상
- ✅ 배터리 사용량 40% 감소
- ✅ 사용자 만족도 4.5+ (App Store)

## 📈 iOS 17 활용 계획

### 즉시 활용
```swift
// @Observable 매크로
@Observable class ViewModel

// SwiftData
@Model class DataModel

// 향상된 ScrollView
.scrollPosition(id:)
.scrollTargetBehavior()

// TipKit
struct UserTip: Tip
```

### 점진적 도입
```swift
// Interactive Widgets
// StoreKit 2
// Vision Pro 지원 (미래)
```

## 🔄 개발 프로세스

### 스프린트 구성
- **스프린트 기간**: 2주
- **데일리 스탠드업**: 매일 10:00
- **스프린트 리뷰**: 격주 금요일
- **회고**: 격주 금요일

### 릴리스 주기
- **Internal**: 매주 (개발팀)
- **Alpha**: 격주 (QA팀)
- **Beta**: 매월 (TestFlight)
- **Production**: Phase 완료 시

## 💡 iOS 26 대비 전략

### 2025년 로드맵
```yaml
Q1 (1-3월):
  - iOS 17 기반 개발 완료
  - MVP 출시

Q2 (4-6월):
  - iOS 26 베타 테스트
  - Xcode 26 마이그레이션 준비

Q3 (7-9월):
  - iOS 26 정식 지원
  - 새로운 기능 활용

Q4 (10-12월):
  - iOS 26 최적화
  - 차세대 기능 개발
```

## 📝 핵심 기술 결정

### 확정 사항
- ✅ **최소 iOS**: 17.0
- ✅ **UI**: SwiftUI 5.0 (95%+)
- ✅ **데이터**: SwiftData
- ✅ **상태관리**: @Observable
- ✅ **네비게이션**: NavigationStack
- ✅ **비동기**: async/await
- ✅ **의존성 관리**: SPM 우선, CocoaPods 보조

### 기대 효과
- 코드량 40% 감소
- 개발 속도 2배 향상
- 유지보수성 대폭 개선
- 미래 기술 부채 최소화