package com.monsware.fold_kit

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

// Android folds already reach Flutter's displayFeatures; this only adds the hinge angle sensor (API 30+).
class FoldKitPlugin : FlutterPlugin, EventChannel.StreamHandler, SensorEventListener {
    private var channel: EventChannel? = null
    private var sensorManager: SensorManager? = null
    private var sink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sensorManager = binding.applicationContext.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        channel = EventChannel(binding.binaryMessenger, "fold_kit/fold").also { it.setStreamHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onCancel(null)
        channel?.setStreamHandler(null)
        channel = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        send(null)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val hinge = sensorManager?.getDefaultSensor(Sensor.TYPE_HINGE_ANGLE) ?: return
        sensorManager?.registerListener(this, hinge, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        send(event.values[0].toDouble())
    }

    private fun send(angle: Double?) {
        sink?.success(
            mapOf(
                "status" to "unknown",
                "angle" to angle,
                "folds" to emptyList<Any>(),
                "model" to Build.MODEL,
            ),
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
