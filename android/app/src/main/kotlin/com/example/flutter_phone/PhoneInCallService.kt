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
import android.provider.ContactsContract
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.InputStream

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
        
        // Listen for internal call state changes to update notification
        call.registerCallback(object : Call.Callback() {
            override fun onStateChanged(call: Call, state: Int) {
                super.onStateChanged(call, state)
                android.util.Log.d("FlutterPhone", "Internal Call State Changed: $state")
                updateCallNotification(call)
            }
        })

        // Only handle ringing state for incoming calls
        if (call.state == Call.STATE_RINGING) {
            startRingtone()
            startVibration()
            showIncomingCallNotification(call)
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
    }

    private fun startRingtone() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val customUriString = prefs.getString("flutter.custom_ringtone_uri", null)
            val ringtoneUri = if (customUriString != null) Uri.parse(customUriString) else RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            ringtone = RingtoneManager.getRingtone(applicationContext, ringtoneUri)
            ringtone?.play()
        } catch (e: Exception) {
            android.util.Log.e("FlutterPhone", "Error starting ringtone: ${e.message}")
        }
    }

    private fun stopRingtone() {
        ringtone?.stop()
        ringtone = null
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
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun updateCallNotification(call: Call) {
        if (call.state == Call.STATE_ACTIVE) {
            stopRingtone()
            stopVibration()
            showOngoingCallNotification(call)
        } else if (call.state == Call.STATE_DISCONNECTED) {
            cancelNotification()
        }
    }

    private fun isScreenLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return keyguardManager.isKeyguardLocked || !powerManager.isInteractive
    }

    private fun getContactPhoto(number: String): Bitmap? {
        val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
        val projection = arrayOf(ContactsContract.PhoneLookup.PHOTO_URI)
        var photoBitmap: Bitmap? = null
        
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val photoUri = cursor.getString(0)
                if (photoUri != null) {
                    try {
                        val inputStream = contentResolver.openInputStream(Uri.parse(photoUri))
                        photoBitmap = BitmapFactory.decodeStream(inputStream)
                    } catch (e: Exception) {
                        android.util.Log.e("FlutterPhone", "Error loading contact photo: ${e.message}")
                    }
                }
            }
        }
        return photoBitmap
    }

    private fun showIncomingCallNotification(call: Call) {
        val details = call.details
        val handle = details?.handle
        val number = handle?.schemeSpecificPart ?: "Unknown"
        val callerName = details?.callerDisplayName ?: number
        val contactPhoto = getContactPhoto(number)

        // Screen is locked? System handles full screen intent automatically if provided
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("incoming_call", true)
            putExtra("caller_number", number)
            putExtra("caller_name", callerName)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val answerIntent = Intent(this, CallActionReceiver::class.java).apply { action = "ANSWER_CALL" }
        val answerPendingIntent = PendingIntent.getBroadcast(this, 1, answerIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val declineIntent = Intent(this, CallActionReceiver::class.java).apply { action = "DECLINE_CALL" }
        val declinePendingIntent = PendingIntent.getBroadcast(this, 2, declineIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        // One UI 7 Style: Minimalist Pill-like notification
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle(callerName)
            .setContentText("Incoming call")
            .setLargeIcon(contactPhoto)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .addPerson("tel:$number")
            .setFullScreenIntent(pendingIntent, true) 
            .setColor(0xFF000000.toInt())
            .addAction(NotificationCompat.Action.Builder(0, "Answer", answerPendingIntent).build())
            .addAction(NotificationCompat.Action.Builder(0, "Decline", declinePendingIntent).build())

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        }

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun showOngoingCallNotification(call: Call) {
        val details = call.details
        val number = details?.handle?.schemeSpecificPart ?: "Unknown"
        val callerName = details?.callerDisplayName ?: number
        val contactPhoto = getContactPhoto(number)

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val hangupIntent = Intent(this, CallActionReceiver::class.java).apply { action = "DECLINE_CALL" }
        val hangupPendingIntent = PendingIntent.getBroadcast(this, 3, hangupIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle(callerName)
            .setContentText("Ongoing call")
            .setLargeIcon(contactPhoto)
            .setPriority(NotificationCompat.PRIORITY_LOW) // Ongoing calls shouldn't pop up
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setUsesChronometer(true)
            .setColor(0xFF4CAF50.toInt()) // Green for active call
            .setContentIntent(pendingIntent)
            .addAction(NotificationCompat.Action.Builder(0, "End Call", hangupPendingIntent).build())

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun cancelNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.cancel(NOTIFICATION_ID)
    }
}
