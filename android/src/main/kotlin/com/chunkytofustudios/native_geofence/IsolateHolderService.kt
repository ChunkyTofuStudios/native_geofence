package com.chunkytofustudios.native_geofence

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import kotlin.time.Duration.Companion.minutes

class IsolateHolderService : Service() {
    companion object {
        @JvmStatic
        private val WAKELOCK_TAG = "IsolateHolderService::WAKE_LOCK"

        @JvmStatic
        private var sBackgroundFlutterEngine: FlutterEngine? = null

        @JvmStatic
        fun setBackgroundFlutterEngine(engine: FlutterEngine?) {
            sBackgroundFlutterEngine = engine
        }
    }

    override fun onBind(p0: Intent): IBinder? {
        return null
    }


    override fun onCreate() {
        super.onCreate()
        val channelId = "native_geofence_plugin_channel"
        val channel = NotificationChannel(
            channelId,
            "Flutter Native Geofence Plugin",
            NotificationManager.IMPORTANCE_LOW
        )

        @SuppressLint("DiscouragedApi") // Can't use R syntax in Flutter plugin.
        val imageId = resources.getIdentifier("ic_launcher", "mipmap", packageName)

        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(
            channel
        )
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Almost home!")
            .setContentText("Within 1KM of home. Fine location tracking enabled.")
            .setSmallIcon(imageId)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                setReferenceCounted(false)
                acquire(5.minutes.inWholeMilliseconds)
            }
        }
        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        if (intent.action == Constants.ACTION_SHUTDOWN) {
            (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
                newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                    if (isHeld) {
                        release()
                    }
                }
            }
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
        return START_STICKY
    }
}
