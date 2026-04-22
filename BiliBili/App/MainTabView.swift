import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: TabType = .home
    @EnvironmentObject var appState: AppState
    
    enum TabType: Int, CaseIterable {
        case home = 0
        case popular = 1
        case mine = 2
        
        var title: String {
            switch self {
            case .home: return "首页"
            case .popular: return "热门"
            case .mine: return "我的"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .popular: return "flame.fill"
            case .mine: return "person.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(TabType.home.title, systemImage: TabType.home.icon)
            }
            .tag(TabType.home)
            
            NavigationStack {
                PopularView()
            }
            .tabItem {
                Label(TabType.popular.title, systemImage: TabType.popular.icon)
            }
            .tag(TabType.popular)
            
            NavigationStack {
                MineView()
            }
            .tabItem {
                Label(TabType.mine.title, systemImage: TabType.mine.icon)
            }
            .tag(TabType.mine)
        }
        .tint(Color(hex: "FB7299"))
    }
}

