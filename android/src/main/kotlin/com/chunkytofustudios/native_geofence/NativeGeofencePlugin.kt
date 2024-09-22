package com.chunkytofustudios.native_geofence

import android.annotation.SuppressLint
import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import org.json.JSONArray

class NativeGeofencePlugin : ActivityAware, FlutterPlugin, MethodCallHandler {
    private var mContext: Context? = null
    private var mActivity: Activity? = null
    private var mGeofencingClient: GeofencingClient? = null

    companion object {
        @JvmStatic
        private val TAG = "NativeGeofencePlugin"

        @JvmStatic
        private val sGeofenceCacheLock = Object()

        @JvmStatic
        fun reRegisterAfterReboot(context: Context) {
            synchronized(sGeofenceCacheLock) {
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                val persistentGeofences =
                    p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS, null) ?: return

                for (id in persistentGeofences) {
                    val gfJson = p.getString(getPersistentGeofenceKey(id), null) ?: continue
                    val gfArgs = JSONArray(gfJson)
                    val list = ArrayList<Any>()
                    for (i in 0 until gfArgs.length()) {
                        list.add(gfArgs.get(i) as Any)
                    }
                    val geoClient = LocationServices.getGeofencingClient(context)
                    registerGeofence(context, geoClient, list, null, false)
                }
            }
        }

        @SuppressLint("MissingPermission")
        @JvmStatic
        private fun registerGeofence(
            context: Context,
            geofencingClient: GeofencingClient,
            args: ArrayList<*>?,
            result: Result?,
            cache: Boolean
        ) {
            val callbackHandle = args!![0] as Long
            val id = args[1] as String
            val lat = args[2] as Double
            val long = args[3] as Double
            val radius = (args[4] as Number).toFloat()
            val fenceTriggers = args[5] as Int
            val initialTriggers = args[6] as Int
            val expirationDuration = (args[7].toIntOrNull())?.toLong()
            val loiteringDelay = args[8] as Int
            val notificationResponsiveness = args[9] as Int?
            val geofenceBuilder = Geofence.Builder()
                .setRequestId(id)
                .setCircularRegion(lat, long, radius)
                .setTransitionTypes(fenceTriggers)
                .setLoiteringDelay(loiteringDelay)
            if (expirationDuration != null) {
                geofenceBuilder.setExpirationDuration(expirationDuration)
            }
            if (notificationResponsiveness != null) {
                geofenceBuilder.setNotificationResponsiveness(notificationResponsiveness)
            }
            geofencingClient.addGeofences(
                getGeofencingRequest(geofenceBuilder.build(), initialTriggers),
                getGeofencePendingIndent(context, callbackHandle)
            ).run {
                addOnSuccessListener {
                    Log.i(TAG, "Successfully added geofence")
                    if (cache) {
                        addGeofenceToCache(context, id, args)
                    }
                    result?.success(true)
                }
                addOnFailureListener {
                    Log.e(TAG, "Failed to add geofence: $it")
                    result?.error(it.toString(), null, null)
                }
            }
        }

        @JvmStatic
        private fun addGeofenceToCache(context: Context, id: String, args: ArrayList<*>) {
            synchronized(sGeofenceCacheLock) {
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                val obj = JSONArray(args)
                var persistentGeofences = p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS, null)
                persistentGeofences = if (persistentGeofences == null) {
                    HashSet<String>()
                } else {
                    HashSet<String>(persistentGeofences)
                }
                persistentGeofences.add(id)
                context.getSharedPreferences(Constants.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                    .edit()
                    .putStringSet(Constants.PERSISTENT_GEOFENCES_IDS, persistentGeofences)
                    .putString(getPersistentGeofenceKey(id), obj.toString())
                    .apply()
            }
        }


        @JvmStatic
        private fun initializeService(context: Context, args: ArrayList<*>?) {
            Log.d(TAG, "Initializing NativeGeofenceService")
            val callbackHandle = args!![0] as Long
            context.getSharedPreferences(Constants.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                .edit()
                .putLong(Constants.CALLBACK_DISPATCHER_HANDLE_KEY, callbackHandle)
                .apply()
        }

        @JvmStatic
        private fun getGeofencingRequest(
            geofence: Geofence,
            initialTrigger: Int
        ): GeofencingRequest {
            return GeofencingRequest.Builder().apply {
                setInitialTrigger(initialTrigger)
                addGeofence(geofence)
            }.build()
        }

        @JvmStatic
        private fun getGeofencePendingIndent(
            context: Context,
            callbackHandle: Long
        ): PendingIntent {
            val intent = Intent(context, NativeGeofenceBroadcastReceiver::class.java)
                .putExtra(Constants.CALLBACK_HANDLE_KEY, callbackHandle)
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.getBroadcast(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )
            } else {
                PendingIntent.getBroadcast(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }
        }

        @JvmStatic
        private fun removeGeofence(
            context: Context,
            geofencingClient: GeofencingClient,
            args: ArrayList<*>?,
            result: Result
        ) {
            val ids = listOf(args!![0] as String)
            geofencingClient.removeGeofences(ids).run {
                addOnSuccessListener {
                    for (id in ids) {
                        removeGeofenceFromCache(context, id)
                    }
                    result.success(true)
                }
                addOnFailureListener {
                    result.error(it.toString(), null, null)
                }
            }
        }

        @JvmStatic
        private fun removeAllGeofences(
            context: Context,
            geofencingClient: GeofencingClient,
            result: Result
        ) {
            val geofenceIds = getRegisteredGeofenceIdsHelper(context)
            geofencingClient.removeGeofences(geofenceIds).run {
                addOnSuccessListener {
                    for (id in geofenceIds) {
                        removeGeofenceFromCache(context, id)
                    }
                    result.success(true)
                }
                addOnFailureListener {
                    result.error(it.toString(), null, null)
                }
            }
        }

        @JvmStatic
        private fun getRegisteredGeofenceIds(context: Context, result: Result) {
            result.success(getRegisteredGeofenceIdsHelper(context))
        }

        @JvmStatic
        private fun getRegisteredGeofenceIdsHelper(context: Context): ArrayList<String> {
            synchronized(sGeofenceCacheLock) {
                val list = ArrayList<String>()
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                val persistentGeofences = p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS, null)
                if (persistentGeofences != null && persistentGeofences.size > 0) {
                    for (id in persistentGeofences) {
                        list.add(id)
                    }
                }
                return list
            }
        }

        @JvmStatic
        private fun getRegisteredGeofences(context: Context, result: Result) {
            synchronized(sGeofenceCacheLock) {
                val list = ArrayList<Map<String, String?>>()
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                val persistentGeofences = p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS, null)
                if (persistentGeofences != null && persistentGeofences.size > 0) {
                    for (geofenceId in persistentGeofences) {
                        val persistentGeofencesData =
                            (p.getString(getPersistentGeofenceKey(geofenceId), null))?.split(",")
                        val id = persistentGeofencesData?.get(1)
                        val lat = persistentGeofencesData?.get(2)
                        val long = persistentGeofencesData?.get(3)
                        val radius = persistentGeofencesData?.get(4)

                        val dataMap =
                            mapOf("id" to id, "lat" to lat, "long" to long, "radius" to radius)
                        list.add(dataMap)

                    }
                }
                result.success(list)
            }
        }

        @JvmStatic
        private fun removeGeofenceFromCache(context: Context, id: String) {
            synchronized(sGeofenceCacheLock) {
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                var persistentGeofences =
                    p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS, null) ?: return
                persistentGeofences = HashSet<String>(persistentGeofences)
                persistentGeofences.remove(id)
                p.edit()
                    .remove(getPersistentGeofenceKey(id))
                    .putStringSet(Constants.PERSISTENT_GEOFENCES_IDS, persistentGeofences)
                    .apply()
            }
        }

        @JvmStatic
        private fun getPersistentGeofenceKey(id: String): String {
            return "persistent_geofence/$id"
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        mContext = binding.applicationContext
        mGeofencingClient = LocationServices.getGeofencingClient(mContext!!)
        val channel = MethodChannel(
            binding.binaryMessenger,
            "native_geofence.chunkytofustudios.com/native_geofence_plugin"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        mContext = null
        mGeofencingClient = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        mActivity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        mActivity = binding.activity
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val args = call.arguments<ArrayList<*>>()
        when (call.method) {
            "NativeGeofencePlugin.initializeService" -> {
                initializeService(mContext!!, args)
                result.success(true)
            }

            "NativeGeofencePlugin.registerGeofence" -> registerGeofence(
                mContext!!,
                mGeofencingClient!!,
                args,
                result,
                true
            )

            "NativeGeofencePlugin.reRegisterAfterReboot" -> {
                reRegisterAfterReboot(mContext!!)
                result.success(true)
            }

            "NativeGeofencePlugin.getRegisteredGeofenceIds" -> getRegisteredGeofenceIds(
                mContext!!,
                result
            )

            "NativeGeofencePlugin.getRegisteredGeofenceRegions" -> getRegisteredGeofences(
                mContext!!,
                result
            )

            "NativeGeofencePlugin.removeGeofence" -> removeGeofence(
                mContext!!,
                mGeofencingClient!!,
                args,
                result
            )

            "NativeGeofencePlugin.removeAllGeofences" -> removeAllGeofences(
                mContext!!,
                mGeofencingClient!!,
                result
            )

            else -> result.notImplemented()
        }
    }
}
