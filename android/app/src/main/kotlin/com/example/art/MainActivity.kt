package com.example.art

import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required for
// purchases_ui_flutter's paywalls, which present as a native Android
// fragment.
class MainActivity : FlutterFragmentActivity() {
    private val methodChannelName = "art/system_media"
    private val eventChannelName = "art/system_media/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessGranted" -> result.success(isNotificationAccessGranted())
                "openNotificationAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "getCurrentMedia" -> result.success(MediaBridge.currentSnapshot())
                "play" -> {
                    MediaBridge.play()
                    result.success(null)
                }
                "pause" -> {
                    MediaBridge.pause()
                    result.success(null)
                }
                "skipNext" -> {
                    MediaBridge.skipNext()
                    result.success(null)
                }
                "skipPrevious" -> {
                    MediaBridge.skipPrevious()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    MediaBridge.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    MediaBridge.eventSink = null
                }
            },
        )
    }

    private fun isNotificationAccessGranted(): Boolean {
        val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(this)
        return enabledPackages.contains(packageName)
    }
}
