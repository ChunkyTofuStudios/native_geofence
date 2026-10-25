package com.chunkytofustudios.native_geofence

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import com.chunkytofustudios.native_geofence.util.Notifications
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

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(p0: Intent): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        val notification = Notifications.createForegroundServiceNotification(this)

        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, Constants.ISOLATE_HOLDER_WAKE_LOCK_TAG).apply {
                setReferenceCounted(false)
                acquire(WAKE_LOCK_TIMEOUT.inWholeMilliseconds)
            }
        }
        startForeground(NOTIFICATION_ID, notification)

        Log.d(TAG, "Foreground service started with notification ID=$NOTIFICATION_ID.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == Constants.ACTION_SHUTDOWN) {
            releaseWakeLock()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            Log.d(TAG, "Foreground service stopped.")
        }
        // The geofence callback that promoted this service does not survive its process being
        // killed, so there is nothing for a restarted service to do.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }
}
