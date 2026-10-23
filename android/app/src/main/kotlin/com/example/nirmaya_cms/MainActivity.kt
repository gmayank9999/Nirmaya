package com.example.nirmaya_cms

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    // Override onBackPressed to ensure Flutter's BackButtonListener
    // receives the event reliably on Samsung Android 14 devices.
    // Calling super delegates to FlutterActivity which sends the
    // back event through the Flutter navigation channel — allowing
    // our Dart BackButtonListener to intercept and handle it.
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onBackPressed() {
        super.onBackPressed()
    }
}
