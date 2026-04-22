import SwiftUI

// MARK: - Popular View
struct PopularView: View {
    @StateObject private var viewModel = PopularViewModel()
    @State private var selectedSegment = PopularViewModel.Segment.popular
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("排行", selection: $selectedSegment) {
                ForEach(PopularViewModel.Segment.allCases, id: \.self) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .onChange(of: selectedSegment) { newValue in
                Task { await viewModel.switchSegment(newValue) }
            }
            
            Group {
                if viewModel.isInitialLoading {
                    ProgressView("加载热门内容...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.items(for: selectedSegment).isEmpty {
                    ErrorStateView(
                        title: "热门内容加载失败",
                        message: errorMessage,
                        buttonTitle: "重新加载"
                    ) {
                        Task { await viewModel.switchSegment(selectedSegment, forceRefresh: true) }
                    }
                } else if viewModel.items(for: selectedSegment).isEmpty {
                    EmptyStateView(
                        title: "暂无热门内容",
                        message: "换个分类或者稍后再试。"
                    )
                } else {
                    ScrollView {
                        if selectedSegment == .popular {
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
                        
                        if let errorMessage = viewModel.errorMessage {
                            InlineErrorView(message: errorMessage) {
                                Task { await viewModel.switchSegment(selectedSegment, forceRefresh: true) }
                            }
                            .padding(16)
                        }
                    }
                    .refreshable {
                        await viewModel.switchSegment(selectedSegment, forceRefresh: true)
                    }
                }
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
    enum Segment: CaseIterable {
        case popular
        case ranking
        case weekly
        
        var title: String {
            switch self {
            case .popular: return "全站"
            case .ranking: return "排行"
            case .weekly: return "每周必看"
            }
        }
    }
    
    @Published var popularItems: [RankingItem] = []
    @Published var rankingItems: [RankingItem] = []
    @Published var weeklyItems: [RankingItem] = []
    @Published var isInitialLoading = true
    @Published var errorMessage: String?
    
    private let api = BiliAPI.shared
    
    init() {
        Task {
            await switchSegment(.popular, forceRefresh: true)
        }
    }
    
    func items(for segment: Segment) -> [RankingItem] {
        switch segment {
        case .popular: return popularItems
        case .ranking: return rankingItems
        case .weekly: return weeklyItems
        }
    }
    
    @MainActor
    func switchSegment(_ segment: Segment, forceRefresh: Bool = false) async {
        if !forceRefresh, !items(for: segment).isEmpty {
            errorMessage = nil
            return
        }
        
        isInitialLoading = true
        errorMessage = nil
        defer { isInitialLoading = false }
        
        do {
            switch segment {
            case .popular:
                popularItems = try await api.getPopular()
            case .ranking:
                rankingItems = try await api.getRanking(rid: 0, day: 3)
            case .weekly:
                weeklyItems = try await api.getWeeklyPopular()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

