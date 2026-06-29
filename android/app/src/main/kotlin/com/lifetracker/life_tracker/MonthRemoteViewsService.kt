package com.lifetracker.life_tracker

import android.content.Intent
import android.widget.RemoteViewsService

/// Hosts the factory that builds the month-grid widget's day cells.
class MonthRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return MonthRemoteViewsFactory(applicationContext)
    }
}
