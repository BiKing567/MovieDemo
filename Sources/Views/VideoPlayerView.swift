import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoSource: VideoSource
    let movie: Movie
    let onDismiss: () -> Void
    
    @StateObject private var playerManager = VideoPlayerManager()
    @State private var showControls = true
    @State private var hideControlsTimer: Timer?
    @State private var danmaku: [Danmaku] = []
    @State private var showDanmaku = true
    @State private var danmakuOpacity: Double = 1.0
    @State private var danmakuSize: Double = 25
    @State private var isResolving = true
    @State private var resolveError: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
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
                        
                        Button("返回") {
                            onDismiss()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.white)
                    }
                } else if let player = playerManager.player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showControls.toggle()
                            }
                            resetHideControlsTimer()
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
                
                if showDanmaku && !danmaku.isEmpty {
                    DanmakuOverlayView(
                        danmaku: danmaku,
                        currentTime: playerManager.currentTime,
                        opacity: danmakuOpacity,
                        fontSize: danmakuSize,
                        size: geometry.size
                    )
                    .allowsHitTesting(false)
                }
                
                VStack {
                    HStack {
                        Button(action: onDismiss) {
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
                        .padding(16)
                        
                        Spacer()
                        
                        Text(movie.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(10)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .opacity(showControls ? 1 : 0)
                        
                        Spacer()
                        
                        Menu {
                            Toggle("显示弹幕", isOn: $showDanmaku)
                            
                            Divider()
                            
                            Button("小") {
                                danmakuSize = 18
                            }
                            Button("中") {
                                danmakuSize = 25
                            }
                            Button("大") {
                                danmakuSize = 35
                            }
                            
                            Divider()
                            
                            Button("透明度: 100%") {
                                danmakuOpacity = 1.0
                            }
                            Button("透明度: 70%") {
                                danmakuOpacity = 0.7
                            }
                            Button("透明度: 40%") {
                                danmakuOpacity = 0.4
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                        .opacity(showControls ? 1 : 0)
                    }
                    .padding(.top, geometry.safeAreaInsets.top)
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
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 30)
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
        }
        .ignoresSafeArea()
        .onAppear {
            setupPlayer()
            loadDanmaku()
            resetHideControlsTimer()
        }
        .onDisappear {
            playerManager.cleanup()
            hideControlsTimer?.invalidate()
        }
    }
    
    private func setupPlayer() {
        Task {
            do {
                let resolvedURL = try await PlayPageResolver.shared.resolveVideoURL(from: videoSource.url)
                await MainActor.run {
                    self.isResolving = false
                    self.playerManager.loadVideo(url: resolvedURL)
                    self.playerManager.play()
                }
            } catch {
                await MainActor.run {
                    self.isResolving = false
                    self.resolveError = "视频源解析失败: \(error.localizedDescription)\n\n请尝试其他播放源"
                }
            }
        }
    }
    
    private func loadDanmaku() {
        Task {
            do {
                danmaku = try await DanmakuService.shared.fetchDanmaku(for: movie.id)
                if danmaku.isEmpty {
                    danmaku = DanmakuService.shared.generateSampleDanmaku()
                }
            } catch {
                danmaku = DanmakuService.shared.generateSampleDanmaku()
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
}

private func formatTime(_ seconds: Double) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%02d:%02d", mins, secs)
}
