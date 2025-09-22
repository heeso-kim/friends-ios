import SwiftUI

/// 메인 탭 뷰
struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    @State private var selectedTab: Tab = .home
    @State private var showingNewOrder = false
    
    enum Tab: String, CaseIterable {
        case home = "홈"
        case orders = "주문"
        case earnings = "수익"
        case myPage = "MY"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .orders: return "list.bullet.rectangle"
            case .earnings: return "wonsign.circle.fill"
            case .myPage: return "person.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            OrderListView()
                .tabItem {
                    Label(Tab.orders.rawValue, systemImage: Tab.orders.icon)
                }
                .tag(Tab.orders)
                .badge(appState.pendingOrderCount > 0 ? "\(appState.pendingOrderCount)" : nil)
            
            EarningsView()
                .tabItem {
                    Label(Tab.earnings.rawValue, systemImage: Tab.earnings.icon)
                }
                .tag(Tab.earnings)
            
            MyPageView()
                .tabItem {
                    Label(Tab.myPage.rawValue, systemImage: Tab.myPage.icon)
                }
                .tag(Tab.myPage)
        }
        .tint(AppColors.brandPrimary)
        .onReceive(NotificationCenter.default.publisher(for: .newOrderAvailable)) { _ in
            showingNewOrder = true
            selectedTab = .home
        }
        .sheet(isPresented: $showingNewOrder) {
            NewOrderPopupView()
        }
    }
}

extension Notification.Name {
    static let newOrderAvailable = Notification.Name("newOrderAvailable")
}

// MARK: - Preview

#Preview {
    MainTabView()
}