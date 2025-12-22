package com.example.flutter_phone

import android.telecom.Call
import android.telecom.VideoProfile
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

object CallManager {
    private var currentCall: Call? = null
    private var eventSink: EventChannel.EventSink? = null
    
    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            notifyCallStateChanged(call, state)
        }
    }
    
    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }
    
    fun setCurrentCall(call: Call?) {
        currentCall?.unregisterCallback(callCallback)
        currentCall = call
        call?.registerCallback(callCallback)
        
        if (call != null) {
            notifyIncomingCall(call)
        }
    }
    
    fun getCurrentCall(): Call? = currentCall
    
    fun answerCall() {
        currentCall?.answer(VideoProfile.STATE_AUDIO_ONLY)
    }
    
    fun rejectCall() {
        currentCall?.reject(false, null)
    }
    
    fun endCall() {
        currentCall?.disconnect()
    }
    
    fun toggleMute(mute: Boolean) {
        // Mute is handled by AudioManager in the InCallService
    }
    
    fun toggleSpeaker(speaker: Boolean) {
        // Speaker is handled by AudioManager in the InCallService
    }
    
    fun sendDtmf(digit: Char) {
        currentCall?.playDtmfTone(digit)
        currentCall?.stopDtmfTone()
    }
    
    private fun notifyIncomingCall(call: Call) {
        val details = call.details
        val handle = details?.handle
        val number = handle?.schemeSpecificPart ?: "Unknown"
        val callerName = details?.callerDisplayName ?: ""
        
        val callInfo = mapOf(
            "event" to "incoming",
            "number" to number,
            "name" to callerName,
            "state" to getStateString(call.state)
        )
        
        eventSink?.success(callInfo)
    }
    
    private fun notifyCallStateChanged(call: Call, state: Int) {
        val details = call.details
        val handle = details?.handle
        val number = handle?.schemeSpecificPart ?: "Unknown"
        val stateString = getStateString(state)
        
        android.util.Log.d("FlutterPhone", "Call state changed: $stateString for $number")
        
        val stateInfo = mapOf(
            "event" to "stateChanged",
            "number" to number,
            "state" to stateString
        )
        
        eventSink?.success(stateInfo)
        
        // If call ended, clear current call
        if (state == Call.STATE_DISCONNECTED) {
            android.util.Log.d("FlutterPhone", "Call disconnected, clearing current call")
            currentCall?.unregisterCallback(callCallback)
            currentCall = null
        }
    }
    
    private fun getStateString(state: Int): String {
        return when (state) {
            Call.STATE_NEW -> "new"
            Call.STATE_DIALING -> "dialing"
            Call.STATE_RINGING -> "ringing"
            Call.STATE_HOLDING -> "holding"
            Call.STATE_ACTIVE -> "active"
            Call.STATE_DISCONNECTED -> "disconnected"
            Call.STATE_CONNECTING -> "connecting"
            Call.STATE_DISCONNECTING -> "disconnecting"
            Call.STATE_SELECT_PHONE_ACCOUNT -> "selectAccount"
            Call.STATE_PULLING_CALL -> "pulling"
            else -> "unknown"
        }
    }
}
