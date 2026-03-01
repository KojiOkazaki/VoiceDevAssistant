package com.example.raybanmetaai.glasses

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.meta.wearable.sdk.Permission
import com.meta.wearable.sdk.PermissionStatus
import com.meta.wearable.sdk.RegistrationState
import com.meta.wearable.sdk.Wearables
import com.meta.wearable.sdk.WearablesDevice
import com.meta.wearable.sdk.camera.CameraStreamListener
import com.meta.wearable.sdk.camera.WearablesCamera
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Manages the connection to Ray-Ban Meta glasses via Meta Wearables DAT SDK.
 * Handles registration, device discovery, camera permissions, and video streaming.
 */
class GlassesConnectionManager {

    companion object {
        private const val TAG = "GlassesConnection"
    }

    sealed class ConnectionState {
        data object Disconnected : ConnectionState()
        data object Registering : ConnectionState()
        data object Registered : ConnectionState()
        data class DeviceConnected(val device: WearablesDevice) : ConnectionState()
        data object Streaming : ConnectionState()
        data class Error(val message: String) : ConnectionState()
    }

    private val _connectionState = MutableStateFlow<ConnectionState>(ConnectionState.Disconnected)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()

    private val _latestFrame = MutableStateFlow<Bitmap?>(null)
    val latestFrame: StateFlow<Bitmap?> = _latestFrame.asStateFlow()

    private var connectedDevice: WearablesDevice? = null
    private var streamJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    /**
     * Start registration with the Meta AI app.
     * This will open the Meta AI app for the user to authorize access.
     */
    fun startRegistration(activity: Activity) {
        _connectionState.value = ConnectionState.Registering
        try {
            Wearables.startRegistration(activity)
            observeRegistrationState()
        } catch (e: Exception) {
            Log.e(TAG, "Registration failed: ${e.message}", e)
            _connectionState.value = ConnectionState.Error("登録に失敗しました: ${e.message}")
        }
    }

    /**
     * Unregister from the Meta AI app.
     */
    fun unregister(activity: Activity) {
        stopStreaming()
        try {
            Wearables.startUnregistration(activity)
            _connectionState.value = ConnectionState.Disconnected
        } catch (e: Exception) {
            Log.e(TAG, "Unregistration failed: ${e.message}", e)
        }
    }

    /**
     * Observe registration state changes from the SDK.
     */
    private fun observeRegistrationState() {
        scope.launch {
            Wearables.registrationState.collect { state ->
                when (state) {
                    is RegistrationState.Registered -> {
                        Log.i(TAG, "Successfully registered with Meta AI app")
                        _connectionState.value = ConnectionState.Registered
                        observeDevices()
                    }
                    is RegistrationState.Unregistered -> {
                        Log.i(TAG, "Unregistered from Meta AI app")
                        _connectionState.value = ConnectionState.Disconnected
                    }
                    else -> {
                        Log.d(TAG, "Registration state: $state")
                    }
                }
            }
        }
    }

    /**
     * Observe connected devices.
     */
    private fun observeDevices() {
        scope.launch {
            Wearables.devices.collect { devices ->
                if (devices.isNotEmpty()) {
                    val device = devices.first()
                    connectedDevice = device
                    Log.i(TAG, "Device connected: ${device.name}")
                    _connectionState.value = ConnectionState.DeviceConnected(device)
                } else {
                    connectedDevice = null
                    if (_connectionState.value !is ConnectionState.Disconnected) {
                        _connectionState.value = ConnectionState.Registered
                    }
                }
            }
        }
    }

    /**
     * Check camera permission and start streaming.
     */
    fun startStreaming(activity: Activity) {
        scope.launch {
            try {
                val permissionStatus = Wearables.checkPermissionStatus(Permission.CAMERA)
                when (permissionStatus) {
                    PermissionStatus.Granted -> {
                        beginCameraStream()
                    }
                    else -> {
                        // Request camera permission - this opens a prompt on the glasses
                        Wearables.requestPermission(activity, Permission.CAMERA)
                        // After permission is granted, the user should tap "Start Streaming" again
                        Log.i(TAG, "Camera permission requested. Waiting for approval on glasses.")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start streaming: ${e.message}", e)
                _connectionState.value = ConnectionState.Error("ストリーミング開始に失敗: ${e.message}")
            }
        }
    }

    /**
     * Begin the camera stream from the glasses.
     */
    private fun beginCameraStream() {
        _connectionState.value = ConnectionState.Streaming
        streamJob = scope.launch(Dispatchers.IO) {
            try {
                WearablesCamera.startStreaming(object : CameraStreamListener {
                    override fun onFrameAvailable(frameData: ByteArray) {
                        try {
                            val bitmap = BitmapFactory.decodeByteArray(frameData, 0, frameData.size)
                            if (bitmap != null) {
                                _latestFrame.value = bitmap
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to decode frame: ${e.message}")
                        }
                    }

                    override fun onStreamError(error: String) {
                        Log.e(TAG, "Stream error: $error")
                        _connectionState.value = ConnectionState.Error("ストリームエラー: $error")
                    }

                    override fun onStreamStopped() {
                        Log.i(TAG, "Stream stopped")
                        if (_connectionState.value is ConnectionState.Streaming) {
                            _connectionState.value = connectedDevice?.let {
                                ConnectionState.DeviceConnected(it)
                            } ?: ConnectionState.Registered
                        }
                    }
                })
                Log.i(TAG, "Camera streaming started")
            } catch (e: Exception) {
                Log.e(TAG, "Camera stream failed: ${e.message}", e)
                _connectionState.value = ConnectionState.Error("カメラストリーム失敗: ${e.message}")
            }
        }
    }

    /**
     * Stop the camera stream.
     */
    fun stopStreaming() {
        streamJob?.cancel()
        streamJob = null
        try {
            WearablesCamera.stopStreaming()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping stream: ${e.message}")
        }
        _latestFrame.value = null
        _connectionState.value = connectedDevice?.let {
            ConnectionState.DeviceConnected(it)
        } ?: ConnectionState.Registered
    }

    /**
     * Clean up resources.
     */
    fun destroy() {
        stopStreaming()
        connectedDevice = null
    }
}
