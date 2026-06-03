import SwiftUI

struct SettingsView: View {
    @AppStorage("videoQuality") private var videoQuality = "自动"
    @AppStorage("autoPlay") private var autoPlay = true
    @AppStorage("danmakuDefaultOn") private var danmakuDefaultOn = true
    @AppStorage("rememberProgress") private var rememberProgress = true
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "film.stack")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("影视解析")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("版本 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("播放设置") {
                Picker("视频画质", selection: $videoQuality) {
                    Text("自动").tag("自动")
                    Text("1080P").tag("1080P")
                    Text("720P").tag("720P")
                    Text("480P").tag("480P")
                    Text("360P").tag("360P")
                }
                
                Toggle("自动播放", isOn: $autoPlay)
                
                Toggle("记住播放进度", isOn: $rememberProgress)
            }
            
            Section("弹幕设置") {
                Toggle("默认开启弹幕", isOn: $danmakuDefaultOn)
                
                NavigationLink {
                    Text("弹幕屏蔽词管理")
                } label: {
                    Label("弹幕屏蔽词", systemImage: "text.badge.minus")
                }
                
                NavigationLink {
                    Text("弹幕发送设置")
                } label: {
                    Label("发送弹幕", systemImage: "text.bubble")
                }
            }
            
            Section("数据管理") {
                NavigationLink {
                    Text("缓存管理")
                } label: {
                    Label("清除缓存", systemImage: "trash")
                }
                
                NavigationLink {
                    Text("下载管理")
                } label: {
                    Label("下载管理", systemImage: "arrow.down.circle")
                }
            }
            
            Section("关于") {
                HStack {
                    Text("开发者")
                    Spacer()
                    Text("MovieDemo Team")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Text("使用条款")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("开源许可")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Text("免责声明")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text("本应用仅供学习交流使用，不存储任何影视资源。所有影视内容均来自第三方网站，如有侵权请联系我们删除。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}
