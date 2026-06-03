import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.favorites.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("暂无收藏")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("在这里显示你收藏的电影和电视剧")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160), spacing: 16)
                    ], spacing: 16) {
                        ForEach(appState.favorites) { movie in
                            MovieCard(movie: movie)
                                .onTapGesture {
                                    appState.selectedMovie = movie
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        appState.removeFromFavorites(movie)
                                    } label: {
                                        Label("取消收藏", systemImage: "star.slash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("收藏")
    }
}
