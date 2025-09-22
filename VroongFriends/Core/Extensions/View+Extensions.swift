import SwiftUI

extension View {
    // MARK: - Conditional Modifiers

    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<Value, Transform: View>(
        _ value: Value?,
        transform: (Self, Value) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    // MARK: - Loading Overlay

    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding(30)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                }
            }
        }
    }

    // MARK: - Error Alert

    func errorAlert(_ error: Binding<AppError?>) -> some View {
        self.alert(
            "오류",
            isPresented: .constant(error.wrappedValue != nil),
            presenting: error.wrappedValue
        ) { _ in
            Button("확인") {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // MARK: - Keyboard

    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    func onTapToHideKeyboard() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }

    // MARK: - Navigation

    func navigationBarColor(_ color: Color) -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(color)

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    // MARK: - Corner Radius

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        self.clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    // MARK: - Shadow

    func softShadow(
        color: Color = .black,
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.shadow(
            color: color.opacity(0.15),
            radius: radius,
            x: x,
            y: y
        )
    }

    // MARK: - Animations

    func fadeIn(duration: Double = 0.3) -> some View {
        self
            .opacity(1)
            .animation(.easeIn(duration: duration), value: UUID())
    }

    func slideIn(from edge: Edge = .bottom, duration: Double = 0.3) -> some View {
        self
            .transition(.move(edge: edge))
            .animation(.easeOut(duration: duration), value: UUID())
    }

    // MARK: - Validation

    func validate(_ isValid: Bool, borderColor: Color = .red) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isValid ? Color.clear : borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Custom Shapes

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Modifiers

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}