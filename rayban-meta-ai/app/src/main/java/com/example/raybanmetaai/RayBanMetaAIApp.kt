package com.example.raybanmetaai

import android.app.Application
import android.util.Log
import com.meta.wearable.sdk.Wearables

class RayBanMetaAIApp : Application() {

    companion object {
        private const val TAG = "RayBanMetaAIApp"
    }

    override fun onCreate() {
        super.onCreate()
        initializeWearablesSDK()
    }

    private fun initializeWearablesSDK() {
        try {
            Wearables.initialize(this)
            Log.i(TAG, "Meta Wearables SDK initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Meta Wearables SDK: ${e.message}", e)
        }
    }
}
