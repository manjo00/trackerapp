package com.lifetracker.life_tracker

import android.content.Intent
import android.widget.RemoteViewsService

/// Hosts the factory that builds the agenda widget's list rows. Android binds
/// to this service (declared with BIND_REMOTEVIEWS permission in the manifest)
/// to populate the ListView.
class AgendaRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return AgendaRemoteViewsFactory(applicationContext)
    }
}
