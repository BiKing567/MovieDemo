import Foundation

actor MovieParserService {
    static let shared = MovieParserService()
    
    private init() {}
    
    func fetchAndParseHomePage(url: String) async throws -> [Movie] {
        let html = try await NetworkService.shared.fetchHTML(from: url)
        return parseMoviesFromHTML(html)
    }
    
    func searchMovies(keyword: String) async throws -> [Movie] {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let url = "https://example.com/search?q=\(encodedKeyword)"
        let html = try await NetworkService.shared.fetchHTML(from: url)
        return parseMoviesFromHTML(html)
    }
    
    func fetchMovieDetail(url: String) async throws -> Movie {
        let html = try await NetworkService.shared.fetchHTML(from: url)
        return parseMovieDetailFromHTML(html, detailUrl: url)
    }
    
    func fetchVideoSources(movieId: String) async throws -> [VideoSource] {
        let url = "https://example.com/api/video/\(movieId)"
        let html = try await NetworkService.shared.fetchHTML(from: url)
        return parseVideoSourcesFromHTML(html)
    }
    
    private func parseMoviesFromHTML(_ html: String) -> [Movie] {
        var movies: [Movie] = []
        
        let pattern = "<div class=\"movie-item\">.*?<a href=\"([^\"]+)\".*?<img src=\"([^\"]+)\".*?<h3>([^<]+)</h3>.*?<p class=\"rating\">([^<]+)</p>.*?</div>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return movies
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        for (index, match) in matches.enumerated() {
            guard match.numberOfRanges >= 5 else { continue }
            
            let url = extractString(from: html, match: match, at: 1)
            let cover = extractString(from: html, match: match, at: 2)
            let title = extractString(from: html, match: match, at: 3)
            let ratingStr = extractString(from: html, match: match, at: 4)
            
            let rating = Double(ratingStr) ?? 0.0
            let movieId = url.components(separatedBy: "/").last ?? UUID().uuidString
            
            let movie = Movie(
                id: movieId,
                title: title,
                coverUrl: cover,
                detailUrl: url,
                rating: rating
            )
            movies.append(movie)
        }
        
        return movies
    }
    
    private func parseMovieDetailFromHTML(_ html: String, detailUrl: String) -> Movie {
        let titlePattern = "<h1 class=\"title\">([^<]+)</h1>"
        let coverPattern = "<img class=\"cover\" src=\"([^\"]+)\""
        let descPattern = "<p class=\"description\">([^<]+)</p>"
        let yearPattern = "<span class=\"year\">([^<]+)</span>"
        let categoryPattern = "<span class=\"category\">([^<]+)</span>"
        let directorPattern = "<span class=\"director\">([^<]+)</span>"
        let actorsPattern = "<span class=\"actors\">([^<]+)</span>"
        
        let title = extractFirstMatch(from: html, pattern: titlePattern)
        let cover = extractFirstMatch(from: html, pattern: coverPattern)
        let description = extractFirstMatch(from: html, pattern: descPattern)
        let year = extractFirstMatch(from: html, pattern: yearPattern)
        let category = extractFirstMatch(from: html, pattern: categoryPattern)
        let director = extractFirstMatch(from: html, pattern: directorPattern)
        let actors = extractFirstMatch(from: html, pattern: actorsPattern)
        
        let movieId = detailUrl.components(separatedBy: "/").last ?? UUID().uuidString
        
        return Movie(
            id: movieId,
            title: title,
            coverUrl: cover,
            detailUrl: detailUrl,
            category: category,
            rating: 0.0,
            description: description,
            year: year,
            region: "",
            actors: actors,
            director: director,
            videoUrls: []
        )
    }
    
    private func parseVideoSourcesFromHTML(_ html: String) -> [VideoSource] {
        var sources: [VideoSource] = []
        
        let pattern = "<source src=\"([^\"]+)\" type=\"([^\"]+)\" label=\"([^\"]+)\""
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return sources
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            
            let url = extractString(from: html, match: match, at: 1)
            let typeStr = extractString(from: html, match: match, at: 2)
            let name = extractString(from: html, match: match, at: 3)
            
            let videoType: VideoSource.VideoType
            if typeStr.contains("m3u8") {
                videoType = .m3u8
            } else if typeStr.contains("mp4") {
                videoType = .mp4
            } else if typeStr.contains("webm") {
                videoType = .webm
            } else {
                videoType = .unknown
            }
            
            let source = VideoSource(
                id: UUID().uuidString,
                name: name,
                url: url,
                type: videoType
            )
            sources.append(source)
        }
        
        return sources
    }
    
    private func extractString(from html: String, match: NSTextCheckingResult, at index: Int) -> String {
        guard index < match.numberOfRanges,
              let range = Range(match.range(at: index), in: html) else {
            return ""
        }
        return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractFirstMatch(from html: String, pattern: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)),
              match.numberOfRanges >= 2,
              let range = Range(match.range(at: 1), in: html) else {
            return ""
        }
        return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
