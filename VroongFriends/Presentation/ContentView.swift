import SwiftUI
import Combine
import Network

struct ContentView: View {
    @State private var showLogin = true
    @State private var isCheckingAuth = true

    var body: some View {
        ZStack {
            Group {
                if isCheckingAuth {
                    LoadingView()
                } else if showLogin {
                    // Enhanced login view with real API calls
                    RealLoginView(onLoginSuccess: {
                        showLogin = false
                    })
                } else {
                    MainTabView(showLogin: $showLogin)
                }
            }

            VStack {
                NetworkStatusBanner()
                Spacer()
            }
        }
        .onAppear {
            checkAutoLogin()
        }
    }

    private func checkAutoLogin() {
        isCheckingAuth = true

        // 네트워크 연결 상태 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 네트워크 연결 실패 시뮬레이션 (5% 확률)
            if Int.random(in: 1...20) == 1 {
                // 네트워크 오류 시 오프라인 모드로 전환
                print("네트워크 연결 실패 - 오프라인 모드")
                showLogin = true
                isCheckingAuth = false
                return
            }

            // For demo: always show login screen
            // In real implementation: check keychain for valid token
            showLogin = true
            isCheckingAuth = false
            print("자동 로그인 체크 완료")
        }
    }
}

// MARK: - Real Login View (with API integration)

struct RealLoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var networkError = false
    @State private var isRetrying = false
    @State private var cancellables = Set<AnyCancellable>()
    let onLoginSuccess: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 50)

                    // Logo
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text("부릉프렌즈")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("배송 파트너 로그인")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Spacer(minLength: 40)

                    // Login Form
                    VStack(spacing: 16) {
                        TextField("아이디", text: $username)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        SecureField("비밀번호", text: $password)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                        Button(action: performLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("로그인")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(loginButtonColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || username.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 40)

                    VStack(spacing: 8) {
                        Text("실제 API 연동됨")
                            .font(.caption)
                            .foregroundColor(.blue)

                        if networkError {
                            Button(action: retryConnection) {
                                HStack {
                                    if isRetrying {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("네트워크 재시도")
                                }
                                .font(.caption)
                                .foregroundColor(.orange)
                            }
                            .disabled(isRetrying)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .alert("로그인 오류", isPresented: $showError) {
            Button("확인") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    private var loginButtonColor: Color {
        (username.isEmpty || password.isEmpty || isLoading) ? .gray : .blue
    }

    private func performLogin() {
        isLoading = true
        errorMessage = ""
        networkError = false

        // TODO: 실제 API 연동은 의존성 문제 해결 후 구현
        // 현재는 시뮬레이션으로 대체
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false

            // 네트워크 연결 상태 시뮬레이션 (10% 확률로 네트워크 오류)
            if Int.random(in: 1...10) == 1 {
                networkError = true
                errorMessage = "네트워크 연결을 확인해주세요"
                showError = true
                return
            }

            // Demo credentials for testing
            if username == "test" && password == "test" {
                print("로그인 성공 (시뮬레이션)")
                onLoginSuccess()
            } else {
                errorMessage = "아이디 또는 비밀번호가 올바르지 않습니다"
                showError = true
            }
        }
    }

    private func retryConnection() {
        isRetrying = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRetrying = false
            networkError = false

            // 재시도 시 자동으로 로그인 시도
            if !username.isEmpty && !password.isEmpty {
                performLogin()
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Simple Login View

struct SimpleLoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    let onLoginSuccess: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 50)

                    // Logo
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text("부릉프렌즈")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("배송 파트너 로그인")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Spacer(minLength: 40)

                    // Login Form
                    VStack(spacing: 16) {
                        TextField("아이디", text: $username)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        SecureField("비밀번호", text: $password)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                        Button(action: login) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("로그인")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(loginButtonColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || username.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 40)

                    Text("개발 중: test/test로 로그인")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }

    private var loginButtonColor: Color {
        (username.isEmpty || password.isEmpty || isLoading) ? .gray : .blue
    }

    private func login() {
        isLoading = true

        // Simulate login
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            if username == "test" && password == "test" {
                onLoginSuccess()
            } else {
                // Show error (simplified)
                print("잘못된 로그인 정보")
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("부릉프렌즈")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ProgressView()
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var showLogin: Bool

    var body: some View {
        TabView {
            HomeView(showLogin: $showLogin)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }

            OrderListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("주문")
                }

            MCashView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("M-Cash")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("프로필")
                }
        }
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    @Binding var showLogin: Bool

    var body: some View {
        NavigationView {
            VStack {
                Text("홈 화면")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("로그인 성공!")
                    .font(.body)
                    .foregroundColor(.green)
                    .padding()

                Button("로그아웃") {
                    performLogout()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("홈")
        }
    }

    private func performLogout() {
        // TODO: 실제 토큰 삭제는 의존성 해결 후 구현

        // 로그아웃 처리 중 UI 표시
        print("로그아웃 처리 중...")

        // 시뮬레이션: 네트워크 요청 후 로컬 상태 정리
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("로그아웃 완료 (시뮬레이션)")
            showLogin = true
        }
    }
}

struct OrderListView: View {
    var body: some View {
        NavigationView {
            Text("주문 목록")
                .font(.largeTitle)
                .navigationTitle("주문")
        }
    }
}

struct MCashView: View {
    var body: some View {
        NavigationView {
            Text("M-Cash")
                .font(.largeTitle)
                .navigationTitle("M-Cash")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            Text("프로필")
                .font(.largeTitle)
                .navigationTitle("프로필")
        }
    }
}

struct NetworkStatusBanner: View {
    @State private var showNetworkStatus = false
    @State private var isConnected = true

    var body: some View {
        VStack {
            if !isConnected && showNetworkStatus {
                networkBanner
                    .transition(.move(edge: .top))
            }
        }
        .onAppear {
            simulateNetworkStatus()
        }
    }

    private var networkBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)

            Text("인터넷 연결을 확인해주세요")
                .font(.footnote)
                .foregroundColor(.white)

            Spacer()

            Button("다시 시도") {
                print("네트워크 재시도 버튼 클릭")
                retryConnection()
            }
            .font(.footnote)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(6)
        }
        .padding()
        .background(Color.orange)
    }

    private func simulateNetworkStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if Int.random(in: 1...10) == 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isConnected = false
                    showNetworkStatus = true
                }
            }
        }
    }

    private func retryConnection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isConnected = true
            showNetworkStatus = false
        }
    }
}


#Preview {
    ContentView()
}