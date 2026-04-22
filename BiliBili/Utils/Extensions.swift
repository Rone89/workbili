import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Bilibili Theme Colors
extension Color {
    static let bilibiliPink = Color(hex: "FB7299")
    static let bilibiliBlue = Color(hex: "23ADE5")
    static let bilibiliGray = Color(hex: "999999")
    static let bilibiliLightGray = Color(hex: "F4F4F4")
    static let bilibiliDarkBg = Color(hex: "1A1A1A")
    static let bilibiliCardBg = Color(hex: "FFFFFF")
    static let bilibiliDarkCardBg = Color(hex: "2A2A2A")
    
    static let primaryColor = Color.bilibiliPink
}

// MARK: - View Extensions
extension View {
    func cardStyle(isDark: Bool = false) -> some View {
        self
            .padding(12)
            .background(isDark ? Color.bilibiliDarkCardBg : Color.bilibiliCardBg)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = UIScreen.main.bounds.width
                }
            }
    }
}

// MARK: - String Extensions
extension String {
    var htmlDecoded: String {
        let decoded = try? NSAttributedString(
            data: Data(self.utf8),
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ).string
        return decoded ?? self
    }
    
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
    
    func formatDuration() -> String {
        guard let time = Int(self) else { return self }
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Format Play Count
func formatPlayCount(_ count: Int) -> String {
    if count >= 10000 {
        let wan = Double(count) / 10000.0
        if wan >= 10000 {
            return String(format: "%.1f亿", wan / 10000.0)
        }
        return String(format: "%.1f万", wan)
    }
    return "\(count)"
}

// MARK: - Date Formatter
extension Date {
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - UIImage from URL
class ImageLoader {
    static let shared = ImageLoader()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func load(url: String) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSString) {
            return cached
        }
        
        guard let requestUrl = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: url as NSString)
                return image
            }
        } catch {
            print("Image load error: \(error)")
        }
        return nil
    }
}

// MARK: - Async Image View
struct BiliAsyncImage: View {
    let url: String
    let placeholder: String
    
    init(url: String, placeholder: String = "photo") {
        self.url = url
        self.placeholder = placeholder
    }
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: placeholder)
                    .foregroundColor(.gray)
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .shimmer()
            @unknown default:
                Image(systemName: placeholder)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Safe Area Helper
struct SafeAreaHelper {
    static var topInset: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.top ?? 0
    }
    
    static var bottomInset: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}
