import Foundation
import UIKit

// MARK: - 分析モード

enum AnalysisMode: String, CaseIterable, Identifiable {
    case general = "一般分析"
    case textRecognition = "テキスト認識"
    case objectDetection = "物体検出"
    case navigation = "ナビ"
    case productInfo = "製品情報"

    var id: String { rawValue }

    var prompt: String {
        switch self {
        case .general:
            return """
            あなたは視覚AIアシスタントです。
            ユーザーがRay-Ban Metaグラスのカメラで見ているものを分析してください。
            画像の内容を簡潔に日本語で説明し、有用な情報があれば提供してください。
            例：テキストの翻訳、物体の識別、場所の説明、製品情報など。
            """
        case .textRecognition:
            return """
            画像内のテキストを読み取り、日本語で内容を説明してください。
            外国語のテキストがあれば日本語に翻訳してください。
            """
        case .objectDetection:
            return """
            画像内の物体を識別し、日本語でリストアップしてください。
            各物体の位置関係や特徴も簡潔に説明してください。
            """
        case .navigation:
            return """
            画像から周囲の環境を分析し、ナビゲーションに役立つ情報を日本語で提供してください。
            看板、道路標識、ランドマークなどを識別してください。
            """
        case .productInfo:
            return """
            画像内の製品やブランドを識別し、日本語で情報を提供してください。
            製品名、ブランド、おおよその価格帯などの情報があれば含めてください。
            """
        }
    }

    var icon: String {
        switch self {
        case .general: return "eye"
        case .textRecognition: return "doc.text.viewfinder"
        case .objectDetection: return "cube.transparent"
        case .navigation: return "location.viewfinder"
        case .productInfo: return "bag"
        }
    }
}

// MARK: - OpenAI Service

actor OpenAIService {

    // APIキーはUserDefaultsまたは環境変数から取得
    // 本番ではKeychainを使うべき
    static let shared = OpenAIService()

    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o"
    private let maxImageSize: CGFloat = 720
    private let jpegQuality: CGFloat = 0.5

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "openai_api_key") ?? "" }
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }

    // MARK: - 画像分析

    func analyzeImage(_ image: UIImage, mode: AnalysisMode = .general) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        // 画像をリサイズしてBase64エンコード
        let resized = resizeImage(image, maxDimension: maxImageSize)
        guard let jpegData = resized.jpegData(compressionQuality: jpegQuality) else {
            throw OpenAIError.imageEncodingFailed
        }
        let base64String = jpegData.base64EncodedString()

        // リクエストBody構築
        let requestBody = buildRequestBody(base64Image: base64String, prompt: mode.prompt)

        // URLRequest作成
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60

        // API呼び出し
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseErrorMessage(from: data)
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseResponse(from: data)
    }

    // MARK: - Private

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func buildRequestBody(base64Image: String, prompt: String) -> [String: Any] {
        [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
        ]
    }

    private func parseResponse(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.parsingFailed
        }
        return content
    }

    private func parseErrorMessage(from data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return String(data: data, encoding: .utf8) ?? "不明なエラー"
        }
        return message
    }
}

// MARK: - エラー定義

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case imageEncodingFailed
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI APIキーが設定されていません。設定画面からAPIキーを入力してください。"
        case .imageEncodingFailed:
            return "画像のエンコードに失敗しました。"
        case .invalidResponse:
            return "サーバーからの応答が不正です。"
        case .apiError(let statusCode, let message):
            return "APIエラー (\(statusCode)): \(message)"
        case .parsingFailed:
            return "応答の解析に失敗しました。"
        }
    }
}
