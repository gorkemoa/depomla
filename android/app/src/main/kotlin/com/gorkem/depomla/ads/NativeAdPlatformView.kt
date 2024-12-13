// NativeAdPlatformView.kt
package com.gorkem.depomla.ads

import android.content.Context
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.gorkem.depomla.R
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugin.platform.PlatformView

class NativeAdPlatformView(private val context: Context) : PlatformView {
    private val view: View
    private var nativeAd: NativeAd? = null

    init {
        Log.d("NativeAdPlatformView", "Inflating native_ad_layout.xml")
        view = LayoutInflater.from(context).inflate(R.layout.native_ad_layout, null)
    }

    override fun getView(): View {
        return view
    }

    override fun dispose() {
        // Burada nativeAd için dispose çağırmanıza gerek yok, çünkü böyle bir metod yok.
        // Eğer view ile ilgili ek temizlemeler yapmanız gerekirse burada yapabilirsiniz.
        Log.d("NativeAdPlatformView", "Disposing NativeAdPlatformView")
        // nativeAd = null // Gerekirse referansı null yapabilirsiniz
    }

    fun setNativeAd(ad: NativeAd) {
        Log.d("NativeAdPlatformView", "Setting NativeAd")
        nativeAd = ad

        val headline = view.findViewById<TextView>(R.id.adHeadline)
        headline.text = ad.headline
        (view as NativeAdView).headlineView = headline

        val imageView = view.findViewById<ImageView>(R.id.adImage)
        ad.images.firstOrNull()?.let {
            imageView.setImageDrawable(it.drawable)
        }
        view.imageView = imageView

        val body = view.findViewById<TextView>(R.id.adBody)
        body.text = ad.body
        view.bodyView = body

        val callToAction = view.findViewById<Button>(R.id.adCallToAction)
        callToAction.text = ad.callToAction
        view.callToActionView = callToAction

        view.setNativeAd(ad)
    }
}