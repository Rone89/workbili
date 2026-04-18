import SwiftUI

// MARK: - Dynamic View
struct DynamicView: View {
    @StateObject private var viewModel = DynamicViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.dynamics) { dynamic in
                    if let modules = dynamic.modules,
                       let author = modules.moduleAuthor,
                       let content = modules.moduleDynamic {
                        DynamicCardView(
                            author: author,
                            content: content
                        )
                        .padding(.vertical, 8)
                        
                        Divider().padding(.horizontal, 16)
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                if !viewModel.isLoading && viewModel.hasMore {
                    Color.clear
                        .frame(height: 1)
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
        .navigationTitle("动态")
    }
}

// MARK: - Dynamic Card View
struct DynamicCardView: View {
    let author: DynamicAuthor
    let content: DynamicContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Author header
            HStack(spacing: 10) {
                BiliAsyncImage(url: author.face)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(author.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let pubTime = author.pubTime {
                        Text(pubTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            // Content
            if let archive = content.major?.archive {
                NavigationLink(destination: VideoDetailView(bvid: archive.bvid ?? "")) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            // Description text
                            if let descText = content.desc?.text, !descText.isEmpty {
                                Text(descText)
                                    .font(.subheadline)
                                    .lineLimit(3)
                            }
                            
                            // Video info
                            HStack(spacing: 8) {
                                Text(archive.title?.htmlDecoded ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            // Stats
                            HStack(spacing: 12) {
                                if let view = archive.stat?.view {
                                    HStack(spacing: 3) {
                                        Image(systemName: "play.circle")
                                            .font(.caption2)
                                        Text(formatPlayCount(view))
                                            .font(.caption2)
                                    }
                                }
                                if let danmaku = archive.stat?.danmaku {
                                    HStack(spacing: 3) {
                                        Image(systemName: "message")
                                            .font(.caption2)
                                        Text(formatPlayCount(danmaku))
                                            .font(.caption2)
                                    }
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Cover
                        ZStack(alignment: .bottomTrailing) {
                            BiliAsyncImage(url: archive.cover ?? "")
                                .frame(width: 130, height: 80)
                                .cornerRadius(8)
                            
                            if let dur = archive.durationText {
                                Text(dur)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(3)
                                    .padding(3)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Dynamic ViewModel
class DynamicViewModel: ObservableObject {
    @Published var dynamics: [DynamicItem] = []
    @Published var isLoading = false
    @Published var hasMore = true
    
    private var offset: String = ""
    private var updateBaseline: String = ""
    private let api = BiliAPI.shared
    
    init() {
        Task { await refresh() }
    }
    
    @MainActor
    func refresh() async {
        offset = ""
        updateBaseline = ""
        hasMore = true
        
        do {
            let feed = try await api.getDynamicFeed()
            dynamics = feed.items ?? []
            offset = feed.offset ?? ""
            updateBaseline = feed.updateBaseline ?? ""
            hasMore = feed.hasMore
        } catch {
            print("Dynamic refresh error: \(error)")
        }
    }
    
    @MainActor
    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let feed = try await api.getDynamicFeed(offset: offset, updateBaseline: updateBaseline)
            let newItems = feed.items ?? []
            dynamics.append(contentsOf: newItems)
            offset = feed.offset ?? ""
            updateBaseline = feed.updateBaseline ?? ""
            hasMore = feed.hasMore
        } catch {
            print("Dynamic load more error: \(error)")
        }
    }
}
