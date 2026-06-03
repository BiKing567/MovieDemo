import SwiftUI
import AVKit
import AVFoundation

#if os(macOS)
class VideoPlayerWindowController: NSWindowController {
    static var shared: VideoPlayerWindowController?
    
    static func open(videoSource: VideoSource, movie: Movie) {
        let windowController = VideoPlayerWindowController(videoSource: videoSource, movie: movie)
        shared = windowController
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
    }
    
    private let videoSource: VideoSource
    private let movie: Movie
    
    init(videoSource: VideoSource, movie: Movie) {
        self.videoSource = videoSource
        self.movie = movie
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 720),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = movie.title
        
        super.init(window: window)
        
        let hostingView = NSHostingView(rootView: MacVideoPlayerView(videoSource: videoSource, movie: movie, isPresented: .init(get: { true }, set: { newValue in
            if !newValue {
                self.close()
            }
        })))
        window.contentView = hostingView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func close() {
        VideoPlayerWindowController.shared = nil
        super.close()
    }
}
#endif

struct MacVideoPlayerView: View {
    let videoSource: VideoSource
    let movie: Movie
    @Binding var isPresented: Bool
    
    @StateObject private var playerManager = VideoPlayerManager()
    @State private var showControls = true
    @State private var hideControlsTimer: Timer?
    @State private var isResolving = true
    @State private var resolveError: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isResolving {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(2)
                        .foregroundColor(.white)
                    Text("正在解析视频源...")
                        .foregroundColor(.white)
                }
            } else if let error = resolveError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("关闭") {
                        closePlayer()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                }
            } else if let player = playerManager.player {
                SimpleAVPlayerView(player: player)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls.toggle()
                        }
                        if showControls {
                            resetHideControlsTimer()
                        } else {
                            hideControlsTimer?.invalidate()
                        }
                    }
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(2)
                        .foregroundColor(.white)
                    Text("正在加载视频...")
                        .foregroundColor(.white)
                }
            }
            
            VStack {
                HStack {
                    Button(action: {
                        closePlayer()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                            Text("返回")
                                .font(.body)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Text(movie.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .opacity(showControls ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showControls)
                
                Spacer()
                
                VStack(spacing: 12) {
                    HStack {
                        Text(formatTime(playerManager.currentTime))
                            .font(.caption)
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        Slider(
                            value: Binding(
                                get: { playerManager.currentTime },
                                set: { playerManager.seek(to: $0) }
                            ),
                            in: 0...max(playerManager.duration, 1)
                        )
                        .accentColor(.white)
                        
                        Text(formatTime(playerManager.duration))
                            .font(.caption)
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 40) {
                        Button {
                            playerManager.seekBackward(seconds: 10)
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            playerManager.togglePlayPause()
                        } label: {
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            playerManager.seekForward(seconds: 10)
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button {
                            playerManager.setVolume(playerManager.player?.volume == 0 ? 1 : 0)
                        } label: {
                            Image(systemName: playerManager.player?.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(showControls ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showControls)
            }
        }
        .onAppear {
            setupPlayer()
            resetHideControlsTimer()
        }
        .onDisappear {
            playerManager.cleanup()
            hideControlsTimer?.invalidate()
        }
    }
    
    private func setupPlayer() {
        Task { @MainActor in
            do {
                let resolvedURL = try await PlayPageResolver.shared.resolveVideoURL(from: videoSource.url)
                self.isResolving = false
                self.playerManager.loadVideo(url: resolvedURL)
                self.playerManager.play()
            } catch {
                self.isResolving = false
                self.resolveError = "视频源解析失败: \(error.localizedDescription)\n\n请尝试其他播放源"
            }
        }
    }
    
    private func resetHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
    
    private func closePlayer() {
        playerManager.cleanup()
        hideControlsTimer?.invalidate()
        isPresented = false
    }
}

#if os(macOS)
struct SimpleAVPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
#endif

private func formatTime(_ seconds: Double) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%02d:%02d", mins, secs)
}
