import SwiftUI

struct DanmakuOverlayView: View {
    let danmaku: [Danmaku]
    let currentTime: Double
    let opacity: Double
    let fontSize: Double
    let size: CGSize
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let currentTime = currentTime
                let visibleDanmaku = danmaku.filter { danmaku in
                    danmaku.time <= currentTime && danmaku.time + 4.0 > currentTime
                }
                
                var trackUsage: [Int: CGFloat] = [:]
                let trackHeight: CGFloat = CGFloat(fontSize) + 10
                let numberOfTracks = Int(canvasSize.height / trackHeight)
                
                for danmaku in visibleDanmaku {
                    let track = findAvailableTrack(
                        danmaku: danmaku,
                        canvasSize: canvasSize,
                        trackUsage: &trackUsage,
                        trackHeight: trackHeight,
                        numberOfTracks: numberOfTracks
                    )
                    
                    if track != -1 {
                        let xPosition = canvasSize.width
                        let yPosition = CGFloat(track) * trackHeight + 10
                        
                        let text = Text(danmaku.text)
                            .font(.system(size: CGFloat(danmaku.fontSize)))
                            .foregroundColor(Color(hex: danmaku.color))
                        
                        context.opacity = opacity
                        context.draw(text, at: CGPoint(x: xPosition, y: yPosition), anchor: .leading)
                    }
                }
            }
        }
    }
    
    private func findAvailableTrack(
        danmaku: Danmaku,
        canvasSize: CGSize,
        trackUsage: inout [Int: CGFloat],
        trackHeight: CGFloat,
        numberOfTracks: Int
    ) -> Int {
        let textWidth = CGFloat(danmaku.text.count) * CGFloat(danmaku.fontSize) * 0.6
        let timeSinceStart = currentTime - danmaku.time
        
        for track in 0..<numberOfTracks {
            let trackEndTime = trackUsage[track] ?? 0
            
            if timeSinceStart > trackEndTime {
                let newEndTime = timeSinceStart + (textWidth / 100.0)
                trackUsage[track] = newEndTime
                return track
            }
        }
        
        return 0
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
