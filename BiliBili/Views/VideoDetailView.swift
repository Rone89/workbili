import SwiftUI
import AVKit

// MARK: - Video Detail View
struct VideoDetailView: View {
    let bvid: String
    @StateObject private var viewModel: VideoDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(bvid: String) {
        self.bvid = bvid
        _viewModel = StateObject(wrappedValue: VideoDetailViewModel(bvid: bvid))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            playerSection
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.detail?.title.htmlDecoded ?? "")
                            .font(.headline)
                            .lineLimit(2)
                        
                        HStack(spacing: 16) {
                            StatBadge(icon: "play.circle", count: viewModel.detail?.stat.view ?? 0)
                            StatBadge(icon: "message", count: viewModel.detail?.stat.danmaku ?? 0)
                            StatBadge(icon: "hand.thumbsup", count: viewModel.detail?.stat.like ?? 0)
                            StatBadge(icon: "star", count: viewModel.detail?.stat.coin ?? 0)
                            StatBadge(icon: "heart", count: viewModel.detail?.stat.favorite ?? 0)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(16)
                    
                    Divider()
                    
                    HStack(spacing: 0) {
                        ActionButton(icon: "hand.thumbsup", title: "点赞", count: viewModel.detail?.stat.like ?? 0) {
                            Task { await viewModel.likeVideo() }
                        }
                        ActionButton(icon: "star.circle", title: "投币", count: viewModel.detail?.stat.coin ?? 0) {
                            Task { await viewModel.coinVideo() }
                        }
                        ActionButton(icon: "heart.fill", title: "收藏", count: viewModel.detail?.stat.favorite ?? 0) {
                            Task { await viewModel.favoriteVideo() }
                        }
                        ActionButton(icon: "magnifyingglass", title: "搜索", count: nil) {}
                        ActionButton(icon: "ellipsis", title: "更多", count: nil) {}
                    }
                    .padding(.vertical, 12)
                    
                    Divider()
                    
                    if let owner = viewModel.detail?.owner {
                        HStack(spacing: 12) {
                            BiliAsyncImage(url: owner.face)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(owner.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(owner.mid) UID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                            } label: {
                                Text("+ 关注")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.bilibiliPink)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.bilibiliPink, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(16)
                    }
                    
                    Divider()
                    
                    if let desc = viewModel.detail?.desc, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("简介")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(4)
                        }
                        .padding(16)
                        
                        Divider()
                    }
                    
                    if let pages = viewModel.detail?.pages, pages.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("选集 (\(pages.count))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(pages) { page in
                                        EpisodeButton(
                                            page: page,
                                            isSelected: page.cid == viewModel.currentCid
                                        ) {
                                            Task { await viewModel.switchToPage(page) }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 12)
                        
                        Divider().padding(.top, 12)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("评论")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let count = viewModel.commentInfo?.cursor.allCount, count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let comments = viewModel.commentInfo?.topReplies, !comments.isEmpty {
                            ForEach(comments) { comment in
                                CommentView(comment: comment)
                            }
                        }
                        
                        if let comments = viewModel.commentInfo?.replies, !comments.isEmpty {
                            ForEach(comments) { comment in
                                CommentView(comment: comment)
                            }
                        }
                        
                        if let commentError = viewModel.commentErrorMessage {
                            InlineErrorView(message: commentError) {
                                Task { await viewModel.loadComments() }
                            }
                        }
                        
                        if viewModel.commentInfo == nil && viewModel.isLoadingComments {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        
                        if let isEnd = viewModel.commentInfo?.cursor.isEnd, !isEnd {
                            Button("加载更多评论") {
                                Task { await viewModel.loadMoreComments() }
                            }
                            .font(.caption)
                            .foregroundColor(Color.bilibiliPink)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .padding(16)
                    
                    Spacer(minLength: 80)
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.container, edges: .top)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    @ViewBuilder
    private var playerSection: some View {
        ZStack(alignment: .topLeading) {
            if let player = viewModel.player {
                VideoPlayerView(player: player)
                    .frame(height: 220)
                    .background(.black)
            } else if let coverURL = viewModel.detail?.coverURL {
                ZStack {
                    BiliAsyncImage(url: coverURL)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                    
                    if viewModel.isLoadingVideo {
                        ProgressView("正在加载视频...")
                            .tint(.white)
                            .foregroundColor(.white)
                    } else if let playbackError = viewModel.playbackErrorMessage {
                        ErrorOverlayView(message: playbackError) {
                            Task { await viewModel.retryPlayback() }
                        }
                    }
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 220)
                    
                    if viewModel.isLoadingVideo {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
            }
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.top, SafeAreaHelper.topInset + 8)
            .padding(.leading, 16)
        }
    }
}


// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
            Text(formatPlayCount(count))
                .font(.caption)
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let count: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                
                HStack(spacing: 2) {
                    Text(title)
                        .font(.caption2)
                    if let count = count {
                        Text(formatPlayCount(count))
                            .font(.caption2)
                    }
                }
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Episode Button
struct EpisodeButton: View {
    let page: VideoPage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text("P\(page.page)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? Color.bilibiliPink : .primary)
                
                Text(page.part)
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundColor(isSelected ? Color.bilibiliPink : .secondary)
                
                Text("\(page.duration).formatDuration()")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(width: 120)
            .background(isSelected ? Color.bilibiliPink.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.bilibiliPink : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Comment View
struct CommentView: View {
    let comment: CommentReply
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 10) {
                BiliAsyncImage(url: comment.member.avatar)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(comment.member.uname)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        // VIP badge
                        if let vipStatus = comment.member.vip?.vipStatus, vipStatus == 1 {
                            Text("大会员")
                                .font(.caption2)
                                .foregroundColor(Color.bilibiliPink)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.bilibiliPink.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        // Level
                        if let level = comment.member.levelInfo?.currentLevel {
                            Text("Lv\(level)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(comment.content.message)
                        .font(.subheadline)
                        .lineLimit(6)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            
            // Bottom actions
            HStack(spacing: 20) {
                Text(Date(timeIntervalSince1970: TimeInterval(comment.time)).relativeTimeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup")
                        .font(.caption2)
                    Text("\(comment.like)")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                if let replyCount = comment.rcount, replyCount > 0 {
                    Text("\(replyCount) 回复")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Sub replies
            if let replies = comment.replies, !replies.isEmpty {
                VStack(spacing: 8) {
                    ForEach(replies) { reply in
                        HStack(alignment: .top, spacing: 8) {
                            BiliAsyncImage(url: reply.member.avatar)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reply.member.uname)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                
                                Text(reply.content.message)
                                    .font(.caption)
                                    .lineLimit(3)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Error Overlay
struct ErrorOverlayView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "play.tv.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
            Text(message)
                .font(.footnote)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button("重新播放", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Color.bilibiliPink)
        }
        .padding(20)
        .background(Color.black.opacity(0.6))
        .cornerRadius(14)
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let player: AVPlayer
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some View {
        ZStack {
            VideoPlayer(player: player)
            
            // Custom controls overlay can be added here
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        playerViewModel.togglePlay(player: player)
                    } label: {
                        Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Player View Model
class PlayerViewModel: ObservableObject {
    @Published var isPlaying = true
    @Published var currentTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    
    func togglePlay(player: AVPlayer) {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}

// MARK: - Video Detail ViewModel
class VideoDetailViewModel: ObservableObject {
    let bvid: String
    @Published var detail: VideoDetail?
    @Published var player: AVPlayer?
    @Published var currentCid: Int = 0
    @Published var isLoadingVideo = false
    @Published var isLoadingComments = false
    @Published var commentInfo: CommentInfo?
    @Published var playbackErrorMessage: String?
    @Published var commentErrorMessage: String?
    
    private let api = BiliAPI.shared
    
    init(bvid: String) {
        self.bvid = bvid
        Task { await loadDetail() }
    }
    
    @MainActor
    func loadDetail() async {
        isLoadingVideo = true
        playbackErrorMessage = nil
        defer { isLoadingVideo = false }
        
        do {
            detail = try await api.getVideoDetail(bvid: bvid)
            guard let detail = detail else { return }
            currentCid = detail.cid
            await loadPlayback(cid: detail.cid)
            await loadComments()
        } catch {
            playbackErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func retryPlayback() async {
        if let cid = detail?.cid, currentCid == 0 {
            currentCid = cid
        }
        await loadPlayback(cid: currentCid == 0 ? (detail?.cid ?? 0) : currentCid)
    }
    
    @MainActor
    private func loadPlayback(cid: Int) async {
        guard cid > 0 else { return }
        isLoadingVideo = true
        playbackErrorMessage = nil
        defer { isLoadingVideo = false }
        
        do {
            let playInfo = try await api.getVideoPlayURL(bvid: bvid, cid: cid, qn: 80)
            if let dashVideo = playInfo.dash?.video?.first,
               let url = URL(string: dashVideo.baseUrl) {
                if let player {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    player.play()
                } else {
                    let newPlayer = AVPlayer(url: url)
                    newPlayer.play()
                    player = newPlayer
                }
            } else {
                playbackErrorMessage = "暂时没有可播放的视频流"
            }
        } catch {
            playbackErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func switchToPage(_ page: VideoPage) async {
        currentCid = page.cid
        await loadPlayback(cid: page.cid)
    }
    
    @MainActor
    func loadComments() async {
        guard let aid = detail?.aid else { return }
        isLoadingComments = true
        commentErrorMessage = nil
        defer { isLoadingComments = false }
        
        do {
            commentInfo = try await api.getComments(oid: aid, type: 1)
        } catch {
            commentErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func loadMoreComments() async {
        guard let aid = detail?.aid,
              let next = commentInfo?.cursor.next else { return }
        
        do {
            let more = try await api.getComments(oid: aid, type: 1, page: next)
            if var currentInfo = commentInfo {
                if let newReplies = more.replies {
                    if currentInfo.replies == nil {
                        currentInfo.replies = []
                    }
                    currentInfo.replies?.append(contentsOf: newReplies)
                }
                currentInfo.cursor = more.cursor
                commentInfo = currentInfo
            }
        } catch {
            commentErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func likeVideo() async {
        guard let detail = detail else { return }
        do {
            _ = try await api.likeVideo(bvid: detail.bvid, aid: detail.aid, like: true)
        } catch {
            playbackErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func coinVideo() async {
        guard let detail = detail else { return }
        do {
            _ = try await api.coinVideo(bvid: detail.bvid, aid: detail.aid)
        } catch {
            playbackErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func favoriteVideo() async {
        guard let detail = detail else { return }
        do {
            _ = try await api.favoriteVideo(bvid: detail.bvid, aid: detail.aid, add: true)
        } catch {
            playbackErrorMessage = error.localizedDescription
        }
    }
}

