import Foundation
import SwiftUI
import Combine

@MainActor
class CameraViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentFrame: UIImage?
    @Published var sessionState: String = "STOPPED"
    @Published var isStreaming: Bool = false
    @Published var isRegistered: Bool = false
    @Published var connectedDeviceName: String?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - AI Analysis Properties

    @Published var analysisResult: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var selectedMode: AnalysisMode = .general
    @Published var showAPIKeyInput: Bool = false
    @Published var apiKeyInput: String = ""

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - デバイス登録 (SDK追加後に実装)

    func startRegistration() {
        showErrorMessage("MWDAT SDK が未追加です。README の手順に従って SDK を追加してください。")
    }

    // MARK: - カメラストリーム制御

    func toggleStream() {
        if isStreaming {
            stopStream()
        } else {
            startStream()
        }
    }

    private func startStream() {
        // TODO: MWDAT SDK 追加後にカメラストリームを実装
        showErrorMessage("MWDAT SDK が未追加のためカメラストリームを開始できません。\nテストとして AI 分析機能を試すには、写真ライブラリから画像を選択してください。")
    }

    private func stopStream() {
        isStreaming = false
        sessionState = "STOPPED"
        currentFrame = nil
    }

    // MARK: - 写真撮影

    func capturePhoto() {
        // TODO: MWDAT SDK 追加後に実装
    }

    // MARK: - AI画像分析 (OpenAI Vision API)

    func analyzeCurrentFrame() {
        guard let image = currentFrame else {
            showErrorMessage("分析する画像がありません。")
            return
        }

        guard !isAnalyzing else { return }
        isAnalyzing = true
        analysisResult = "分析中..."

        Task {
            do {
                let result = try await OpenAIService.shared.analyzeImage(image, mode: selectedMode)
                self.analysisResult = result
            } catch let error as OpenAIError where error.errorDescription?.contains("APIキー") == true {
                self.analysisResult = ""
                self.showAPIKeyInput = true
            } catch {
                self.analysisResult = ""
                self.showErrorMessage("AI分析エラー: \(error.localizedDescription)")
            }
            self.isAnalyzing = false
        }
    }

    // MARK: - テスト用: 画像を直接設定

    func setTestImage(_ image: UIImage) {
        currentFrame = image
    }

    // MARK: - APIキー管理

    func saveAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        Task {
            await OpenAIService.shared.setAPIKey(key)
            showAPIKeyInput = false
            analyzeCurrentFrame()
        }
    }

    func loadAPIKey() {
        Task {
            let key = await OpenAIService.shared.apiKey
            self.apiKeyInput = key
        }
    }

    // MARK: - エラー処理

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
