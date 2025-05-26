package com.example.callsms

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import android.telephony.SmsManager
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.callsms/call"
    private val SMS_CHANNEL = "com.example.callsms/sms"
    private var callEndedResult: MethodChannel.Result? = null
    private var callStateChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "directCall") {
                val phoneNumber = call.argument<String>("phone")
                if (phoneNumber != null) {
                    makeDirectCall(phoneNumber)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val phoneNumber = call.argument<String>("phone")
                val message = call.argument<String>("message")
                if (phoneNumber != null && message != null) {
                    val sent = sendSms(phoneNumber, message)
                    if (sent) {
                        result.success(null)
                    } else {
                        result.error("FAILED", "Failed to send SMS", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number or message is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        callStateChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.callsms/callstate")
    }

    private fun makeDirectCall(phoneNumber: String) {
        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$phoneNumber")
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
            startActivity(intent)
            listenForCallEnd()
        }
    }

    private fun listenForCallEnd() {
        val telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        telephonyManager.listen(object : PhoneStateListener() {
            var wasRingingOrOffhook = false
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                if (state == TelephonyManager.CALL_STATE_OFFHOOK || state == TelephonyManager.CALL_STATE_RINGING) {
                    wasRingingOrOffhook = true
                }
                if (wasRingingOrOffhook && state == TelephonyManager.CALL_STATE_IDLE) {
                    // Call ended
                    callStateChannel?.invokeMethod("callEnded", null)
                    telephonyManager.listen(this, PhoneStateListener.LISTEN_NONE)
                }
            }
        }, PhoneStateListener.LISTEN_CALL_STATE)
    }

    private fun sendSms(phoneNumber: String, message: String): Boolean {
        return try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            true
        } catch (e: Exception) {
            false
        }
    }
}
