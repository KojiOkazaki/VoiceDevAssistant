import Foundation
import SwiftUI
import Combine
#if MWDAT_ENABLED
import MWDATCore
import MWDATCamera
#endif

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

    #if MWDAT_ENABLED
    private var streamSession: StreamSession?
    #endif
    private var deviceSessionStateToken: Any?
    private var deviceMetadataToken: Any?
    private var cancellables = Set<AnyCancellable>()
    private var currentDeviceId: String?

    // MARK: - Step 4: アプリから登録を開始する

    func startRegistration() {
        #if MWDAT_ENABLED
        Task {
            do {
                try await Wearables.shared.startRegistration()
                isRegistered = true
                observeDevices()
            } catch {
                showError(message: "登録に失敗しました: \(error.localizedDescription)")
            }
        }
        #else
        showError(message: "MWDAT SDK が追加されていません。Xcode で Swift Package を追加し、Build Settings の SWIFT_ACTIVE_COMPILATION_CONDITIONS に MWDAT_ENABLED を追加してください。")
        #endif
    }

    // MARK: - デバイスの監視

    private func observeDevices() {
        #if MWDAT_ENABLED
        Task {
            let wearables = Wearables.shared
            for await devices in wearables.devices {
                if let device = devices.first {
                    currentDeviceId = device.identifier
                    connectedDeviceName = device.name
                    observeDeviceSessionState(deviceId: device.identifier)
                    observeDeviceAvailability(deviceId: device.identifier)
                    break
                }
            }
        }
        #endif
    }

    // MARK: - デバイスセッション状態の監視

    private func observeDeviceSessionState(deviceId: String) {
        #if MWDAT_ENABLED
        Task {
            let token = await Wearables.shared.addDeviceSessionStateListener(
                forDeviceId: deviceId,
                listener: { [weak self] state in
                    Task { @MainActor in
                        guard let self = self else { return }
                        switch state {
                        case .running:
                            self.sessionState = "RUNNING"
                            self.isStreaming = true
                        case .paused:
                            self.sessionState = "PAUSED"
                        case .stopped:
                            self.sessionState = "STOPPED"
                            self.isStreaming = false
                            self.currentFrame = nil
                            self.streamSession = nil
                        default:
                            break
                        }
                    }
                }
            )
            deviceSessionStateToken = token
        }
        #endif
    }

    // MARK: - デバイスの可用性監視

    private func observeDeviceAvailability(deviceId: String) {
        #if MWDAT_ENABLED
        Task {
            let device = Wearables.shared.deviceForIdentifier(deviceId)
            let token = device.addLinkStateListener { [weak self] linkState in
                Task { @MainActor in
                    guard let self = self else { return }
                    if linkState == .connected {
                        self.connectedDeviceName = device.name
                    } else {
                        self.connectedDeviceName = nil
                    }
                }
            }
            deviceMetadataToken = token
        }
        #endif
    }

    // MARK: - Step 5: カメラの権限を管理する

    private func checkCameraPermission() async -> Bool {
        #if MWDAT_ENABLED
        let cameraStatus = await Wearables.shared.cameraPermissionStatus
        switch cameraStatus {
        case .granted:
            return true
        case .denied:
            showError(message: "カメラの権限が拒否されています。設定から許可してください。")
            return false
        case .notDetermined:
            let granted = await Wearables.shared.requestCameraPermission()
            return granted
        @unknown default:
            return false
        }
        #else
        return false
        #endif
    }

    // MARK: - Step 6: カメラストリームを開始する

    func toggleStream() {
        if isStreaming {
            stopStream()
        } else {
            startStream()
        }
    }

    private func startStream() {
        #if MWDAT_ENABLED
        Task {
            guard await checkCameraPermission() else { return }

            let config = StreamSessionConfig(
                resolution: .medium,
                frameRate: 15
            )
            let deviceSelector = AutoDeviceSelector()
            let session = StreamSession(
                config: config,
                deviceSelector: deviceSelector
            )
            streamSession = session

            session.frameHandler = { [weak self] frame in
                Task { @MainActor in
                    self?.currentFrame = frame.image
                }
            }

            session.stateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self = self else { return }
                    switch state {
                    case .streaming:
                        self.isStreaming = true
                        self.sessionState = "RUNNING"
                    case .stopping, .stopped:
                        self.isStreaming = false
                        self.sessionState = "STOPPED"
                    case .waitingForDevice:
                        self.sessionState = "待機中..."
                    case .starting:
                        self.sessionState = "開始中..."
                    case .paused:
                        self.sessionState = "PAUSED"
                    @unknown default:
                        break
                    }
                }
            }

            session.start()
        }
        #else
        showError(message: "MWDAT SDK が追加されていません。")
        #endif
    }

    private func stopStream() {
        #if MWDAT_ENABLED
        streamSession?.stop()
        streamSession = nil
        #endif
        isStreaming = false
        sessionState = "STOPPED"
        currentFrame = nil
    }

    // MARK: - Step 7: 写真を撮影して共有する

    func capturePhoto() {
        #if MWDAT_ENABLED
        guard let session = streamSession, isStreaming else { return }
        session.capturePhoto()
        session.photoHandler = { [weak self] photoData in
            Task { @MainActor in
                guard let self = self else { return }
                if let image = UIImage(data: photoData.data) {
                    self.currentFrame = image
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
        #endif
    }

    // MARK: - Step 8: AI画像分析 (OpenAI Vision API)

    func analyzeCurrentFrame() {
        guard let image = currentFrame else {
            showError(message: "分析する画像がありません。カメラストリームを開始してください。")
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
                self.showError(message: "AI分析エラー: \(error.localizedDescription)")
            }
            self.isAnalyzing = false
        }
    }

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

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
