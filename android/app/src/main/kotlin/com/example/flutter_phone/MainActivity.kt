package com.example.flutter_phone

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.telecom.TelecomManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.net.Uri
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private val DIALER_CHANNEL = "com.example.flutter_phone/dialer"
    private val CALL_CHANNEL = "com.example.flutter_phone/calls"
    private val CALL_EVENTS = "com.example.flutter_phone/call_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Dialer channel for default dialer operations
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIALER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkDefaultDialer" -> {
                    val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    val isDefault = telecomManager.defaultDialerPackage == packageName
                    result.success(isDefault)
                }
                "requestDefaultDialer" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                        intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Call control channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "answerCall" -> {
                    CallManager.answerCall()
                    result.success(true)
                }
                "rejectCall" -> {
                    CallManager.rejectCall()
                    result.success(true)
                }
                "endCall" -> {
                    CallManager.endCall()
                    result.success(true)
                }
                "makeCall" -> {
                    val number = call.argument<String>("number")
                    if (number != null) {
                        makePhoneCall(number)
                        result.success(true)
                    } else {
                        result.error("INVALID_NUMBER", "Phone number is required", null)
                    }
                }
                "sendDtmf" -> {
                    val digit = call.argument<String>("digit")
                    if (digit != null && digit.isNotEmpty()) {
                        CallManager.sendDtmf(digit[0])
                        result.success(true)
                    } else {
                        result.error("INVALID_DIGIT", "DTMF digit is required", null)
                    }
                }
                "hasActiveCall" -> {
                    result.success(CallManager.getCurrentCall() != null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Call events stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    CallManager.setEventSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    CallManager.setEventSink(null)
                }
            }
        )
    }

    private fun makePhoneCall(number: String) {
        android.util.Log.d("FlutterPhone", "makePhoneCall called with: $number")
        
        // Check permission
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) 
            != PackageManager.PERMISSION_GRANTED) {
            android.util.Log.w("FlutterPhone", "CALL_PHONE permission not granted, requesting...")
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), 1)
            return
        }
        
        try {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val isDefaultDialer = telecomManager.defaultDialerPackage == packageName
            android.util.Log.d("FlutterPhone", "Is default dialer: $isDefaultDialer")
            
            if (isDefaultDialer) {
                // Use TelecomManager.placeCall when we're the default dialer
                val uri = Uri.fromParts("tel", number, null)
                val extras = Bundle()
                android.util.Log.d("FlutterPhone", "Placing call via TelecomManager: $uri")
                telecomManager.placeCall(uri, extras)
            } else {
                // Use ACTION_CALL intent
                android.util.Log.d("FlutterPhone", "Placing call via ACTION_CALL intent")
                val intent = Intent(Intent.ACTION_CALL).apply {
                    data = Uri.parse("tel:$number")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            }
        } catch (e: SecurityException) {
            android.util.Log.e("FlutterPhone", "SecurityException: ${e.message}")
            e.printStackTrace()
            // Fallback to dial intent if no permission
            val intent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$number")
            }
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("FlutterPhone", "Exception making call: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupLockScreenFlags()
        handleIncomingCallIntent(intent)
    }

    private fun setupLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingCallIntent(intent)
    }

    private fun handleIncomingCallIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("incoming_call", false) == true) {
            val number = intent.getStringExtra("caller_number") ?: "Unknown"
            val name = intent.getStringExtra("caller_name") ?: ""
            
            // Send to Flutter via method channel
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CALL_CHANNEL).invokeMethod(
                    "incomingCall",
                    mapOf("number" to number, "name" to name)
                )
            }
        }
    }
}
