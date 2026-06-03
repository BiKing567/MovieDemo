import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @EnvironmentObject var appState: AppState
    @State private var imageData: Data?
    @State private var isFavorite: Bool = false
    @State private var selectedVideoSource: VideoSource?
    @State private var videoSources: [VideoSource] = []
    @State private var videoLines: [VideoLine] = []
    @State private var isLoadingVideos = false
    @State private var detailedMovie: Movie?
    @State private var isLoadingDetails = false
    @State private var selectedLineIndex = 0
    
    private var currentMovie: Movie {
        detailedMovie ?? movie
    }
    
    private var currentLine: VideoLine? {
        guard selectedLineIndex < videoLines.count else { return nil }
        return videoLines[selectedLineIndex]
    }
    
    var body: some View {
        #if os(macOS)
        if #available(macOS 13.0, *) {
            NavigationStack {
                ScrollView {
                    contentView
                }
                .navigationTitle(movie.title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("关闭") {
                            appState.selectedMovie = nil
                        }
                    }
                }
                .onAppear {
                    isFavorite = appState.isFavorite(movie)
                    appState.addToHistory(movie)
                    loadMovieDetails()
                    loadVideoLines()
                }
            }
        } else {
            NavigationView {
                ScrollView {
                    contentView
                }
                .navigationTitle(movie.title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("关闭") {
                            appState.selectedMovie = nil
                        }
                    }
                }
                .onAppear {
                    isFavorite = appState.isFavorite(movie)
                    appState.addToHistory(movie)
                    loadMovieDetails()
                    loadVideoLines()
                }
            }
        }
        #else
        if #available(iOS 16.0, *) {
            NavigationStack {
                scrollViewContent
                    .sheet(isPresented: .constant(selectedVideoSource != nil)) {
                        if let source = selectedVideoSource {
                            VideoPlayerView(videoSource: source, movie: movie, onDismiss: { selectedVideoSource = nil })
                        }
                    }
            }
        } else {
            NavigationView {
                scrollViewContent
                    .sheet(isPresented: .constant(selectedVideoSource != nil)) {
                        if let source = selectedVideoSource {
                            VideoPlayerView(videoSource: source, movie: movie, onDismiss: { selectedVideoSource = nil })
                        }
                    }
            }
        }
        .onAppear {
            isFavorite = appState.isFavorite(movie)
            appState.addToHistory(movie)
            loadMovieDetails()
            loadVideoLines()
        }
        #endif
    }
    
    private var scrollViewContent: some View {
        ScrollView {
            contentView
        }
    }
    
    private func loadMovieDetails() {
        isLoadingDetails = true
        Task {
            do {
                let details = try await RainviParserService.shared.fetchMovieDetail(movieId: movie.id)
                await MainActor.run {
                    self.detailedMovie = details
                    self.isLoadingDetails = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingDetails = false
                }
            }
        }
    }
    
    private func loadVideoLines() {
        isLoadingVideos = true
        Task {
            do {
                let lines = try await RainviParserService.shared.fetchVideoLines(movieId: movie.id)
                await MainActor.run {
                    self.videoLines = lines
                    self.videoSources = lines.flatMap { $0.episodes }
                    self.isLoadingVideos = false
                }
            } catch {
                await MainActor.run {
                    self.videoLines = []
                    self.videoSources = []
                    self.isLoadingVideos = false
                }
            }
        }
    }
    
    private func playVideo(_ source: VideoSource) {
        #if os(macOS)
        VideoPlayerWindowController.open(videoSource: source, movie: movie)
        #else
        selectedVideoSource = source
        #endif
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                AsyncImageView(url: currentMovie.coverUrl, data: $imageData)
                    .frame(width: 200, height: 280)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(currentMovie.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        TagView(text: currentMovie.category)
                        if !currentMovie.year.isEmpty {
                            TagView(text: currentMovie.year)
                        }
                        if !currentMovie.region.isEmpty {
                            TagView(text: currentMovie.region)
                        }
                        if !currentMovie.language.isEmpty {
                            TagView(text: currentMovie.language)
                        }
                    }
                    
                    if !currentMovie.updateDate.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("更新: \(currentMovie.updateDate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !currentMovie.director.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "film")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("导演: \(currentMovie.director)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !currentMovie.actors.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "users")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("主演: \(currentMovie.actors)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .lineLimit(nil)
                    }
                    
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(isFavorite ? "已收藏" : "添加收藏",
                              systemImage: isFavorite ? "star.fill" : "star")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isFavorite ? .orange : .blue)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("剧情简介")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text(currentMovie.description.isEmpty ? "暂无简介" : currentMovie.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("播放列表")
                    .font(.headline)
                    .padding(.horizontal)
                
                if isLoadingVideos {
                    ProgressView("加载播放源...")
                        .padding()
                } else if videoLines.isEmpty {
                    Text("暂无播放源")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    if videoLines.count > 1 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("播放源：")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(videoLines.enumerated()), id: \.element.id) { index, line in
                                        Button {
                                            selectedLineIndex = index
                                        } label: {
                                            Text(line.name)
                                                .font(.subheadline)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedLineIndex == index ? Color.blue : Color.secondary.opacity(0.15))
                                                .foregroundColor(selectedLineIndex == index ? .white : .primary)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    if let currentLine = currentLine, !currentLine.episodes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("选集：")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 70, maximum: 100))
                            ], spacing: 10) {
                                ForEach(currentLine.episodes) { episode in
                                    Button {
                                        playVideo(episode)
                                    } label: {
                                        Text(episode.name)
                                            .font(.subheadline)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.secondary.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func toggleFavorite() {
        if isFavorite {
            appState.removeFromFavorites(movie)
        } else {
            appState.addToFavorites(movie)
        }
        isFavorite.toggle()
    }
}
