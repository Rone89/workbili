import Foundation

// MARK: - Video Item
struct VideoItem: Identifiable, Codable {
    let id: Int
    let bvid: String?
    let aid: Int?
    let title: String
    let pic: String
    let desc: String?
    let owner: Owner
    let stat: VideoStat
    let duration: Int
    let pubdate: Int?
    let rname: String?
    let tname: String?
    let uri: String?
    let goto: String?
    
    var videoId: String {
        bvid ?? "av\(aid ?? 0)"
    }
    
    var coverURL: String {
        // B站图片需要 HTTPS
        pic.hasPrefix("http") ? pic : "https:\(pic)"
    }
    
    var publishDate: Date? {
        guard let ts = pubdate else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }
    
    enum CodingKeys: String, CodingKey {
        case id, bvid, aid, title, pic, desc, owner, stat, duration, pubdate, rname, tname, uri, goto
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        bvid = try? container.decode(String.self, forKey: .bvid)
        aid = try? container.decode(Int.self, forKey: .aid)
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        pic = (try? container.decode(String.self, forKey: .pic)) ?? ""
        desc = try? container.decode(String.self, forKey: .desc)
        owner = (try? container.decode(Owner.self, forKey: .owner)) ?? Owner()
        stat = (try? container.decode(VideoStat.self, forKey: .stat)) ?? VideoStat()
        duration = (try? container.decode(Int.self, forKey: .duration)) ?? 0
        pubdate = try? container.decode(Int.self, forKey: .pubdate)
        rname = try? container.decode(String.self, forKey: .rname)
        tname = try? container.decode(String.self, forKey: .tname)
        uri = try? container.decode(String.self, forKey: .uri)
        goto = try? container.decode(String.self, forKey: .goto)
    }
    
    init() {
        id = 0; bvid = nil; aid = nil; title = ""; pic = ""; desc = nil
        owner = Owner(); stat = VideoStat(); duration = 0; pubdate = nil
        rname = nil; tname = nil; uri = nil; goto = nil
    }
}

// MARK: - Owner
struct Owner: Codable {
    let mid: Int
    let name: String
    let face: String
    
    init() {
        mid = 0; name = ""; face = ""
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mid = (try? container.decode(Int.self, forKey: .mid)) ?? 0
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        face = (try? container.decode(String.self, forKey: .face)) ?? ""
    }
}

// MARK: - Video Stat
struct VideoStat: Codable {
    let view: Int
    let danmaku: Int
    let like: Int
    let coin: Int
    let favorite: Int
    let share: Int
    let reply: Int
    
    init() {
        view = 0; danmaku = 0; like = 0; coin = 0
        favorite = 0; share = 0; reply = 0
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        view = (try? container.decode(Int.self, forKey: .view)) ?? 0
        danmaku = (try? container.decode(Int.self, forKey: .danmaku)) ?? 0
        like = (try? container.decode(Int.self, forKey: .like)) ?? 0
        coin = (try? container.decode(Int.self, forKey: .coin)) ?? 0
        favorite = (try? container.decode(Int.self, forKey: .favorite)) ?? 0
        share = (try? container.decode(Int.self, forKey: .share)) ?? 0
        reply = (try? container.decode(Int.self, forKey: .reply)) ?? 0
    }
}

// MARK: - Video Detail
struct VideoDetail: Codable {
    let bvid: String
    let aid: Int
    let videos: [VideoPage]
    let title: String
    let pic: String
    let desc: String
    let pubdate: Int
    let owner: Owner
    let stat: VideoStat
    let cid: Int
    let pages: [VideoPage]
    let subtitle: SubtitleInfo?
    let dash: DashInfo?
    
    var coverURL: String {
        pic.hasPrefix("http") ? pic : "https:\(pic)"
    }
    
    enum CodingKeys: String, CodingKey {
        case bvid, aid, videos, title, pic, desc, pubdate, owner, stat, cid, pages, subtitle, dash
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bvid = (try? container.decode(String.self, forKey: .bvid)) ?? ""
        aid = (try? container.decode(Int.self, forKey: .aid)) ?? 0
        videos = (try? container.decode([VideoPage].self, forKey: .videos)) ?? []
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        pic = (try? container.decode(String.self, forKey: .pic)) ?? ""
        desc = (try? container.decode(String.self, forKey: .desc)) ?? ""
        pubdate = (try? container.decode(Int.self, forKey: .pubdate)) ?? 0
        owner = (try? container.decode(Owner.self, forKey: .owner)) ?? Owner()
        stat = (try? container.decode(VideoStat.self, forKey: .stat)) ?? VideoStat()
        cid = (try? container.decode(Int.self, forKey: .cid)) ?? 0
        pages = (try? container.decode([VideoPage].self, forKey: .pages)) ?? []
        subtitle = try? container.decode(SubtitleInfo.self, forKey: .subtitle)
        dash = try? container.decode(DashInfo.self, forKey: .dash)
    }
    
    init() {
        bvid = ""; aid = 0; videos = []; title = ""; pic = ""; desc = ""
        pubdate = 0; owner = Owner(); stat = VideoStat(); cid = 0
        pages = []; subtitle = nil; dash = nil
    }
}

// MARK: - Video Page
struct VideoPage: Codable, Identifiable {
    let cid: Int
    let page: Int
    let from: String?
    let part: String
    let duration: Int
    let dimension: VideoDimension?
    let width: Int?
    let height: Int?
    
    var id: Int { cid }
    
    init() {
        cid = 0; page = 0; from = nil; part = ""; duration = 0; dimension = nil; width = nil; height = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cid = (try? container.decode(Int.self, forKey: .cid)) ?? 0
        page = (try? container.decode(Int.self, forKey: .page)) ?? 0
        from = try? container.decode(String.self, forKey: .from)
        part = (try? container.decode(String.self, forKey: .part)) ?? ""
        duration = (try? container.decode(Int.self, forKey: .duration)) ?? 0
        dimension = try? container.decode(VideoDimension.self, forKey: .dimension)
        width = try? container.decode(Int.self, forKey: .width)
        height = try? container.decode(Int.self, forKey: .height)
    }
}

// MARK: - Video Dimension
struct VideoDimension: Codable {
    let width: Int
    let height: Int
    let rotate: Int
    
    init() { width = 0; height = 0; rotate = 0 }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = (try? container.decode(Int.self, forKey: .width)) ?? 0
        height = (try? container.decode(Int.self, forKey: .height)) ?? 0
        rotate = (try? container.decode(Int.self, forKey: .rotate)) ?? 0
    }
}

// MARK: - Subtitle Info
struct SubtitleInfo: Codable {
    let subtitles: [SubtitleItem]
    
    init() { subtitles = [] }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subtitles = (try? container.decode([SubtitleItem].self, forKey: .subtitles)) ?? []
    }
}

struct SubtitleItem: Codable {
    let lan: String
    let lanDoc: String
    let subtitleUrl: String
    
    init() { lan = ""; lanDoc = ""; subtitleUrl = "" }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lan = (try? container.decode(String.self, forKey: .lan)) ?? ""
        lanDoc = (try? container.decode(String.self, forKey: .lanDoc)) ?? ""
        subtitleUrl = (try? container.decode(String.self, forKey: .subtitleUrl)) ?? ""
    }
}

// MARK: - Dash Play Info
struct DashInfo: Codable {
    let duration: Int
    let minBufferTime: Double
    let video: [DashStream]?
    let audio: [DashStream]?
    
    init() { duration = 0; minBufferTime = 0; video = nil; audio = nil }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = (try? container.decode(Int.self, forKey: .duration)) ?? 0
        minBufferTime = (try? container.decode(Double.self, forKey: .minBufferTime)) ?? 0
        video = try? container.decode([DashStream].self, forKey: .video)
        audio = try? container.decode([DashStream].self, forKey: .audio)
    }
}

struct DashStream: Codable {
    let id: Int
    let baseUrl: String
    let backupUrl: [String]?
    let mimeType: String?
    let codecs: String?
    let bandwidth: Int?
    let width: Int?
    let height: Int?
    let codecid: Int?
    let md5: String?
    
    init() {
        id = 0; baseUrl = ""; backupUrl = nil; mimeType = nil
        codecs = nil; bandwidth = nil; width = nil; height = nil
        codecid = nil; md5 = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        baseUrl = (try? container.decode(String.self, forKey: .baseUrl)) ?? ""
        backupUrl = try? container.decode([String].self, forKey: .backupUrl)
        mimeType = try? container.decode(String.self, forKey: .mimeType)
        codecs = try? container.decode(String.self, forKey: .codecs)
        bandwidth = try? container.decode(Int.self, forKey: .bandwidth)
        width = try? container.decode(Int.self, forKey: .width)
        height = try? container.decode(Int.self, forKey: .height)
        codecid = try? container.decode(Int.self, forKey: .codecid)
        md5 = try? container.decode(String.self, forKey: .md5)
    }
}

// MARK: - Comment
struct CommentInfo: Codable {
    let cursor: CommentCursor
    let replies: [CommentReply]?
    let topReplies: [CommentReply]?
    
    init() { cursor = CommentCursor(); replies = nil; topReplies = nil }
    
    init(from decoder: Decoder) throws {
        let cursor = try decoder.container(keyedBy: CodingKeys.self)
        self.cursor = (try? cursor.decode(CommentCursor.self, forKey: .cursor)) ?? CommentCursor()
        self.replies = try? cursor.decode([CommentReply].self, forKey: .replies)
        self.topReplies = try? cursor.decode([CommentReply].self, forKey: .topReplies)
    }
}

struct CommentCursor: Codable {
    let allCount: Int
    let isEnd: Bool
    let mode: Int
    let next: Int?
    
    init() { allCount = 0; isEnd = true; mode = 3; next = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        allCount = (try? c.decode(Int.self, forKey: .allCount)) ?? 0
        isEnd = (try? c.decode(Bool.self, forKey: .isEnd)) ?? true
        mode = (try? c.decode(Int.self, forKey: .mode)) ?? 3
        next = try? c.decode(Int.self, forKey: .next)
    }
}

struct CommentReply: Codable, Identifiable {
    let rpid: Int
    let oid: Int
    let type: Int
    let mid: Int
    let root: Int
    let parent: Int
    let count: Int
    let rcount: Int
    let like: Int
    let replyControl: CommentReplyControl?
    let content: CommentContent
    let member: CommentMember
    let replies: [CommentReply]?
    let time: Int
    
    var id: Int { rpid }
    
    init() {
        rpid = 0; oid = 0; type = 1; mid = 0; root = 0; parent = 0
        count = 0; rcount = 0; like = 0; replyControl = nil
        content = CommentContent(); member = CommentMember(); replies = nil; time = 0
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rpid = (try? c.decode(Int.self, forKey: .rpid)) ?? 0
        oid = (try? c.decode(Int.self, forKey: .oid)) ?? 0
        type = (try? c.decode(Int.self, forKey: .type)) ?? 1
        mid = (try? c.decode(Int.self, forKey: .mid)) ?? 0
        root = (try? c.decode(Int.self, forKey: .root)) ?? 0
        parent = (try? c.decode(Int.self, forKey: .parent)) ?? 0
        count = (try? c.decode(Int.self, forKey: .count)) ?? 0
        rcount = (try? c.decode(Int.self, forKey: .rcount)) ?? 0
        like = (try? c.decode(Int.self, forKey: .like)) ?? 0
        replyControl = try? c.decode(CommentReplyControl.self, forKey: .replyControl)
        content = (try? c.decode(CommentContent.self, forKey: .content)) ?? CommentContent()
        member = (try? c.decode(CommentMember.self, forKey: .member)) ?? CommentMember()
        replies = try? c.decode([CommentReply].self, forKey: .replies)
        time = (try? c.decode(Int.self, forKey: .time)) ?? 0
    }
}

struct CommentContent: Codable {
    let message: String
    let emote: [String: CommentEmote]?
    
    init() { message = ""; emote = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        message = (try? c.decode(String.self, forKey: .message)) ?? ""
        emote = try? c.decode([String: CommentEmote].self, forKey: .emote)
    }
}

struct CommentEmote: Codable {
    let id: Int
    let text: String
    let url: String
    let meta: CommentEmoteMeta?
    
    init() { id = 0; text = ""; url = ""; meta = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        text = (try? c.decode(String.self, forKey: .text)) ?? ""
        url = (try? c.decode(String.self, forKey: .url)) ?? ""
        meta = try? c.decode(CommentEmoteMeta.self, forKey: .meta)
    }
}

struct CommentEmoteMeta: Codable {
    let size: Int
    
    init() { size = 1 }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        size = (try? c.decode(Int.self, forKey: .size)) ?? 1
    }
}

struct CommentReplyControl: Codable {
    let location: String?
    let maxLine: Int?
    
    init() { location = nil; maxLine = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        location = try? c.decode(String.self, forKey: .location)
        maxLine = try? c.decode(Int.self, forKey: .maxLine)
    }
}

struct CommentMember: Codable {
    let mid: Int
    let uname: String
    let avatar: String
    let levelInfo: LevelInfo?
    let vip: VipInfo?
    
    init() { mid = 0; uname = ""; avatar = ""; levelInfo = nil; vip = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mid = (try? c.decode(Int.self, forKey: .mid)) ?? 0
        uname = (try? c.decode(String.self, forKey: .uname)) ?? ""
        avatar = (try? c.decode(String.self, forKey: .avatar)) ?? ""
        levelInfo = try? c.decode(LevelInfo.self, forKey: .levelInfo)
        vip = try? c.decode(VipInfo.self, forKey: .vip)
    }
}

struct LevelInfo: Codable {
    let currentLevel: Int
    
    init() { currentLevel = 0 }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentLevel = (try? c.decode(Int.self, forKey: .currentLevel)) ?? 0
    }
}

struct VipInfo: Codable {
    let vipType: Int
    let vipStatus: Int
    let label: VipLabel?
    
    init() { vipType = 0; vipStatus = 0; label = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vipType = (try? c.decode(Int.self, forKey: .vipType)) ?? 0
        vipStatus = (try? c.decode(Int.self, forKey: .vipStatus)) ?? 0
        label = try? c.decode(VipLabel.self, forKey: .label)
    }
}

struct VipLabel: Codable {
    let path: String?
    let text: String?
    
    init() { path = nil; text = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = try? c.decode(String.self, forKey: .path)
        text = try? c.decode(String.self, forKey: .text)
    }
}

// MARK: - Search
struct SearchResult: Codable {
    let result: [SearchItem]?
    let numResults: Int
    let page: Int
    
    init() { result = nil; numResults = 0; page = 1 }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = try? c.decode([SearchItem].self, forKey: .result)
        numResults = (try? c.decode(Int.self, forKey: .numResults)) ?? 0
        page = (try? c.decode(Int.self, forKey: .page)) ?? 1
    }
}

struct SearchItem: Codable, Identifiable {
    let bvid: String
    let aid: Int
    let title: String
    let description: String
    let pic: String
    let author: String
    let mid: Int
    let play: Int
    let videoReview: Int
    let duration: String
    let tag: String?
    let typeName: String?
    
    var id: String { bvid }
    
    init() {
        bvid = ""; aid = 0; title = ""; description = ""; pic = ""
        author = ""; mid = 0; play = 0; videoReview = 0
        duration = ""; tag = nil; typeName = nil
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bvid = (try? c.decode(String.self, forKey: .bvid)) ?? ""
        aid = (try? c.decode(Int.self, forKey: .aid)) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        pic = (try? c.decode(String.self, forKey: .pic)) ?? ""
        author = (try? c.decode(String.self, forKey: .author)) ?? ""
        mid = (try? c.decode(Int.self, forKey: .mid)) ?? 0
        play = (try? c.decode(Int.self, forKey: .play)) ?? 0
        videoReview = (try? c.decode(Int.self, forKey: .videoReview)) ?? 0
        duration = (try? c.decode(String.self, forKey: .duration)) ?? ""
        tag = try? c.decode(String.self, forKey: .tag)
        typeName = try? c.decode(String.self, forKey: .typeName)
    }
    
    var toVideoItem: VideoItem {
        VideoItem(
            id: aid,
            bvid: bvid,
            aid: aid,
            title: title.htmlDecoded,
            pic: pic,
            desc: description,
            owner: Owner(mid: mid, name: author, face: ""),
            stat: VideoStat(view: play, danmaku: videoReview, like: 0, coin: 0, favorite: 0, share: 0, reply: 0),
            duration: parseDuration(duration),
            pubdate: nil, rname: nil, tname: typeName, uri: nil, goto: "av"
        )
    }
    
    private func parseDuration(_ dur: String) -> Int {
        let parts = dur.split(separator: ":").compactMap { Int($0) }
        if parts.count == 3 { return parts[0] * 3600 + parts[1] * 60 + parts[2] }
        if parts.count == 2 { return parts[0] * 60 + parts[1] }
        return parts.first ?? 0
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let mid: Int
    let uname: String
    let face: String
    let sign: String
    let level: Int
    let vip: VipInfo?
    let stat: UserNavStat?
    
    var name: String { uname }
    
    init() {
        mid = 0; uname = ""; face = ""; sign = ""; level = 0; vip = nil; stat = nil
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mid = (try? c.decode(Int.self, forKey: .mid)) ?? 0
        uname = (try? c.decode(String.self, forKey: .uname)) ?? ""
        face = (try? c.decode(String.self, forKey: .face)) ?? ""
        sign = (try? c.decode(String.self, forKey: .sign)) ?? ""
        level = (try? c.decode(Int.self, forKey: .level)) ?? 0
        vip = try? c.decode(VipInfo.self, forKey: .vip)
        stat = try? c.decode(UserNavStat.self, forKey: .stat)
    }
}

// MARK: - User Nav Stat (from /x/web-interface/nav)
struct UserNavStat: Codable {
    let following: Int
    let follower: Int
    
    init() { following = 0; follower = 0 }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        following = (try? c.decode(Int.self, forKey: .following)) ?? 0
        follower = (try? c.decode(Int.self, forKey: .follower)) ?? 0
    }
    
    var dynamicCount: Int { 0 }
}

// MARK: - Region/Category
struct RegionCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let tid: Int?
    let reid: Int?
    let children: [RegionCategory]?
    
    var regionId: Int { tid ?? id }
    
    init() { id = 0; name = ""; tid = nil; reid = nil; children = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        tid = try? c.decode(Int.self, forKey: .tid)
        reid = try? c.decode(Int.self, forKey: .reid)
        children = try? c.decode([RegionCategory].self, forKey: .children)
    }
}

// MARK: - Login QR
struct LoginQRResponse: Codable {
    let url: String
    let qrcodeKey: String
    
    init() { url = ""; qrcodeKey = "" }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        url = (try? c.decode(String.self, forKey: .url)) ?? ""
        qrcodeKey = (try? c.decode(String.self, forKey: .qrcodeKey)) ?? ""
    }
}

struct LoginResult: Codable {
    let isLogin: Bool
    let cookieInfo: CookieInfo?
    let url: String?
    
    init() { isLogin = false; cookieInfo = nil; url = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isLogin = (try? c.decode(Int.self, forKey: .isLogin)) == 1
        cookieInfo = try? c.decode(CookieInfo.self, forKey: .cookieInfo)
        url = try? c.decode(String.self, forKey: .url)
    }
}

struct CookieInfo: Codable {
    let cookies: [CookieItem]?
    
    init() { cookies = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cookies = try? c.decode([CookieItem].self, forKey: .cookies)
    }
}

struct CookieItem: Codable {
    let name: String
    let value: String
    let domain: String
    
    init() { name = ""; value = ""; domain = "" }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        value = (try? c.decode(String.self, forKey: .value)) ?? ""
        domain = (try? c.decode(String.self, forKey: .domain)) ?? ""
    }
}

// MARK: - Popular / Ranking
struct RankingItem: Codable, Identifiable {
    let aid: Int
    let bvid: String
    let title: String
    let pic: String
    let owner: Owner
    let stat: VideoStat
    let duration: Int
    let pubdate: Int
    let rname: String?
    
    var id: String { bvid }
    
    var toVideoItem: VideoItem {
        VideoItem(
            id: aid,
            bvid: bvid,
            aid: aid,
            title: title.htmlDecoded,
            pic: pic,
            desc: nil,
            owner: owner,
            stat: stat,
            duration: duration,
            pubdate: pubdate,
            rname: rname,
            tname: nil, uri: nil, goto: "av"
        )
    }
    
    init() {
        aid = 0; bvid = ""; title = ""; pic = ""; owner = Owner()
        stat = VideoStat(); duration = 0; pubdate = 0; rname = nil
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        aid = (try? c.decode(Int.self, forKey: .aid)) ?? 0
        bvid = (try? c.decode(String.self, forKey: .bvid)) ?? ""
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        pic = (try? c.decode(String.self, forKey: .pic)) ?? ""
        owner = (try? c.decode(Owner.self, forKey: .owner)) ?? Owner()
        stat = (try? c.decode(VideoStat.self, forKey: .stat)) ?? VideoStat()
        duration = (try? c.decode(Int.self, forKey: .duration)) ?? 0
        pubdate = (try? c.decode(Int.self, forKey: .pubdate)) ?? 0
        rname = try? c.decode(String.self, forKey: .rname)
    }
}

// MARK: - API Response Wrapper
struct BiliResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T?
    
    var isSuccess: Bool { code == 0 }
}

// MARK: - Dynamic Feed
struct DynamicFeed: Codable {
    let items: [DynamicItem]?
    let offset: String?
    let updateBaseline: String?
    let hasMore: Bool
    
    init() { items = nil; offset = nil; updateBaseline = nil; hasMore = false }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try? c.decode([DynamicItem].self, forKey: .items)
        offset = try? c.decode(String.self, forKey: .offset)
        updateBaseline = try? c.decode(String.self, forKey: .updateBaseline)
        hasMore = (try? c.decode(Bool.self, forKey: .hasMore)) ?? false
    }
}

struct DynamicItem: Codable, Identifiable {
    let idStr: String
    let modules: DynamicModules?
    let type: String?
    
    var id: String { idStr }
    
    init() { idStr = ""; modules = nil; type = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idStr = (try? c.decode(String.self, forKey: .idStr)) ?? ""
        modules = try? c.decode(DynamicModules.self, forKey: .modules)
        type = try? c.decode(String.self, forKey: .type)
    }
}

struct DynamicModules: Codable {
    let moduleAuthor: DynamicAuthor?
    let moduleDynamic: DynamicContent?
    
    init() { moduleAuthor = nil; moduleDynamic = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        moduleAuthor = try? c.decode(DynamicAuthor.self, forKey: .moduleAuthor)
        moduleDynamic = try? c.decode(DynamicContent.self, forKey: .moduleDynamic)
    }
}

struct DynamicAuthor: Codable {
    let mid: Int
    let name: String
    let face: String
    let pubTime: String?
    let pubTs: Int?
    
    init() { mid = 0; name = ""; face = ""; pubTime = nil; pubTs = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mid = (try? c.decode(Int.self, forKey: .mid)) ?? 0
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        face = (try? c.decode(String.self, forKey: .face)) ?? ""
        pubTime = try? c.decode(String.self, forKey: .pubTime)
        pubTs = try? c.decode(Int.self, forKey: .pubTs)
    }
}

struct DynamicContent: Codable {
    let major: DynamicMajor?
    let desc: DynamicDesc?
    
    init() { major = nil; desc = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        major = try? c.decode(DynamicMajor.self, forKey: .major)
        desc = try? c.decode(DynamicDesc.self, forKey: .desc)
    }
}

struct DynamicMajor: Codable {
    let type: String?
    let archive: DynamicArchive?
    
    init() { type = nil; archive = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try? c.decode(String.self, forKey: .type)
        archive = try? c.decode(DynamicArchive.self, forKey: .archive)
    }
}

struct DynamicArchive: Codable {
    let aid: Int?
    let bvid: String?
    let title: String?
    let desc: String?
    let cover: String?
    let durationText: String?
    let stat: DynamicStat?
    
    init() { aid = nil; bvid = nil; title = nil; desc = nil; cover = nil; durationText = nil; stat = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        aid = try? c.decode(Int.self, forKey: .aid)
        bvid = try? c.decode(String.self, forKey: .bvid)
        title = try? c.decode(String.self, forKey: .title)
        desc = try? c.decode(String.self, forKey: .desc)
        cover = try? c.decode(String.self, forKey: .cover)
        durationText = try? c.decode(String.self, forKey: .durationText)
        stat = try? c.decode(DynamicStat.self, forKey: .stat)
    }
    
    var toVideoItem: VideoItem {
        VideoItem(
            id: aid ?? 0,
            bvid: bvid,
            aid: aid,
            title: (title ?? "").htmlDecoded,
            pic: cover ?? "",
            desc: desc,
            owner: Owner(), stat: VideoStat(view: stat?.view ?? 0, danmaku: stat?.danmaku ?? 0, like: 0, coin: 0, favorite: 0, share: 0, reply: 0),
            duration: parseDuration(durationText ?? "0:00"),
            pubdate: nil, rname: nil, tname: nil, uri: nil, goto: "av"
        )
    }
    
    private func parseDuration(_ dur: String) -> Int {
        let parts = dur.split(separator: ":").compactMap { Int($0) }
        if parts.count == 3 { return parts[0] * 3600 + parts[1] * 60 + parts[2] }
        if parts.count == 2 { return parts[0] * 60 + parts[1] }
        return parts.first ?? 0
    }
}

struct DynamicStat: Codable {
    let view: Int?
    let danmaku: Int?
    
    init() { view = nil; danmaku = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        view = try? c.decode(Int.self, forKey: .view)
        danmaku = try? c.decode(Int.self, forKey: .danmaku)
    }
}

struct DynamicDesc: Codable {
    let text: String?
    
    init() { text = nil }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try? c.decode(String.self, forKey: .text)
    }
}
