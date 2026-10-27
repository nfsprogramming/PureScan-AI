package com.purescanai.mobile

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Aligns the splash screen with Android 12 API
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
