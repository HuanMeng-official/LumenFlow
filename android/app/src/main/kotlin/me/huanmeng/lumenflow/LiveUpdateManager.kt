package me.huanmeng.lumenflow

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LiveUpdateManager : MethodCallHandler {
    private var context: Context? = null

    companion object {
        const val CHANNEL = "me.huanmeng.lumenflow/live_update"
    }

    fun initialize(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        val channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startLiveUpdate" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
                    startLiveUpdate(call.argument<String>("title") ?: "Live Update")
                    result.success(true)
                } else {
                    result.error("UNSUPPORTED_SDK", "Live Update requires Android 16 (BAKLAVA)", null)
                }
            }
            "isLiveUpdateAvailable" -> {
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA)
            }
            "stopLiveUpdate" -> {
                stopLiveUpdate()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    private fun startLiveUpdate(title: String) {
        val notificationManager = context?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.let {
            SnackbarNotificationManager.initialize(context!!, it)
            SnackbarNotificationManager.setTitle(title)
            SnackbarNotificationManager.start()
        }
    }

    private fun stopLiveUpdate() {
        val notificationManager = context?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(SnackbarNotificationManager.NOTIFICATION_ID)
    }
}
