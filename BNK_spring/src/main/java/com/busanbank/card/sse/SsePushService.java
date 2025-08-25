package com.busanbank.card.sse;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Collection;
import java.util.Map;
import java.util.UUID;

@Service
public class SsePushService {

    private final SseEmitterRegistry registry;

    public SsePushService(SseEmitterRegistry registry) {
        this.registry = registry;
    }

    /** 특정 멤버에게 이벤트 전송 (eventName: "marketing", "card" 등) */
    public void sendToMember(Long memberNo, String eventName, Map<String, Object> payload, boolean saveHistory) {
        var event = SseEmitter.event()
                .name(eventName)
                .id(UUID.randomUUID().toString())
                .data(payload);

        var emitters = registry.getEmitters(memberNo);
        if (emitters.isEmpty()) {
            // 필요한 경우 여기서 오프라인 저장 로직을 붙일 수 있음(saveHistory 사용)
            return;
        }
        for (var e : emitters) {
            registry.safeSend(e, event, () -> registry.remove(memberNo, e));
        }
        // 히스토리 저장이 필요하면 여기서 별도 Repo 호출 (현재는 최소 구현이라 생략)
    }

    /** 다수 멤버에게 브로드캐스트 */
    public void sendToMembers(Collection<Long> memberNos, String eventName, Map<String, Object> payload, boolean saveHistory) {
        for (Long m : memberNos) {
            sendToMember(m, eventName, payload, saveHistory);
        }
    }
}
