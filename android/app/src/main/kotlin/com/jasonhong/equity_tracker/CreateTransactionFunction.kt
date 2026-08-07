package com.jasonhong.equity_tracker

import android.content.Context
import androidx.appfunctions.AppFunction
import androidx.appfunctions.AppFunctionContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class CreateTransactionFunction {
    
    @AppFunction
    fun createTransaction(
        appContext: AppFunctionContext,
        amount: Double,
        category: String,
        description: String?,
        date: String? // Optional date, e.g. "2026-08-07"
    ): String {
        // We will send this to Flutter via a MethodChannel (or handle it in a background engine)
        
        val context = appContext.context
        
        // Pass the request to the Flutter side
        FlutterVoiceCommandReceiver.processCommand(
            context, 
            amount, 
            category, 
            description ?: "", 
            date ?: SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        )
        
        return "已經成功為您記下一筆 $amount 元的 $category 帳務。"
    }
}
