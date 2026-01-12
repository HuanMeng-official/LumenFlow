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

object SnackbarNotificationManager {
    private lateinit var notificationManager: NotificationManager
    private lateinit var appContext: Context
    var customTitle: String = "LumenFlow"

    const val CHANNEL_ID = "live_updates_channel_id"
    private const val CHANNEL_NAME = "LumenFlow Live Updates"
    const val NOTIFICATION_ID = 9999

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

    private enum class UpdateState(val delay: Long, val progress: Int) {
        INITIALIZING(1000, 0),
        PROCESSING(2000, 0),
        COMPLETED(4000, 100);

        @RequiresApi(Build.VERSION_CODES.BAKLAVA)
        fun buildNotification(): NotificationCompat.Builder {
            return buildBaseNotification(appContext, this)
        }
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    private fun buildBaseNotification(context: Context, state: UpdateState): NotificationCompat.Builder {
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setRequestPromotedOngoing(true)

        when (state) {
            UpdateState.INITIALIZING -> {
                builder.setContentTitle("$customTitle: 初始化")
                    .setContentText("正在准备...")
                    .setStyle(
                        buildProgressStyle(state).setProgressIndeterminate(true)
                    )
            }
            UpdateState.PROCESSING -> {
                builder.setContentTitle("$customTitle: 处理中")
                    .setContentText("正在处理数据...")
                    .setStyle(
                        buildProgressStyle(state)
                            .setProgressTrackerIcon(
                                IconCompat.createWithResource(
                                    context,
                                    R.mipmap.ic_launcher
                                )
                            )
                            .setProgressIndeterminate(true)
                    )
            }
            UpdateState.COMPLETED -> {
                builder.setContentTitle("$customTitle: 已完成")
                    .setContentText("所有操作已成功完成！")
                    .setStyle(
                        buildProgressStyle(state)
                            .setProgressTrackerIcon(
                                IconCompat.createWithResource(
                                    context,
                                    R.mipmap.ic_launcher
                                )
                            )
                            .setProgress(100)
                    )
                    .setOngoing(false)
                    .setAutoCancel(true)
            }
        }

        return builder
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    private fun buildProgressStyle(state: UpdateState): ProgressStyle {
        val pointColor = Color.valueOf(100f / 255f, 181f / 255f, 246f / 255f, 1f).toArgb()
        val segmentColor = Color.valueOf(129f / 255f, 212f / 255f, 250f / 255f, 1f).toArgb()

        return when (state) {
            UpdateState.COMPLETED -> {
                val points = mutableListOf<ProgressStyle.Point>()
                for (i in 25..100 step 25) {
                    points.add(ProgressStyle.Point(i).setColor(pointColor))
                }
                val segments = mutableListOf<ProgressStyle.Segment>()
                repeat(4) {
                    segments.add(ProgressStyle.Segment(25).setColor(segmentColor))
                }
                NotificationCompat.ProgressStyle()
                    .setProgressPoints(points)
                    .setProgressSegments(segments)
            }
            else -> {
                NotificationCompat.ProgressStyle()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun start() {
        for (state in UpdateState.entries) {
            val notification = state.buildNotification().build()

            Handler(Looper.getMainLooper()).postDelayed({
                notificationManager.notify(NOTIFICATION_ID, notification)
            }, state.delay)
        }
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    fun isPostPromotionsEnabled(): Boolean {
        return notificationManager.canPostPromotedNotifications()
    }
}
