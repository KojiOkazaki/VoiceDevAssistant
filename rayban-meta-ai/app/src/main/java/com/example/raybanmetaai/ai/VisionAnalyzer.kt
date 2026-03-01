package com.example.raybanmetaai.ai

import android.graphics.Bitmap
import android.util.Base64
import android.util.Log
import com.example.raybanmetaai.config.AppConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit

/**
 * Handles AI vision analysis by sending camera frames to OpenAI GPT-4 Vision API.
 * Encodes images as base64 and sends them for analysis.
 */
class VisionAnalyzer {

    companion object {
        private const val TAG = "VisionAnalyzer"
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    /**
     * Analyze a bitmap image using OpenAI GPT-4 Vision API.
     *
     * @param bitmap The camera frame to analyze
     * @param mode The analysis mode determining the prompt
     * @return Analysis result text, or error message
     */
    suspend fun analyze(
        bitmap: Bitmap,
        mode: AppConfig.AnalysisMode = AppConfig.AnalysisMode.GENERAL
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            val apiKey = AppConfig.OPENAI_API_KEY
            if (apiKey.isBlank()) {
                return@withContext Result.failure(
                    IllegalStateException("OpenAI APIキーが設定されていません。local.propertiesにopenai_api_keyを設定してください。")
                )
            }

            // Resize and compress the image
            val resizedBitmap = resizeBitmap(bitmap, AppConfig.MAX_IMAGE_WIDTH, AppConfig.MAX_IMAGE_HEIGHT)
            val base64Image = bitmapToBase64(resizedBitmap, AppConfig.JPEG_QUALITY)

            // Build the API request
            val prompt = AppConfig.ANALYSIS_PROMPTS[mode] ?: AppConfig.DEFAULT_ANALYSIS_PROMPT
            val requestBody = buildRequestBody(base64Image, prompt)

            val request = Request.Builder()
                .url(AppConfig.OPENAI_API_URL)
                .addHeader("Authorization", "Bearer $apiKey")
                .addHeader("Content-Type", "application/json")
                .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                .build()

            Log.d(TAG, "Sending image to OpenAI for analysis (mode: $mode)")

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()

            if (!response.isSuccessful) {
                Log.e(TAG, "API error ${response.code}: $responseBody")
                return@withContext Result.failure(
                    RuntimeException("API エラー (${response.code}): ${parseErrorMessage(responseBody)}")
                )
            }

            val result = parseResponse(responseBody)
            Log.i(TAG, "Analysis complete: ${result.take(100)}...")
            Result.success(result)
        } catch (e: Exception) {
            Log.e(TAG, "Analysis failed: ${e.message}", e)
            Result.failure(e)
        }
    }

    /**
     * Resize a bitmap while maintaining aspect ratio.
     */
    private fun resizeBitmap(bitmap: Bitmap, maxWidth: Int, maxHeight: Int): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        if (width <= maxWidth && height <= maxHeight) return bitmap

        val ratio = minOf(maxWidth.toFloat() / width, maxHeight.toFloat() / height)
        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }

    /**
     * Encode a bitmap to base64 JPEG string.
     */
    private fun bitmapToBase64(bitmap: Bitmap, quality: Int): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    /**
     * Build the OpenAI API request JSON body.
     */
    private fun buildRequestBody(base64Image: String, prompt: String): JSONObject {
        val imageContent = JSONObject().apply {
            put("type", "image_url")
            put("image_url", JSONObject().apply {
                put("url", "data:image/jpeg;base64,$base64Image")
                put("detail", "low")  // Use "low" detail for faster/cheaper analysis
            })
        }

        val textContent = JSONObject().apply {
            put("type", "text")
            put("text", prompt)
        }

        val userMessage = JSONObject().apply {
            put("role", "user")
            put("content", JSONArray().apply {
                put(textContent)
                put(imageContent)
            })
        }

        return JSONObject().apply {
            put("model", AppConfig.OPENAI_MODEL)
            put("messages", JSONArray().apply { put(userMessage) })
            put("max_tokens", 500)
        }
    }

    /**
     * Parse the analysis result from the API response.
     */
    private fun parseResponse(responseBody: String?): String {
        if (responseBody == null) return "応答が空です"

        val json = JSONObject(responseBody)
        val choices = json.getJSONArray("choices")
        if (choices.length() == 0) return "分析結果がありません"

        return choices.getJSONObject(0)
            .getJSONObject("message")
            .getString("content")
    }

    /**
     * Parse error message from API error response.
     */
    private fun parseErrorMessage(responseBody: String?): String {
        if (responseBody == null) return "不明なエラー"
        return try {
            JSONObject(responseBody).getJSONObject("error").getString("message")
        } catch (e: Exception) {
            responseBody.take(200)
        }
    }
}
