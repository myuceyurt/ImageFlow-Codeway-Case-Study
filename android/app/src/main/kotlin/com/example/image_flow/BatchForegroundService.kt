package com.example.image_flow

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BatchForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "batch_processing"
        private const val CHANNEL_NAME = "Batch Processing"
        private const val ACTION_START = "action_start"
        private const val ACTION_UPDATE = "action_update"
        private const val ACTION_STOP = "action_stop"

        private const val EXTRA_TOTAL = "extra_total"
        private const val EXTRA_COMPLETED = "extra_completed"

        fun start(context: Context, total: Int, completed: Int) {
            val intent = Intent(context, BatchForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TOTAL, total)
                putExtra(EXTRA_COMPLETED, completed)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun update(context: Context, total: Int, completed: Int) {
            val intent = Intent(context, BatchForegroundService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_TOTAL, total)
                putExtra(EXTRA_COMPLETED, completed)
            }
            context.startService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, BatchForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    private var isForeground = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(true)
                stopSelf()
                isForeground = false
                return START_NOT_STICKY
            }
            ACTION_START, ACTION_UPDATE -> {
                val total = intent.getIntExtra(EXTRA_TOTAL, 0)
                val completed = intent.getIntExtra(EXTRA_COMPLETED, 0)
                val notification = buildNotification(total, completed)
                if (!isForeground) {
                    startForeground(1, notification)
                    isForeground = true
                } else {
                    val manager =
                        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.notify(1, notification)
                }
            }
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(total: Int, completed: Int): Notification {
        val progressText = "Processing $completed of $total"
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ImageFlow")
            .setContentText(progressText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setProgress(total, completed, total == 0)
            .build()
    }
}
