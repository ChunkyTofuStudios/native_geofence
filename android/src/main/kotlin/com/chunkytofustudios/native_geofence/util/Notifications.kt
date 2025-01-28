package com.chunkytofustudios.native_geofence.util

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat

class Notifications {
    companion object {
        fun createBackgroundWorkerNotification(context: Context): Notification {
            // Background Worker notification is only needed for Android 30 and below (30% of users
            // as of Jan 2025), so we are re-using the Foreground Service notification.
            return createForegroundServiceNotification(context)
        }

        // TODO: Make notification details customizable by plugin user.
        fun createForegroundServiceNotification(context: Context): Notification {
            val channelId = "native_geofence_plugin_channel"
            val channel = NotificationChannel(
                channelId,
                "Geofence Events",
                // This has to be at least IMPORTANCE_LOW.
                // Source: https://developer.android.com/develop/background-work/services/foreground-services#start
                NotificationManager.IMPORTANCE_LOW
            )

            @SuppressLint("DiscouragedApi") // Can't use R syntax in Flutter plugin.
            val imageId = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)

            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(
                channel
            )
            return NotificationCompat.Builder(context, channelId)
                .setContentTitle("Processing geofence event.")
                .setContentText("We noticed you are near a key location and are checking if we can help.")
                .setSmallIcon(imageId)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        }
    }
}
