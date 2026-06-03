import Foundation

struct Movie: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let coverUrl: String
    let detailUrl: String
    let category: String
    let rating: Double
    let description: String
    let year: String
    let region: String
    let actors: String
    let director: String
    let language: String
    let updateDate: String
    var videoUrls: [VideoSource]
    
    init(id: String, title: String, coverUrl: String, detailUrl: String,
         category: String = "", rating: Double = 0.0, description: String = "",
         year: String = "", region: String = "", actors: String = "",
         director: String = "", language: String = "", updateDate: String = "",
         videoUrls: [VideoSource] = []) {
        self.id = id
        self.title = title
        self.coverUrl = coverUrl
        self.detailUrl = detailUrl
        self.category = category
        self.rating = rating
        self.description = description
        self.year = year
        self.region = region
        self.actors = actors
        self.director = director
        self.language = language
        self.updateDate = updateDate
        self.videoUrls = videoUrls
    }
}

struct VideoSource: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let url: String
    let type: VideoType
    let lineId: String?
    let episodeNumber: Int?
    
    enum VideoType: String, Codable {
        case m3u8
        case mp4
        case webm
        case unknown
    }
    
    init(id: String, name: String, url: String, type: VideoType, lineId: String? = nil, episodeNumber: Int? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
        self.lineId = lineId
        self.episodeNumber = episodeNumber
    }
}

struct VideoLine: Identifiable, Equatable {
    let id: String
    let name: String
    var episodes: [VideoSource]
    
    init(id: String, name: String, episodes: [VideoSource] = []) {
        self.id = id
        self.name = name
        self.episodes = episodes
    }
}

struct Danmaku: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let time: Double
    let color: String
    let fontSize: Int
    
    init(id: String = UUID().uuidString, text: String, time: Double, color: String = "#FFFFFF", fontSize: Int = 25) {
        self.id = id
        self.text = text
        self.time = time
        self.color = color
        self.fontSize = fontSize
    }
}

struct MovieCategory: Identifiable {
    let id: String
    let name: String
    let url: String
    
    static let defaultCategories: [MovieCategory] = [
        MovieCategory(id: "1", name: "电影", url: "https://example.com/movie"),
        MovieCategory(id: "2", name: "电视剧", url: "https://example.com/tv"),
        MovieCategory(id: "3", name: "综艺", url: "https://example.com/variety"),
        MovieCategory(id: "4", name: "动漫", url: "https://example.com/animation"),
        MovieCategory(id: "5", name: "纪录片", url: "https://example.com/documentary")
    ]
}

struct SearchResult: Identifiable {
    let id: String
    let movies: [Movie]
    let hasMore: Bool
    let currentPage: Int
}
