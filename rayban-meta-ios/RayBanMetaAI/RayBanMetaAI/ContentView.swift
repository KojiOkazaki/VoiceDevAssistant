import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // ステータス表示
                    StatusBadge(state: viewModel.sessionState)

                    // カメラプレビュー
                    if let image = viewModel.currentFrame {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    } else {
                        PlaceholderView()
                    }

                    // デバイス情報
                    if let deviceName = viewModel.connectedDeviceName {
                        Text("接続中: \(deviceName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // コントロールボタン
                    HStack(spacing: 16) {
                        Button(action: { viewModel.toggleStream() }) {
                            Label(
                                viewModel.isStreaming ? "停止" : "開始",
                                systemImage: viewModel.isStreaming ? "stop.circle.fill" : "play.circle.fill"
                            )
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isStreaming ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: { viewModel.capturePhoto() }) {
                            Label("撮影", systemImage: "camera.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isStreaming ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(!viewModel.isStreaming)
                    }
                    .padding(.horizontal)

                    // MARK: - AI 分析セクション

                    VStack(spacing: 12) {
                        Divider()

                        // 分析モード選択
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AnalysisMode.allCases) { mode in
                                    Button(action: { viewModel.selectedMode = mode }) {
                                        Label(mode.rawValue, systemImage: mode.icon)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedMode == mode
                                                    ? Color.purple
                                                    : Color(.systemGray5)
                                            )
                                            .foregroundColor(
                                                viewModel.selectedMode == mode
                                                    ? .white
                                                    : .primary
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // AI分析ボタン
                        Button(action: { viewModel.analyzeCurrentFrame() }) {
                            HStack {
                                if viewModel.isAnalyzing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Label(
                                    viewModel.isAnalyzing ? "分析中..." : "AI で分析",
                                    systemImage: "sparkles"
                                )
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                viewModel.currentFrame != nil && !viewModel.isAnalyzing
                                    ? Color.purple
                                    : Color.gray
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.currentFrame == nil || viewModel.isAnalyzing)
                        .padding(.horizontal)

                        // 分析結果表示
                        if !viewModel.analysisResult.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                    Text("AI 分析結果")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        UIPasteboard.general.string = viewModel.analysisResult
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Text(viewModel.analysisResult)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 登録ボタン
                    if !viewModel.isRegistered {
                        Button(action: { viewModel.startRegistration() }) {
                            Label("Meta AI アプリに登録", systemImage: "link.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // APIキー設定ボタン
                    Button(action: {
                        viewModel.loadAPIKey()
                        viewModel.showAPIKeyInput = true
                    }) {
                        Label("OpenAI APIキー設定", systemImage: "key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .navigationTitle("Ray-Ban Meta AI")
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $viewModel.showAPIKeyInput) {
                APIKeyInputView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - APIキー入力画面

struct APIKeyInputView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)

                Text("OpenAI APIキーを入力")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("GPT-4o Vision APIを使用して\nカメラ映像を分析します")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                SecureField("sk-...", text: $viewModel.apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button(action: {
                    viewModel.saveAPIKey()
                    dismiss()
                }) {
                    Text("保存")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray
                                : Color.purple
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(viewModel.apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ステータスバッジ

struct StatusBadge: View {
    let state: String

    var body: some View {
        HStack {
            Circle()
                .fill(stateColor)
                .frame(width: 10, height: 10)
            Text(state)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(stateColor.opacity(0.15))
        .cornerRadius(20)
    }

    private var stateColor: Color {
        switch state {
        case "RUNNING": return .green
        case "PAUSED": return .orange
        case "STOPPED": return .red
        default: return .gray
        }
    }
}

// MARK: - プレースホルダービュー

struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eyeglasses")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Ray-Ban Meta グラスに接続してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
