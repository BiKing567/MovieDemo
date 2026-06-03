import Foundation

actor DanmakuService {
    static let shared = DanmakuService()
    
    private init() {}
    
    func fetchDanmaku(for movieId: String) async throws -> [Danmaku] {
        let url = "https://example.com/api/danmaku/\(movieId)"
        let html = try await NetworkService.shared.fetchHTML(from: url)
        return parseDanmakuFromHTML(html)
    }
    
    private func parseDanmakuFromHTML(_ html: String) -> [Danmaku] {
        var danmakuList: [Danmaku] = []
        
        let pattern = "<d p=\"([^\"]+)\">([^<]+)</d>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return danmakuList
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            
            let timeStr = extractString(from: html, match: match, at: 1)
            let text = extractString(from: html, match: match, at: 2)
            
            let components = timeStr.components(separatedBy: ",")
            let time = Double(components.first ?? "0") ?? 0.0
            let color = components.count > 3 ? "#\(components[3])" : "#FFFFFF"
            let fontSize = components.count > 4 ? Int(components[4]) ?? 25 : 25
            
            let danmaku = Danmaku(
                id: UUID().uuidString,
                text: text,
                time: time,
                color: color,
                fontSize: fontSize
            )
            danmakuList.append(danmaku)
        }
        
        return danmakuList
    }
    
    private func extractString(from html: String, match: NSTextCheckingResult, at index: Int) -> String {
        guard index < match.numberOfRanges,
              let range = Range(match.range(at: index), in: html) else {
            return ""
        }
        return String(html[range])
    }
    
    func generateSampleDanmaku() -> [Danmaku] {
        let sampleTexts = [
            "太精彩了！", "这也太好笑了吧", "233333", "支持！",
            "前排", "来看看", "不错不错", "顶一个",
            "666", "厉害", "这个必须赞", "真香",
            "我笑了", "哈哈哈", "awsl", "奥利给"
        ]
        
        var danmakuList: [Danmaku] = []
        let colors = ["#FFFFFF", "#FF0000", "#00FF00", "#FFFF00", "#FF00FF", "#00FFFF"]
        
        for i in 0..<50 {
            let time = Double.random(in: 0...120)
            let text = sampleTexts.randomElement() ?? "弹幕"
            let color = colors.randomElement() ?? "#FFFFFF"
            let fontSize = [20, 25, 30].randomElement() ?? 25
            
            let danmaku = Danmaku(
                id: UUID().uuidString,
                text: text,
                time: time,
                color: color,
                fontSize: fontSize
            )
            danmakuList.append(danmaku)
        }
        
        return danmakuList.sorted { $0.time < $1.time }
    }
}
