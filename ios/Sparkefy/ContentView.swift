import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if appVM.requires2FA {
                PhoneVerificationView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if !appVM.isAuthenticated {
                AuthView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                mainTabView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if appVM.showToast, let message = appVM.toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.snappy, value: appVM.showToast)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.snappy, value: appVM.isAuthenticated)
        .animation(.snappy, value: appVM.requires2FA)
        .task {
            try? await Task.sleep(for: .seconds(2))
            showSplash = false
        }
    }

    @ViewBuilder
    private var mainTabView: some View {
        @Bindable var appVM = appVM
        TabView(selection: $appVM.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
            }

            Tab("Services", systemImage: "sparkles", value: .services) {
                ServicesView()
            }

            Tab("Bookings", systemImage: "calendar", value: .bookings) {
                BookingsView()
            }

            Tab("Chat", systemImage: "message.fill", value: .chat) {
                ChatListView()
            }

            Tab("Profile", systemImage: "person.fill", value: .profile) {
                ProfileView()
            }
        }
        .tint(SparkefyTheme.primaryBlue)
    }
}
