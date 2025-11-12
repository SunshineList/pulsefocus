# PulseFocus

基于 Apple Watch 心率的自适应番茄钟，含 iOS 与 watchOS 端。支持 HealthKit 实时心率、SwiftData 历史统计、AI 总结与建议（兼容 OpenAI 协议的厂商）。

## 功能总览
- 番茄系统：固定/自适应模式，开始/暂停/重置，倒计时与本地通知
- 心率监控：读取 HR/HRV/RHR；Watch 端 `HKWorkoutSession` 保活
- 历史统计：SwiftData 存储，会话记录与周报曲线；支持按钮删除与滑动删除
- AI 模块：统一 `AIService`，兼容 OpenAI 协议，测试连通性与总结报告
- UI：极简玻璃风，中文文案；应用内品牌过渡页（支持自定义图片）

## 环境要求
- Xcode 15+，iOS 17+/watchOS 10+
- 已配对的 iPhone 与 Apple Watch（真机）

## 安装到 iPhone
1. 打开 Xcode，选择设备为你的 iPhone 真机
2. Targets → PulseFocus → Signing & Capabilities：选择你的 Team，保持自动签名开启
3. Capabilities 勾选 `HealthKit` 与 `Push Notifications`
4. 点击运行安装到 iPhone，首次启动允许健康与通知权限

## 安装到 Apple Watch
1. File → New → Target… → 选择 watchOS → Watch App（建议包含 Watch App 与 Extension）
2. Watch Target → Signing 选择 Team，开启自动签名；Capabilities 勾选 `HealthKit`
3. Scheme 切换到 Watch App，设备选择你的 iPhone（显示 iPhone + Watch）
4. 运行安装；按手表提示完成安装

## 权限与设置
- HealthKit 权限说明已写入构建设置：
  - `NSHealthShareUsageDescription`/`NSHealthUpdateUsageDescription`（读取心率与 HRV，应用不写入健康数据）
- 通知权限在首次进入应用时申请（iOS）：`PulseFocus/ContentView.swift:26`

## AI 配置与连通性测试
- 打开设置页（“设置” Tab）在“AI 设置”中填入：
  - 服务地址（Base URL）、模型名、API Key；高级可选设置 Header 名与前缀
- 点击“测试 AI 连接”，弹框显示模型返回文本；同时在下方显示连接成功/失败
- 代码位置：
  - 设置页：`PulseFocus/Views/SettingsView.swift:23` 与测试逻辑 `SettingsView.swift:104`
  - 服务端调用：`PulseFocus/Services/AIService.swift:57`（无 Key 或错误时返回空）

## 历史记录管理
- 进入“历史”，卡片上可：
  - 点“AI 总结报告”查看该段的总结与建议（支持加载与失败提示）
  - 删除：按钮删除或右滑删除
- 代码位置：
  - 历史页：`PulseFocus/Views/HistoryView.swift:28`、滑动删除 `HistoryView.swift:36`
  - 总结弹窗：`PulseFocus/Views/Components/AISummarySheet.swift:12`

## 启动页与品牌过渡
- 系统启动页使用默认白色背景，避免 storyboard 报错
- 应用内品牌过渡页（支持你的图片），启动后淡入 1.2s：
  - 图片资源：将你的图片命名为 `LaunchArt.png`，放入 `PulseFocus/Assets.xcassets/LaunchArt.imageset/`
  - 过渡页：`PulseFocus/Views/Components/SplashBrandingView.swift:8`
  - 触发逻辑：`PulseFocus/ContentView.swift:13`（`showSplash` 淡出）

## 资源放置
- App 图标：把你的 PNG 图标放入 `PulseFocus/Assets.xcassets/AppIcon.appiconset/`（Xcode 自动切片）
- 启动图/品牌图：`PulseFocus/Assets.xcassets/LaunchArt.imageset/LaunchArt.png`

## 交互提示
- 主页：
  - 圆环显示剩余时间；下方显示当前心率
  - “结束并保存”：暂停并按实际已用时长保存历史，便于快速查看图表
- 总结弹窗：
  - 有加载状态与错误提示；AI 未配置或失败会显示红色提示

## 常见问题
- 启动页 storyboard 报错：使用默认系统启动页 + 应用内过渡页即可避免 IB 预览问题
- AI 总是“连接成功”：测试逻辑基于当前输入框的 API Key 与返回内容；未填 Key 会弹框提示并标注“未配置 Key”
- 白屏弹窗：历史页已改为 `.sheet(item:)`，仅在选中记录时展示，避免空白

## 目录结构
- iOS 端：
  - `AppState` 全局状态：`PulseFocus/App/AppState.swift`
  - 健康管理：`PulseFocus/Managers/HealthManager.swift`
  - 自适应与计时：`PulseFocus/Controllers/*`
  - AI 服务与提示词：`PulseFocus/Services/*`
  - 视图与组件：`PulseFocus/Views/*`
  - 数据模型（SwiftData）：`PulseFocus/Models/*`
- watchOS 端：
  - Watch 主页与会话控制：`WatchPulseFocus/WatchHomeView.swift`

## 快速上手步骤
1. 在 Xcode 中选择 iPhone 真机，配置签名并运行
2. 打开“设置”Tab，填入 AI Base URL/模型名/API Key，点击“测试 AI 连接”
3. 在主页点击“开始”，或用“结束并保存”生成一条历史记录查看图表
4. 在历史记录中点击“AI 总结报告”，查看该段总结与建议；需要时右滑删除记录

## 版本与许可
- 本项目无第三方依赖；仅使用系统框架（SwiftUI/HealthKit/ActivityKit/SwiftData/WatchConnectivity）
- 仅用于演示与学习目的
