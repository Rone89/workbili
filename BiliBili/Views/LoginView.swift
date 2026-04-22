import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo
            VStack(spacing: 8) {
                Text("B")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(Color.bilibiliPink)
                
                Text("BiliBili")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("使用哔哩哔哩 APP 扫码登录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // QR Code
            if let qrImage = viewModel.qrImage {
                VStack(spacing: 16) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8)
                    
                    // Status
                    if viewModel.isPolling {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("等待扫码...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.loginSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("登录成功！")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
            
            // Refresh QR button
            if viewModel.showRefresh {
                Button {
                    Task { await viewModel.generateQR() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("刷新二维码")
                    }
                    .foregroundColor(Color.bilibiliPink)
                }
            }
            
            // Skip login
            Button {
                // Allow browsing without login
            } label: {
                Text("游客模式浏览")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .underline()
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .task {
            await viewModel.generateQR()
        }
        .onChange(of: viewModel.loginSuccess) { success in
            if success {
                appState.isLoggedIn = true
            }
        }
    }
}

// MARK: - Login ViewModel
class LoginViewModel: ObservableObject {
    @Published var qrImage: UIImage?
    @Published var isLoading = false
    @Published var isPolling = false
    @Published var loginSuccess = false
    @Published var showRefresh = false
    @Published var errorMessage: String?
    
    private var qrKey: String = ""
    private var pollTask: Task<Void, Never>?
    private let api = BiliAPI.shared
    
    @MainActor
    func generateQR() async {
        isLoading = true
        errorMessage = nil
        loginSuccess = false
        showRefresh = false
        pollTask?.cancel()
        
        defer { isLoading = false }
        
        do {
            let response = try await api.getLoginQR()
            qrKey = response.qrcodeKey
            
            // Generate QR code image
            qrImage = generateQRCode(from: response.url)
            
            // Start polling
            startPolling()
        } catch {
            errorMessage = "获取二维码失败: \(error.localizedDescription)"
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        
        if let output = filter.outputImage?.transformed(by: transform),
           let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    private func startPolling() {
        isPolling = true
        
        pollTask = Task {
            while !Task.isCancelled && !loginSuccess {
                do {
                    let result = try await api.checkQRLogin(qrKey: qrKey)
                    
                    switch result.isLogin {
                    case true:
                        await MainActor.run {
                            isPolling = false
                            loginSuccess = true
                            
                            // Save cookies
                            if let cookies = result.cookieInfo?.cookies {
                                let cookieString = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                                UserDefaults.standard.set(cookieString, forKey: "cookieString")
                                AppState().cookieString = cookieString
                            }
                        }
                        return
                        
                    default:
                        // QR expired or not scanned
                        if !result.isLogin {
                            await MainActor.run {
                                isPolling = false
                                showRefresh = true
                                errorMessage = "二维码已过期，请刷新"
                            }
                            return
                        }
                    }
                } catch {
                    // Continue polling on network error
                }
                
                // Poll every 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
    
    deinit {
        pollTask?.cancel()
    }
}
