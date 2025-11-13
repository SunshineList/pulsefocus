import SwiftUI

struct SettingsView: View {
    @ObservedObject var app: AppState
    @State private var aiKeyInput: String = ""
    @State private var aiTestLoading: Bool = false
    @State private var aiTestStatus: String? = nil
    @State private var aiTestContent: String = ""
    @State private var showTestAlert: Bool = false
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionCard(title: "专注模式") {
                    Picker("选择模式", selection: $app.mode) { Text("固定").tag(FocusMode.fixed); Text("自适应").tag(FocusMode.adaptive) }
                    Text(app.mode == .fixed ? "固定为手动设定的时长。" : "自适应会根据心率与 HRV 自动微调时长。").font(.footnote).foregroundStyle(.secondary)
                }
                SectionCard(title: "心率设置") {
                    Toggle("使用模拟心率（无手表）", isOn: $app.isSimulatedHR)
                    Stepper("专注分钟数: \(app.focusMinutes)", value: $app.focusMinutes, in: 15...60)
                    Stepper("休息分钟数: \(app.restMinutes)", value: $app.restMinutes, in: 3...15)
                    Text("建议 25/5 为默认。心率较高时自适应会减少专注、增加休息。").font(.footnote).foregroundStyle(.secondary)
                }
                SectionCard(title: "AI 设置") {
                    Toggle("启用云端 AI 建议", isOn: $app.aiEnabled)
                    if app.aiEnabled {
                        VerticalField(title: "服务地址") {
                            TextField("https://api.moonshot.cn", text: $app.aiBaseURL)
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 6)
                        }
                        VerticalField(title: "模型名") {
                            TextField("kimi-k2-turbo-preview", text: $app.aiModel)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 6)
                        }
                        Toggle("使用 API Key", isOn: $app.aiRequireKey)
                        if app.aiRequireKey {
                            VerticalField(title: "API Key") {
                                SecureField("你的 Key", text: $aiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.vertical, 6)
                            }
                        }
                        DisclosureGroup("高级") {
                            VerticalField(title: "Key Header 名称") {
                                TextField("Authorization", text: $app.aiKeyHeaderName)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.vertical, 6)
                            }
                            VerticalField(title: "Key 前缀") {
                                TextField("Bearer ", text: $app.aiKeyPrefix)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.vertical, 6)
                            }
                            VerticalField(title: "API 路径") {
                                TextField("/v1/chat/completions", text: $app.aiPath)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.vertical, 6)
                            }
                        }
                        HStack(spacing: 12) {
                            Button("保存 AI 设置") { SecureStore.set("aiKey", value: aiKeyInput) }
                                .buttonStyle(.borderedProminent)
                            Button(aiTestLoading ? "测试中…" : "测试 AI 连接") { Task { await testAIConnectivity() } }
                                .buttonStyle(.bordered)
                                .disabled(aiTestLoading)
                        }
                        if let status = aiTestStatus { Text(status).font(.callout).foregroundStyle(status.contains("成功") ? .green : .red) }
                    }
                    Text("不开启时使用本地建议 25/5，并附简短鼓励语。心率数据仅本地计算。").font(.footnote).foregroundStyle(.secondary)
                }
            }.padding()
        }
        .alert("AI 测试结果", isPresented: $showTestAlert) { Button("好的", role: .cancel) {} } message: { Text(aiTestContent.isEmpty ? "无返回内容" : aiTestContent) }
        .background(LinearGradient(colors: [Color.green.opacity(0.15), Color.purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
        .onAppear { aiKeyInput = SecureStore.get("aiKey") ?? "" }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 22, weight: .semibold))
            content()
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.linearGradient(colors: [.green.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 8, x: 0, y: 4)
    }
}

struct VerticalField<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.callout).foregroundStyle(.secondary)
            content()
        }
    }
}

extension SettingsView {
    func testAIConnectivity() async {
        aiTestLoading = true
        defer { aiTestLoading = false }
        let entered = aiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        var endpoint = AIEndpoint(baseURL: app.aiBaseURL)
        endpoint.apiKeyHeaderName = app.aiKeyHeaderName
        endpoint.apiKeyPrefix = app.aiKeyPrefix
        endpoint.path = app.aiPath
        let keyToUse = app.aiRequireKey ? entered : nil
        if app.aiRequireKey && (keyToUse ?? "").isEmpty {
            aiTestStatus = "未配置 Key"
            aiTestContent = "请填写 API Key 或打开“无需 API Key”"
            showTestAlert = true
            return
        }
        let ai = AIService(provider: .remote, endpoint: endpoint, model: app.aiModel, apiKey: keyToUse)
        let (ok, txt) = await ai.testConnectivity()
        aiTestStatus = ok ? "连接成功" : "连接失败"
        aiTestContent = txt
        showTestAlert = true
    }
}
