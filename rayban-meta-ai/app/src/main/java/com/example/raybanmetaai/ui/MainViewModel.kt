package com.example.raybanmetaai.ui

import android.app.Activity
import android.graphics.Bitmap
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.raybanmetaai.ai.VisionAnalyzer
import com.example.raybanmetaai.config.AppConfig
import com.example.raybanmetaai.glasses.GlassesConnectionManager
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel : ViewModel() {

    companion object {
        private const val TAG = "MainViewModel"
        private const val ANALYSIS_INTERVAL_MS = 3000L  // Analyze every 3 seconds
    }

    val glassesManager = GlassesConnectionManager()
    private val visionAnalyzer = VisionAnalyzer()

    private val _analysisResult = MutableStateFlow("")
    val analysisResult: StateFlow<String> = _analysisResult.asStateFlow()

    private val _isAnalyzing = MutableStateFlow(false)
    val isAnalyzing: StateFlow<Boolean> = _isAnalyzing.asStateFlow()

    private val _analysisMode = MutableStateFlow(AppConfig.AnalysisMode.GENERAL)
    val analysisMode: StateFlow<AppConfig.AnalysisMode> = _analysisMode.asStateFlow()

    private val _analysisHistory = MutableStateFlow<List<AnalysisEntry>>(emptyList())
    val analysisHistory: StateFlow<List<AnalysisEntry>> = _analysisHistory.asStateFlow()

    private var continuousAnalysisJob: Job? = null

    data class AnalysisEntry(
        val timestamp: Long,
        val mode: AppConfig.AnalysisMode,
        val result: String
    )

    fun connectGlasses(activity: Activity) {
        glassesManager.startRegistration(activity)
    }

    fun disconnectGlasses(activity: Activity) {
        stopContinuousAnalysis()
        glassesManager.unregister(activity)
    }

    fun startStreaming(activity: Activity) {
        glassesManager.startStreaming(activity)
    }

    fun stopStreaming() {
        stopContinuousAnalysis()
        glassesManager.stopStreaming()
    }

    fun setAnalysisMode(mode: AppConfig.AnalysisMode) {
        _analysisMode.value = mode
    }

    /**
     * Analyze the current frame once.
     */
    fun analyzeCurrentFrame() {
        val frame = glassesManager.latestFrame.value
        if (frame == null) {
            _analysisResult.value = "カメラフレームがありません。ストリーミングを開始してください。"
            return
        }
        analyzeFrame(frame)
    }

    /**
     * Start continuous analysis at regular intervals.
     */
    fun startContinuousAnalysis() {
        if (continuousAnalysisJob?.isActive == true) return

        continuousAnalysisJob = viewModelScope.launch {
            while (true) {
                val frame = glassesManager.latestFrame.value
                if (frame != null) {
                    analyzeFrame(frame)
                }
                delay(ANALYSIS_INTERVAL_MS)
            }
        }
    }

    /**
     * Stop continuous analysis.
     */
    fun stopContinuousAnalysis() {
        continuousAnalysisJob?.cancel()
        continuousAnalysisJob = null
    }

    private fun analyzeFrame(bitmap: Bitmap) {
        if (_isAnalyzing.value) return  // Skip if already analyzing

        viewModelScope.launch {
            _isAnalyzing.value = true
            _analysisResult.value = "分析中..."

            val result = visionAnalyzer.analyze(bitmap, _analysisMode.value)

            result.onSuccess { text ->
                _analysisResult.value = text
                addToHistory(text)
            }.onFailure { error ->
                _analysisResult.value = "エラー: ${error.message}"
                Log.e(TAG, "Analysis failed", error)
            }

            _isAnalyzing.value = false
        }
    }

    private fun addToHistory(result: String) {
        val entry = AnalysisEntry(
            timestamp = System.currentTimeMillis(),
            mode = _analysisMode.value,
            result = result
        )
        _analysisHistory.value = listOf(entry) + _analysisHistory.value.take(19)
    }

    override fun onCleared() {
        super.onCleared()
        stopContinuousAnalysis()
        glassesManager.destroy()
    }
}
