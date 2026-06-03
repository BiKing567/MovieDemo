import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showClearConfirmation = false
    
    var body: some View {
        Group {
            if appState.history.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("暂无观看历史")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("在这里显示你最近观看的电影和电视剧")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    HStack {
                        Text("共 \(appState.history.count) 条记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("清空历史") {
                            showClearConfirmation = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    List {
                        ForEach(Array(appState.history.enumerated()), id: \.element.id) { index, movie in
                            HistoryRowView(movie: movie, index: index)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    appState.selectedMovie = movie
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        appState.history.remove(at: index)
                                        appState.saveHistory()
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("历史记录")
        .alert("清空历史记录", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                appState.clearHistory()
            }
        } message: {
            Text("确定要清空所有观看历史吗？此操作无法撤销。")
        }
    }
}

struct HistoryRowView: View {
    let movie: Movie
    let index: Int
    @State private var imageData: Data?
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: movie.coverUrl, data: $imageData)
                .frame(width: 80, height: 100)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if !movie.category.isEmpty {
                    Text(movie.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if movie.rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", movie.rating))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
    }
}