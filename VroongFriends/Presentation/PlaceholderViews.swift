import SwiftUI

// MARK: - Mission View

struct MissionView: View {
    var body: some View {
        ContentUnavailableView(
            "미션",
            systemImage: "target",
            description: Text("미션 기능이 곧 추가됩니다")
        )
        .navigationTitle("미션")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Invite Friends View

struct InviteFriendsView: View {
    var body: some View {
        ContentUnavailableView(
            "친구 초대",
            systemImage: "person.2.fill",
            description: Text("친구를 초대하고 보상을 받으세요")
        )
        .navigationTitle("친구 초대")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Insurance View

struct InsuranceView: View {
    var body: some View {
        ContentUnavailableView(
            "보험",
            systemImage: "shield.fill",
            description: Text("보험 정보가 여기에 표시됩니다")
        )
        .navigationTitle("보험")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Friends News View

struct FriendsNewsView: View {
    var body: some View {
        ContentUnavailableView(
            "프렌즈 소식",
            systemImage: "newspaper.fill",
            description: Text("프렌즈 소식이 곧 업데이트됩니다")
        )
        .navigationTitle("프렌즈 소식")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Criminal Record View

struct CriminalRecordView: View {
    var body: some View {
        ContentUnavailableView(
            "범죄경력회신서",
            systemImage: "doc.text.fill",
            description: Text("범죄경력회신서 관리")
        )
        .navigationTitle("범죄경력회신서")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Vroong Mall View

struct VroongMallView: View {
    var body: some View {
        ContentUnavailableView(
            "부릉몰",
            systemImage: "cart.fill",
            description: Text("부릉몰에서 쇼핑하세요")
        )
        .navigationTitle("부릉몰")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - VOC View

struct VOCView: View {
    var body: some View {
        ContentUnavailableView(
            "VOC",
            systemImage: "bubble.left.and.bubble.right.fill",
            description: Text("고객의 소리를 들려주세요")
        )
        .navigationTitle("VOC")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            // Profile Section
            Section("프로필") {
                NavigationLink(destination: ProfileEditView()) {
                    Label("프로필 편집", systemImage: "person.circle")
                }

                NavigationLink(destination: VehicleSettingsView()) {
                    Label("차량 정보", systemImage: "car.fill")
                }

                NavigationLink(destination: DriverLicenseView()) {
                    Label("운전면허", systemImage: "creditcard")
                }
            }

            // App Settings Section
            Section("앱 설정") {
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("알림 설정", systemImage: "bell")
                }

                NavigationLink(destination: LanguageSettingsView()) {
                    Label("언어 설정", systemImage: "globe")
                }

                Toggle(isOn: $viewModel.isDarkMode) {
                    Label("다크 모드", systemImage: "moon.fill")
                }
            }

            // Support Section
            Section("지원") {
                NavigationLink(destination: FAQView()) {
                    Label("자주 묻는 질문", systemImage: "questionmark.circle")
                }

                NavigationLink(destination: ContactSupportView()) {
                    Label("고객 지원", systemImage: "headphones")
                }

                NavigationLink(destination: TermsView()) {
                    Label("이용약관", systemImage: "doc.text")
                }

                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("개인정보처리방침", systemImage: "lock.shield")
                }
            }

            // Account Section
            Section("계정") {
                Button(action: viewModel.logout) {
                    Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }

                Button(action: viewModel.deleteAccount) {
                    Label("회원 탈퇴", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }

            // Version Info
            Section {
                HStack {
                    Text("버전")
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Settings ViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isDarkMode: Bool = false

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    func logout() {
        // TODO: 로그아웃 로직
        Logger.info("로그아웃", category: .auth)
    }

    func deleteAccount() {
        // TODO: 회원 탈퇴 로직
        Logger.info("회원 탈퇴 요청", category: .auth)
    }
}

// MARK: - Settings Sub Views (Placeholders)

struct ProfileEditView: View {
    var body: some View {
        Text("프로필 편집")
            .navigationTitle("프로필 편집")
    }
}

struct VehicleSettingsView: View {
    var body: some View {
        Text("차량 정보")
            .navigationTitle("차량 정보")
    }
}

struct DriverLicenseView: View {
    var body: some View {
        Text("운전면허")
            .navigationTitle("운전면허")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("알림 설정")
            .navigationTitle("알림 설정")
    }
}

struct LanguageSettingsView: View {
    var body: some View {
        Text("언어 설정")
            .navigationTitle("언어 설정")
    }
}

struct FAQView: View {
    var body: some View {
        Text("자주 묻는 질문")
            .navigationTitle("FAQ")
    }
}

struct ContactSupportView: View {
    var body: some View {
        Text("고객 지원")
            .navigationTitle("고객 지원")
    }
}

struct TermsView: View {
    var body: some View {
        Text("이용약관")
            .navigationTitle("이용약관")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("개인정보처리방침")
            .navigationTitle("개인정보처리방침")
    }
}