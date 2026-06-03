import Foundation

actor RainviParserService {
    static let shared = RainviParserService()
    
    private let baseURL = "https://www.rainvi.com"
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func fetchHomePage() async throws -> [Movie] {
        let html = try await networkService.fetchHTML(from: baseURL)
        return parseHomePageMovies(from: html)
    }
    
    func searchMovies(keyword: String) async throws -> [Movie] {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let searchURL = "\(baseURL)/index.php/vod/search.html?wd=\(encodedKeyword)&submit="
        let html = try await networkService.fetchHTML(from: searchURL)
        return parseSearchResults(from: html)
    }
    
    func fetchMovieDetail(movieId: String) async throws -> Movie {
        let detailURL = "\(baseURL)/index.php/vod/detail/id/\(movieId).html"
        let html = try await networkService.fetchHTML(from: detailURL)
        return parseMovieDetail(from: html, movieId: movieId, detailURL: detailURL)
    }
    
    func fetchVideoSources(movieId: String) async throws -> [VideoSource] {
        let detailURL = "\(baseURL)/index.php/vod/detail/id/\(movieId).html"
        let html = try await networkService.fetchHTML(from: detailURL)
        return parseVideoSources(from: html, movieId: movieId)
    }
    
    func fetchVideoLines(movieId: String) async throws -> [VideoLine] {
        let detailURL = "\(baseURL)/index.php/vod/detail/id/\(movieId).html"
        let html = try await networkService.fetchHTML(from: detailURL)
        let lines = parseVideoLines(from: html, movieId: movieId)
        if !lines.isEmpty {
            return lines
        }
        return parseBackupVideoLines(from: html, movieId: movieId)
    }
    
    private func parseHomePageMovies(from html: String) -> [Movie] {
        var movies: [Movie] = []
        let cardPattern = "<a[^>]*href=\"(/index\\.php/vod/detail/id/(\\d+)\\.html)\"[^>]*class=\"[^\"]*card vod-list-item[^\"]*\"[^>]*title=\"([^\"]+)\"[^>]*>(.*?)</a>"
        
        guard let regex = try? NSRegularExpression(pattern: cardPattern, options: [.dotMatchesLineSeparators]) else {
            return movies
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        var seenIds = Set<String>()
        
        for match in matches {
            guard match.numberOfRanges >= 5 else { continue }
            
            let url = extractString(from: html, match: match, at: 1)
            let id = extractString(from: html, match: match, at: 2)
            let title = extractString(from: html, match: match, at: 3).trimmingCharacters(in: .whitespacesAndNewlines)
            let cardContent = extractString(from: html, match: match, at: 4)
            
            guard !seenIds.contains(id), !title.isEmpty else { continue }
            seenIds.insert(id)
            
            var coverUrl = ""
            if let dataSrcRegex = try? NSRegularExpression(pattern: "data-src=\"([^\"]+)\"", options: []) {
                let dataSrcRange = NSRange(cardContent.startIndex..<cardContent.endIndex, in: cardContent)
                if let dataSrcMatch = dataSrcRegex.firstMatch(in: cardContent, options: [], range: dataSrcRange) {
                    coverUrl = extractString(from: cardContent, match: dataSrcMatch, at: 1)
                }
            }
            
            if coverUrl.isEmpty {
                if let srcRegex = try? NSRegularExpression(pattern: "<img[^>]+src=\"([^\"]+)\"", options: []) {
                    let srcRange = NSRange(cardContent.startIndex..<cardContent.endIndex, in: cardContent)
                    if let srcMatch = srcRegex.firstMatch(in: cardContent, options: [], range: srcRange) {
                        coverUrl = extractString(from: cardContent, match: srcMatch, at: 1)
                    }
                }
            }
            
            var year = ""
            var region = ""
            if let tagsInfoRegex = try? NSRegularExpression(pattern: "<div class=\"vod-tagsinfo\">.*?<span>([^<]+)</span>.*?<span[^>]*>([^<]*)</span>", options: [.dotMatchesLineSeparators]) {
                let tagsRange = NSRange(cardContent.startIndex..<cardContent.endIndex, in: cardContent)
                if let tagsMatch = tagsInfoRegex.firstMatch(in: cardContent, options: [], range: tagsRange) {
                    year = extractString(from: cardContent, match: tagsMatch, at: 1).trimmingCharacters(in: .whitespacesAndNewlines)
                    region = extractString(from: cardContent, match: tagsMatch, at: 2).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            var remark = ""
            if let remarkRegex = try? NSRegularExpression(pattern: "subtitle is-6\">([^<]+)<", options: []) {
                let remarkRange = NSRange(cardContent.startIndex..<cardContent.endIndex, in: cardContent)
                if let remarkMatch = remarkRegex.firstMatch(in: cardContent, options: [], range: remarkRange) {
                    remark = extractString(from: cardContent, match: remarkMatch, at: 1).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            let movie = Movie(
                id: id,
                title: title,
                coverUrl: normalizeImageURL(coverUrl),
                detailUrl: baseURL + url,
                category: "影视",
                rating: 0.0,
                description: remark,
                year: year,
                region: region,
                actors: "",
                director: "",
                videoUrls: []
            )
            movies.append(movie)
        }
        
        return movies
    }
    
    private func parseSearchResults(from html: String) -> [Movie] {
        var movies: [Movie] = []
        
        let boxPattern = "<div class=\"columns vod-detail-box[^>]*>(.*?)</div></div></div></div>"
        
        guard let boxRegex = try? NSRegularExpression(pattern: boxPattern, options: [.dotMatchesLineSeparators]) else {
            return movies
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let boxMatches = boxRegex.matches(in: html, options: [], range: range)
        
        var seenIds = Set<String>()
        
        for boxMatch in boxMatches {
            guard boxMatch.numberOfRanges >= 2 else { continue }
            let boxContent = extractString(from: html, match: boxMatch, at: 1)
            
            let idPattern = "/index\\.php/vod/detail/id/(\\d+)\\.html"
            let titlePattern = "class=\"title\">([^<]+)<"
            let imgPattern = "<img[^>]+src=\"([^\"]+)\"[^>]*alt=\"([^\"]+)\""
            let yearPattern = "/search/year/(\\d+)\\.html"
            let regionPattern = "/search/area/([^.\"]+)\\.html"
            
            guard let idRegex = try? NSRegularExpression(pattern: idPattern, options: []) else { continue }
            
            let idRange = NSRange(boxContent.startIndex..<boxContent.endIndex, in: boxContent)
            guard let idMatch = idRegex.firstMatch(in: boxContent, options: [], range: idRange) else { continue }
            let id = extractString(from: boxContent, match: idMatch, at: 1)
            
            guard !seenIds.contains(id) else { continue }
            seenIds.insert(id)
            
            var title = ""
            if let titleRegex = try? NSRegularExpression(pattern: titlePattern, options: []) {
                if let titleMatch = titleRegex.firstMatch(in: boxContent, options: [], range: idRange) {
                    title = extractString(from: boxContent, match: titleMatch, at: 1).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            var coverUrl = ""
            if let imgRegex = try? NSRegularExpression(pattern: imgPattern, options: []) {
                if let imgMatch = imgRegex.firstMatch(in: boxContent, options: [], range: idRange) {
                    coverUrl = extractString(from: boxContent, match: imgMatch, at: 1)
                    if title.isEmpty {
                        title = extractString(from: boxContent, match: imgMatch, at: 2).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
            
            var year = ""
            if let yearRegex = try? NSRegularExpression(pattern: yearPattern, options: []) {
                if let yearMatch = yearRegex.firstMatch(in: boxContent, options: [], range: idRange) {
                    year = extractString(from: boxContent, match: yearMatch, at: 1)
                }
            }
            
            var region = ""
            if let regionRegex = try? NSRegularExpression(pattern: regionPattern, options: []) {
                if let regionMatch = regionRegex.firstMatch(in: boxContent, options: [], range: idRange) {
                    let raw = extractString(from: boxContent, match: regionMatch, at: 1)
                    region = raw.removingPercentEncoding ?? raw
                }
            }
            
            var description = ""
            if let descRegex = try? NSRegularExpression(pattern: "class=\"label\">简介：</label></div><div class=\"field-body\"><div class=\"field is-narrow\"><p class=\"subtitle\">([^<]+)</p>", options: []) {
                if let descMatch = descRegex.firstMatch(in: boxContent, options: [], range: idRange) {
                    description = extractString(from: boxContent, match: descMatch, at: 1).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            let movie = Movie(
                id: id,
                title: title.isEmpty ? "未命名" : title,
                coverUrl: normalizeImageURL(coverUrl),
                detailUrl: "\(baseURL)/index.php/vod/detail/id/\(id).html",
                category: "影视",
                rating: 0.0,
                description: description,
                year: year,
                region: region,
                actors: "",
                director: "",
                videoUrls: []
            )
            movies.append(movie)
        }
        
        return movies
    }
    
    private func parseMovieDetail(from html: String, movieId: String, detailURL: String) -> Movie {
        var title = ""
        var coverUrl = ""
        var description = ""
        var year = ""
        var region = ""
        var actors = ""
        var director = ""
        var category = "影视"
        var language = ""
        var updateDate = ""
        
        if let historyRegex = try? NSRegularExpression(pattern: "mac_history_set[^>]*data-name=\"\\[([^\\]]+)\\]([^\"]+)\"[^>]*data-pic=\"([^\"]+)\"", options: []) {
            let r = NSRange(html.startIndex..<html.endIndex, in: html)
            if let historyMatch = historyRegex.firstMatch(in: html, options: [], range: r) {
                category = extractString(from: html, match: historyMatch, at: 1)
                title = extractString(from: html, match: historyMatch, at: 2).trimmingCharacters(in: .whitespacesAndNewlines)
                coverUrl = extractString(from: html, match: historyMatch, at: 3)
            }
        }
        
        if title.isEmpty {
            let titleMetaRegex = try? NSRegularExpression(pattern: "<title>([^<]+)<", options: [])
            if let titleMetaMatch = titleMetaRegex?.firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
                let rawTitle = extractString(from: html, match: titleMetaMatch, at: 1).trimmingCharacters(in: .whitespacesAndNewlines)
                if rawTitle.contains("详情介绍") {
                    title = rawTitle.components(separatedBy: "详情介绍").first ?? ""
                } else {
                    title = rawTitle
                }
            }
        }
        
        if coverUrl.isEmpty {
            if let coverRegex = try? NSRegularExpression(pattern: "data-pic=\"([^\"]+)\"", options: []) {
                let r = NSRange(html.startIndex..<html.endIndex, in: html)
                if let coverMatch = coverRegex.firstMatch(in: html, options: [], range: r) {
                    coverUrl = extractString(from: html, match: coverMatch, at: 1)
                }
            }
        }
        
        if coverUrl.isEmpty {
            let altPattern = "<img[^>]+src=\"([^\"]+)\"[^>]*alt=\"[^\"]*\(NSRegularExpression.escapedPattern(for: title))"
            if let coverRegex = try? NSRegularExpression(pattern: altPattern, options: []) {
                let r = NSRange(html.startIndex..<html.endIndex, in: html)
                if let coverMatch = coverRegex.firstMatch(in: html, options: [], range: r) {
                    coverUrl = extractString(from: html, match: coverMatch, at: 1)
                }
            }
        }
        
        if let descRegex = try? NSRegularExpression(pattern: "name=\"description\" content=\"([^\"]+)\"", options: []).firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
            let raw = extractString(from: html, match: descRegex, at: 1)
            if raw.contains("剧情:") {
                description = raw.components(separatedBy: "剧情:").last ?? raw
            } else {
                description = raw
            }
        }
        
        if let yearMatch = try? NSRegularExpression(pattern: "/search/year/(\\d+)\\.html", options: []).firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
            year = extractString(from: html, match: yearMatch, at: 1)
        }
        
        if let regionMatch = try? NSRegularExpression(pattern: "/search/area/([^.\"]+)\\.html", options: []).firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
            let raw = extractString(from: html, match: regionMatch, at: 1)
            region = raw.removingPercentEncoding ?? raw
        }
        
        if let langMatch = try? NSRegularExpression(pattern: "/search/lang/([^.\"]+)\\.html", options: []).firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
            let raw = extractString(from: html, match: langMatch, at: 1)
            language = raw.removingPercentEncoding ?? raw
        }
        
        if let updateMatch = try? NSRegularExpression(pattern: "更新[:：]\\s*(\\d{4}-\\d{2}-\\d{2})", options: []).firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
            updateDate = extractString(from: html, match: updateMatch, at: 1)
        }
        
        if let directorMatch = try? NSRegularExpression(pattern: "class=\"label\">导演：</label></div><div class=\"field-body\"><div class=\"field is-narrow\"><p class=\"subtitle\"><a[^>]*>([^<]+)</a>", options: []).firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
            director = extractString(from: html, match: directorMatch, at: 1).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let actorsMatch = try? NSRegularExpression(pattern: "class=\"label\">主演：</label></div><div class=\"field-body\"><div class=\"field is-narrow\"><p class=\"subtitle\">(.*?)</p>", options: [.dotMatchesLineSeparators]).firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)) {
            let raw = extractString(from: html, match: actorsMatch, at: 1)
            let linkRegex = try? NSRegularExpression(pattern: ">([^<]+)</a>", options: [])
            if let linkRegex = linkRegex {
                let r = NSRange(raw.startIndex..<raw.endIndex, in: raw)
                let matches = linkRegex.matches(in: raw, options: [], range: r)
                var names: [String] = []
                for match in matches {
                    names.append(extractString(from: raw, match: match, at: 1).trimmingCharacters(in: .whitespacesAndNewlines))
                }
                actors = names.joined(separator: ", ")
            }
        }
        
        return Movie(
            id: movieId,
            title: title.isEmpty ? "未命名" : title,
            coverUrl: normalizeImageURL(coverUrl),
            detailUrl: detailURL,
            category: category,
            rating: 0.0,
            description: description,
            year: year,
            region: region,
            actors: actors,
            director: director,
            language: language,
            updateDate: updateDate,
            videoUrls: []
        )
    }
    
    private func parseVideoSources(from html: String, movieId: String) -> [VideoSource] {
        var sources: [VideoSource] = []
        
        let fromPattern = "var\\s+player_aaaa\\s*=\\s*\\{[^}]*from\\s*:\\s*\"([^\"]+)\""
        
        var playFroms: [String] = []
        if let fromRegex = try? NSRegularExpression(pattern: fromPattern, options: []) {
            let fromRange = NSRange(html.startIndex..<html.endIndex, in: html)
            if let fromMatch = fromRegex.firstMatch(in: html, options: [], range: fromRange) {
                let fromString = extractString(from: html, match: fromMatch, at: 1)
                playFroms = fromString.components(separatedBy: "$$$")
            }
        }
        
        if playFroms.isEmpty {
            let pattern = "from[\\\"':\\s]*[\\\"']([^\\\"'$$]+)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let r = NSRange(html.startIndex..<html.endIndex, in: html)
                let matches = regex.matches(in: html, options: [], range: r)
                for match in matches {
                    let name = extractString(from: html, match: match, at: 1)
                    if !name.isEmpty && !playFroms.contains(name) {
                        playFroms.append(name)
                    }
                }
            }
        }
        
        let detailURLPattern = "/index\\.php/vod/play/id/\(movieId)/sid/(\\d+)/nid/(\\d+)\\.html"
        if let sidRegex = try? NSRegularExpression(pattern: detailURLPattern, options: []) {
            let r = NSRange(html.startIndex..<html.endIndex, in: html)
            let sidMatches = sidRegex.matches(in: html, options: [], range: r)
            
            var seenSids = Set<String>()
            
            for match in sidMatches {
                guard match.numberOfRanges >= 3 else { continue }
                let sid = extractString(from: html, match: match, at: 1)
                let nid = extractString(from: html, match: match, at: 2)
                
                let key = "\(sid)_\(nid)"
                guard !seenSids.contains(key) else { continue }
                seenSids.insert(key)
                
                let playURL = "\(baseURL)/index.php/vod/play/id/\(movieId)/sid/\(sid)/nid/\(nid).html"
                let fromName: String
                if let sidIndex = Int(sid), sidIndex < playFroms.count {
                    fromName = playFroms[sidIndex - 1]
                } else {
                    fromName = "播放源 \(sid)"
                }
                
                let source = VideoSource(
                    id: "\(movieId)_\(sid)_\(nid)",
                    name: "\(fromName) 第\(nid)集",
                    url: playURL,
                    type: .m3u8
                )
                sources.append(source)
            }
        }
        
        if sources.isEmpty {
            let singlePattern = "/index\\.php/vod/play/id/\(movieId)/sid/(\\d+)\\.html"
            if let regex = try? NSRegularExpression(pattern: singlePattern, options: []) {
                let r = NSRange(html.startIndex..<html.endIndex, in: html)
                let matches = regex.matches(in: html, options: [], range: r)
                for (index, match) in matches.prefix(20).enumerated() {
                    guard match.numberOfRanges >= 2 else { continue }
                    let sid = extractString(from: html, match: match, at: 1)
                    let playURL = "\(baseURL)/index.php/vod/play/id/\(movieId)/sid/\(sid).html"
                    let fromName: String
                    if let sidIndex = Int(sid), sidIndex > 0, sidIndex <= playFroms.count {
                        fromName = playFroms[sidIndex - 1]
                    } else {
                        fromName = "播放源"
                    }
                    let source = VideoSource(
                        id: "\(movieId)_\(sid)_\(index)",
                        name: fromName,
                        url: playURL,
                        type: .m3u8
                    )
                    sources.append(source)
                }
            }
        }
        
        return sources
    }
    
    private func parseVideoLines(from html: String, movieId: String) -> [VideoLine] {
        var lines: [VideoLine] = []
        
        let fromPattern = "var\\s+player_aaaa\\s*=\\s*\\{[^}]*from\\s*:\\s*\"([^\"]+)\""
        var playFroms: [String] = []
        
        if let fromRegex = try? NSRegularExpression(pattern: fromPattern, options: []) {
            let fromRange = NSRange(html.startIndex..<html.endIndex, in: html)
            if let fromMatch = fromRegex.firstMatch(in: html, options: [], range: fromRange) {
                let fromString = extractString(from: html, match: fromMatch, at: 1)
                playFroms = fromString.components(separatedBy: "$$$")
            }
        }
        
        if playFroms.isEmpty {
            let pattern = "from[\\\"':\\s]*[\\\"']([^\\\"'$$]+)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let r = NSRange(html.startIndex..<html.endIndex, in: html)
                let matches = regex.matches(in: html, options: [], range: r)
                for match in matches {
                    let name = extractString(from: html, match: match, at: 1)
                    if !name.isEmpty && !playFroms.contains(name) {
                        playFroms.append(name)
                    }
                }
            }
        }
        
        if playFroms.isEmpty {
            playFroms = ["播放源1", "播放源2", "播放源3"]
        }
        
        let playURLPattern = "/index\\.php/vod/play/id/\(movieId)/sid/(\\d+)/nid/(\\d+)\\.html"
        if let urlRegex = try? NSRegularExpression(pattern: playURLPattern, options: []) {
            let r = NSRange(html.startIndex..<html.endIndex, in: html)
            let urlMatches = urlRegex.matches(in: html, options: [], range: r)
            
            var sidNidMap: [String: Set<String>] = [:]
            
            for match in urlMatches {
                guard match.numberOfRanges >= 3 else { continue }
                let sid = extractString(from: html, match: match, at: 1)
                let nid = extractString(from: html, match: match, at: 2)
                
                if sidNidMap[sid] == nil {
                    sidNidMap[sid] = Set<String>()
                }
                sidNidMap[sid]?.insert(nid)
            }
            
            let sortedSids = sidNidMap.keys.sorted { Int($0) ?? 0 < Int($1) ?? 0 }
            
            for (index, sid) in sortedSids.enumerated() {
                let lineName: String
                if index < playFroms.count {
                    lineName = playFroms[index]
                } else {
                    lineName = "播放源\(index + 1)"
                }
                
                var line = VideoLine(id: sid, name: lineName, episodes: [])
                
                if let nids = sidNidMap[sid] {
                    let sortedNids = nids.sorted { Int($0) ?? 0 < Int($1) ?? 0 }
                    
                    for nid in sortedNids {
                        let playURL = "\(baseURL)/index.php/vod/play/id/\(movieId)/sid/\(sid)/nid/\(nid).html"
                        let episodeNumber = Int(nid)
                        
                        let source = VideoSource(
                            id: "\(movieId)_\(sid)_\(nid)",
                            name: "第\(nid)集",
                            url: playURL,
                            type: .m3u8,
                            lineId: sid,
                            episodeNumber: episodeNumber
                        )
                        line.episodes.append(source)
                    }
                }
                
                if !line.episodes.isEmpty {
                    lines.append(line)
                }
            }
        }
        
        if lines.isEmpty {
            let sources = parseVideoSources(from: html, movieId: movieId)
            if !sources.isEmpty {
                let line = VideoLine(id: "1", name: "默认线路", episodes: sources.map { source in
                    VideoSource(
                        id: source.id,
                        name: source.name,
                        url: source.url,
                        type: source.type,
                        lineId: "1",
                        episodeNumber: source.episodeNumber
                    )
                })
                lines.append(line)
            }
        }
        
        return lines
    }
    
    private func extractString(from html: String, match: NSTextCheckingResult, at index: Int) -> String {
        guard index < match.numberOfRanges,
              let range = Range(match.range(at: index), in: html) else {
            return ""
        }
        return String(html[range])
    }
    
    private func normalizeImageURL(_ url: String) -> String {
        if url.hasPrefix("//") {
            return "https:" + url
        } else if url.hasPrefix("/") {
            return baseURL + url
        }
        return url
    }
    
    private func parseBackupVideoLines(from html: String, movieId: String) -> [VideoLine] {
        var lines: [VideoLine] = []
        
        let urlPatterns = [
            "url\\s*[:=]\\s*['\"]([^'\"]*\\.m3u8[^'\"]*)['\"]",
            "\"url\"\\s*:\\s*\"([^\"]*\\.m3u8[^\"]*)\"",
            "(https?://[^\\s\"'<>]+\\.m3u8[^\\s\"'<>]*)",
            "player_aaaa\\s*=\\s*\\{[^}]*url\\s*:\\s*['\"]([^'\"]+)['\"]",
            "playurl\\s*[:=]\\s*['\"]([^'\"]+)['\"]",
            "videoUrl\\s*[:=]\\s*['\"]([^'\"]+)['\"]"
        ]
        
        var foundURLs: [String] = []
        
        for pattern in urlPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                let matches = regex.matches(in: html, options: [], range: range)
                for match in matches {
                    guard match.numberOfRanges >= 2 else { continue }
                    let url = extractString(from: html, match: match, at: 1)
                    if !url.isEmpty && !foundURLs.contains(url) {
                        foundURLs.append(url)
                    }
                }
            }
        }
        
        if !foundURLs.isEmpty {
            var episodes: [VideoSource] = []
            for (index, url) in foundURLs.enumerated() {
                let normalizedURL = url.hasPrefix("http") ? url : (url.hasPrefix("//") ? "https:" + url : "https://www.rainvi.com" + url)
                let source = VideoSource(
                    id: "\(movieId)_backup_\(index)",
                    name: "第\(index + 1)集",
                    url: normalizedURL,
                    type: .m3u8,
                    lineId: "1",
                    episodeNumber: index + 1
                )
                episodes.append(source)
            }
            let line = VideoLine(id: "1", name: "默认线路", episodes: episodes)
            lines.append(line)
        }
        
        if lines.isEmpty {
            let jsPlayerPattern = "<script[^>]*>([^<]+player_aaaa[^<]+)</script>"
            if let jsRegex = try? NSRegularExpression(pattern: jsPlayerPattern, options: [.dotMatchesLineSeparators]) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let jsMatch = jsRegex.firstMatch(in: html, options: [], range: range) {
                    let jsContent = extractString(from: html, match: jsMatch, at: 1)
                    
                    let patterns = [
                        "url\\s*[:=]\\s*['\"]([^'\"]+)['\"]",
                        "'([^']+\\.m3u8[^']+)'",
                        "\"([^\"]+\\.m3u8[^\"]+)\""
                    ]
                    
                    var urls: [String] = []
                    for pattern in patterns {
                        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                            let r = NSRange(jsContent.startIndex..<jsContent.endIndex, in: jsContent)
                            let matches = regex.matches(in: jsContent, options: [], range: r)
                            for match in matches {
                                guard match.numberOfRanges >= 2 else { continue }
                                let url = extractString(from: jsContent, match: match, at: 1)
                                if !url.isEmpty && !urls.contains(url) && (url.contains(".m3u8") || url.contains(".mp4")) {
                                    urls.append(url)
                                }
                            }
                        }
                    }
                    
                    if !urls.isEmpty {
                        var episodes: [VideoSource] = []
                        for (index, url) in urls.enumerated() {
                            let normalizedURL = url.hasPrefix("http") ? url : (url.hasPrefix("//") ? "https:" + url : "https://www.rainvi.com" + url)
                            let source = VideoSource(
                                id: "\(movieId)_js_\(index)",
                                name: "第\(index + 1)集",
                                url: normalizedURL,
                                type: .m3u8,
                                lineId: "1",
                                episodeNumber: index + 1
                            )
                            episodes.append(source)
                        }
                        let line = VideoLine(id: "1", name: "默认线路", episodes: episodes)
                        lines.append(line)
                    }
                }
            }
        }
        
        return lines
    }
}
