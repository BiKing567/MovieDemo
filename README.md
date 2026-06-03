# MovieDemo

一款跨平台视频播放器应用，支持 macOS 和 iOS 系统，可解析并播放多个视频源的内容。

## 功能特性

- 🎬 **多源视频解析** - 支持多个视频播放源
- 🖥️ **跨平台支持** - 同时支持 macOS 和 iOS
- 🎵 **视频播放** - 内置播放器，支持完整播放控制
- ⭐ **收藏管理** - 收藏你喜欢影片
- 📜 **历史记录** - 追踪观看历史
- 🎭 **弹幕支持** - 实时弹幕显示功能

## 系统要求

- macOS 12.0+
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 快速开始

### 环境准备

1. 安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)
   ```bash
   brew install xcodegen
   ```

### 构建项目

1. 克隆仓库
   ```bash
   git clone https://github.com/BiKing567/MovieDemo.git
   cd MovieDemo
   ```

2. 生成 Xcode 项目
   ```bash
   xcodegen generate
   ```

3. 使用 Xcode 打开项目
   ```bash
   open MovieDemo.xcodeproj
   ```

4. 选择目标平台并运行

## 项目结构

```
MovieDemo/
├── Sources/
│   ├── App/               # 应用入口
│   ├── Components/         # UI 组件
│   ├── Models/            # 数据模型
│   ├── Services/          # 业务逻辑
│   └── Views/             # 视图
├── Resources/             # 资源文件
├── project.yml            # XcodeGen 配置
├── LICENSE                # MIT 许可证
└── README.md              # 说明文档
```

## 技术栈

- **SwiftUI** - 跨平台 UI 框架
- **AVKit/AVFoundation** - 音视频播放
- **Swift Concurrency** - 异步编程
- **XcodeGen** - 项目配置管理

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解更多详情。

## 免责声明

本应用仅供学习交流使用。请尊重版权法，只访问您有权限访问的内容。
