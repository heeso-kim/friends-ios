# Vroong Friends Flutter 앱 분석 보고서

## 📊 프로젝트 개요

- **프로젝트명**: Vroong Friends
- **현재 버전**: 1.13.98+166
- **최소 SDK**: Flutter 3.0.0 / Dart 3.0.0
- **아키텍처**: Clean Architecture
- **상태관리**: Riverpod 2.5.1

## 🏗️ 프로젝트 구조

### 아키텍처 레이어

```
lib/
├── domain/          # 비즈니스 로직 레이어
│   ├── entity/      # 291개 도메인 엔티티
│   ├── repository/  # 레포지토리 인터페이스
│   └── usecase/     # 67개 비즈니스 유스케이스
│
├── data/            # 데이터 레이어
│   ├── datasource/  # 로컬/리모트 데이터소스
│   ├── model/       # DTO 모델
│   ├── mapper/      # 엔티티 ↔ DTO 매퍼
│   └── repository/  # 레포지토리 구현체
│
├── presentation/    # 프레젠테이션 레이어
│   ├── pages/       # UI 화면
│   ├── providers/   # 148개 Riverpod 프로바이더
│   └── navigation/  # GoRouter 네비게이션
│
└── infrastructure/  # 인프라 레이어
    ├── fcm/         # 푸시 알림
    ├── service/     # 플랫폼 서비스
    └── analytics/   # Firebase Analytics
```

### 주요 통계

- **도메인 엔티티**: 291개
- **유스케이스**: 67개
- **프로바이더**: 148개
- **외부 의존성**: 89개 패키지

## 🎯 핵심 기능 분석

### 1. 인증 및 사용자 관리

#### 기능 목록
- JWT 기반 로그인/로그아웃
- 액세스 토큰 / 리프레시 토큰 관리
- 비밀번호 재설정 및 변경
- 사용자 프로필 관리
- 운전면허 인증
- 안전모 사진 인증
- 전자 서명 및 약관 동의

#### 관련 유스케이스
```dart
- LoginUseCase
- LogoutUseCase
- ResetPasswordUseCase
- ChangePasswordUseCase
- GetLoggedInUserUseCase
- UpdateUserProfileUseCase
```

### 2. 주문 관리 시스템

#### 기능 목록
- 주문 목록 조회 (진행중/완료)
- 주문 상세정보 조회
- 주문 수락/거절
- 주문 상태 업데이트
- 주문 완료 처리
- 셀프 주문 기능
- 주문 취소 및 수정

#### 관련 유스케이스
```dart
- GetInprogressOrdersUseCase
- GetCompletedOrdersUseCase
- AcceptOrderUseCase
- UpdateOrderStatusUseCase
- CompleteOrderUseCase
- GetOrderDetailsUseCase
```

### 3. 위치 서비스

#### 기능 목록
- 실시간 GPS 추적
- 백그라운드 위치 업데이트
- 위치 권한 관리
- 위치 진행률 추적
- 지오펜싱
- 경로 기록

#### 관련 유스케이스
```dart
- StartLocationServiceUseCase
- StopLocationServiceUseCase
- UpdateLocationProgressUseCase
- GetLastLocationProgressUseCase
- CheckLocationPermissionUseCase
```

### 4. 지도 통합

#### 듀얼 맵 시스템
- **네이버 맵**: 메인 지도 서비스
- **카카오 맵**: 보조 지도 서비스

#### 기능 목록
- 실시간 위치 표시
- 경로 안내
- 매장 위치 표시
- 다중 마커 관리
- 지도 제스처 처리

### 5. 실시간 채팅 (Sendbird)

#### 기능 목록
- 1:1 채팅
- 그룹 채팅
- 실시간 메시지 송수신
- 읽음 상태 관리
- 푸시 알림 연동
- 미디어 전송

### 6. 결제 및 금융 관리

#### M캐시 시스템
- 잔액 조회
- 입출금 내역
- 출금 신청
- 은행 계좌 연동

#### 관련 유스케이스
```dart
- GetMcashBalanceUseCase
- GetMcashEntriesUseCase
- WithdrawMcashUseCase
- SetMcashWithdrawAccountUseCase
```

## 📦 주요 의존성 분석

### 상태 관리 및 아키텍처
| 패키지 | 버전 | 용도 |
|--------|------|------|
| flutter_riverpod | 2.5.1 | 상태 관리 |
| riverpod_annotation | 2.3.4 | 코드 생성 |
| freezed | 2.4.7 | 불변 객체 |
| go_router | 12.1.1 | 네비게이션 |

### 네트워킹
| 패키지 | 버전 | 용도 |
|--------|------|------|
| dio | 5.4.0 | HTTP 클라이언트 |
| retrofit | 4.0.3 | REST API |
| connectivity_plus | 6.0.5 | 네트워크 상태 |

### 플랫폼 기능
| 패키지 | 버전 | 용도 |
|--------|------|------|
| camera | 0.10.5+4 | 카메라 |
| image_picker | 1.0.4 | 이미지 선택 |
| permission_handler | 11.1.0 | 권한 관리 |
| background_locator_2 | git | 백그라운드 위치 |

### 지도 서비스
| 패키지 | 경로 | 용도 |
|--------|------|------|
| flutter_naver_map | packages/flutter_naver_map | 네이버 맵 |
| kakao_map_sdk | packages/flutter_kakao_maps | 카카오 맵 |

### 메시징 및 알림
| 패키지 | 버전 | 용도 |
|--------|------|------|
| sendbird_chat_sdk | 4.4.1 | 채팅 |
| firebase_messaging | 15.2.5 | FCM |
| flutter_local_notifications | 19.2.1 | 로컬 알림 |

### Firebase 서비스
| 패키지 | 버전 | 용도 |
|--------|------|------|
| firebase_core | 3.13.0 | Firebase 초기화 |
| firebase_analytics | 11.4.5 | 애널리틱스 |
| firebase_crashlytics | 4.3.5 | 크래시 리포팅 |
| firebase_remote_config | 5.4.3 | 원격 설정 |

## 🔄 데이터 플로우

### 상태 관리 패턴
```
View → Provider → UseCase → Repository → DataSource
         ↓                                    ↓
      State ←─────── Entity ←──── Model ←── API/DB
```

### Provider 타입 분석
- **Repository Providers**: 38개 (싱글톤)
- **UseCase Providers**: 67개
- **State Notifiers**: 43개
- **Stream Providers**: 12개

## 🎯 iOS 마이그레이션 우선순위

### Phase 1 - MVP (필수)
1. 인증 시스템
2. 주문 목록 및 상세
3. 기본 위치 추적
4. 푸시 알림

### Phase 2 - 핵심 기능
1. 네이버 맵 통합
2. 백그라운드 위치 추적
3. Sendbird 채팅
4. M캐시 기본 기능

### Phase 3 - 완전한 기능
1. 카카오 맵 추가
2. 고급 금융 기능
3. 미션 시스템
4. 프로모션 관리

## 📝 마이그레이션 고려사항

### 기술적 도전과제
1. **백그라운드 위치 추적**: iOS의 엄격한 백그라운드 제한
2. **듀얼 맵 시스템**: 두 개의 맵 SDK 동시 관리
3. **복잡한 상태 관리**: 148개 프로바이더의 iOS 변환
4. **실시간 기능**: 위치, 채팅, 주문 상태의 실시간 동기화

### 보안 고려사항
1. RSA 암호화 구현
2. Keychain 통합
3. 생체 인증
4. 안전 디바이스 체크

### 성능 최적화 포인트
1. 이미지 캐싱 전략
2. 네트워크 요청 최적화
3. 메모리 관리
4. 배터리 효율성

## 📊 프로젝트 규모 추정

- **예상 iOS 코드 라인**: 50,000-70,000 라인
- **예상 개발 기간**: 12-16주
- **필요 인력**: iOS 개발자 2-3명
- **테스트 커버리지 목표**: 90%