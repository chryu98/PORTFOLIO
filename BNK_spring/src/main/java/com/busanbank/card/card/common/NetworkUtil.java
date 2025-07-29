package com.busanbank.card.card.common;

import java.net.InetAddress;
import java.net.UnknownHostException;

public class NetworkUtil {
    public static String getServerIp() {
        try {
            return InetAddress.getLocalHost().getHostAddress(); // 예: 192.168.0.5
        } catch (UnknownHostException e) {
            return "localhost"; // 실패 시 기본값
        }
    }
}
