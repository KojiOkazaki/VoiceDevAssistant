import SwiftUI
import MWDATCore
import MWDATCamera

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ステータス表示
                StatusBadge(state: viewModel.sessionState)

                // カメラプレビュー
                if let image = viewModel.currentFrame {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
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

                Spacer()
            }
            .padding()
            .navigationTitle("Ray-Ban Meta AI")
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
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
