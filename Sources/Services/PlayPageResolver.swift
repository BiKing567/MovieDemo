import Foundation

actor PlayPageResolver {
    static let shared = PlayPageResolver()
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func resolveVideoURL(from playPageURL: String) async throws -> String {
        if isDirectMediaURL(playPageURL) {
            return playPageURL
        }
        
        let html = try await networkService.fetchHTML(from: playPageURL)
        
        if let m3u8 = extractM3U8URL(from: html), !m3u8.isEmpty {
            return normalizeURL(m3u8)
        }
        
        if let mp4 = extractMP4URL(from: html), !mp4.isEmpty {
            return normalizeURL(mp4)
        }
        
        if let flv = extractFLVURL(from: html), !flv.isEmpty {
            return normalizeURL(flv)
        }
        
        if let encryptedURL = extractAndDecryptMaccmsURL(from: html) {
            return encryptedURL
        }
        
        if let iframe = extractIframeURL(from: html), !iframe.isEmpty {
            let iframeURL = normalizeURL(iframe)
            if isDirectMediaURL(iframeURL) {
                return iframeURL
            }
            return try await resolveVideoURL(from: iframeURL)
        }
        
        throw PlayPageError.noVideoFound
    }
    
    private func isDirectMediaURL(_ url: String) -> Bool {
        let lower = url.lowercased()
        return lower.contains(".m3u8") || 
               lower.contains(".mp4") || 
               lower.contains(".flv") ||
               lower.contains(".webm") ||
               lower.contains(".ts")
    }
    
    private func extractM3U8URL(from html: String) -> String? {
        let patterns = [
            "url\\s*[:=]\\s*['\"]([^'\"]*\\.m3u8[^'\"]*)['\"]",
            "\"url\"\\s*:\\s*\"([^\"]*\\.m3u8[^\"]*)\"",
            "src\\s*[:=]\\s*['\"]([^'\"]*\\.m3u8[^'\"]*)['\"]",
            "(https?://[^\\s\"'<>]+\\.m3u8[^\\s\"'<>]*)",
            "player_url\\s*=\\s*['\"]([^'\"]*\\.m3u8[^'\"]*)['\"]",
            "videoUrl\\s*[:=]\\s*['\"]([^'\"]*\\.m3u8[^'\"]*)['\"]",
            "playUrl\\s*[:=]\\s*['\"]([^'\"]*\\.m3u8[^'\"]*)['\"]"
        ]
        
        for pattern in patterns {
            if let url = firstMatch(in: html, pattern: pattern) {
                return cleanURL(url)
            }
        }
        return nil
    }
    
    private func extractMP4URL(from html: String) -> String? {
        let patterns = [
            "(https?://[^\\s\"'<>]+\\.mp4[^\\s\"'<>]*)",
            "url\\s*[:=]\\s*['\"]([^'\"]*\\.mp4[^'\"]*)['\"]"
        ]
        
        for pattern in patterns {
            if let url = firstMatch(in: html, pattern: pattern) {
                return cleanURL(url)
            }
        }
        return nil
    }
    
    private func extractFLVURL(from html: String) -> String? {
        let patterns = [
            "(https?://[^\\s\"'<>]+\\.flv[^\\s\"'<>]*)",
            "url\\s*[:=]\\s*['\"]([^'\"]*\\.flv[^'\"]*)['\"]"
        ]
        
        for pattern in patterns {
            if let url = firstMatch(in: html, pattern: pattern) {
                return cleanURL(url)
            }
        }
        return nil
    }
    
    private func extractIframeURL(from html: String) -> String? {
        let patterns = [
            "iframe[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"]",
            "<iframe\\s+src=\"([^\"]+)\""
        ]
        for pattern in patterns {
            if let url = firstMatch(in: html, pattern: pattern) {
                return cleanURL(url)
            }
        }
        return nil
    }
    
    private func extractAndDecryptMaccmsURL(from html: String) -> String? {
        let pattern = "player_aaaa\\s*=\\s*(\\{[^<]*?\\})\\s*<"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges >= 2,
              let jsonRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        var jsonString = String(html[jsonRange])
        if jsonString.hasSuffix(">") {
            jsonString = String(jsonString.dropLast())
        }
        
        return decryptMaccmsURL(jsonString: jsonString)
    }
    
    private func decryptMaccmsURL(jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        guard let encryptedURL = json["url"] as? String, !encryptedURL.isEmpty else {
            return nil
        }
        
        guard let url = decodeMaccmsEncryptedURL(encryptedURL) else {
            return nil
        }
        
        return url
    }
    
    private func decodeMaccmsEncryptedURL(_ encrypted: String) -> String? {
        guard let decoded1 = base64Decode(encrypted) else {
            return nil
        }
        
        if isDirectMediaURL(decoded1) {
            return decoded1
        }
        
        if decoded1.hasPrefix("%") || decoded1.contains("%3A") || decoded1.contains("%2F") {
            return urlDecode(decoded1)
        }
        
        if let decoded2 = base64Decode(decoded1) {
            if isDirectMediaURL(decoded2) {
                return decoded2
            }
            if decoded2.hasPrefix("%") || decoded2.contains("%3A") {
                return urlDecode(decoded2)
            }
            return decoded2
        }
        
        return decoded1
    }
    
    private func base64Decode(_ string: String) -> String? {
        let cleaned = string.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        
        var padded = cleaned
        let remainder = padded.count % 4
        if remainder > 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: padded) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func urlDecode(_ string: String) -> String? {
        return string.removingPercentEncoding
    }
    
    private func firstMatch(in html: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range) {
            if let r = Range(match.range(at: 1), in: html) {
                return String(html[r])
            }
        }
        return nil
    }
    
    private func cleanURL(_ url: String) -> String {
        return url.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\\\/", with: "/")
            .replacingOccurrences(of: "\\\"", with: "\"")
    }
    
    private func normalizeURL(_ url: String) -> String {
        let cleaned = cleanURL(url)
        
        if cleaned.hasPrefix("//") {
            return "https:" + cleaned
        } else if cleaned.hasPrefix("/") {
            return "https://www.rainvi.com" + cleaned
        } else if !cleaned.hasPrefix("http") {
            return "https://" + cleaned
        }
        return cleaned
    }
}

enum PlayPageError: LocalizedError {
    case noVideoFound
    
    var errorDescription: String? {
        switch self {
        case .noVideoFound:
            return "未找到视频源"
        }
    }
}
