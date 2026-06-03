import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var favorites: [Movie] = []
    @Published var history: [Movie] = []
    @Published var searchHistory: [String] = []
    @Published var isLoading: Bool = false
    @Published var selectedMovie: Movie?
    
    private let favoritesKey = "favorites"
    private let historyKey = "history"
    private let searchHistoryKey = "searchHistory"
    
    enum Tab: String, CaseIterable {
        case home = "首页"
        case search = "搜索"
        case favorites = "收藏"
        case history = "历史"
        case settings = "设置"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .favorites: return "star.fill"
            case .history: return "clock.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    init() {
        loadData()
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
            favorites = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
            history = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: searchHistoryKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = decoded
        }
    }
    
    func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    func saveSearchHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(encoded, forKey: searchHistoryKey)
        }
    }
    
    func addToFavorites(_ movie: Movie) {
        if !favorites.contains(where: { $0.id == movie.id }) {
            favorites.insert(movie, at: 0)
            saveFavorites()
        }
    }
    
    func removeFromFavorites(_ movie: Movie) {
        favorites.removeAll { $0.id == movie.id }
        saveFavorites()
    }
    
    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains { $0.id == movie.id }
    }
    
    func addToHistory(_ movie: Movie) {
        history.removeAll { $0.id == movie.id }
        history.insert(movie, at: 0)
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    func addSearchKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        searchHistory.removeAll { $0 == trimmed }
        searchHistory.insert(trimmed, at: 0)
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        saveSearchHistory()
    }
    
    func removeSearchKeyword(_ keyword: String) {
        searchHistory.removeAll { $0 == keyword }
        saveSearchHistory()
    }
    
    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }
}
