// com.busanbank.card.common.websocket.StompAuthChannelInterceptor
package com.busanbank.card.common.websocket;

import org.springframework.messaging.*;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class StompAuthChannelInterceptor implements ChannelInterceptor {
    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor acc = StompHeaderAccessor.wrap(message);
        if (acc == null || acc.getCommand() == null) return message;

        // HttpSessionHandshakeInterceptor 가 복사한 세션 속성
        Map<String,Object> sess = acc.getSessionAttributes();
        if (sess != null && sess.get("loginAdminNo") != null) {
            return message; // 관리자 세션 OK
        }
        // JWT 등 추가검증이 있으면 여기서 처리 (없으면 그대로 통과)
        return message;
    }
}
