package com.example.raybanmetaai.config

import com.example.raybanmetaai.BuildConfig

/**
 * Application configuration constants.
 */
object AppConfig {
    // Facebook App ID (from developers.facebook.com)
    const val FACEBOOK_APP_ID = "696998827356456"

    // OpenAI API settings
    val OPENAI_API_KEY: String get() = BuildConfig.OPENAI_API_KEY
    const val OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
    const val OPENAI_MODEL = "gpt-4o"

    // Camera streaming settings
    const val STREAM_TARGET_FPS = 1          // Send 1 frame per second to AI
    const val JPEG_QUALITY = 50              // JPEG compression quality (0-100)
    const val MAX_IMAGE_WIDTH = 720          // Max image width for AI analysis
    const val MAX_IMAGE_HEIGHT = 720         // Max image height for AI analysis

    // AI analysis prompt (Japanese)
    const val DEFAULT_ANALYSIS_PROMPT = """あなたは視覚AIアシスタントです。
ユーザーがRay-Ban Metaグラスのカメラで見ているものを分析してください。
画像の内容を簡潔に日本語で説明し、有用な情報があれば提供してください。
例：テキストの翻訳、物体の識別、場所の説明、製品情報など。"""

    // Analysis mode prompts
    val ANALYSIS_PROMPTS = mapOf(
        AnalysisMode.GENERAL to DEFAULT_ANALYSIS_PROMPT,
        AnalysisMode.TEXT_RECOGNITION to """画像内のテキストを読み取り、日本語で内容を説明してください。
外国語のテキストがあれば日本語に翻訳してください。""",
        AnalysisMode.OBJECT_DETECTION to """画像内の物体を識別し、日本語でリストアップしてください。
各物体の位置関係や特徴も簡潔に説明してください。""",
        AnalysisMode.NAVIGATION to """画像から周囲の環境を分析し、ナビゲーションに役立つ情報を日本語で提供してください。
看板、道路標識、ランドマークなどを識別してください。""",
        AnalysisMode.PRODUCT_INFO to """画像内の製品やブランドを識別し、日本語で情報を提供してください。
製品名、ブランド、おおよその価格帯などの情報があれば含めてください。"""
    )

    enum class AnalysisMode {
        GENERAL,
        TEXT_RECOGNITION,
        OBJECT_DETECTION,
        NAVIGATION,
        PRODUCT_INFO
    }
}
