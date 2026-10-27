package com.test.app.testfeature.apps

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.widget.LinearLayout
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.widget.Toast
import io.flutter.plugins.GeneratedPluginRegistrant
import com.facebook.FacebookSdk
import com.facebook.LoggingBehavior
import com.facebook.appevents.AppEventsLogger

fun safeParseColor(colorStr: String, defaultColor: String = "#FFFFFF"): Int {
    return try {
        val formatted = if (colorStr.startsWith("#")) colorStr else "#$colorStr"
        Color.parseColor(formatted)
    } catch (e: Exception) {
        try {
            Color.parseColor(defaultColor)
        } catch (ex: Exception) {
            Color.WHITE
        }
    }
}

class MainActivity: FlutterActivity(){
    private fun setText(myText: String) {
        Toast.makeText(this, myText, Toast.LENGTH_SHORT).show()
    }

    private val CHANNEL = "nativeChannel"

    private var startColor: String = "0091FF"
    private var endColor: String = "0091FF"
    private var backgroundColor: String = "A7DAFB"
    private var headLineTextColor: String = "000000"
    private var bodyTextColor: String = "000000"
    private var buttonTextColor: String = "FFFFFF"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call: MethodCall, result ->
                Log.i("xyz", "configureFlutterEngine: ")
                when (call.method) {
                    "setToast" -> {

                        try {
                            Log.i("xyz", "configureFlutterEngine: 1111")
                            val fb_appid = call.argument<String>("fb_appid")!!
                            val fb_token = call.argument<String>("fb_token")!!
                            startColor = call.argument<String>("btnBgColorG1")!!
                            Log.i("xyz", "configureFlutterEngine: 1111")
                            endColor = call.argument<String>("btnBgColorG2")!!
                            backgroundColor = call.argument<String>("nativeBGColor")!!
                            headLineTextColor = call.argument<String>("headerTextColor")!!
                            bodyTextColor = call.argument<String>("bodyTextColor")!!
                            buttonTextColor = call.argument<String>("btnTextColor")!!
                            Log.i("xyz", "configureFlutterEngine: 2")


                            FacebookSdk.setApplicationId(fb_appid)
                            FacebookSdk.setClientToken(fb_token)
                            FacebookSdk.sdkInitialize(this@MainActivity)
                            FacebookSdk.setAutoInitEnabled(true)
                            FacebookSdk.fullyInitialize()
                            FacebookSdk.setAutoLogAppEventsEnabled(true)
                            FacebookSdk.addLoggingBehavior(LoggingBehavior.APP_EVENTS)
                            AppEventsLogger.newLogger(this@MainActivity).applicationId

                            // Register ad factories here, after initializing properties
                            GoogleMobileAdsPlugin.registerNativeAdFactory(
                                flutterEngine,
                                "smallNativeAds",
                                NativeAdFactorySmall(layoutInflater, startColor, endColor, backgroundColor, headLineTextColor, bodyTextColor, buttonTextColor)
                            )
                            GoogleMobileAdsPlugin.registerNativeAdFactory(
                                flutterEngine,
                                "bigNativeAds",
                                NativeAdFactoryBig(layoutInflater, startColor, endColor, backgroundColor, headLineTextColor, bodyTextColor, buttonTextColor)
                            )
                            GoogleMobileAdsPlugin.registerNativeAdFactory(
                                flutterEngine,
                                "fullNativeAds",
                                NativeAdFactoryFull(layoutInflater, startColor, endColor, backgroundColor, headLineTextColor, bodyTextColor, buttonTextColor)
                            )
                            Log.i("xyz", "configureFlutterEngine: 3")

                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                        result.success(true)
                    }
//                    "setScreenshotDisabled" -> {
//                        try {
//                            val disable = call.argument<Boolean>("disable") ?: false
//                            if (disable) {
//                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
//                            } else {
//                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
//                            }
//                            result.success(true)
//                        } catch (e: Exception) {
//                            result.error("ERROR", "Failed to update screenshot state: ${e.message}", null)
//                        }
//                    }
                }
            }

        flutterEngine.plugins.add(GoogleMobileAdsPlugin())
        super.configureFlutterEngine(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        Log.i("xyz", "configureFlutterEngine:4 ")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "smallNativeAds")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "bigNativeAds")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "fullNativeAds")
        Log.i("xyz", "configureFlutterEngine: 5")
    }

}
