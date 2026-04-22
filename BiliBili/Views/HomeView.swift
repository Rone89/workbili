import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSearch = false
    
    var body: some View {
        Group {
            Group {
                if viewModel.isInitialLoading {
                    HomeSkeletonView()
                } else if let errorMessage = viewModel.errorMessage, viewModel.videos.isEmpty {
                    ErrorStateView(
                        title: "首页加载失败",
                        message: errorMessage,
                        buttonTitle: "重新加载"
                    ) {
                        Task { await viewModel.refresh() }
                    }
                } else if viewModel.videos.isEmpty {
                    EmptyStateView(
                        title: "暂时没有内容",
                        message: "下拉试试重新获取推荐视频。"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            BannerView()
                                .padding(.horizontal, 16)
                            
                            ForEach(viewModel.videos) { video in
                                NavigationLink(destination: VideoDetailView(bvid: video.bvid ?? video.videoId)) {
                                    VideoCardView(video: video)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if let errorMessage = viewModel.errorMessage, !viewModel.videos.isEmpty {
                                InlineErrorView(message: errorMessage) {
                                    Task { await viewModel.loadMore() }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            if viewModel.isLoadingMore {
                                ProgressView("加载中...")
                                    .padding(.vertical, 12)
                            } else if viewModel.hasMore {
                                ProgressView()
                                    .onAppear {
                                        Task { await viewModel.loadMore() }
                                    }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeNavigationBar(showSearch: $showSearch)
                .background(.ultraThinMaterial)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .overlay {
            if showSearch {
                SearchView(isPresented: $showSearch)
                    .transition(.move(edge: .top))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSearch)
    }
}


// MARK: - Home Navigation Bar
struct HomeNavigationBar: View {
    @Binding var showSearch: Bool
    @State private var selectedTab = 0
    let tabs = ["推荐", "热门", "影视", "直播"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Logo
                Text("BiliBili")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.bilibiliPink)
                
                Spacer()
                
                // Search button
                Button {
                    showSearch = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        Text("搜索")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, SafeAreaHelper.topInset)
            .padding(.bottom, 8)
            
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button {
                            withAnimation { selectedTab = index }
                        } label: {
                            VStack(spacing: 4) {
                                Text(tabs[index])
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                                    .foregroundColor(selectedTab == index ? Color.bilibiliPink : .primary)
                                
                                Rectangle()
                                    .fill(Color.bilibiliPink)
                                    .frame(width: 20, height: 2)
                                    .opacity(selectedTab == index ? 1 : 0)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Banner View (placeholder)
struct BannerView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FB7299"), Color(hex: "F25D8E"), Color(hex: "FF6C6C")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 140)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("BiliBili")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("原生 iOS 客户端")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}

// MARK: - Video Card View
struct VideoCardView: View {
    let video: VideoItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Cover image
            ZStack(alignment: .bottomTrailing) {
                BiliAsyncImage(url: video.coverURL)
                    .frame(width: 170, height: 100)
                    .cornerRadius(8)
                
                // Duration badge
                if video.duration > 0 {
                    Text("\(video.duration).formatDuration()")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(4)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title.htmlDecoded)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Author
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 14, height: 14)
                    Text(video.owner.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Stats
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatPlayCount(video.stat.view))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "message")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatPlayCount(video.stat.danmaku))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Video Card Grid View (for popular)
struct VideoGridCardView: View {
    let video: VideoItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                BiliAsyncImage(url: video.coverURL)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .clipped()
                
                if video.duration > 0 {
                    Text("\(video.duration).formatDuration()")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(4)
                }
            }
            
            Text(video.title.htmlDecoded)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            HStack(spacing: 4) {
                Image(systemName: "play.circle")
                    .font(.caption2)
                Text(formatPlayCount(video.stat.view))
                    .font(.caption2)
                Text("·")
                Text(video.owner.name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Home ViewModel
class HomeViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var isInitialLoading = true
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var currentPage = 1
    @Published var errorMessage: String?
    
    private let api = BiliAPI.shared
    
    init() {
        Task { await refresh() }
    }
    
    @MainActor
    func refresh() async {
        currentPage = 1
        hasMore = true
        errorMessage = nil
        isInitialLoading = true
        defer { isInitialLoading = false }
        await loadVideos(page: 1, append: false)
    }
    
    @MainActor
    func loadMore() async {
        guard !isInitialLoading, !isLoadingMore, hasMore else { return }
        await loadVideos(page: currentPage, append: true)
    }
    
    @MainActor
    private func loadVideos(page: Int, append: Bool) async {
        if append {
            isLoadingMore = true
        }
        defer { isLoadingMore = false }
        
        do {
            let newVideos = try await api.getHomeFeed(page: page)
            errorMessage = nil
            if append {
                videos.append(contentsOf: newVideos)
            } else {
                videos = newVideos
            }
            currentPage = page + 1
            hasMore = newVideos.count >= 20
        } catch {
            errorMessage = error.localizedDescription
            if !append {
                videos = []
            }
        }
    }
}

