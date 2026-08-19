package com.example.persalone_mobile

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTimestamp
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.max

class MainActivity : FlutterActivity() {
    companion object {
        private const val microphonePermissionRequestCode = 4101
        private const val inputChannelName = "persalone.audio/input"
        private const val inputEventsChannelName = "persalone.audio/input_events"
        private const val outputChannelName = "persalone.audio/output"
        private const val outputEventsChannelName = "persalone.audio/output_events"
    }

    private var inputSink: EventChannel.EventSink? = null
    private var outputSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var captureThread: Thread? = null
    @Volatile private var capturing = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, inputEventsChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    inputSink = events
                }

                override fun onCancel(arguments: Any?) {
                    inputSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, inputChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestMicrophonePermission(result)
                    "start" -> startInput(call, result)
                    "stop" -> stopInput(result)
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, outputEventsChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    outputSink = events
                }

                override fun onCancel(arguments: Any?) {
                    outputSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, outputChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startOutput(call, result)
                    "write" -> writeOutput(call, result)
                    "stop" -> stopOutput(result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        stopCaptureInternal()
        stopPlaybackInternal()
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != microphonePermissionRequestCode) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        emitInputEvent(
            mapOf(
                "type" to if (granted) "permission_granted" else "permission_denied",
            ),
        )
    }

    private fun requestMicrophonePermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission_in_flight", "A microphone permission request is already active.", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            microphonePermissionRequestCode,
        )
    }

    @Suppress("UNCHECKED_CAST")
    private fun startInput(call: MethodCall, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission_required", "RECORD_AUDIO permission has not been granted.", null)
            return
        }
        if (capturing) {
            result.error("already_capturing", "Android microphone capture is already active.", null)
            return
        }
        val arguments = call.arguments as? Map<String, Any?> ?: emptyMap()
        val sampleRateHz = arguments["sampleRateHz"] as? Int ?: 16000
        val channels = arguments["channels"] as? Int ?: 1
        val bytesPerSample = arguments["bytesPerSample"] as? Int ?: 2
        if (sampleRateHz <= 0 || channels != 1 || bytesPerSample != 2) {
            result.error(
                "unsupported_pcm_format",
                "G3 requires positive-rate, mono, signed 16-bit PCM.",
                null,
            )
            return
        }

        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBufferBytes = AudioRecord.getMinBufferSize(sampleRateHz, channelConfig, encoding)
        if (minBufferBytes <= 0) {
            result.error("buffer_unavailable", "AudioRecord did not provide a minimum buffer size.", null)
            return
        }
        val chunkBytes = max(sampleRateHz / 50 * bytesPerSample, 320)
        val bufferBytes = max(minBufferBytes * 2, chunkBytes * 4)
        val recorder = AudioRecord.Builder()
            .setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(encoding)
                    .setSampleRate(sampleRateHz)
                    .setChannelMask(channelConfig)
                    .build(),
            )
            .setBufferSizeInBytes(bufferBytes)
            .build()
        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            result.error("record_uninitialized", "AudioRecord did not initialize.", null)
            return
        }

        audioRecord = recorder
        capturing = true
        recorder.startRecording()
        captureThread = thread(name = "persalone-audio-record", isDaemon = true) {
            readPcmLoop(recorder, sampleRateHz, bytesPerSample, chunkBytes)
        }
        emitInputEvent(
            mapOf(
                "type" to "capture_started",
                "sampleRateHz" to sampleRateHz,
                "bufferBytes" to bufferBytes,
                "chunkBytes" to chunkBytes,
            ),
        )
        result.success(
            mapOf(
                "sampleRateHz" to sampleRateHz,
                "bufferBytes" to bufferBytes,
                "chunkBytes" to chunkBytes,
            ),
        )
    }

    private fun readPcmLoop(
        recorder: AudioRecord,
        sampleRateHz: Int,
        bytesPerSample: Int,
        chunkBytes: Int,
    ) {
        val buffer = ByteArray(chunkBytes)
        var sequence = 0
        var droppedFrames = 0
        while (capturing) {
            val bytesRead = recorder.read(buffer, 0, buffer.size)
            val receivedAtMicros = System.nanoTime() / 1_000L
            when {
                bytesRead > 0 -> {
                    val frameCount = bytesRead / bytesPerSample
                    val durationMicros = frameCount * 1_000_000 / sampleRateHz
                    emitInputEvent(
                        mapOf(
                            "type" to "frame",
                            "pcm" to buffer.copyOf(bytesRead),
                            "sequence" to sequence,
                            "capturedAtMicros" to receivedAtMicros,
                            "durationMicros" to durationMicros,
                            "discontinuity" to (droppedFrames > 0),
                        ),
                    )
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        val timestamp = AudioTimestamp()
                        if (recorder.getTimestamp(timestamp, AudioTimestamp.TIMEBASE_MONOTONIC) ==
                            AudioRecord.SUCCESS
                        ) {
                            emitInputEvent(
                                mapOf(
                                    "type" to "capture_timestamp",
                                    "framePosition" to timestamp.framePosition,
                                    "timestampMicros" to timestamp.nanoTime / 1_000L,
                                ),
                            )
                        } else {
                            emitInputEvent(mapOf("type" to "capture_timestamp_unavailable"))
                        }
                    } else {
                        emitInputEvent(mapOf("type" to "capture_timestamp_unavailable"))
                    }
                    sequence += 1
                    droppedFrames = 0
                }
                bytesRead == 0 -> {
                    // A zero-byte blocking read is not accepted as an audio frame.
                    droppedFrames += 1
                    emitInputEvent(
                        mapOf(
                            "type" to "input_drop",
                            "sequence" to sequence,
                            "droppedFrames" to droppedFrames,
                        ),
                    )
                }
                else -> {
                    droppedFrames += 1
                    emitInputEvent(
                        mapOf(
                            "type" to "capture_error",
                            "code" to "audio_record_$bytesRead",
                        ),
                    )
                    if (bytesRead == AudioRecord.ERROR_DEAD_OBJECT) {
                        capturing = false
                    }
                }
            }
        }
    }

    private fun stopInput(result: MethodChannel.Result) {
        stopCaptureInternal()
        result.success(null)
    }

    private fun stopCaptureInternal() {
        capturing = false
        val recorder = audioRecord
        try {
            recorder?.stop()
        } catch (_: IllegalStateException) {
            // The recorder can already be stopped after a device error.
        }
        val thread = captureThread
        if (thread != null && thread != Thread.currentThread()) {
            thread.join(500)
        }
        captureThread = null
        recorder?.release()
        audioRecord = null
        emitInputEvent(mapOf("type" to "capture_stopped"))
    }

    @Suppress("UNCHECKED_CAST")
    private fun startOutput(call: MethodCall, result: MethodChannel.Result) {
        if (audioTrack != null) {
            result.error("already_playing", "Android speaker playback is already active.", null)
            return
        }
        val arguments = call.arguments as? Map<String, Any?> ?: emptyMap()
        val sampleRateHz = arguments["sampleRateHz"] as? Int ?: 16000
        val channels = arguments["channels"] as? Int ?: 1
        val bytesPerSample = arguments["bytesPerSample"] as? Int ?: 2
        if (sampleRateHz <= 0 || channels != 1 || bytesPerSample != 2) {
            result.error(
                "unsupported_pcm_format",
                "G4 requires positive-rate, mono, signed 16-bit PCM.",
                null,
            )
            return
        }

        val channelConfig = AudioFormat.CHANNEL_OUT_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBufferBytes = AudioTrack.getMinBufferSize(sampleRateHz, channelConfig, encoding)
        if (minBufferBytes <= 0) {
            result.error("buffer_unavailable", "AudioTrack did not provide a minimum buffer size.", null)
            return
        }
        val chunkBytes = max(sampleRateHz / 50 * bytesPerSample, 320)
        val bufferBytes = max(minBufferBytes * 2, chunkBytes * 4)
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(encoding)
                    .setSampleRate(sampleRateHz)
                    .setChannelMask(channelConfig)
                    .build(),
            )
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(bufferBytes)
            .build()
        if (track.state != AudioTrack.STATE_INITIALIZED) {
            track.release()
            result.error("track_uninitialized", "AudioTrack did not initialize.", null)
            return
        }

        audioTrack = track
        track.play()
        emitOutputEvent(
            mapOf(
                "type" to "playback_started",
                "sampleRateHz" to sampleRateHz,
                "bufferBytes" to bufferBytes,
                "chunkBytes" to chunkBytes,
            ),
        )
        result.success(
            mapOf(
                "sampleRateHz" to sampleRateHz,
                "bufferBytes" to bufferBytes,
                "chunkBytes" to chunkBytes,
            ),
        )
    }

    private fun writeOutput(call: MethodCall, result: MethodChannel.Result) {
        val track = audioTrack
        if (track == null || track.playState != AudioTrack.PLAYSTATE_PLAYING) {
            result.error("output_not_ready", "Android speaker playback is not ready.", null)
            return
        }
        val pcm = call.argument<ByteArray>("pcm")
        if (pcm == null || pcm.isEmpty() || pcm.size % 2 != 0) {
            result.error("invalid_pcm", "Output expects non-empty 16-bit PCM bytes.", null)
            return
        }
        val writtenBytes = track.write(pcm, 0, pcm.size, AudioTrack.WRITE_BLOCKING)
        if (writtenBytes < 0) {
            emitOutputEvent(mapOf("type" to "output_error", "code" to "audio_track_$writtenBytes"))
            result.error("audio_track_write", "AudioTrack write failed: $writtenBytes", null)
            return
        }

        val response = mutableMapOf<String, Any>("writtenBytes" to writtenBytes)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            response["underrunCount"] = track.underrunCount
        }
        val timestamp = AudioTimestamp()
        if (track.getTimestamp(timestamp)) {
            response["presentationTimestampMicros"] = timestamp.nanoTime / 1_000L
            response["framePosition"] = timestamp.framePosition
            emitOutputEvent(
                mapOf(
                    "type" to "output_timestamp",
                    "framePosition" to timestamp.framePosition,
                    "timestampMicros" to timestamp.nanoTime / 1_000L,
                ),
            )
        } else {
            emitOutputEvent(mapOf("type" to "output_timestamp_unavailable"))
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && track.underrunCount > 0) {
            emitOutputEvent(
                mapOf(
                    "type" to "output_underrun",
                    "underrunCount" to track.underrunCount,
                ),
            )
        }
        result.success(response)
    }

    private fun stopOutput(result: MethodChannel.Result) {
        stopPlaybackInternal()
        result.success(null)
    }

    private fun stopPlaybackInternal() {
        val track = audioTrack ?: return
        try {
            track.pause()
            track.flush()
            track.stop()
        } catch (_: IllegalStateException) {
            // The track may have been stopped after a device or route error.
        }
        track.release()
        audioTrack = null
        emitOutputEvent(mapOf("type" to "playback_stopped"))
    }

    private fun emitInputEvent(event: Map<String, Any>) {
        runOnUiThread { inputSink?.success(event) }
    }

    private fun emitOutputEvent(event: Map<String, Any>) {
        runOnUiThread { outputSink?.success(event) }
    }
}
