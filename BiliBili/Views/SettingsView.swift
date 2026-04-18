import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // Account
            Section {
                HStack {
                    Text("账号")
                    Spacer()
                    if appState.isLoggedIn {
                        Text(appState.username.isEmpty ? "已登录" : appState.username)
                            .foregroundColor(.secondary)
                    } else {
                        Text("未登录")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive) {
                    appState.logout()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("退出登录")
                    }
                }
                .disabled(!appState.isLoggedIn)
            } header: {
                Text("账号")
            }
            
            // Appearance
            Section {
                Toggle("深色模式", isOn: $appState.isDarkMode)
                
                Picker("播放画质", selection: .constant(1)) {
                    Text("自动").tag(0)
                    Text("1080P").tag(1)
                    Text("720P").tag(2)
                    Text("480P").tag(3)
                    Text("360P").tag(4)
                }
                
                Picker("弹幕开关", selection: .constant(true)) {
                    Text("开启").tag(true)
                    Text("关闭").tag(false)
                }
                .pickerStyle(.menu)
            } header: {
                Text("播放设置")
            }
            
            // About
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Text("GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://www.bilibili.com")!) {
                    HStack {
                        Text("哔哩哔哩官网")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("关于")
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
    }
}
