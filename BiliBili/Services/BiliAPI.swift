import Foundation
import CryptoKit
import CommonCrypto

// MARK: - Bilibili API Service
class BiliAPI {
    static let shared = BiliAPI()
    
    private let baseURL = "https://api.bilibili.com"
    private let grpcBaseURL = "https://grpc.biliapi.net"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Referer": "https://www.bilibili.com",
            "Accept": "application/json",
        ]
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Build Request with Cookie
    private func buildRequest(url: String, queryItems: [URLQueryItem] = []) -> URLRequest? {
        var components = URLComponents(string: url)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let fullURL = components?.url else { return nil }
        var request = URLRequest(url: fullURL)
        request.httpMethod = "GET"
        
        // Add cookie if available
        let cookie = AppState().cookieString
        if !cookie.isEmpty {
            request.addValue(cookie, forHTTPHeaderField: "Cookie")
        }
        
        return request
    }
    
    private func buildPostRequest(url: String, body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let cookie = AppState().cookieString
        if !cookie.isEmpty {
            request.addValue(cookie, forHTTPHeaderField: "Cookie")
        }
        
        if let body = body {
            let bodyString = body.map { "\($0.key)=\(($0.value as? String ?? "").urlEncoded)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
        }
        
        return request
    }
    
    // MARK: - Generic Fetch
    private func fetch<T: Decodable>(_ type: T.Type, from url: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard let request = buildRequest(url: url, queryItems: queryItems) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // Extract Set-Cookie headers and save
        if let headerFields = httpResponse.allHeaderFields as? [String: String],
           let cookies = headerFields["Set-Cookie"] {
            saveCookies(cookies)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
    
    private func fetchRaw(from url: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        guard let request = buildRequest(url: url, queryItems: queryItems) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        if let headerFields = httpResponse.allHeaderFields as? [String: String],
           let cookies = headerFields["Set-Cookie"] {
            saveCookies(cookies)
        }
        
        return data
    }
    
    // MARK: - Cookie Management
    private func saveCookies(_ cookieString: String) {
        var existing = UserDefaults.standard.string(forKey: "cookieString") ?? ""
        
        // Parse new cookies
        let newCookies = cookieString.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        // Merge with existing
        var cookieDict: [String: String] = [:]
        for cookie in (existing + "; " + cookieString).split(separator: ";") {
            let parts = String(cookie).trimmingCharacters(in: .whitespaces).split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                cookieDict[String(parts[0])] = String(parts[1])
            }
        }
        
        let merged = cookieDict.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
        UserDefaults.standard.set(merged, forKey: "cookieString")
        
        // Update app state
        DispatchQueue.main.async {
            AppState().cookieString = merged
        }
    }
    
    // MARK: - WBI Sign
    // B站部分 API 需要 WBI 签名
    private var wbiKeys: (imgKey: String, subKey: String)? {
        let imgKey = UserDefaults.standard.string(forKey: "wbi_img_key") ?? ""
        let subKey = UserDefaults.standard.string(forKey: "wbi_sub_key") ?? ""
        if imgKey.isEmpty || subKey.isEmpty { return nil }
        return (imgKey, subKey)
    }
    
    private func getMixinKey(encKey: String) -> String {
        let e = [46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
                  33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40, 61,
                  26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36,
                  20, 34, 44, 52]
        var result = ""
        for i in 0..<32 {
            let index = e[i]
            if index < encKey.count {
                let idx = encKey.index(encKey.startIndex, offsetBy: index)
                result.append(encKey[idx])
            }
        }
        return String(result.prefix(32))
    }
    
    private func wbiSign(params: [String: String]) -> [String: String] {
        guard let keys = wbiKeys else { return params }
        let mixinKey = getMixinKey(encKey: keys.imgKey + keys.subKey)
        
        var allParams = params
        allParams["wts"] = String(Int(Date().timeIntervalSince1970))
        
        // Sort by key
        let sortedParams = allParams.sorted { $0.key < $1.key }
        let query = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        // MD5
        let sign = md5(query + mixinKey)
        allParams["w_rid"] = sign
        
        return allParams
    }
    
    private func md5(_ string: String) -> String {
        let data = Data(string.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            CC_MD5(body.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: ============ API Endpoints ============
    
    // MARK: - Login QR Code
    func getLoginQR() async throws -> LoginQRResponse {
        let response: BiliResponse<LoginQRResponse> = try await fetch(
            BiliResponse<LoginQRResponse>.self,
            from: "\(baseURL)/x/web-interface/v2/qrcode/generate"
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    func checkQRLogin(qrKey: String) async throws -> LoginResult {
        let response: BiliResponse<LoginResult> = try await fetch(
            BiliResponse<LoginResult>.self,
            from: "\(baseURL)/x/web-interface/v2/qrcode/poll",
            queryItems: [URLQueryItem(name: "qrcode_key", value: qrKey)]
        )
        guard let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    // MARK: - Home Feed (Recommended)
    func getHomeFeed(page: Int = 1) async throws -> [VideoItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "ps", value: "20"),
            URLQueryItem(name: "pn", value: "\(page)"),
            URLQueryItem(name: "feed_version", value: "V_VIDEO_V2"),
        ]
        
        let response: BiliResponse<HomeFeedData> = try await fetch(
            BiliResponse<HomeFeedData>.self,
            from: "\(baseURL)/x/web-interface/feed",
            queryItems: items
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data.items
    }
    
    // MARK: - Video Detail
    func getVideoDetail(bvid: String) async throws -> VideoDetail {
        let response: BiliResponse<VideoDetail> = try await fetch(
            BiliResponse<VideoDetail>.self,
            from: "\(baseURL)/x/web-interface/view",
            queryItems: [URLQueryItem(name: "bvid", value: bvid)]
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    // MARK: - Video Play URL
    func getVideoPlayURL(bvid: String, cid: Int, qn: Int = 80) async throws -> VideoDetail {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "bvid", value: bvid),
            URLQueryItem(name: "cid", value: "\(cid)"),
            URLQueryItem(name: "qn", value: "\(qn)"),
            URLQueryItem(name: "fnver", value: "0"),
            URLQueryItem(name: "fnval", value: "16"),
            URLQueryItem(name: "fourk", value: "1"),
        ]
        
        // Add WBI sign if available
        if let keys = wbiKeys {
            var params: [String: String] = [
                "bvid": bvid, "cid": "\(cid)", "qn": "\(qn)",
                "fnver": "0", "fnval": "16", "fourk": "1"
            ]
            params = wbiSign(params: params)
            items = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        let response: BiliResponse<VideoDetail> = try await fetch(
            BiliResponse<VideoDetail>.self,
            from: "\(baseURL)/x/player/wbi/playurl",
            queryItems: items
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    // MARK: - Comments
    func getComments(oid: Int, type: Int = 1, page: Int = 1) async throws -> CommentInfo {
        let response: BiliResponse<CommentInfo> = try await fetch(
            BiliResponse<CommentInfo>.self,
            from: "\(baseURL)/x/v2/reply",
            queryItems: [
                URLQueryItem(name: "type", value: "\(type)"),
                URLQueryItem(name: "oid", value: "\(oid)"),
                URLQueryItem(name: "pn", value: "\(page)"),
                URLQueryItem(name: "ps", value: "20"),
                URLQueryItem(name: "sort", value: "1"),
            ]
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    // MARK: - Search
    func search(keyword: String, page: Int = 1) async throws -> SearchResult {
        let response: BiliResponse<SearchResult> = try await fetch(
            BiliResponse<SearchResult>.self,
            from: "\(baseURL)/x/web-interface/search/type",
            queryItems: [
                URLQueryItem(name: "search_type", value: "video"),
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "page", value: "\(page)"),
            ]
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    // MARK: - Popular / Ranking
    func getPopular(page: Int = 1) async throws -> [RankingItem] {
        let response: BiliResponse<[RankingItem]> = try await fetch(
            BiliResponse<[RankingItem]>.self,
            from: "\(baseURL)/x/web-interface/popular",
            queryItems: [
                URLQueryItem(name: "ps", value: "20"),
                URLQueryItem(name: "pn", value: "\(page)"),
            ]
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    func getWeeklyPopular() async throws -> [RankingItem] {
        let response: BiliResponse<WeeklyPopularData> = try await fetch(
            BiliResponse<WeeklyPopularData>.self,
            from: "\(baseURL)/x/web-interface/popular/series/one"
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data.list
    }
    
    // MARK: - Regions

    func getRegions() async throws -> [RegionCategory] {
        let response: BiliResponse<[RegionCategory]> = try await fetch(
            BiliResponse<[RegionCategory]>.self,
            from: "\(baseURL)/x/web-interface/nav"
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    // MARK: - User Info
    func getUserInfo() async throws -> UserProfile {
        let response: BiliResponse<UserProfile> = try await fetch(
            BiliResponse<UserProfile>.self,
            from: "\(baseURL)/x/web-interface/nav"
        )
        guard response.isSuccess else {
            throw APIError.apiError(response.message)
        }
        // Parse user info from nav data
        // The nav endpoint returns a more complex structure, but we handle it in decoding
        return response.data ?? UserProfile()
    }
    
    // MARK: - Dynamic Feed
    func getDynamicFeed(offset: String = "", updateBaseline: String = "") async throws -> DynamicFeed {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "timezone_offset", value: "-480"),
        ]
        if !offset.isEmpty {
            items.append(URLQueryItem(name: "offset", value: offset))
        }
        if !updateBaseline.isEmpty {
            items.append(URLQueryItem(name: "update_baseline", value: updateBaseline))
        }
        
        let response: BiliResponse<DynamicFeed> = try await fetch(
            BiliResponse<DynamicFeed>.self,
            from: "\(baseURL)/x/polymer/web-dynamic/v1/feed/all",
            queryItems: items
        )
        guard response.isSuccess, let data = response.data else {
            throw APIError.apiError(response.message)
        }
        return data
    }
    
    // MARK: - Like Video
    func likeVideo(bvid: String, aid: Int, like: Bool) async throws -> Bool {
        guard let request = buildPostRequest(
            url: "\(baseURL)/x/web-interface/v2/like",
            body: [
                "bvid": bvid,
                "aid": "\(aid)",
                "like": like ? "1" : "2",
                "csrf": getCSRF(),
            ]
        ) else { throw APIError.invalidURL }
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(BiliResponse<String>.self, from: data)
        return response.isSuccess
    }
    
    // MARK: - Coin Video
    func coinVideo(bvid: String, aid: Int, multiply: Int = 1) async throws -> Bool {
        guard let request = buildPostRequest(
            url: "\(baseURL)/x/web-interface/v2/coin/add",
            body: [
                "bvid": bvid,
                "aid": "\(aid)",
                "multiply": "\(multiply)",
                "select_like": "0",
                "csrf": getCSRF(),
            ]
        ) else { throw APIError.invalidURL }
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(BiliResponse<String>.self, from: data)
        return response.isSuccess
    }
    
    // MARK: - Favorite Video
    func favoriteVideo(bvid: String, aid: Int, add: Bool, mlId: Int = 0) async throws -> Bool {
        guard let request = buildPostRequest(
            url: "\(baseURL)/x/v3/fav/resource/deal",
            body: [
                "bvid": bvid,
                "rid": "\(aid)",
                "type": "2",
                "add": add ? "1" : "0",
                "csrf": getCSRF(),
                "mlid": "\(mlId)",
            ]
        ) else { throw APIError.invalidURL }
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(BiliResponse<String>.self, from: data)
        return response.isSuccess
    }
    
    // MARK: - Helper: Get CSRF from cookie
    private func getCSRF() -> String {
        let cookie = UserDefaults.standard.string(forKey: "cookieString") ?? ""
        let parts = cookie.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
        for part in parts {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 && kv[0] == "bili_jct" {
                return String(kv[1])
            }
        }
        return ""
    }
}

// MARK: - Home Feed Data
struct HomeFeedData: Codable {
    let items: [VideoItem]
    
    init() { items = [] }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = (try? c.decode([VideoItem].self, forKey: .items)) ?? []
    }
}

// MARK: - Weekly Popular Data
struct WeeklyPopularData: Codable {
    let list: [RankingItem]
    
    init() {
        list = []
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        list = (try? c.decode([RankingItem].self, forKey: .list)) ?? []
    }
}

// MARK: - API Error
enum APIError: LocalizedError {

    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .invalidResponse: return "无效的响应"
        case .httpError(let code): return "HTTP错误: \(code)"
        case .apiError(let msg): return "API错误: \(msg)"
        case .decodingError: return "数据解析失败"
        case .networkError(let err): return "网络错误: \(err.localizedDescription)"
        }
    }
}
