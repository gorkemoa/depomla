// NativeAdFactory.kt
package com.gorkem.depomla.ads

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeAdFactory(private val context: Context) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        Log.d("NativeAdFactory", "Creating NativeAdPlatformView with viewId: $viewId")
        return NativeAdPlatformView(this.context)
    }
}