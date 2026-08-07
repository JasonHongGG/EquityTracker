package com.jasonhong.equity_tracker

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.appfunctions.AppFunctionServiceEntryPoint
import androidx.appfunctions.AppFunctionService

@AppFunctionServiceEntryPoint(
    serviceName = "EquityTrackerAppFunctionService",
    appFunctionXmlFileName = "app_functions.xml"
)
abstract class BaseAppFunctionService : AppFunctionService() {
    // KSP will generate EquityTrackerAppFunctionService that extends this class.
}
