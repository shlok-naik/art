package com.example.art

import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayOutputStream

/**
 * Process-wide bridge between [MediaNotificationListenerService] (which runs
 * detached from any Activity) and the Flutter EventChannel set up in
 * [MainActivity]. Flutter apps run the listener service in the same process
 * as the Activity by default, so a plain singleton is enough — no need for a
 * cross-process IPC mechanism.
 */
object MediaBridge {
    private val mainHandler = Handler(Looper.getMainLooper())

    var eventSink: EventChannel.EventSink? = null
        set(value) {
            field = value
            // Replay the last known state immediately so a freshly attached
            // Flutter listener doesn't wait for the next playback change.
            value?.let { pushCurrentState() }
        }

    private var controller: MediaController? = null
    private val controllerCallback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) = pushCurrentState()
        override fun onMetadataChanged(metadata: MediaMetadata?) = pushCurrentState()
        override fun onSessionDestroyed() {
            controller = null
            pushCurrentState()
        }
    }

    /** Called by the listener service whenever the system's active session list changes. */
    fun setActiveController(newController: MediaController?) {
        if (controller?.sessionToken == newController?.sessionToken) return
        controller?.unregisterCallback(controllerCallback)
        controller = newController
        controller?.registerCallback(controllerCallback, mainHandler)
        pushCurrentState()
    }

    fun currentSnapshot(): Map<String, Any?> {
        val c = controller ?: return mapOf("connected" to false)
        val metadata = c.metadata
        val playbackState = c.playbackState
        val artBytes = extractArt(metadata?.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: metadata?.getBitmap(MediaMetadata.METADATA_KEY_ART))

        return mapOf(
            "connected" to true,
            "packageName" to c.packageName,
            "title" to metadata?.getString(MediaMetadata.METADATA_KEY_TITLE),
            "artist" to metadata?.getString(MediaMetadata.METADATA_KEY_ARTIST),
            "isPlaying" to (playbackState?.state == PlaybackState.STATE_PLAYING),
            "art" to artBytes,
        )
    }

    private fun extractArt(bitmap: Bitmap?): ByteArray? {
        if (bitmap == null) return null
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun pushCurrentState() {
        val snapshot = currentSnapshot()
        mainHandler.post { eventSink?.success(snapshot) }
    }

    fun play() = controller?.transportControls?.play()
    fun pause() = controller?.transportControls?.pause()
    fun skipNext() = controller?.transportControls?.skipToNext()
    fun skipPrevious() = controller?.transportControls?.skipToPrevious()
}
