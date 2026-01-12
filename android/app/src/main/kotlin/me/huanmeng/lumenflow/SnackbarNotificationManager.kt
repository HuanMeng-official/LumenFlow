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
        INITIALIZING(2000, 0),
        PROCESSING(5000, 25),
        TRANSFERRING(8000, 50),
        NEARLY_DONE(11000, 75),
        COMPLETED(14000, 100);

        @RequiresApi(Build.VERSION_CODES.BAKLAVA)
        fun buildNotification(): NotificationCompat.Builder {
            return buildBaseNotification(appContext, this)
        }
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    private fun buildBaseNotification(context: Context, state: UpdateState): NotificationCompat.Builder {
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
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
                        buildProgressStyle(state).setProgress(state.progress)
                    )
            }
            UpdateState.TRANSFERRING -> {
                builder.setContentTitle("$customTitle: 传输中")
                    .setContentText("正在同步数据...")
                    .setStyle(
                        buildProgressStyle(state)
                            .setProgressTrackerIcon(
                                IconCompat.createWithResource(
                                    context,
                                    android.R.drawable.ic_menu_upload
                                )
                            )
                            .setProgress(state.progress)
                    )
                    .setWhen(System.currentTimeMillis().plus(5 * 60 * 1000))
                    .setUsesChronometer(true)
                    .setChronometerCountDown(true)
            }
            UpdateState.NEARLY_DONE -> {
                builder.setContentTitle("$customTitle: 即将完成")
                    .setContentText("正在完成最后的步骤...")
                    .setStyle(
                        buildProgressStyle(state)
                            .setProgressTrackerIcon(
                                IconCompat.createWithResource(
                                    context,
                                    android.R.drawable.ic_menu_view
                                )
                            )
                            .setProgress(state.progress)
                    )
                    .setWhen(System.currentTimeMillis().plus(2 * 60 * 1000))
                    .setUsesChronometer(true)
                    .setChronometerCountDown(true)
            }
            UpdateState.COMPLETED -> {
                builder.setContentTitle("$customTitle: 已完成")
                    .setContentText("所有操作已成功完成！")
                    .setStyle(
                        buildProgressStyle(state)
                            .setProgressTrackerIcon(
                                IconCompat.createWithResource(
                                    context,
                                    android.R.drawable.checkbox_on_background
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

        val points = mutableListOf<ProgressStyle.Point>()
        for (i in 25..100 step 25) {
            points.add(ProgressStyle.Point(i).setColor(pointColor))
        }

        val segments = mutableListOf<ProgressStyle.Segment>()
        repeat(4) {
            segments.add(ProgressStyle.Segment(25).setColor(segmentColor))
        }

        val completedPoints = when (state) {
            UpdateState.INITIALIZING -> emptyList()
            UpdateState.PROCESSING -> emptyList()
            UpdateState.TRANSFERRING -> listOf(ProgressStyle.Point(25).setColor(pointColor))
            UpdateState.NEARLY_DONE -> listOf(
                ProgressStyle.Point(25).setColor(pointColor),
                ProgressStyle.Point(50).setColor(pointColor)
            )
            UpdateState.COMPLETED -> listOf(
                ProgressStyle.Point(25).setColor(pointColor),
                ProgressStyle.Point(50).setColor(pointColor),
                ProgressStyle.Point(75).setColor(pointColor)
            )
        }

        return NotificationCompat.ProgressStyle()
            .setProgressPoints(if (completedPoints.isEmpty()) points else completedPoints)
            .setProgressSegments(segments)
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
