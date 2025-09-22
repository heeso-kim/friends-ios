import Foundation
import Swinject
import Alamofire
import Moya

/// 의존성 주입 컨테이너
final class AppContainer {
    static let shared = AppContainer()
    private let container = Container()

    private init() {}

    // MARK: - Resolve

    func resolve<T>(_ type: T.Type) -> T? {
        container.resolve(type)
    }

    // MARK: - Register Dependencies

    func registerDependencies() {
        registerNetworking()
        registerServices()
        registerRepositories()
        registerUseCases()
        registerViewModels()
    }

    // MARK: - Networking

    private func registerNetworking() {
        // Alamofire Session
        container.register(Session.self) { _ in
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.headers = .default

            let interceptor = AuthInterceptor()
            return Session(configuration: configuration, interceptor: interceptor)
        }.inObjectScope(.container)

        // Moya Provider
        container.register(MoyaProvider<FriendsAPI>.self) { resolver in
            let session = resolver.resolve(Session.self)!
            let plugins: [PluginType] = [
                NetworkLoggerPlugin(configuration: .init(logOptions: .verbose)),
                AuthPlugin()
            ]
            return MoyaProvider<FriendsAPI>(session: session, plugins: plugins)
        }.inObjectScope(.container)

        // API Client
        container.register(APIClient.self) { resolver in
            let provider = resolver.resolve(MoyaProvider<FriendsAPI>.self)!
            return APIClient(provider: provider)
        }.inObjectScope(.container)
    }

    // MARK: - Services

    private func registerServices() {
        // Keychain Service
        container.register(KeychainService.self) { _ in
            KeychainServiceImpl()
        }.inObjectScope(.container)

        // Location Service
        container.register(LocationService.self) { _ in
            LocationServiceImpl()
        }.inObjectScope(.container)

        // Push Notification Service
        container.register(PushNotificationService.self) { _ in
            PushNotificationServiceImpl()
        }.inObjectScope(.container)

        // Auth Service
        container.register(AuthService.self) { resolver in
            AuthServiceImpl(
                apiClient: resolver.resolve(APIClient.self)!,
                keychainService: resolver.resolve(KeychainService.self)!
            )
        }.inObjectScope(.container)

        // User Service
        container.register(UserService.self) { resolver in
            UserServiceImpl(
                apiClient: resolver.resolve(APIClient.self)!
            )
        }.inObjectScope(.container)
    }

    // MARK: - Repositories

    private func registerRepositories() {
        // Auth Repository
        container.register(AuthRepository.self) { resolver in
            AuthRepositoryImpl(
                apiClient: resolver.resolve(APIClient.self)!,
                keychainService: resolver.resolve(KeychainService.self)!
            )
        }

        // Order Repository
        container.register(OrderRepository.self) { resolver in
            OrderRepositoryImpl(
                apiClient: resolver.resolve(APIClient.self)!
            )
        }

        // User Repository
        container.register(UserRepository.self) { resolver in
            UserRepositoryImpl(
                apiClient: resolver.resolve(APIClient.self)!
            )
        }

        // Location Repository
        container.register(LocationRepository.self) { resolver in
            LocationRepositoryImpl(
                locationService: resolver.resolve(LocationService.self)!,
                apiClient: resolver.resolve(APIClient.self)!
            )
        }
    }

    // MARK: - Use Cases

    private func registerUseCases() {
        // Auth Use Cases
        container.register(LoginUseCase.self) { resolver in
            LoginUseCase(
                repository: resolver.resolve(AuthRepository.self)!
            )
        }

        container.register(LogoutUseCase.self) { resolver in
            LogoutUseCase(
                repository: resolver.resolve(AuthRepository.self)!
            )
        }

        container.register(RefreshTokenUseCase.self) { resolver in
            RefreshTokenUseCase(
                repository: resolver.resolve(AuthRepository.self)!
            )
        }

        // Order Use Cases
        container.register(GetOrdersUseCase.self) { resolver in
            GetOrdersUseCase(
                repository: resolver.resolve(OrderRepository.self)!
            )
        }

        container.register(AcceptOrderUseCase.self) { resolver in
            AcceptOrderUseCase(
                repository: resolver.resolve(OrderRepository.self)!
            )
        }

        container.register(CompleteOrderUseCase.self) { resolver in
            CompleteOrderUseCase(
                repository: resolver.resolve(OrderRepository.self)!
            )
        }

        // User Use Cases
        container.register(GetCurrentUserUseCase.self) { resolver in
            GetCurrentUserUseCase(
                repository: resolver.resolve(UserRepository.self)!
            )
        }

        container.register(UpdateProfileUseCase.self) { resolver in
            UpdateProfileUseCase(
                repository: resolver.resolve(UserRepository.self)!
            )
        }
    }

    // MARK: - ViewModels

    private func registerViewModels() {
        // Login ViewModel
        container.register(LoginViewModel.self) { resolver in
            LoginViewModel(
                loginUseCase: resolver.resolve(LoginUseCase.self)!,
                keychainService: resolver.resolve(KeychainService.self)!
            )
        }

        // Order List ViewModel
        container.register(OrderListViewModel.self) { resolver in
            OrderListViewModel(
                getOrdersUseCase: resolver.resolve(GetOrdersUseCase.self)!,
                acceptOrderUseCase: resolver.resolve(AcceptOrderUseCase.self)!
            )
        }

        // Order Detail ViewModel
        container.register(OrderDetailViewModel.self) { resolver in
            OrderDetailViewModel(
                completeOrderUseCase: resolver.resolve(CompleteOrderUseCase.self)!
            )
        }

        // Profile ViewModel
        container.register(ProfileViewModel.self) { resolver in
            ProfileViewModel(
                getCurrentUserUseCase: resolver.resolve(GetCurrentUserUseCase.self)!,
                updateProfileUseCase: resolver.resolve(UpdateProfileUseCase.self)!,
                logoutUseCase: resolver.resolve(LogoutUseCase.self)!
            )
        }
    }
}