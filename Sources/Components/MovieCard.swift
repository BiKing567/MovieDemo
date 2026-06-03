import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct MovieCard: View {
    let movie: Movie
    @State private var imageData: Data?
    @EnvironmentObject var appState: AppState
    @State private var isFavorite: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                if let data = imageData, let image = createImage(from: data) {
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } else if imageLoaded {
                    placeholderView
                } else {
                    loadingView
                }
                
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(6)
            }
            .aspectRatio(2/3, contentMode: .fill)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(alignment: .center, spacing: 4) {
                    if movie.rating > 0 {
                        HStack(spacing: 1) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(String(format: "%.1f", movie.rating))
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if !movie.category.isEmpty {
                        Text(movie.category)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 2)
        }
        .onAppear {
            isFavorite = appState.isFavorite(movie)
            loadImage()
        }
    }
    
    @State private var imageLoaded = false
    
    private func loadImage() {
        guard imageData == nil, !imageLoaded else { return }
        
        Task {
            do {
                let data = try await NetworkService.shared.downloadImage(from: movie.coverUrl)
                await MainActor.run {
                    self.imageData = data
                    self.imageLoaded = true
                }
            } catch {
                await MainActor.run {
                    self.imageLoaded = true
                }
            }
        }
    }
    
    private func createImage(from data: Data) -> Image? {
        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #else
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #endif
        return nil
    }
    
    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.3)
            VStack(spacing: 6) {
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundColor(.gray)
                Button(action: loadImage) {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .aspectRatio(2/3, contentMode: .fill)
    }
    
    private var loadingView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            ProgressView()
        }
        .aspectRatio(2/3, contentMode: .fill)
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