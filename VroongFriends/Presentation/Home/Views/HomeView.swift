import SwiftUI
import MapKit

/// 홈 화면 (지도 및 주문 현황)
struct HomeView: View {
    @Binding var showingDrawer: Bool
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var showingNewOrder = false
    @State private var newOrder: Order?
    
    var body: some View {
        ZStack {
            // Map Background
            mapView
            
            // Overlay UI
            VStack {
                // Top Status Bar
                topStatusBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
                
                // Floating Cards
                VStack(spacing: 12) {
                    // New Order Alert
                    if showingNewOrder, let order = newOrder {
                        NewOrderCard(order: order) {
                            acceptOrder(order)
                        } onReject: {
                            rejectOrder(order)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Current Order Status
                    if let currentOrder = viewModel.currentOrder {
                        CurrentOrderStatusCard(order: currentOrder)
                            .onTapGesture {
                                viewModel.showOrderDetail = true
                            }
                    }
                    
                    // Online/Offline Toggle
                    onlineToggleButton
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $viewModel.showOrderDetail) {
            if let order = viewModel.currentOrder {
                OrderDetailView(orderId: order.id)
            }
        }
        .onAppear {
            viewModel.startLocationTracking()
            setupNewOrderListener()
        }
        .onDisappear {
            viewModel.stopLocationTracking()
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map(
            coordinateRegion: $mapRegion,
            showsUserLocation: true,
            annotationItems: viewModel.nearbyOrders
        ) { order in
            MapAnnotation(coordinate: order.pickupLocation.coordinate.clLocation.coordinate) {
                OrderMapPin(order: order)
            }
        }
        .ignoresSafeArea()
        .onReceive(locationManager.$currentLocation) { location in
            if let location = location {
                withAnimation {
                    mapRegion.center = location.coordinate
                }
            }
        }
    }
    
    // MARK: - Top Status Bar
    
    private var topStatusBar: some View {
        HStack {
            // Status Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isOnline ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                
                Text(viewModel.isOnline ? "운행중" : "오프라인")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
            )
            
            Spacer()
            
            // Today's Summary
            VStack(alignment: .trailing, spacing: 2) {
                Text("오늘")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("\(viewModel.completedOrdersToday)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wonsign")
                            .font(.system(size: 12))
                        Text(viewModel.earningsToday.formatted())
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
    
    // MARK: - Online Toggle Button
    
    private var onlineToggleButton: some View {
        Button(action: viewModel.toggleOnlineStatus) {
            HStack {
                Image(systemName: viewModel.isOnline ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 22))
                
                Text(viewModel.isOnline ? "운행 종료" : "운행 시작")
                    .font(.system(size: 16, weight: .semibold))
                
                if viewModel.isToggling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.isOnline ? AppColors.error : AppColors.brandPrimary)
            )
        }
        .disabled(viewModel.isToggling)
    }
    
    // MARK: - Methods
    
    private func setupNewOrderListener() {
        // 새 주문 알림 리스너
        NotificationCenter.default.publisher(for: .newOrderAvailable)
            .compactMap { $0.object as? Order }
            .receive(on: DispatchQueue.main)
            .sink { order in
                withAnimation(.spring()) {
                    self.newOrder = order
                    self.showingNewOrder = true
                }
                
                // 30초 후 자동으로 숨김
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    withAnimation {
                        self.showingNewOrder = false
                        self.newOrder = nil
                    }
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    private func acceptOrder(_ order: Order) {
        viewModel.acceptOrder(order)
        withAnimation {
            showingNewOrder = false
            newOrder = nil
        }
    }
    
    private func rejectOrder(_ order: Order) {
        withAnimation {
            showingNewOrder = false
            newOrder = nil
        }
    }
}