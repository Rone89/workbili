import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = SearchViewModel()
    
    init(isPresented: Binding<Bool> = .constant(true)) {
        _isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索视频、UP主", text: $viewModel.keyword)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task { await viewModel.search() }
                        }
                        .submitLabel(.search)
                    
                    if !viewModel.keyword.isEmpty {
                        Button {
                            viewModel.keyword = ""
                            viewModel.results = []
                            viewModel.errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                if isPresented {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(Color.bilibiliPink)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, SafeAreaHelper.topInset + 8)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
            
            Group {
                if viewModel.isSearching && viewModel.results.isEmpty {
                    ProgressView("搜索中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.results.isEmpty {
                    ErrorStateView(
                        title: "搜索失败",
                        message: errorMessage,
                        buttonTitle: "重试"
                    ) {
                        Task { await viewModel.search() }
                    }
                } else if viewModel.results.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("热门搜索")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(SearchViewModel.hotSearches, id: \.self) { keyword in
                                Button {
                                    viewModel.keyword = keyword
                                    Task { await viewModel.search() }
                                } label: {
                                    Text(keyword)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(16)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.results) { item in
                                NavigationLink(destination: VideoDetailView(bvid: item.bvid)) {
                                    VideoCardView(video: item.toVideoItem)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if let errorMessage = viewModel.errorMessage {
                                InlineErrorView(message: errorMessage) {
                                    Task { await viewModel.loadMore() }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            if viewModel.isSearching {
                                ProgressView()
                                    .padding()
                            } else if viewModel.hasMore {
                                ProgressView()
                                    .onAppear {
                                        Task { await viewModel.loadMore() }
                                    }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}


// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: ProposedViewSize(result.sizes[index]))
        }
    }
    
    private func layout(in width: CGFloat, subviews: Subviews) -> (positions: [CGPoint], sizes: [CGSize], size: CGSize) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let dimensions = subview.dimensions(in: .unspecified)
            let size = CGSize(width: dimensions.width, height: dimensions.height)
            sizes.append(size)
            
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        
        return (positions, sizes, CGSize(width: width, height: totalHeight))
    }
}

// MARK: - Search ViewModel
class SearchViewModel: ObservableObject {
    @Published var keyword: String = ""
    @Published var results: [SearchItem] = []
    @Published var isSearching = false
    @Published var currentPage = 1
    @Published var hasMore = true
    @Published var errorMessage: String?
    
    static let hotSearches = [
        "鬼畜", "游戏", "音乐", "舞蹈", "科技", "生活", "美食",
        "动漫", "电影", "纪录片", "搞笑", "知识", "运动", "时尚"
    ]
    
    private let api = BiliAPI.shared
    
    @MainActor
    func search() async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        currentPage = 1
        hasMore = true
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        
        do {
            let result = try await api.search(keyword: keyword)
            results = result.result ?? []
            hasMore = (result.result?.count ?? 0) >= 20
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
    }
    
    @MainActor
    func loadMore() async {
        guard !isSearching, hasMore else { return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        
        do {
            let result = try await api.search(keyword: keyword, page: currentPage + 1)
            let newItems = result.result ?? []
            results.append(contentsOf: newItems)
            currentPage += 1
            hasMore = newItems.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

