# PulseFocus

基于 Apple Watch 实时心率打造的自适应番茄钟组合应用，将 iOS 与 watchOS 双端串联，帮助你在专注与恢复之间找到最佳节奏。应用采用 SwiftUI 全栈构建，依托 HealthKit、SwiftData 与可插拔的 AI 模块，提供覆盖会话前中后的完整闭环体验。

---

## ✨ 项目亮点
- **实时生理反馈驱动**：结合心率、HRV、RHR，动态调整专注/休息长度，避免过度透支。
- **双端协同设计**：iPhone 主控 + Apple Watch 常驻采集，`HKWorkoutSession` 保活 + WatchConnectivity 保持数据同步。
- **数据驱动复盘**：SwiftData 本地持久化，Charts 可视化趋势，周报/单段总结开箱即用。
- **AI 插拔架构**：`AIService` 统一封装 OpenAI 协议，支持 Moonshot、Kimi、Ollama 等兼容模型，可离线 fallback 到本地策略。
- **极简沉浸体验**：玻璃拟态 UI、渐变配色与品牌过渡动画，提升专注氛围；Haptics 与通知提示保证节奏感。

---

## 🧱 架构速览
PulseFocus 按“状态驱动 + 模块职责”拆分，保持清晰的可维护性：

```
PulseFocus (iOS)
├─ App/AppState.swift          // 全局状态、用户偏好持久化、AI 配置
├─ Controllers/                // SessionTimer、AdaptiveController 等业务控制器
├─ Managers/                   // HealthKit、通知、触感、WatchConnectivity 管理
├─ Services/                   // AIEndpoint、AIService、PromptFactory、SecureStore
├─ Models/                     // SwiftData 会话实体、枚举
├─ Views/                      // Home/History/Settings 及组件
└─ Utils/                      // AISummary 解析、日期格式化、Sparkline 等工具

WatchPulseFocus (watchOS)
├─ WatchHomeView.swift         // 手表端主 UI + 控制入口
└─ WatchSessionController      // HKWorkoutSession 持续采集 + WCSession 双向同步
```

- **AppState** 将模式、心率、AI 配置集中管理，并写入 `UserDefaults`，保证跨启动一致。
- **HealthManager** 负责授权、实时心率/HRV 查询与模拟数据，必要时允许手表端覆盖最新心率。
- **SessionTimer + AdaptiveController** 将计时、策略分离，便于未来替换算法或接入更多指标。
- **ConnectivityManager** 统一 watchOS ↔︎ iOS 消息/上下文同步，A/B 面互为主控。
- **SwiftData 模型 + Charts** 支撑历史统计、周报与趋势图，配合 AI 总结形成闭环。

---

## 🚀 核心流程图谱
1. 用户在 iPhone 上启动会话，`AdaptiveController` 根据实时心率建议时长 → `SessionTimer` 开始倒计时。
2. `ConnectivityManager` 广播上下文至 Watch，Watch 端 `HKWorkoutSession` 常驻采集心率并定期回传。
3. `HealthManager` 汇总来自 HealthKit/Watch 的心率数据，驱动 UI 与自适应策略实时更新。
4. 会话结束触发 `Session` SwiftData 持久化，同时调起 `AISummarySheet`，由 `AIService` 输出总结与建议。
5. 用户在历史页查看趋势、生成近期报告或直接删除不需要的记录，形成复盘闭环。

---

## 📲 双端体验概览
- **Home**：倒计时环 + 心率监视，提供开始/暂停/重置与“一键结束并保存”。
- **History**：周报、趋势图、单日卡片、AI 总结报告与滑动删除；支持聚合近期总结。
- **Settings**：专注模式、心率模拟、AI 服务配置与连通性测试（含 Header/路径高级选项）。
- **Apple Watch**：独立开始/暂停/重置，实时心率显示，支持离线缓冲消息；与 iPhone 互相同步状态与剩余时长。

---

## ⚙️ 环境与部署
- Xcode 15 及以上
- iOS 17 / watchOS 10 真机设备（建议保持配对）
- HealthKit/推送能力需关联开发者账号

**部署步骤**
1. 在 Xcode 选择 iPhone 真机，目标 `PulseFocus`，完成 Team 签名并启用 `HealthKit`、`Push Notifications`。
2. 运行 iOS App，首启按照系统提示授权健康与通知。
3. 切换 Scheme 至 `WatchPulseFocus Watch App`，目标选择“iPhone + Apple Watch”，运行安装手表端。
4. 如需模拟心率，可在设置页打开“使用模拟心率”，无需真机手表即可体验。

---

## 🧠 AI 模块配置
1. 打开 iOS App“设置 → AI 设置”，启用云端 AI。
2. 填写 Base URL、模型名、是否需要 API Key（可自定义 Header/Prefix/Path）。
3. 点击“测试 AI 连接”即时验证；弹窗会返回模型原始响应，底部状态展示成功或失败原因。
4. 若关闭云端，应用自动回退至本地建议逻辑（基于心率推导专注/休息时长与鼓励语）。

- `PulseFocus/Services/AIService.swift`：远程调用与内容解析
- `PulseFocus/Services/PromptFactory.swift`：提示词模板
- `PulseFocus/Views/Components/AISummarySheet.swift`：总结弹窗与加载状态

---

## 🗂️ 数据与资源
- **SwiftData 模型**：`PulseFocus/Models/Session.swift` 定义会话字段（心率/HRV/打断次数等）。
- **资源放置**：
  - App 图标 → `PulseFocus/Assets.xcassets/AppIcon.appiconset/`
  - 品牌过渡图 → `PulseFocus/Assets.xcassets/LaunchArt.imageset/LaunchArt.png`
  - Watch 图标 → `WatchPulseFocus Watch App/Assets.xcassets/`
- **品牌体验**：`SplashBrandingView` 做 1.2s 淡入，搭配玻璃拟态背景（`HomeView`、`HistoryView`、`SettingsView`）。

---

## 🔍 常见问题
- **启动页 storyboard 报错**：保持系统默认 Launch Screen，品牌展示交给 SwiftUI 过渡页即可。
- **AI 测试总是成功？**：未填 Key 时会弹窗提示“未配置 Key”，并在状态栏显示失败原因。
- **历史页空白弹窗**：已改用 `.sheet(item:)` 绑定 Selected Session，仅在有数据时展示。
- **手表心率未同步**：确认在 Watch 端授权 HealthKit，并保证 iPhone App 处于前台或后台可用状态。

---

## 🏁 快速体验 Checklist
1. 运行 iOS App，完成权限授权。
2. 在设置页配置 AI（可选），执行连通性测试。
3. 手表端启动会话或在 iPhone 侧点击“开始”，观察心率/时长动态调整。
4. 完成一段后查看总结弹窗，保存记录，在历史页生成近期 AI 报告。

---

## 📄 版本与许可
- 仅依赖 Apple 系统框架：SwiftUI、HealthKit、SwiftData、Charts、ActivityKit、WatchConnectivity。
- 项目提供学习与演示用途，欢迎在此基础上继续拓展功能或接入自有模型。
