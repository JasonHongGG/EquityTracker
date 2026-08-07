package com.jasonhong.equity_tracker

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.appfunctions.AppFunctionServiceEntryPoint
import androidx.appfunctions.AppFunctionService

import androidx.appfunctions.AppFunction
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@AppFunctionServiceEntryPoint(
    serviceName = "EquityTrackerAppFunctionService",
    appFunctionXmlFileName = "app_functions.xml"
)
abstract class BaseAppFunctionService : AppFunctionService() {
    
    /**
     * 在 EquityTracker 記帳應用程式中新增一筆交易紀錄。
     *
     * @param amount 交易的金額，例如 100。
     * @param category 交易的分類，例如 伙食、交通、娛樂。
     * @param description 交易的詳細描述或備註。
     * @param date 交易的日期，格式為 yyyy-MM-dd。
     */
    @AppFunction
    fun createTransaction(
        amount: Double,
        category: String,
        description: String?,
        date: String? // Optional date, e.g. "2026-08-07"
    ): String {
        // Pass the request to the Flutter side
        FlutterVoiceCommandReceiver.processCommand(
            this, 
            amount, 
            category, 
            description ?: "", 
            date ?: SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        )
        
        return "已經成功為您記下一筆 $amount 元的 $category 帳務。"
    }
}
