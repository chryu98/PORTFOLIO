package com.busanbank.card.sse;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Collection;
import java.util.Map;
import java.util.UUID;

@Service
public class SsePushService {

    private final SseEmitterRegistry registry;
    private final SseEventStore store;

    public SsePushService(SseEmitterRegistry registry, SseEventStore store) {
        this.registry = registry;
        this.store = store;
    }

    /** 특정 멤버에게 이벤트 전송 (eventName: "marketing", "card" 등) */
    public void sendToMember(Long memberNo, String eventName, Map<String, Object> payload, boolean saveHistory) {
        String id = UUID.randomUUID().toString();
        long ts = System.currentTimeMillis();

        if (saveHistory) {
            store.append(memberNo, new SseEventStore.StoredEvent(id, ts, eventName, payload));
        }

        var event = SseEmitter.event()
                .id(id)
                .name(eventName)
                .data(payload);

        var emitters = registry.getEmitters(memberNo);
        if (emitters.isEmpty()) return;

        for (var e : emitters) {
            registry.safeSend(e, event, () -> registry.remove(memberNo, e));
        }
    }

    /** 브로드캐스트 */
    public void sendToMembers(Collection<Long> memberNos, String eventName, Map<String, Object> payload, boolean saveHistory) {
        for (Long m : memberNos) {
            sendToMember(m, eventName, payload, saveHistory);
        }
    }
}
