import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @State private var error: String?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveGridColumns: [GridItem] {
        let minWidth: CGFloat = horizontalSizeClass == .regular ? 180 : 150
        return [
            GridItem(.adaptive(minimum: minWidth, maximum: 280), spacing: 16)
        ]
    }
    
    var body: some View {
        Group {
            if isLoading && movies.isEmpty {
                VStack {
                    ProgressView("加载中...")
                }
            } else if let error = error, movies.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("重试") {
                        Task {
                            await loadMovies()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        Section {
                            LazyVGrid(columns: adaptiveGridColumns, spacing: 16) {
                                ForEach(movies) { movie in
                                    MovieCard(movie: movie)
                                        .onTapGesture {
                                            appState.selectedMovie = movie
                                        }
                                }
                            }
                            .padding(.horizontal)
                        } header: {
                            Text("推荐影视")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await loadMovies()
                }
            }
        }
        .navigationTitle("首页")
        .task {
            if movies.isEmpty {
                await loadMovies()
            }
        }
    }
    
    private func loadMovies() async {
        isLoading = true
        error = nil
        
        do {
            movies = try await RainviParserService.shared.fetchHomePage()
        } catch let err {
            error = "加载失败: \(err.localizedDescription)"
        }
        
        isLoading = false
    }
}
