import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct AsyncImageView: View {
    let url: String
    @Binding var data: Data?
    @State private var imageLoaded = false
    
    var body: some View {
        ZStack {
            if let data = data, let image = createImage(from: data) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if imageLoaded {
                placeholderView
            } else {
                loadingView
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard data == nil, !imageLoaded else { return }
        
        Task {
            do {
                let loadedData = try await NetworkService.shared.downloadImage(from: url)
                await MainActor.run {
                    self.data = loadedData
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
            Image(systemName: "photo")
                .font(.title)
                .foregroundColor(.gray)
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            ProgressView()
        }
    }
}
