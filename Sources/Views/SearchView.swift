import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var searchResults: [Movie] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveGridColumns: [GridItem] {
        let minWidth: CGFloat = horizontalSizeClass == .regular ? 180 : 150
        return [
            GridItem(.adaptive(minimum: minWidth, maximum: 280), spacing: 16)
        ]
    }
    
    private var searchBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.systemGray6)
        #endif
    }
    
    private var tagBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.tertiaryLabelColor)
        #else
        return Color(UIColor.systemGray5)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索电影、电视剧、综艺...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(searchBackgroundColor)
            .cornerRadius(10)
            .padding()
            
            if !appState.searchHistory.isEmpty && searchText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("搜索历史")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("清除") {
                            appState.clearSearchHistory()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(appState.searchHistory, id: \.self) { keyword in
                                Button {
                                    searchText = keyword
                                    performSearch()
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(keyword)
                                            .font(.subheadline)
                                        Image(systemName: "arrow.up.left")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(tagBackgroundColor)
                                    .cornerRadius(16)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("删除") {
                                        appState.removeSearchKeyword(keyword)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            
            Divider()
            
            if isSearching {
                Spacer()
                ProgressView("搜索中...")
                Spacer()
            } else if hasSearched && searchResults.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("没有找到相关结果")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if !searchResults.isEmpty {
                ScrollView {
                    LazyVGrid(columns: adaptiveGridColumns, spacing: 16) {
                        ForEach(searchResults) { movie in
                            MovieCard(movie: movie)
                                .onTapGesture {
                                    appState.selectedMovie = movie
                                }
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "film")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("搜索你喜欢的影视内容")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .navigationTitle("搜索")
    }
    
    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        appState.addSearchKeyword(trimmed)
        hasSearched = true
        isSearching = true
        
        Task {
            do {
                let results = try await RainviParserService.shared.searchMovies(keyword: trimmed)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}
