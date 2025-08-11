package com.example.bnkandroid;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class NaverMapFactory extends PlatformViewFactory {
    private final Context context;
    private final BinaryMessenger messenger;

    public NaverMapFactory(Context context, BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.context = context;
        this.messenger = messenger;
    }

    public NaverMapPlatformView create(Context ctx, int id, Object args) {
        // ⬇️ 여기서 (Context, BinaryMessenger, int) 시그니처 호출
        return new NaverMapPlatformView(context, messenger, id);
    }
}
