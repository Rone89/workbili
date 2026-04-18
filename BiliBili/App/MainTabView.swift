import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: TabType = .home
    @EnvironmentObject var appState: AppState
    
    enum TabType: Int, CaseIterable {
        case home = 0
        case popular = 1
        case dynamic = 2
        case mine = 3
        
        var title: String {
            switch self {
            case .home: return "首页"
            case .popular: return "热门"
            case .dynamic: return "动态"
            case .mine: return "我的"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .popular: return "flame.fill"
            case .dynamic: return "doc.text.fill"
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
                DynamicView()
            }
            .tabItem {
                Label(TabType.dynamic.title, systemImage: TabType.dynamic.icon)
            }
            .tag(TabType.dynamic)
            
            NavigationStack {
                MineView()
            }
            .tabItem {
                Label(TabType.mine.title, systemImage: TabType.mine.icon)
            }
            .tag(TabType.mine)
        }
        .tint(Color(hex: "FB7299")) // B站粉
    }
}
