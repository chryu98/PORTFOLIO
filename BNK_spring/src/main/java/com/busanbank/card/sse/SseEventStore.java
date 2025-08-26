package com.busanbank.card.sse;

import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;

@Component
public class SseEventStore {

    // 멤버당 최근 N개만 보관 (필요하면 늘리세요)
    private static final int MAX_EVENTS = 200;

    public static final class StoredEvent {
        public final String id;
        public final long ts;
        public final String name;
        public final Map<String, Object> payload;

        public StoredEvent(String id, long ts, String name, Map<String, Object> payload) {
            this.id = id;
            this.ts = ts;
            this.name = name;
            this.payload = payload;
        }
    }

    private final Map<Long, Deque<StoredEvent>> store = new ConcurrentHashMap<>();

    public void append(Long memberNo, StoredEvent e) {
        var q = store.computeIfAbsent(memberNo, k -> new ConcurrentLinkedDeque<>());
        q.addLast(e);
        while (q.size() > MAX_EVENTS) q.pollFirst();
    }

    /** lastEventId 이후 이벤트를 최대 limit개 반환 (못 찾으면 최신 limit개) */
    public List<StoredEvent> since(Long memberNo, String lastEventId, int limit) {
        var q = store.get(memberNo);
        if (q == null || q.isEmpty()) return List.of();

        if (lastEventId == null || lastEventId.isBlank()) {
            int skip = Math.max(0, q.size() - limit);
            return q.stream().skip(skip).toList();
        }

        boolean found = false;
        List<StoredEvent> out = new ArrayList<>();
        for (var se : q) {
            if (found) out.add(se);
            else if (se.id.equals(lastEventId)) found = true;
        }
        if (!found) {
            int skip = Math.max(0, q.size() - limit);
            return q.stream().skip(skip).toList();
        }
        return out;
    }
}
