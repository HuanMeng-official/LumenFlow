package me.huanmeng.lumenflow

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding

class LiveUpdatePlugin : FlutterPlugin {
    private var liveUpdateManager: LiveUpdateManager? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        liveUpdateManager = LiveUpdateManager()
        liveUpdateManager?.initialize(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        liveUpdateManager = null
    }
}
