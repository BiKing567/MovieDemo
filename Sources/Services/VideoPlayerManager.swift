import Foundation
import AVFoundation
import Combine

class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    
    @Published var player: AVPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering: Bool = false
    @Published var error: String?
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    func loadVideo(url: String) {
        guard let videoURL = URL(string: url) else {
            self.error = "无效的视频 URL"
            return
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)
        
        self.player = player
        self.isPlaying = false
        self.currentTime = 0
        self.duration = 0
        self.error = nil
        
        setupObservers(playerItem: playerItem)
    }
    
    func loadVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        
        self.player = player
        self.isPlaying = false
        self.currentTime = 0
        self.duration = 0
        self.error = nil
        
        setupObservers(playerItem: playerItem)
    }
    
    private func setupObservers(playerItem: AVPlayerItem) {
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.duration = playerItem.duration.seconds
                    self?.error = nil
                case .failed:
                    self?.error = playerItem.error?.localizedDescription ?? "播放失败"
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        playerItem.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.isBuffering = isEmpty
            }
            .store(in: &cancellables)
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPlaying = false
                self?.seek(to: 0)
            }
            .store(in: &cancellables)
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func seekForward(seconds: Double = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func seekBackward(seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
    
    func setPlaybackRate(_ rate: Float) {
        player?.rate = rate
    }
    
    func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
        cancellables.removeAll()
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    
    deinit {
        cleanup()
    }
}
