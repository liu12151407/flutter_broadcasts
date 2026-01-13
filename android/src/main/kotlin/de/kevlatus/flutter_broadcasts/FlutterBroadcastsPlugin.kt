package de.kevlatus.flutter_broadcasts

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.Serializable
import java.util.Date

class CustomBroadcastReceiver(

        val id: Int,

        private val names: List<String>,

        private val categories: List<String> = listOf(),

        private val isExported: Boolean = false,

        private val listener: (Any) -> Unit

) : BroadcastReceiver() {

    companion object {

        const val TAG: String = "CustomBroadcastReceiver"

        const val RECEIVER_EXPORTED = 2

        const val RECEIVER_NOT_EXPORTED = 4

    }



    private val intentFilter: IntentFilter by lazy {

        val intentFilter = IntentFilter()

        names.forEach { intentFilter.addAction(it) }

        categories.forEach { intentFilter.addCategory(it) }

        intentFilter

    }



    override fun onReceive(context: Context?, intent: Intent?) {

        Log.d(TAG, "received intent " + intent?.action)

        intent?.let {

            val bundle = it.extras

            val dataPairs = bundle?.keySet()?.map { key ->

                Pair(key, bundle.get(key))

            }

            val data = dataPairs?.toMap() ?: mapOf()

            val action = it.action

            val receivedCategories = it.categories?.toList() ?: listOf()

            if (action != null) {

                listener(mapOf(

                        "receiverId" to id,

                        "name" to action,

                        "data" to normalize(data),

                        "categories" to normalize(receivedCategories)

                ))

            } else {

                Log.w(TAG, "Received intent with null action, ignoring")

            }

        }

    }



    fun start(context: Context) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

            val flags = if (isExported) RECEIVER_EXPORTED else RECEIVER_NOT_EXPORTED

            context.registerReceiver(this, intentFilter, flags)

        } else {

            context.registerReceiver(this, intentFilter)

        }

        Log.d(TAG, "starting to listen for broadcasts: " + names.joinToString(";") + 

              " (categories: " + categories.joinToString(";") + ", exported: $isExported)")

    }



    fun stop(context: Context) {

        context.unregisterReceiver(this)

        Log.d(TAG, "stopped listening for broadcasts: " + names.joinToString(";"))

    }

}



class BroadcastManager(private val applicationContext: Context) {
    companion object {
        const val TAG: String = "BroadcastManager"
    }

    private val receiversLock = Any()
    private var receivers: MutableMap<Int, CustomBroadcastReceiver> = mutableMapOf()

    fun startReceiver(receiver: CustomBroadcastReceiver) {
        Log.d(TAG, "starting receiver " + receiver.id.toString())

        synchronized(receiversLock) {
            // Stop existing receiver with the same ID if it exists
            receivers[receiver.id]?.let { existing ->
                Log.w(TAG, "Receiver ${receiver.id} already exists, stopping it first")
                existing.stop(applicationContext)
            }

            receiver.start(applicationContext)
            receivers[receiver.id] = receiver
        }
    }

    fun stopReceiver(id: Int) {
        Log.d(TAG, "stopping receiver $id")

        synchronized(receiversLock) {
            val receiver = receivers.remove(id)
            if (receiver != null) {
                receiver.stop(applicationContext)
            } else {
                Log.w(TAG, "Receiver $id does not exist, nothing to stop")
            }
        }
    }

    fun stopAll() {
        synchronized(receiversLock) {
            receivers.values.forEach { it.stop(applicationContext) }
            receivers.clear()
        }
    }
}

class MethodCallHandlerImpl(
        private val context: Context,
        private val broadcastManager: BroadcastManager
) : MethodCallHandler {
    companion object {
        const val TAG: String = "MethodCallHandlerImpl"
    }

    private var channel: MethodChannel? = null

    private fun withReceiverArgs(
            call: MethodCall,
            result: Result,
            func: (id: Int, names: List<String>, categories: List<String>, isExported: Boolean) -> Unit
    ) {
        val id = call.argument<Int>("id")
                ?: return result.error("1", "no receiver id provided", null)

        val names = call.argument<List<String>>("names")
                ?: return result.error("1", "no names provided", null)

        val categories = call.argument<List<String>>("categories") ?: listOf()
        val isExported = call.argument<Boolean>("isExported") ?: false

        func(id, names, categories, isExported)
    }

    private fun withBroadcastArgs(
            call: MethodCall,
            result: Result,
            func: (name: String, data: Map<String, Any>, flags: List<Int>, categories: List<String>, androidPackage: String?) -> Unit
    ) {
        val name = call.argument<String>("name")
                ?: return result.error("1", "no broadcast name provided", null)
        val data = call.argument<Map<String, Any>>("data") ?: mapOf()
        val flags = call.argument<List<Int>>("flags") ?: listOf()
        val categories = call.argument<List<String>>("categories") ?: listOf()
        val androidPackage = call.argument<String>("androidPackage")
        func(name, data, flags, categories, androidPackage)
    }

    private fun onStartReceiver(call: MethodCall, result: Result) {
        withReceiverArgs(call, result) { id, names, categories, isExported ->
            broadcastManager.startReceiver(CustomBroadcastReceiver(id, names, categories, isExported) { broadcast ->
                channel?.invokeMethod("receiveBroadcast", broadcast)
            })
            result.success(null)
        }
    }

    private fun onStopReceiver(call: MethodCall, result: Result) {
        withReceiverArgs(call, result) { id, _ ->
            broadcastManager.stopReceiver(id)
            result.success(null)
        }
    }

    private fun onSendBroadcast(call: MethodCall, result: Result) {
        withBroadcastArgs(call, result) { name, data, flags, categories, androidPackage ->
            Intent().also { intent ->
                intent.action = name
                if (androidPackage != null) {
                    intent.setPackage(androidPackage)
                }
                flags.forEach { intent.addFlags(it) }
                categories.forEach { intent.addCategory(it) }
                
                intent.putExtras(toBundle(data))
                
                context.sendBroadcast(intent)
                Log.d(TAG, "sent broadcast: $name (package: $androidPackage)")
            }
            result.success(null)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "received method call " + call.method)
        when (call.method) {
            "startReceiver" -> {
                onStartReceiver(call, result)
            }
            "stopReceiver" -> {
                onStopReceiver(call, result)
            }
            "sendBroadcast" -> {
                onSendBroadcast(call, result)
            }
        }
    }

    fun startListening(messenger: BinaryMessenger) {
        if (channel != null) {
            Log.wtf(TAG, "Setting a method call handler before the last was disposed.")
            stopListening()
        }

        channel = MethodChannel(messenger, "de.kevlatus.flutter_broadcasts")
        channel!!.setMethodCallHandler(this)
    }

    fun stopListening() {
        if (channel == null) {
            Log.d(TAG, "Tried to stop listening when no MethodChannel had been initialized.")
            return
        }

        channel!!.setMethodCallHandler(null)
        channel = null
    }
}

class FlutterBroadcastsPlugin : FlutterPlugin {
    companion object {
        const val TAG: String = "FlutterBroadcastsPlugin"
    }

    private var methodCallHandler: MethodCallHandlerImpl? = null
    private var broadcastManager: BroadcastManager? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        broadcastManager = BroadcastManager(flutterPluginBinding.applicationContext)
        methodCallHandler = MethodCallHandlerImpl(
                flutterPluginBinding.applicationContext,
                broadcastManager!!
        )
        methodCallHandler!!.startListening(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        if (methodCallHandler == null) {
            Log.wtf(TAG, "Already detached from engine.")
            return
        }
        methodCallHandler!!.stopListening()
        methodCallHandler = null
        broadcastManager?.stopAll()
        broadcastManager = null
    }    
}

/***
 * Normalize the intent data to types that Flutter's StandardMessageCodec can pass.
 *
 * Flutter's StandardMessageCodec is the mechanism used for passing intent contents to the Flutter
 * layer. As only specific types are supported by it, other types are normalized to their String
 * representation.
 *
 * This code should be updated when Flutter Engine's code supports additional types.
 * See https://github.com/flutter/engine/blob/main/shell/platform/android/io/flutter/plugin/common/StandardMessageCodec.java
 */
private fun normalize(x: Any?) : Any? {
	if (
        x == null
        || x is Boolean
        || x is Int
        || x is Short
        || x is Byte
        || x is Long
        || x is Float
        || x is Double
        || x is java.math.BigInteger
        || x is CharSequence
        || x is ByteArray
        || x is IntArray
        || x is LongArray
        || x is DoubleArray
        || x is FloatArray
    ) {
    	return x
    } else if (x is android.os.Bundle) {
        val dataPairs = x.keySet()?.map { key ->
            Pair(key, x.get(key))
        }
        return normalizeMap(dataPairs?.toMap() ?: mapOf<String, Any?>())
    } else if (x is Date) {
        return x.time
    } else if (x is List<*>) {
        return normalizeList(x)
    } else if (x is Map<*, *>) {
    	return normalizeMap(x)
    } else {
        return x.toString()
    }
}

private fun <V> normalizeList(x: List<V>) : List<Any?> {
    return x.map { item ->
    	normalize(item)
    }
}

private fun <K, V> normalizeMap(x: Map<K, V>) : Map<K, Any?> {
    val pairs = x.keys.map { key ->
        Pair(key, normalize(x[key]))
    }
    return pairs.toMap()
}

private fun toBundle(map: Map<String, Any?>): android.os.Bundle {
    val bundle = android.os.Bundle()
    for (entry in map) {
        val key = entry.key
        val value = entry.value
        when (value) {
            null -> {} // Skip nulls
            is Boolean -> bundle.putBoolean(key, value)
            is Byte -> bundle.putByte(key, value)
            is Char -> bundle.putChar(key, value)
            is Short -> bundle.putShort(key, value)
            is Int -> bundle.putInt(key, value)
            is Long -> bundle.putLong(key, value)
            is Float -> bundle.putFloat(key, value)
            is Double -> bundle.putDouble(key, value)
            is String -> bundle.putString(key, value)
            is CharSequence -> bundle.putCharSequence(key, value)
            is ByteArray -> bundle.putByteArray(key, value)
            is android.os.Bundle -> bundle.putBundle(key, value)
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                bundle.putBundle(key, toBundle(value as Map<String, Any?>))
            }
            is List<*> -> {
                bundle.putSerializable(key, ArrayList(toSafeList(value)))
            }
            is Serializable -> bundle.putSerializable(key, value)
            else -> bundle.putString(key, value.toString())
        }
    }
    return bundle
}

private fun toSafeList(list: List<*>): List<Any?> {
    return list.map { item ->
        when (item) {
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                toBundle(item as Map<String, Any?>)
            }
            is List<*> -> toSafeList(item)
            else -> item
        }
    }
}
