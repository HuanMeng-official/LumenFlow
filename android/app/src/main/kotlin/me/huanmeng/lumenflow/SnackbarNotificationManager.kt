package me.huanmeng.lumenflow

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat.ProgressStyle
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.graphics.drawable.IconCompat
import me.huanmeng.lumenflow.R
import java.util.concurrent.atomic.AtomicBoolean

object SnackbarNotificationManager {
    private lateinit var notificationManager: NotificationManager
    private lateinit var appContext: Context
    var customTitle: String = "LumenFlow"

    const val CHANNEL_ID = "live_updates_channel_id"
    private const val CHANNEL_NAME = "LumenFlow Live Updates"
    const val NOTIFICATION_ID = 9999

    private var isRunning = AtomicBoolean(false)
    private var currentProgress = 0
    private val handler = Handler(Looper.getMainLooper())
    private var lastUpdateContent = ""

    @RequiresApi(Build.VERSION_CODES.O)
    fun initialize(context: Context, notifManager: NotificationManager) {
        notificationManager = notifManager
        appContext = context
        val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT)
        notificationManager.createNotificationChannel(channel)
    }

    fun setTitle(title: String) {
        customTitle = title
    }

    private fun buildProgressStyle(progress: Int, isIndeterminate: Boolean): ProgressStyle {
        val pointColor = Color.valueOf(100f / 255f, 181f / 255f, 246f / 255f, 1f).toArgb()
        val segmentColor = Color.valueOf(129f / 255f, 212f / 255f, 250f / 255f, 1f).toArgb()

        if (progress >= 100) {
            val points = mutableListOf<ProgressStyle.Point>()
            for (i in 25..100 step 25) {
                points.add(ProgressStyle.Point(i).setColor(pointColor))
            }
            val segments = mutableListOf<ProgressStyle.Segment>()
            repeat(4) {
                segments.add(ProgressStyle.Segment(25).setColor(segmentColor))
            }
            return NotificationCompat.ProgressStyle()
                .setProgressTrackerIcon(
                    IconCompat.createWithResource(appContext, R.mipmap.ic_launcher)
                )
                .setProgressPoints(points)
                .setProgressSegments(segments)
                .setProgress(100)
        } else if (isIndeterminate) {
            return NotificationCompat.ProgressStyle()
                .setProgressTrackerIcon(
                    IconCompat.createWithResource(appContext, R.mipmap.ic_launcher)
                )
                .setProgressIndeterminate(true)
        } else {
            return NotificationCompat.ProgressStyle()
                .setProgressTrackerIcon(
                    IconCompat.createWithResource(appContext, R.mipmap.ic_launcher)
                )
                .setProgress(progress.coerceIn(0, 99))
        }
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun start() {
        isRunning.set(true)
        currentProgress = 0
        lastUpdateContent = ""

        val builder = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setRequestPromotedOngoing(true)
            .setContentTitle(customTitle)
            .setContentText("正在思考...")
            .setStyle(buildProgressStyle(0, true))

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun updateContent(content: String) {
        if (!isRunning.get()) return

        // 显示内容预览（最多80字符）
        val previewContent = if (content.length > 80) {
            "${content.substring(0, 80)}..."
        } else {
            content
        }.ifEmpty { "正在思考..." }

        lastUpdateContent = previewContent

        // 基于内容长度估算进度（简单启发式）
        val estimatedProgress = if (content.isNotEmpty()) {
            minOf(95, 10 + (content.length / 20))
        } else {
            0
        }

        val builder = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setRequestPromotedOngoing(true)
            .setContentTitle(customTitle)
            .setContentText(previewContent)
            .setStyle(buildProgressStyle(estimatedProgress, estimatedProgress <= 0))

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun complete() {
        isRunning.set(false)

        val builder = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("$customTitle: 已完成")
            .setContentText("响应已完成")
            .setStyle(buildProgressStyle(100, false))
            .setOngoing(false)
            .setAutoCancel(true)

        notificationManager.notify(NOTIFICATION_ID, builder.build())

        // 3秒后自动取消
        handler.postDelayed({
            notificationManager.cancel(NOTIFICATION_ID)
        }, 3000)
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun cancel() {
        isRunning.set(false)
        notificationManager.cancel(NOTIFICATION_ID)
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun isRunning(): Boolean {
        return isRunning.get()
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun isPostPromotionsEnabled(): Boolean {
        return notificationManager.canPostPromotedNotifications()
    }
}
