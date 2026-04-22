import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile header
                if appState.isLoggedIn {
                    loggedInHeader
                } else {
                    loggedOutHeader
                }
                
                Divider().padding(.leading, 16)
                
                // Stats
                if let user = viewModel.userInfo, let stat = viewModel.userStat {
                    HStack(spacing: 0) {
                        ProfileStatItem(value: stat.dynamicCount, label: "动态")
                        ProfileStatItem(value: stat.following, label: "关注")
                        ProfileStatItem(value: stat.follower, label: "粉丝")
                    }
                    .padding(.vertical, 16)
                    
                    Divider().padding(.horizontal, 16)
                }
                
                // Menu sections
                VStack(spacing: 0) {
                    if appState.isLoggedIn {
                        ProfileSectionHeader(title: "我的内容")
                        ProfileMenuItem(icon: "clock", title: "历史记录", badge: nil) {
                            // History
                        }
                        ProfileMenuItem(icon: "bookmark", title: "收藏", badge: nil) {
                            // Favorites
                        }
                        ProfileMenuItem(icon: "square.and.arrow.down", title: "下载", badge: nil) {
                            // Downloads
                        }
                        ProfileMenuItem(icon: "eye.slash", title: "稍后再看", badge: nil) {
                            // Watch Later
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        ProfileSectionHeader(title: "设置")
                        ProfileMenuItem(icon: "moon", title: "深色模式", badge: nil) {
                            // Dark mode toggle
                        }
                        ProfileMenuItem(icon: "bell", title: "推送设置", badge: nil) {
                            // Push settings
                        }
                        ProfileMenuItem(icon: "shield", title: "隐私设置", badge: nil) {
                            // Privacy
                        }
                        ProfileMenuItem(icon: "info.circle", title: "关于", badge: nil) {
                            // About
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        ProfileMenuItem(icon: "rectangle.portrait.and.arrow.right", title: "退出登录", isDestructive: true) {
                            appState.isLoggedIn = false
                            appState.cookieString = ""
                            UserDefaults.standard.removeObject(forKey: "cookieString")
                        }
                    } else {
                        ProfileSectionHeader(title: "浏览")
                        ProfileMenuItem(icon: "clock", title: "历史记录", badge: nil) {}
                        ProfileMenuItem(icon: "square.and.arrow.down", title: "下载", badge: nil) {}
                        
                        Divider().padding(.leading, 52)
                        
                        ProfileSectionHeader(title: "设置")
                        ProfileMenuItem(icon: "moon", title: "深色模式", badge: nil) {}
                        ProfileMenuItem(icon: "info.circle", title: "关于", badge: nil) {}
                    }
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("我的")
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
    
    // MARK: - Logged In Header
    private var loggedInHeader: some View {
        HStack(spacing: 16) {
            if let face = viewModel.userInfo?.face {
                BiliAsyncImage(url: face)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.bilibiliPink, lineWidth: 2)
                    )
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.userInfo?.name ?? "加载中...")
                    .font(.title3)
                    .fontWeight(.bold)
                
                if let sign = viewModel.userInfo?.sign, !sign.isEmpty {
                    Text(sign)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let level = viewModel.userInfo?.level {
                    HStack(spacing: 4) {
                        Text("LV\(level)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(levelColor(level))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            NavigationLink(destination: Text("编辑资料")) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            if let mid = viewModel.userInfo?.mid {
                // Navigate to user detail
            }
        }
    }
    
    // MARK: - Logged Out Header
    private var loggedOutHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("未登录")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("登录后享受更多功能")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            NavigationLink(destination: LoginView()) {
                Text("登录")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.bilibiliPink)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
    
    // MARK: - Level Color
    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 0: return .gray
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        case 6: return .pink
        default: return .gray
        }
    }
}

// MARK: - Profile Stat Item
struct ProfileStatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatPlayCount(value))
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Section Header
struct ProfileSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var badge: String? = nil
    var isDestructive: Bool = false
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.bilibiliPink)
                        .cornerRadius(10)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Profile ViewModel
class ProfileViewModel: ObservableObject {
    @Published var userInfo: UserInfo?
    @Published var userStat: UserStat?
    
    private let api = BiliAPI.shared
    
    @MainActor
    func loadUserInfo() async {
        do {
            let info = try await api.getUserInfo()
            userInfo = info
            
            userStat = try await api.getUserStat(mid: info.mid)
        } catch {
            print("Profile load error: \(error)")
        }
    }
}
