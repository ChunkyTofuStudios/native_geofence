package com.chunkytofustudios.native_geofence

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlin.time.Duration.Companion.minutes

// TODO: Allow customizing notification details.
class NativeGeofenceForegroundService : Service() {
    companion object {
        @JvmStatic
        private val TAG = "NativeGeofenceForegroundService"

        // TODO: Consider using random ID.
        private const val NOTIFICATION_ID = 938130

        private val WAKE_LOCK_TIMEOUT = 5.minutes
    }

    override fun onBind(p0: Intent): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        val channelId = "native_geofence_plugin_channel"
        val channel = NotificationChannel(
            channelId,
            "Geofence Events",
            // This has to be at least IMPORTANCE_LOW.
            // Source: https://developer.android.com/develop/background-work/services/foreground-services#start
            NotificationManager.IMPORTANCE_LOW
        )

        @SuppressLint("DiscouragedApi") // Can't use R syntax in Flutter plugin.
        val imageId = resources.getIdentifier("ic_launcher", "mipmap", packageName)

        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(
            channel
        )
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Processing geofence event.")
            .setContentText("We noticed you are near a key location and are checking if we can help.")
            .setSmallIcon(imageId)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.ISOLATE_HOLDER_WAKE_LOCK_TAG).apply {
                setReferenceCounted(false)
                acquire(WAKE_LOCK_TIMEOUT.inWholeMilliseconds)
            }
        }
        startForeground(NOTIFICATION_ID, notification)

        Log.d(TAG, "Foreground service started with notification ID=$NOTIFICATION_ID.")
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        if (intent.action == Constants.ACTION_SHUTDOWN) {
            (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
                newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.ISOLATE_HOLDER_WAKE_LOCK_TAG).apply {
                    if (isHeld) {
                        release()
                    }
                }
            }
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            Log.d(TAG, "Foreground service stopped.")
        }
        return START_STICKY
    }
}
