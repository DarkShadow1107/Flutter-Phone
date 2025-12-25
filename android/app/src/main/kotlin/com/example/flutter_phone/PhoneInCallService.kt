package com.example.flutter_phone

import android.telecom.InCallService
import android.telecom.Call
import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.Build
import android.media.RingtoneManager
import android.media.Ringtone
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.content.Context
import android.app.KeyguardManager
import android.os.PowerManager
import android.net.Uri
import androidx.core.app.NotificationCompat

class PhoneInCallService : InCallService() {
    
    companion object {
        const val CHANNEL_ID = "incoming_call_channel"
        const val NOTIFICATION_ID = 1001
    }

    private var ringtone: Ringtone? = null
    private var vibrator: Vibrator? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        android.util.Log.d("FlutterPhone", "onCallAdded: state=${call.state}")
        CallManager.setCurrentCall(call)
        
        // Only handle ringing state for incoming calls
        if (call.state == Call.STATE_RINGING) {
            startRingtone()
            startVibration()
            
            // Check if screen is locked to decide notification type
            if (isScreenLocked()) {
                android.util.Log.d("FlutterPhone", "Screen is locked - showing full screen")
                showIncomingCallNotification(call, fullScreen = true)
                launchIncomingCallScreen(call)
            } else {
                android.util.Log.d("FlutterPhone", "Screen is unlocked - showing notification only")
                showIncomingCallNotification(call, fullScreen = false)
                // Still notify Flutter about the incoming call
                notifyFlutterIncomingCall(call)
            }
        }
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        android.util.Log.d("FlutterPhone", "onCallRemoved")
        stopRingtone()
        stopVibration()
        
        if (CallManager.getCurrentCall() == call) {
            CallManager.setCurrentCall(null)
        }
        cancelNotification()
        // Don't launch app here - just clean up
    }

    private fun isScreenLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        
        // Screen is locked if keyguard is locked OR screen is off
        return keyguardManager.isKeyguardLocked || !powerManager.isInteractive
    }

    private fun notifyFlutterIncomingCall(call: Call) {
        val details = call.details
        val handle = details?.handle
        val number = handle?.schemeSpecificPart ?: "Unknown"
        val callerName = details?.callerDisplayName ?: ""
        
        // Notify Flutter via the call manager event sink
        // This is already done in CallManager.setCurrentCall, but we can explicitly trigger here too
        android.util.Log.d("FlutterPhone", "Notifying Flutter of incoming call: $number")
    }

    private fun startRingtone() {
        try {
            // Load custom ringtone path from SharedPreferences (Flutter uses "FlutterSharedPreferences")
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val customUriString = prefs.getString("flutter.custom_ringtone_uri", null)
            
            val ringtoneUri = if (customUriString != null) {
                android.util.Log.d("FlutterPhone", "Loading custom ringtone: $customUriString")
                Uri.parse(customUriString)
            } else {
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            }
            
            ringtone = RingtoneManager.getRingtone(applicationContext, ringtoneUri)
            ringtone?.play()
            android.util.Log.d("FlutterPhone", "Ringtone started with URI: $ringtoneUri")
        } catch (e: Exception) {
            android.util.Log.e("FlutterPhone", "Error starting ringtone: ${e.message}")
        }
    }

    private fun stopRingtone() {
        ringtone?.stop()
        ringtone = null
        android.util.Log.d("FlutterPhone", "Ringtone stopped")
    }

    private fun startVibration() {
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            
            val pattern = longArrayOf(0, 1000, 1000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            android.util.Log.e("FlutterPhone", "Error starting vibration: ${e.message}")
        }
    }

    private fun stopVibration() {
        vibrator?.cancel()
        vibrator = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Incoming Calls"
            val descriptionText = "Notifications for incoming phone calls"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setSound(null, null)
                enableVibration(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showIncomingCallNotification(call: Call, fullScreen: Boolean) {
        val details = call.details
        val handle = details?.handle
        val number = handle?.schemeSpecificPart ?: "Unknown"
        val callerName = details?.callerDisplayName ?: number

        // Intent to launch app
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("incoming_call", true)
            putExtra("caller_number", number)
            putExtra("caller_name", callerName)
        }
        
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, 0, fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Answer action with green color
        val answerIntent = Intent(this, CallActionReceiver::class.java).apply {
            action = "ANSWER_CALL"
        }
        val answerPendingIntent = PendingIntent.getBroadcast(
            this, 1, answerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Decline action with red color
        val declineIntent = Intent(this, CallActionReceiver::class.java).apply {
            action = "DECLINE_CALL"
        }
        val declinePendingIntent = PendingIntent.getBroadcast(
            this, 2, declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build enhanced notification
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle(callerName)
            .setContentText("Incoming call")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Incoming call from $number")
                .setBigContentTitle(callerName))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(0xFF4CAF50.toInt()) // Green accent
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_call,
                    "Answer",
                    answerPendingIntent
                ).build()
            )
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_close_clear_cancel,
                    "Decline",
                    declinePendingIntent
                ).build()
            )
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenPendingIntent)
            .setDeleteIntent(declinePendingIntent)
        
        // Set full screen intent for lock screen
        if (fullScreen) {
            builder.setFullScreenIntent(fullScreenPendingIntent, true)
        }

        val notification = builder.build()
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun launchIncomingCallScreen(call: Call) {
        val details = call.details
        val handle = details?.handle
        val number = handle?.schemeSpecificPart ?: "Unknown"
        val callerName = details?.callerDisplayName ?: ""

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("incoming_call", true)
            putExtra("caller_number", number)
            putExtra("caller_name", callerName)
        }
        startActivity(intent)
    }

    private fun cancelNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.cancel(NOTIFICATION_ID)
    }
}
