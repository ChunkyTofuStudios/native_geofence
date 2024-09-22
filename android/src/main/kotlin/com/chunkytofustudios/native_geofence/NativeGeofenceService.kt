package com.chunkytofustudios.native_geofence

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.util.Log
import androidx.core.app.JobIntentService
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.view.FlutterCallbackInformation
import java.util.ArrayDeque
import java.util.concurrent.atomic.AtomicBoolean
import java.util.UUID

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback

import com.google.android.gms.location.GeofencingEvent
import io.flutter.embedding.engine.loader.FlutterLoader

class NativeGeofenceService : MethodCallHandler, JobIntentService() {
    private val queue = ArrayDeque<List<Any>>()
    private lateinit var mBackgroundChannel: MethodChannel
    private lateinit var mContext: Context

    companion object {
        @JvmStatic
        private val TAG = "NativeGeofenceService"

        @JvmStatic
        private val JOB_ID = UUID.randomUUID().mostSignificantBits.toInt()

        @JvmStatic
        private var sBackgroundFlutterEngine: FlutterEngine? = null

        @JvmStatic
        private val sServiceStarted = AtomicBoolean(false)

        @JvmStatic
        fun enqueueWork(context: Context, work: Intent) {
            enqueueWork(context, NativeGeofenceService::class.java, JOB_ID, work)
        }
    }

    private fun startNativeGeofenceService(context: Context) {
        synchronized(sServiceStarted) {
            mContext = context
            if (sBackgroundFlutterEngine == null) {
                sBackgroundFlutterEngine = FlutterEngine(context)

                val callbackHandle = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                    .getLong(Constants.CALLBACK_DISPATCHER_HANDLE_KEY, 0)
                if (callbackHandle == 0L) {
                    Log.e(TAG, "Fatal: no callback registered")
                    return
                }

                val callbackInfo =
                    FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
                if (callbackInfo == null) {
                    Log.e(TAG, "Fatal: failed to find callback")
                    return
                }
                Log.i(TAG, "Starting NativeGeofenceService...")

                val args = DartCallback(
                    context.assets,
                    FlutterLoader().findAppBundlePath(),
                    callbackInfo
                )
                sBackgroundFlutterEngine!!.dartExecutor.executeDartCallback(args)
                IsolateHolderService.setBackgroundFlutterEngine(sBackgroundFlutterEngine)
            }
        }
        mBackgroundChannel = MethodChannel(
            sBackgroundFlutterEngine!!.dartExecutor.binaryMessenger,
            "native_geofence.chunkytofustudios.com/native_geofence_plugin_background"
        )
        mBackgroundChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "NativeGeofenceService.initialized" -> {
                synchronized(sServiceStarted) {
                    while (!queue.isEmpty()) {
                        mBackgroundChannel.invokeMethod("", queue.remove())
                    }
                    sServiceStarted.set(true)
                }
            }

            "NativeGeofenceService.promoteToForeground" -> {
                mContext.startForegroundService(Intent(mContext, IsolateHolderService::class.java))
            }

            "NativeGeofenceService.demoteToBackground" -> {
                val intent = Intent(mContext, IsolateHolderService::class.java)
                intent.setAction(Constants.ACTION_SHUTDOWN)
                mContext.startForegroundService(intent)
            }

            else -> result.notImplemented()
        }
        result.success(null)
    }

    override fun onCreate() {
        super.onCreate()
        startNativeGeofenceService(this)
    }

    override fun onHandleWork(intent: Intent) {
        val callbackHandle = intent.getLongExtra(Constants.CALLBACK_HANDLE_KEY, 0)
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent == null) {
            Log.e(TAG, "GeofencingEvent was null.")
            return
        }
        if (geofencingEvent.hasError()) {
            Log.e(TAG, "Geofencing error: ${geofencingEvent.errorCode}")
            return
        }

        // Get the transition type.
        val geofenceTransition = geofencingEvent.geofenceTransition

        // Get the geofences that were triggered. A single event can trigger
        // multiple geofences.
        val triggeringGeofences = geofencingEvent.triggeringGeofences?.map {
            it.requestId
        }
        if (triggeringGeofences == null) {
            Log.e(TAG, "No triggering geofences found.")
            return
        }

        val location = geofencingEvent.triggeringLocation
        if (location == null) {
            Log.e(TAG, "No triggering location found.")
            return
        }

        val locationList = listOf(
            location.latitude,
            location.longitude
        )
        val geofenceUpdateList = listOf(
            callbackHandle,
            triggeringGeofences,
            locationList,
            geofenceTransition
        )

        synchronized(sServiceStarted) {
            if (!sServiceStarted.get()) {
                // Queue up geofencing events while background isolate is starting
                queue.add(geofenceUpdateList)
            } else {
                // Callback method name is intentionally left blank.
                Handler(mContext.mainLooper).post {
                    mBackgroundChannel.invokeMethod(
                        "",
                        geofenceUpdateList
                    )
                }
            }
        }
    }
}
