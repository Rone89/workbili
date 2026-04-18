import SwiftUI

// MARK: - Mine View (Profile)
struct MineView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MineViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile header
                profileHeader
                
                // Stats bar
                if let stats = viewModel.userInfo?.stat, appState.isLoggedIn {
                    statsBar(stats: stats)
                }
                
                // Menu sections
                VStack(spacing: 16) {
                    // Media section
                    menuSection("我的媒体") {
                        MenuItemView(icon: "clock.fill", title: "历史记录", color: .blue) {}
                        MenuItemView(icon: "heart.fill", title: "我的收藏", color: .pink) {}
                        MenuItemView(icon: "bookmark.fill", title: "稍后再看", color: .orange) {}
                        MenuItemView(icon: "arrow.down.circle.fill", title: "离线缓存", color: .green) {}
                    }
                    
                    // Service section
                    menuSection("更多服务") {
                        MenuItemView(icon: "wallet.pass", title: "我的大会员", color: .orange) {}
                        MenuItemView(icon: "bag.fill", title: "个性装扮", color: .purple) {}
                        MenuItemView(icon: "ticket.fill", title: "直播中心", color: .pink) {}
                        MenuItemView(icon: "gearshape.fill", title: "设置", color: .gray) {
                            viewModel.showSettings = true
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("我的")
        .sheet(isPresented: $viewModel.showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(appState)
            }
        }
        .task {
            if appState.isLoggedIn {
                await viewModel.loadUserInfo()
            }
        }
        .refreshable {
            if appState.isLoggedIn {
                await viewModel.loadUserInfo()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            if let face = viewModel.userInfo?.face, !face.isEmpty {
                BiliAsyncImage(url: face)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.bilibiliPink, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.userInfo?.name ?? "未登录")
                    .font(.title3)
                    .fontWeight(.bold)
                
                if let sign = viewModel.userInfo?.sign, !sign.isEmpty {
                    Text(sign)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Level badge
                if let level = viewModel.userInfo?.level {
                    HStack(spacing: 4) {
                        Text("LV\(level)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(levelGradient(level))
                            .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
            
            // Edit profile button
            if appState.isLoggedIn {
                Button {
                    // Navigate to edit profile
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Stats Bar
    private func statsBar(stats: UserNavStat) -> some View {
        HStack(spacing: 0) {
            statItem(title: "关注", count: stats.following)
            statItem(title: "粉丝", count: stats.follower)
            statItem(title: "等级", count: 0, text: "LV\(viewModel.userInfo?.level ?? 0)")
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private func statItem(title: String, count: Int, text: String? = nil) -> some View {
        VStack(spacing: 4) {
            Text(text ?? formatPlayCount(count))
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Level Gradient
    private func levelGradient(_ level: Int) -> LinearGradient {
        switch level {
        case 0...1: return LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
        case 2: return LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
        case 3: return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        case 4: return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        case 5: return LinearGradient(colors: [.pink, Color.bilibiliPink], startPoint: .leading, endPoint: .trailing)
        default: return LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    // MARK: - Menu Section
    private func menuSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        
        if title != "离线缓存" && title != "设置" {
            Divider()
                .padding(.leading, 54)
        }
    }
}

// MARK: - Mine ViewModel
class MineViewModel: ObservableObject {
    @Published var userInfo: UserProfile?
    @Published var showSettings = false
    
    private let api = BiliAPI.shared
    
    @MainActor
    func loadUserInfo() async {
        do {
            userInfo = try await api.getUserInfo()
        } catch {
            print("Load user info error: \(error)")
        }
    }
}
