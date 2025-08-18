package com.example.bnkandroid;

import android.content.Context;
import android.graphics.PointF;
import android.util.TypedValue;
import android.view.View;

import androidx.annotation.NonNull;

import com.naver.maps.geometry.LatLng;
import com.naver.maps.geometry.LatLngBounds;
import com.naver.maps.map.CameraAnimation;
import com.naver.maps.map.CameraPosition;
import com.naver.maps.map.CameraUpdate;
import com.naver.maps.map.MapView;
import com.naver.maps.map.NaverMap;
import com.naver.maps.map.NaverMapOptions;
import com.naver.maps.map.overlay.Marker;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class NaverMapPlatformView implements PlatformView, MethodChannel.MethodCallHandler {

    private static final String CHANNEL_NAME = "bnk_naver_map_channel";
    private static final String TAG = "NaverMapPlatformView";

    private final Context context;
    private final MapView mapView;
    private final MethodChannel channel;
    private NaverMap naverMap;

    private final List<Marker> currentMarkers = new ArrayList<>();
    private Marker myLocationMarker; // ✅ 내 위치 마커

    // 지도 준비 전 보관용
    private final List<Map<String, Object>> pendingMarkers = new ArrayList<>();
    private boolean pendingFitBounds = false;
    private int pendingPadding = 60;

    public NaverMapPlatformView(Context context, BinaryMessenger messenger) {
        this.context = context;

        mapView = new MapView(context, new NaverMapOptions());
        mapView.onCreate(null);
        mapView.onResume();

        channel = new MethodChannel(messenger, CHANNEL_NAME);
        channel.setMethodCallHandler(this);

        mapView.getMapAsync(map -> {
            naverMap = map;

            // 줌 범위 여유 있게 설정
            naverMap.setMinZoom(4.0);
            naverMap.setMaxZoom(20.0);

            // Flutter에 지도 준비 완료 이벤트
            channel.invokeMethod("onMapReady", null);

            // 지도 준비 전에 들어온 setMarkers 요청 반영
            if (!pendingMarkers.isEmpty()) {
                setMarkersInternal(pendingMarkers, pendingFitBounds, pendingPadding);
                pendingMarkers.clear();
            }
        });
    }

    @NonNull @Override
    public View getView() { return mapView; }

    @Override
    public void dispose() {
        channel.setMethodCallHandler(null);
        for (Marker m : currentMarkers) m.setMap(null);
        currentMarkers.clear();
        if (myLocationMarker != null) myLocationMarker.setMap(null);
        mapView.onPause();
        mapView.onDestroy();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "ping": {
                result.success("pong"); // ✅ Flutter에서 ping 테스트용
                return;
            }

            case "setMyLocation": { // ✅ 내 위치 마커 + 카메라 이동
                if (naverMap == null) { result.success(null); return; }

                Double lat = call.argument("lat");
                Double lng = call.argument("lng");
                Double zoom = call.argument("zoom");
                Boolean animate = call.argument("animate");

                if (lat == null || lng == null || !isValidCoord(lat, lng)) {
                    result.success(null);
                    return;
                }

                LatLng pos = new LatLng(lat, lng);

                if (myLocationMarker == null) {
                    myLocationMarker = new Marker();
                    // 필요 시 커스텀 아이콘 지정 가능
                    // myLocationMarker.setIcon(OverlayImage.fromResource(R.drawable.ic_my_location));
                    myLocationMarker.setOnClickListener(overlay -> {
                        // Flutter로 콜백 (원하시면 사용)
                        channel.invokeMethod("onMyLocationTapped", null);
                        return true;
                    });
                }
                myLocationMarker.setPosition(pos);
                myLocationMarker.setMap(naverMap);

                CameraUpdate cu = (zoom != null)
                        ? CameraUpdate.toCameraPosition(new CameraPosition(pos, zoom.floatValue()))
                        : CameraUpdate.scrollTo(pos);
                if (Boolean.TRUE.equals(animate)) {
                    cu = cu.animate(CameraAnimation.Easing, 400);
                }
                naverMap.moveCamera(cu);

                result.success(null);
                return;
            }

            case "setMarkers": {
                @SuppressWarnings("unchecked")
                Map<String, Object> args = (Map<String, Object>) call.arguments;
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> markers = (List<Map<String, Object>>) args.get("markers");

                boolean fitBounds = args.get("fitBounds") != null && (boolean) args.get("fitBounds");
                int paddingDp = 60;
                if (args.get("padding") instanceof Number) {
                    paddingDp = ((Number) args.get("padding")).intValue();
                }

                if (markers == null) { result.success(null); return; }

                if (naverMap == null) {
                    // 지도 준비 전이면 보관
                    pendingMarkers.clear();
                    pendingMarkers.addAll(markers);
                    pendingFitBounds = fitBounds;
                    pendingPadding = paddingDp;
                    result.success(null);
                    return;
                }

                setMarkersInternal(markers, fitBounds, paddingDp);
                result.success(null);
                return;
            }

            case "moveCamera": { // ✅ 좌표+줌을 한 번에 (체인 대신 toCameraPosition)
                if (naverMap == null) {
                    result.error("MAP_NOT_READY", "NaverMap not ready", null);
                    return;
                }
                @SuppressWarnings("unchecked")
                Map<String, Object> args = (Map<String, Object>) call.arguments;

                double lat = toDouble(args.get("lat"), Double.NaN);
                double lng = toDouble(args.get("lng"), Double.NaN);
                Float zoom = args.get("zoom") != null ? ((Number) args.get("zoom")).floatValue() : null;
                boolean animate = args.get("animate") != null && (boolean) args.get("animate");

                if (!isValidCoord(lat, lng)) { result.success(null); return; }

                LatLng target = new LatLng(lat, lng);
                CameraUpdate cu = (zoom != null)
                        ? CameraUpdate.toCameraPosition(new CameraPosition(target, zoom))
                        : CameraUpdate.scrollTo(target);
                if (animate) {
                    cu = cu.animate(CameraAnimation.Easing, 400);
                }
                naverMap.moveCamera(cu);

                result.success(null);
                return;
            }

            case "fitBounds": {
                if (naverMap == null) {
                    result.error("MAP_NOT_READY", "NaverMap not ready", null);
                    return;
                }
                @SuppressWarnings("unchecked")
                Map<String, Object> args = (Map<String, Object>) call.arguments;
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> points = (List<Map<String, Object>>) args.get("points");
                int paddingDp = args.get("padding") != null ? ((Number) args.get("padding")).intValue() : 80;

                if (points == null || points.isEmpty()) { result.success(null); return; }

                LatLngBounds.Builder b = new LatLngBounds.Builder();
                int included = 0;
                for (Map<String, Object> p : points) {
                    double lat = toDouble(p.get("lat"), toDouble(p.get("latitude"), Double.NaN));
                    double lng = toDouble(p.get("lng"), toDouble(p.get("longitude"), Double.NaN));
                    if (!isValidCoord(lat, lng)) continue;
                    b.include(new LatLng(lat, lng));
                    included++;
                }
                if (included > 0) {
                    int paddingPx = dpToPx(paddingDp); // ✅ dp → px 변환
                    CameraUpdate cu = CameraUpdate
                            .fitBounds(b.build(), paddingPx)
                            .animate(CameraAnimation.Easing, 400);
                    naverMap.moveCamera(cu);
                }

                result.success(null);
                return;
            }

            default:
                result.notImplemented();
        }
    }

    // 마커 생성 + (옵션) 전체 보기
    private void setMarkersInternal(List<Map<String, Object>> markers, boolean fitBounds, int paddingDp) {
        // 기존 마커 제거
        for (Marker m : currentMarkers) m.setMap(null);
        currentMarkers.clear();

        if (markers == null || markers.isEmpty()) return;

        LatLngBounds.Builder bounds = new LatLngBounds.Builder();
        int count = 0;

        for (Map<String, Object> item : markers) {
            double lat = toDouble(item.get("lat"), toDouble(item.get("latitude"), Double.NaN));
            double lng = toDouble(item.get("lng"), toDouble(item.get("longitude"), Double.NaN));
            if (!isValidCoord(lat, lng)) continue;

            Marker mk = new Marker();
            mk.setPosition(new LatLng(lat, lng));
            mk.setCaptionText(getString(item.get("title"), getString(item.get("branchName"), "")));
            mk.setSubCaptionText(getString(item.get("snippet"), ""));
            mk.setMap(naverMap);
            currentMarkers.add(mk);

            if (fitBounds) bounds.include(new LatLng(lat, lng));
            count++;
        }

        // ❌ (중요) 테스트 마커 추가하던 코드 삭제 — fitBounds 왜곡의 원인이 됩니다.

        if (fitBounds && count > 0) {
            int paddingPx = dpToPx(paddingDp); // ✅ dp → px 변환
            CameraUpdate cu = CameraUpdate
                    .fitBounds(bounds.build(), paddingPx)
                    .animate(CameraAnimation.Easing, 400);
            naverMap.moveCamera(cu);
        }
    }

    // ───────────────────────────
    // 유틸
    // ───────────────────────────
    private static boolean isValidCoord(double lat, double lng) {
        if (Double.isNaN(lat) || Double.isNaN(lng)) return false;
        if (lat < -90 || lat > 90) return false;
        if (lng < -180 || lng > 180) return false;
        // (0,0) 차단은 선택적으로: if (lat == 0.0 && lng == 0.0) return false;
        return true;
    }

    private static double toDouble(Object v, double def) {
        if (v == null) return def;
        if (v instanceof Number) return ((Number) v).doubleValue();
        try { return Double.parseDouble(String.valueOf(v)); } catch (Exception ignored) { return def; }
    }

    private static String getString(Object v, String def) {
        return v == null ? def : String.valueOf(v);
    }

    private int dpToPx(int dp) {
        return Math.round(TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, dp, context.getResources().getDisplayMetrics()));
    }
}
