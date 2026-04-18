import SwiftUI

// MARK: - Popular View
struct PopularView: View {
    @StateObject private var viewModel = PopularViewModel()
    @State private var selectedSegment = 0
    let segments = ["全站", "原创", "每周必看"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Segment control
            Picker("排行", selection: $selectedSegment) {
                ForEach(0..<segments.count, id: \.self) { i in
                    Text(segments[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Content
            ScrollView {
                if selectedSegment == 0 {
                    // Popular grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 16) {
                        ForEach(viewModel.popularItems) { item in
                            NavigationLink(destination: VideoDetailView(bvid: item.bvid)) {
                                VideoGridCardView(video: item.toVideoItem)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    // Ranking list
                    LazyVStack(spacing: 12) {
                        ForEach(Array(viewModel.rankingItems.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(destination: VideoDetailView(bvid: item.bvid)) {
                                RankingRowView(index: index, item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Load more
                if !viewModel.isLoading {
                    ProgressView()
                        .onAppear {
                            Task { await viewModel.loadMore() }
                        }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationTitle("热门")
    }
}

// MARK: - Ranking Row View
struct RankingRowView: View {
    let index: Int
    let item: RankingItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(index + 1)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(index < 3 ? Color.bilibiliPink : .secondary)
                .frame(width: 30)
            
            // Cover
            ZStack(alignment: .bottomTrailing) {
                BiliAsyncImage(url: item.pic)
                    .frame(width: 140, height: 85)
                    .cornerRadius(8)
                
                Text("\(item.duration).formatDuration()")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(4)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title.htmlDecoded)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(item.owner.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.circle")
                            .font(.caption2)
                        Text(formatPlayCount(item.stat.view))
                            .font(.caption2)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "hand.thumbsup")
                            .font(.caption2)
                        Text(formatPlayCount(item.stat.like))
                            .font(.caption2)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Popular ViewModel
class PopularViewModel: ObservableObject {
    @Published var popularItems: [RankingItem] = []
    @Published var rankingItems: [RankingItem] = []
    @Published var isLoading = false
    
    private let api = BiliAPI.shared
    
    init() {
        Task {
            await refresh()
        }
    }
    
    @MainActor
    func refresh() async {
        async let popular = api.getPopular()
        async let ranking = api.getRanking()
        
        do {
            popularItems = try await popular
            rankingItems = try await ranking
        } catch {
            print("Popular refresh error: \(error)")
        }
    }
    
    @MainActor
    func loadMore() async {
        // Popular API doesn't support pagination well, but we can try
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let items = try await api.getPopular(page: popularItems.count / 20 + 1)
            popularItems.append(contentsOf: items)
        } catch {
            print("Load more error: \(error)")
        }
    }
}
