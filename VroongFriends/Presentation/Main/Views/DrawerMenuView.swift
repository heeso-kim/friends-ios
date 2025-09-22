import SwiftUI

/// Drawer 메뉴 뷰
struct DrawerMenuView: View {
    @Binding var showingDrawer: Bool
    @Binding var selectedMenuItem: DrawerMenuItem
    @StateObject private var viewModel = DrawerMenuViewModel()
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Section
            profileSection
                .padding(.top, 50)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            // Status & MCash Info
            statusSection
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Menu Items
            ScrollView {
                VStack(spacing: 0) {
                    // Main Menu Items
                    ForEach(mainMenuItems, id: \.self) { item in
                        DrawerMenuItemView(
                            item: item,
                            isSelected: selectedMenuItem == item,
                            action: {
                                selectMenuItem(item)
                            }
                        )
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    
                    // Sub Menu Items
                    ForEach(subMenuItems, id: \.self) { item in
                        DrawerMenuItemView(
                            item: item,
                            isSelected: selectedMenuItem == item,
                            action: {
                                selectMenuItem(item)
                            }
                        )
                    }
                }
            }
            
            Spacer()
            
            // Bottom Section
            bottomSection
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color.white)
        .onAppear {
            viewModel.loadUserInfo()
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let profileImage = viewModel.profileImageUrl {
                AsyncImage(url: URL(string: profileImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(AppColors.gray400)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.gray400)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.userName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(viewModel.agentNumber)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isOnline ? AppColors.success : AppColors.gray400)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.statusText)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            // MCash Balance
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("M캐시")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(viewModel.mcashBalance.formatted())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.brandPrimary)
                }
                
                Spacer()
                
                Button(action: {
                    selectMenuItem(.mcash)
                }) {
                    Text("출금")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.brandPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppColors.brandPrimary, lineWidth: 1)
                        )
                }
            }
            .padding(12)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(8)
            
            // Criminal Record Status (if needed)
            if viewModel.showCriminalRecordBanner {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    
                    Text("범죄경력회신서 제출이 필요합니다")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .onTapGesture {
                    selectMenuItem(.criminalRecord)
                }
            }
        }
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("버전")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text("v\(Environment.appVersion) (\(Environment.current.rawValue))")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Button(action: viewModel.logout) {
                Text("로그아웃")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Menu Items
    
    private var mainMenuItems: [DrawerMenuItem] {
        [.home, .orders, .selfOrders, .mcash, .mission]
    }
    
    private var subMenuItems: [DrawerMenuItem] {
        [.invite, .insurance, .friendsNews, .criminalRecord, .vroongMall, .voc, .settings]
    }
    
    // MARK: - Methods
    
    private func selectMenuItem(_ item: DrawerMenuItem) {
        selectedMenuItem = item
        withAnimation(.spring()) {
            showingDrawer = false
        }
    }
}

// MARK: - Drawer Menu Item View

struct DrawerMenuItemView: View {
    let item: DrawerMenuItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppColors.brandPrimary : AppColors.gray600)
                    .frame(width: 24)
                
                Text(item.title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.brandPrimary : AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? AppColors.brandPrimary.opacity(0.1) : Color.clear)
        }
    }
}