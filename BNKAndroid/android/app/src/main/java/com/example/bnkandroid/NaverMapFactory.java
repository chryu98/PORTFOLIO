package com.example.bnkandroid;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class NaverMapFactory extends PlatformViewFactory {

    private final BinaryMessenger messenger;

    public NaverMapFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int id, Object args) {
        // ✅ BinaryMessenger를 플랫폼뷰로 전달
        return new NaverMapPlatformView(context, messenger);
    }
}
