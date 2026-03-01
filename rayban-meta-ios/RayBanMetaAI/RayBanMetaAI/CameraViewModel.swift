import Foundation
import SwiftUI
import Combine
import MWDATCore
import MWDATCamera

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

    // MARK: - Private Properties

    private var streamSession: StreamSession?
    private var deviceSessionStateToken: Any?
    private var deviceMetadataToken: Any?
    private var cancellables = Set<AnyCancellable>()
    private var currentDeviceId: String?

    // MARK: - Step 4: アプリから登録を開始する

    func startRegistration() {
        Task {
            do {
                try await Wearables.shared.startRegistration()
                isRegistered = true
                observeDevices()
            } catch {
                showError(message: "登録に失敗しました: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - デバイスの監視

    private func observeDevices() {
        Task {
            let wearables = Wearables.shared

            // デバイスの検出を監視
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
    }

    // MARK: - デバイスセッション状態の監視

    private func observeDeviceSessionState(deviceId: String) {
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
                            // 一時停止中はデバイスセッションの再開を試みない
                        case .stopped:
                            self.sessionState = "STOPPED"
                            self.isStreaming = false
                            self.currentFrame = nil
                            // リソース解放
                            self.streamSession = nil
                        default:
                            break
                        }
                    }
                }
            )
            deviceSessionStateToken = token
        }
    }

    // MARK: - デバイスの可用性監視

    private func observeDeviceAvailability(deviceId: String) {
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
    }

    // MARK: - Step 5: カメラの権限を管理する

    private func checkCameraPermission() async -> Bool {
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
        Task {
            // カメラ権限確認
            guard await checkCameraPermission() else { return }

            // StreamSession 設定
            // 解像度: high (720x1280), medium (504x896), low (360x640)
            // フレームレート: 2, 7, 15, 24, 30 FPS
            let config = StreamSessionConfig(
                resolution: .medium,
                frameRate: 15
            )

            // AutoDeviceSelector を使用してデバイスを自動選択
            let deviceSelector = AutoDeviceSelector()

            let session = StreamSession(
                config: config,
                deviceSelector: deviceSelector
            )

            streamSession = session

            // フレームと状態イベントのコールバックを登録
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

            // ストリーム開始
            session.start()
        }
    }

    private func stopStream() {
        streamSession?.stop()
        streamSession = nil
        isStreaming = false
        sessionState = "STOPPED"
        currentFrame = nil
    }

    // MARK: - Step 7: 写真を撮影して共有する

    func capturePhoto() {
        guard let session = streamSession, isStreaming else { return }

        session.capturePhoto()

        // photoDataPublisher で写真データを受信
        session.photoHandler = { [weak self] photoData in
            Task { @MainActor in
                guard let self = self else { return }
                if let image = UIImage(data: photoData.data) {
                    self.currentFrame = image
                    // 写真をフォトライブラリに保存
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
    }

    // MARK: - エラー処理

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
