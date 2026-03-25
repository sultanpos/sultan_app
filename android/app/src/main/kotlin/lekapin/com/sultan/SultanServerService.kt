package lekapin.com.sultan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import com.sultan.android.SultanServer

class SultanServerService : Service() {

    companion object {
        const val TAG = "SultanServerService"
        const val CHANNEL_ID = "sultan_server_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val EXTRA_JWT_SECRET = "jwt_secret"
        const val EXTRA_PORT = "port"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopServer()
                return START_NOT_STICKY
            }
            ACTION_START, null -> {
                val jwtSecret = intent?.getStringExtra(EXTRA_JWT_SECRET) ?: "sultan-secret-key"
                val port = intent?.getIntExtra(EXTRA_PORT, 8721) ?: 8721
                startServer(jwtSecret, port)
            }
        }
        return START_STICKY
    }

    private fun startServer(jwtSecret: String, port: Int) {
        if (SultanServer.isRunning()) {
            Log.i(TAG, "Server already running")
            return
        }

        val dbPath = getDatabasePath("sultan.db").absolutePath
        getDatabasePath("sultan.db").parentFile?.mkdirs()

        val notification = buildNotification(port)
        startForeground(NOTIFICATION_ID, notification)

        val started = SultanServer.start(dbPath, jwtSecret, port)
        if (started) {
            Log.i(TAG, "Server started on port $port")
        } else {
            Log.e(TAG, "Failed to start server")
            stopSelf()
        }
    }

    private fun stopServer() {
        if (SultanServer.isRunning()) {
            SultanServer.stop()
            Log.i(TAG, "Server stopped")
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification(port: Int): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, SultanServerService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Sultan Server")
            .setContentText("Running on port $port")
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .addAction(
                Notification.Action.Builder(
                    null, "Stop", stopPendingIntent
                ).build()
            )
            .build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Sultan Server",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Sultan backend server status"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopServer()
        super.onDestroy()
    }
}
