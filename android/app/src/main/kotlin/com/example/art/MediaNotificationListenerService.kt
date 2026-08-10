package com.example.art

import android.content.ComponentName
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.service.notification.NotificationListenerService

/**
 * Grants this app the system-wide "Notification access" special permission
 * (toggled manually by the user in Settings — see
 * [MainActivity.NOTIFICATION_ACCESS_CHANNEL]), which is the prerequisite for
 * [MediaSessionManager.getActiveSessions]. Once granted, this mirrors
 * whatever music app the user already has playing (Spotify, YouTube Music,
 * etc.) into the session timer's mini player — the same mechanism the
 * device's own lock screen uses, not any one service's SDK, so it works
 * regardless of subscription tier.
 */
class MediaNotificationListenerService : NotificationListenerService() {

    private lateinit var sessionManager: MediaSessionManager
    private lateinit var componentName: ComponentName

    private val sessionsChangedListener =
        MediaSessionManager.OnActiveSessionsChangedListener { controllers ->
            pickActiveController(controllers ?: emptyList())
        }

    override fun onListenerConnected() {
        super.onListenerConnected()
        sessionManager = getSystemService(MediaSessionManager::class.java)
        componentName = ComponentName(this, MediaNotificationListenerService::class.java)
        sessionManager.addOnActiveSessionsChangedListener(sessionsChangedListener, componentName)
        pickActiveController(sessionManager.getActiveSessions(componentName))
    }

    override fun onListenerDisconnected() {
        sessionManager.removeOnActiveSessionsChangedListener(sessionsChangedListener)
        MediaBridge.setActiveController(null)
        super.onListenerDisconnected()
    }

    /**
     * Prefers a session that's actually playing over one that's merely
     * present (e.g. a paused podcast app left in the background), since
     * that's the one the user cares about controlling right now.
     */
    private fun pickActiveController(controllers: List<MediaController>) {
        val playing = controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
        MediaBridge.setActiveController(playing ?: controllers.firstOrNull())
    }
}
