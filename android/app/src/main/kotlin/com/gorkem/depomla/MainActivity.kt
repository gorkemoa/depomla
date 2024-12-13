package com.gorkem.depomla

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.gorkem.depomla.ads.NativeAdFactory
import android.util.Log

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("MainActivity", "Registering NativeAdFactory with viewType 'listTile'")
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("listTile", NativeAdFactory(this))
    }
}