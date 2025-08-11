package com.example.bnkandroid;

import android.content.Context;
import android.view.View;

import com.naver.maps.map.MapView;
import com.naver.maps.map.NaverMapOptions;

public class NaverMapView extends MapView {
    public NaverMapView(Context context) {
        super(context, new NaverMapOptions());
    }
}