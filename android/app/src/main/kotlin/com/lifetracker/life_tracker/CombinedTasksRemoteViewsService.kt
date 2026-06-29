package com.lifetracker.life_tracker

import android.content.Intent
import android.widget.RemoteViewsService

/// Hosts the factory for the combined month widget's side task list.
class CombinedTasksRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CombinedTasksRemoteViewsFactory(applicationContext)
    }
}
