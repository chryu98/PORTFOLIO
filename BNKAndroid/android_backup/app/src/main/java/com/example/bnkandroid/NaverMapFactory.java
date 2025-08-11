package com.example.bnkandroid;

import android.content.Context;

import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.common.StandardMessageCodec;

public class NaverMapFactory extends PlatformViewFactory {

    public NaverMapFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    @Override
    public PlatformView create(Context context, int id, Object args) {
        return new NaverMapPlatformView(context);
    }
}
