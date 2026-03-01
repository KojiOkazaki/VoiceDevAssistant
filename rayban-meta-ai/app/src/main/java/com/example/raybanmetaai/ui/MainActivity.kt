package com.example.raybanmetaai.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.example.raybanmetaai.R
import com.example.raybanmetaai.config.AppConfig
import com.example.raybanmetaai.databinding.ActivityMainBinding
import com.example.raybanmetaai.glasses.GlassesConnectionManager.ConnectionState
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var viewModel: MainViewModel

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.values.all { it }
        if (allGranted) {
            viewModel.connectGlasses(this)
        } else {
            binding.tvStatus.text = "必要な権限が許可されていません"
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        viewModel = ViewModelProvider(this)[MainViewModel::class.java]

        setupUI()
        observeState()
    }

    private fun setupUI() {
        // Connect / Disconnect button
        binding.btnConnect.setOnClickListener {
            val state = viewModel.glassesManager.connectionState.value
            if (state is ConnectionState.Disconnected || state is ConnectionState.Error) {
                checkPermissionsAndConnect()
            } else {
                viewModel.disconnectGlasses(this)
            }
        }

        // Start / Stop streaming button
        binding.btnStream.setOnClickListener {
            val state = viewModel.glassesManager.connectionState.value
            if (state is ConnectionState.Streaming) {
                viewModel.stopStreaming()
            } else {
                viewModel.startStreaming(this)
            }
        }

        // Analyze once button
        binding.btnAnalyze.setOnClickListener {
            viewModel.analyzeCurrentFrame()
        }

        // Continuous analysis toggle
        binding.btnContinuous.setOnClickListener {
            if (binding.btnContinuous.text == getString(R.string.start_continuous)) {
                viewModel.startContinuousAnalysis()
                binding.btnContinuous.text = getString(R.string.stop_continuous)
            } else {
                viewModel.stopContinuousAnalysis()
                binding.btnContinuous.text = getString(R.string.start_continuous)
            }
        }

        // Analysis mode spinner
        val modes = AppConfig.AnalysisMode.entries.map { mode ->
            when (mode) {
                AppConfig.AnalysisMode.GENERAL -> "一般分析"
                AppConfig.AnalysisMode.TEXT_RECOGNITION -> "テキスト認識"
                AppConfig.AnalysisMode.OBJECT_DETECTION -> "物体検出"
                AppConfig.AnalysisMode.NAVIGATION -> "ナビゲーション"
                AppConfig.AnalysisMode.PRODUCT_INFO -> "製品情報"
            }
        }
        binding.spinnerMode.adapter = ArrayAdapter(
            this, android.R.layout.simple_spinner_dropdown_item, modes
        )
        binding.spinnerMode.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                viewModel.setAnalysisMode(AppConfig.AnalysisMode.entries[position])
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
    }

    private fun observeState() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                // Observe connection state
                launch {
                    viewModel.glassesManager.connectionState.collect { state ->
                        updateUIForConnectionState(state)
                    }
                }

                // Observe camera frames
                launch {
                    viewModel.glassesManager.latestFrame.collect { bitmap ->
                        if (bitmap != null) {
                            binding.ivCamera.setImageBitmap(bitmap)
                            binding.ivCamera.visibility = View.VISIBLE
                            binding.tvCameraPlaceholder.visibility = View.GONE
                        } else {
                            binding.ivCamera.visibility = View.GONE
                            binding.tvCameraPlaceholder.visibility = View.VISIBLE
                        }
                    }
                }

                // Observe analysis result
                launch {
                    viewModel.analysisResult.collect { result ->
                        binding.tvAnalysisResult.text = result
                    }
                }

                // Observe analyzing state
                launch {
                    viewModel.isAnalyzing.collect { analyzing ->
                        binding.progressAnalysis.visibility = if (analyzing) View.VISIBLE else View.GONE
                        binding.btnAnalyze.isEnabled = !analyzing
                    }
                }
            }
        }
    }

    private fun updateUIForConnectionState(state: ConnectionState) {
        when (state) {
            is ConnectionState.Disconnected -> {
                binding.tvStatus.text = "未接続"
                binding.tvStatus.setTextColor(ContextCompat.getColor(this, R.color.status_disconnected))
                binding.btnConnect.text = getString(R.string.connect)
                binding.btnStream.isEnabled = false
                binding.btnAnalyze.isEnabled = false
                binding.btnContinuous.isEnabled = false
            }
            is ConnectionState.Registering -> {
                binding.tvStatus.text = "Meta AIアプリで登録中..."
                binding.tvStatus.setTextColor(ContextCompat.getColor(this, R.color.status_connecting))
                binding.btnConnect.isEnabled = false
            }
            is ConnectionState.Registered -> {
                binding.tvStatus.text = "登録済み (グラスの接続待ち)"
                binding.tvStatus.setTextColor(ContextCompat.getColor(this, R.color.status_connecting))
                binding.btnConnect.text = getString(R.string.disconnect)
                binding.btnConnect.isEnabled = true
                binding.btnStream.isEnabled = false
            }
            is ConnectionState.DeviceConnected -> {
                binding.tvStatus.text = "接続済み: ${state.device.name}"
                binding.tvStatus.setTextColor(ContextCompat.getColor(this, R.color.status_connected))
                binding.btnConnect.text = getString(R.string.disconnect)
                binding.btnConnect.isEnabled = true
                binding.btnStream.isEnabled = true
                binding.btnStream.text = getString(R.string.start_stream)
            }
            is ConnectionState.Streaming -> {
                binding.tvStatus.text = "ストリーミング中"
                binding.tvStatus.setTextColor(ContextCompat.getColor(this, R.color.status_streaming))
                binding.btnStream.text = getString(R.string.stop_stream)
                binding.btnAnalyze.isEnabled = true
                binding.btnContinuous.isEnabled = true
            }
            is ConnectionState.Error -> {
                binding.tvStatus.text = "エラー: ${state.message}"
                binding.tvStatus.setTextColor(ContextCompat.getColor(this, R.color.status_error))
                binding.btnConnect.text = getString(R.string.connect)
                binding.btnConnect.isEnabled = true
                binding.btnStream.isEnabled = false
            }
        }
    }

    private fun checkPermissionsAndConnect() {
        val requiredPermissions = arrayOf(
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.CAMERA
        )

        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            viewModel.connectGlasses(this)
        } else {
            permissionLauncher.launch(missingPermissions.toTypedArray())
        }
    }
}
