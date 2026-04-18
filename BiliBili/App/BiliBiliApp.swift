import SwiftUI

// MARK: - App Entry
@main
struct BiliBiliApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
    
    private func setupAppearance() {
        // Global appearance settings
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userId") var userId: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("faceUrl") var faceUrl: String = ""
    @Published var cookieString: String = "" {
        didSet {
            UserDefaults.standard.set(cookieString, forKey: "cookieString")
        }
    }
    
    init() {
        self.cookieString = UserDefaults.standard.string(forKey: "cookieString") ?? ""
        // 如果有 cookie，认为已登录
        if !cookieString.isEmpty {
            _isLoggedIn = AppStorage(wrappedValue: true, "isLoggedIn")
        }
    }
    
    func logout() {
        isLoggedIn = false
        userId = ""
        username = ""
        faceUrl = ""
        cookieString = ""
        UserDefaults.standard.removeObject(forKey: "cookieString")
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isLoggedIn {
            MainTabView()
                .environmentObject(appState)
        } else {
            LoginView()
                .environmentObject(appState)
        }
    }
}
