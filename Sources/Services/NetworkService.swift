import Foundation

actor NetworkService {
    static let shared = NetworkService()
    
    private let session: URLSession
    private let timeout: TimeInterval = 30
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Referer": "https://www.rainvi.com/",
            "Sec-Ch-Ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Safari\";v=\"605\"",
            "Sec-Ch-Ua-Mobile": "?0",
            "Sec-Ch-Ua-Platform": "\"macOS\"",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "same-origin",
            "Sec-Fetch-User": "?1",
            "Upgrade-Insecure-Requests": "1"
        ]
        session = URLSession(configuration: config)
    }
    
    func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        var encoding = String.Encoding.utf8
        if let encodingName = httpResponse.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
            }
        }
        
        guard let html = String(data: data, encoding: encoding) ?? String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingError
        }
        
        return html
    }
    
    func fetchData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
    
    func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("https://www.rainvi.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let statusCode):
            return "HTTP 错误: \(statusCode)"
        case .decodingError:
            return "数据解码错误"
        case .noData:
            return "没有数据"
        }
    }
}
