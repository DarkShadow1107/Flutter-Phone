package com.example.flutter_phone

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CallActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "ANSWER_CALL" -> {
                CallManager.answerCall()
            }
            "DECLINE_CALL" -> {
                CallManager.rejectCall()
            }
        }
    }
}
