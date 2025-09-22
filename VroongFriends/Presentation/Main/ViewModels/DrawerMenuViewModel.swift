import Foundation
import Combine
import SwiftUI

/// Drawer 메뉴 뷰모델
@MainActor
final class DrawerMenuViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var userName: String = ""
    @Published var agentNumber: String = ""
    @Published var profileImageUrl: String?
    @Published var isOnline: Bool = false
    @Published var statusText: String = "오프라인"
    @Published var mcashBalance: Decimal = 0
    @Published var showCriminalRecordBanner: Bool = false
    @Published var agentStatus: AgentStatus = .pending
    
    // MARK: - Properties
    
    private let userRepository: UserRepositoryProtocol
    private let paymentRepository: PaymentRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        userRepository: UserRepositoryProtocol = UserRepository(provider: NetworkProvider.shared.provider),
        paymentRepository: PaymentRepositoryProtocol = PaymentRepository(provider: NetworkProvider.shared.provider),
        authRepository: AuthRepositoryProtocol = AuthRepository(
            provider: NetworkProvider.shared.provider,
            keychainService: KeychainService()
        )
    ) {
        self.userRepository = userRepository
        self.paymentRepository = paymentRepository
        self.authRepository = authRepository
        
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // AppState 구독
        AppState.shared.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.updateUserInfo(user)
            }
            .store(in: &cancellables)
        
        AppState.shared.$isOnline
            .sink { [weak self] isOnline in
                self?.isOnline = isOnline
                self?.updateStatusText(isOnline: isOnline)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    
    func loadUserInfo() {
        // 사용자 정보 로드
        userRepository.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Logger.error("사용자 정보 로드 실패: \(error)", category: .general)
                    }
                },
                receiveValue: { [weak self] user in
                    self?.updateUserInfo(user)
                    AppState.shared.currentUser = user
                }
            )
            .store(in: &cancellables)
        
        // MCash 잔액 로드
        loadMCashBalance()
    }
    
    func loadMCashBalance() {
        paymentRepository.getMCashBalance()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Logger.error("MCash 잔액 로드 실패: \(error)", category: .general)
                    }
                },
                receiveValue: { [weak self] mcash in
                    self?.mcashBalance = mcash.balance
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        authRepository.logout()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // 실패해도 로컬 로그아웃 진행
                        self.performLocalLogout()
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.performLocalLogout()
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func updateUserInfo(_ user: User) {
        userName = user.displayName.isEmpty ? user.username : user.displayName
        agentNumber = user.agentId ?? "AGENT-\(user.id.prefix(6))"
        profileImageUrl = user.profileImageUrl
        agentStatus = user.agentStatus
        
        // 범죄경력회신서 제출 필요 여부 체크
        checkCriminalRecordStatus(user)
        
        // 상태 텍스트 업데이트
        updateStatusText(isOnline: isOnline)
    }
    
    private func updateStatusText(isOnline: Bool) {
        if isOnline {
            switch agentStatus {
            case .active:
                statusText = "운행 중"
            case .suspended:
                statusText = "일시정지"
            case .pending:
                statusText = "승인 대기"
            case .terminated:
                statusText = "종료"
            }
        } else {
            statusText = "오프라인"
        }
    }
    
    private func checkCriminalRecordStatus(_ user: User) {
        // 범죄경력회신서 제출이 필요한 경우 배너 표시
        // TODO: 실제 로직 구현 필요
        showCriminalRecordBanner = false
    }
    
    private func performLocalLogout() {
        // 로컬 데이터 초기화
        AppState.shared.currentUser = nil
        AppState.shared.isAuthenticated = false
        AppState.shared.isOnline = false
        
        // 토큰 삭제
        TokenManager.shared.clearToken()
        
        // 로그인 화면으로 이동 알림
        NotificationCenter.default.post(
            name: .userDidLogout,
            object: nil
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}