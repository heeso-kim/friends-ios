import SwiftUI

/// 메인 컨테이너 뷰 (Drawer 포함)
struct MainContainerView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingDrawer = false
    @State private var selectedMenuItem: DrawerMenuItem = .home
    @State private var dragOffset = CGSize.zero
    
    private let drawerWidth: CGFloat = 280
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main Content
                mainContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: showingDrawer ? drawerWidth : 0)
                    .overlay(
                        // 사이드 메뉴 열려있을 때 배경 딜멜 처리
                        Group {
                            if showingDrawer {
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            showingDrawer = false
                                        }
                                    }
                            }
                        }
                    )
                
                // Drawer Menu
                HStack(spacing: 0) {
                    DrawerMenuView(
                        showingDrawer: $showingDrawer,
                        selectedMenuItem: $selectedMenuItem
                    )
                    .frame(width: drawerWidth)
                    .offset(x: showingDrawer ? 0 : -drawerWidth)
                    
                    Spacer()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 왼쪽에서 오른쪽으로 드래그 - Drawer 열기
                        if value.startLocation.x < 20 && value.translation.width > 0 {
                            dragOffset = value.translation
                            if dragOffset.width > 50 {
                                withAnimation(.spring()) {
                                    showingDrawer = true
                                }
                            }
                        }
                        // 오른쪽에서 왼쪽으로 드래그 - Drawer 닫기
                        else if showingDrawer && value.translation.width < 0 {
                            if abs(value.translation.width) > 50 {
                                withAnimation(.spring()) {
                                    showingDrawer = false
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        dragOffset = .zero
                    }
            )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            Group {
                switch selectedMenuItem {
                case .home:
                    HomeView(showingDrawer: $showingDrawer)
                case .orders:
                    OrderListView()
                case .selfOrders:
                    SelfOrderListView()
                case .mcash:
                    MCashView()
                case .mission:
                    MissionView()
                case .invite:
                    InviteFriendsView()
                case .insurance:
                    InsuranceView()
                case .friendsNews:
                    FriendsNewsView()
                case .criminalRecord:
                    CriminalRecordView()
                case .vroongMall:
                    VroongMallView()
                case .voc:
                    VOCView()
                case .settings:
                    SettingsView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring()) {
                            showingDrawer.toggle()
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(selectedMenuItem.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
}

// MARK: - Drawer Menu Item

enum DrawerMenuItem: String, CaseIterable {
    case home = "홈"
    case orders = "주문"
    case selfOrders = "셀프 주문"
    case mcash = "M캐시"
    case mission = "미션"
    case invite = "친구 초대"
    case insurance = "보험"
    case friendsNews = "프렌즈 소식"
    case criminalRecord = "범죄경력회신서"
    case vroongMall = "부릉몰"
    case voc = "VOC"
    case settings = "설정"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .orders: return "list.bullet.rectangle"
        case .selfOrders: return "person.badge.plus"
        case .mcash: return "wonsign.circle.fill"
        case .mission: return "target"
        case .invite: return "person.2.fill"
        case .insurance: return "shield.fill"
        case .friendsNews: return "newspaper.fill"
        case .criminalRecord: return "doc.text.fill"
        case .vroongMall: return "cart.fill"
        case .voc: return "bubble.left.and.bubble.right.fill"
        case .settings: return "gearshape.fill"
        }
    }
}