import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var previousTab: AppState.Tab = .home
    
    private func closeDetail() {
        withAnimation(.easeInOut(duration: 0.3)) {
            appState.selectedMovie = nil
        }
    }
    
    var body: some View {
        #if os(macOS)
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                SidebarView()
                    .onChange(of: appState.selectedTab) { _ in
                        closeDetail()
                    }
            } detail: {
                ZStack {
                    DetailView()
                    
                    if appState.selectedMovie != nil {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .transition(.opacity)
                            .onTapGesture {
                                closeDetail()
                            }
                    }
                    
                    if let movie = appState.selectedMovie {
                        MovieDetailView(movie: movie)
                            .frame(minWidth: 800, minHeight: 600)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .cornerRadius(16)
                            .shadow(radius: 20)
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(1)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: appState.selectedMovie)
            }
        } else {
            macOSLegacyView()
        }
        #else
        iOSMainView()
        #endif
    }
}

#if os(iOS)
struct iOSMainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if #available(iOS 16.0, *) {
                TabView(selection: $appState.selectedTab) {
                    NavigationStack {
                        List {
                            Text("首页内容")
                            Text("测试1")
                            Text("测试2")
                            Text("测试3")
                        }
                        .navigationTitle("首页")
                    }
                    .tabItem { Label("首页", systemImage: "house") }
                    .tag(AppState.Tab.home)
                    
                    NavigationStack {
                        Text("搜索页面")
                            .navigationTitle("搜索")
                    }
                    .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                    .tag(AppState.Tab.search)
                    
                    NavigationStack {
                        Text("收藏页面")
                            .navigationTitle("收藏")
                    }
                    .tabItem { Label("收藏", systemImage: "star") }
                    .tag(AppState.Tab.favorites)
                    
                    NavigationStack {
                        Text("历史页面")
                            .navigationTitle("历史")
                    }
                    .tabItem { Label("历史", systemImage: "clock") }
                    .tag(AppState.Tab.history)
                    
                    NavigationStack {
                        Text("设置页面")
                            .navigationTitle("设置")
                    }
                    .tabItem { Label("设置", systemImage: "gear") }
                    .tag(AppState.Tab.settings)
                }
            } else {
                TabView {
                    NavigationView {
                        List {
                            Text("首页内容")
                            Text("测试1")
                            Text("测试2")
                            Text("测试3")
                        }
                        .navigationBarTitle("首页")
                    }
                    .tabItem { Label("首页", systemImage: "house") }
                    
                    NavigationView {
                        Text("搜索页面")
                            .navigationBarTitle("搜索")
                    }
                    .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                    
                    NavigationView {
                        Text("收藏页面")
                            .navigationBarTitle("收藏")
                    }
                    .tabItem { Label("收藏", systemImage: "star") }
                    
                    NavigationView {
                        Text("历史页面")
                            .navigationBarTitle("历史")
                    }
                    .tabItem { Label("历史", systemImage: "clock") }
                    
                    NavigationView {
                        Text("设置页面")
                            .navigationBarTitle("设置")
                    }
                    .tabItem { Label("设置", systemImage: "gear") }
                }
            }
        }
    }
}
#endif

#if os(macOS)
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if #available(macOS 13.0, *) {
            List(selection: $appState.selectedTab) {
                Section("导航") {
                    ForEach(AppState.Tab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Text("影视解析")
                        .font(.headline)
                }
            }
        } else {
            List(AppState.Tab.allCases, id: \.self) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
                    .onTapGesture {
                        appState.selectedTab = tab
                    }
            }
            .frame(minWidth: 180)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Text("影视解析")
                        .font(.headline)
                }
            }
        }
    }
}
#endif

#if os(macOS)
struct macOSLegacyView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(AppState.Tab.home)
            
            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(AppState.Tab.search)
            
            FavoritesView()
                .tabItem {
                    Label("收藏", systemImage: "star.fill")
                }
                .tag(AppState.Tab.favorites)
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock.fill")
                }
                .tag(AppState.Tab.history)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(AppState.Tab.settings)
        }
    }
}
#endif

#if os(macOS)
struct DetailView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch appState.selectedTab {
            case .home:
                HomeView()
            case .search:
                SearchView()
            case .favorites:
                FavoritesView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            }
        }
    }
}
#endif
