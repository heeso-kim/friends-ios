import SwiftUI

/// 로그인 화면
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username
        case password
    }
    
    init(viewModel: LoginViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                logoSection
                    .padding(.bottom, 60)
                
                // Login Form
                loginForm
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Version Info
                versionInfo
                    .padding(.bottom, 20)
            }
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            
            VStack(spacing: 4) {
                Text("부릉프렌즈")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("빠르고 안전한 배송")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    // MARK: - Login Form
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                Text("아이디")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 20)
                    
                    TextField("아이디를 입력하세요", text: $viewModel.username)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                    
                    if !viewModel.username.isEmpty {
                        Button(action: viewModel.clearUsername) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.isValidUsername ? Color.clear : Color.red,
                            lineWidth: 1
                        )
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("비밀번호")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 20)
                    
                    if viewModel.isPasswordVisible {
                        TextField("비밀번호를 입력하세요", text: $viewModel.password)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                viewModel.login()
                            }
                    } else {
                        SecureField("비밀번호를 입력하세요", text: $viewModel.password)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                viewModel.login()
                            }
                    }
                    
                    Button(action: viewModel.togglePasswordVisibility) {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.isValidPassword ? Color.clear : Color.red,
                            lineWidth: 1
                        )
                )
            }
            
            // Save Username Checkbox
            HStack {
                Button(action: viewModel.toggleSaveUsername) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.state.isUsernameSaved ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.state.isUsernameSaved ? .white : .white.opacity(0.6))
                            .font(.system(size: 18))

                        Text("아이디 저장")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                Spacer()
            }
            .padding(.top, 8)

            // Login Button
            Button(action: viewModel.login) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("로그인")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.isLoginButtonEnabled ?
                    Color.white : Color.white.opacity(0.3)
                )
                .foregroundColor(
                    viewModel.isLoginButtonEnabled ?
                    Color("BrandPrimary") : Color.white.opacity(0.6)
                )
                .cornerRadius(12)
            }
            .disabled(!viewModel.isLoginButtonEnabled)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Version Info
    
    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text(Environment.current.rawValue.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text("v\(Environment.appVersion) (\(Environment.buildNumber))")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}