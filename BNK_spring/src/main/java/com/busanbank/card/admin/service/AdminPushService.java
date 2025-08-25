package com.busanbank.card.admin.service;

import com.busanbank.card.admin.dao.AdminPushMapper;
import com.busanbank.card.admin.dto.AdminPushRow;
import com.busanbank.card.sse.SsePushService; // ← 네 SSE 서비스 위치에 맞게 수정
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class AdminPushService {
    private final AdminPushMapper mapper;
    private final SsePushService sse;

    public AdminPushService(AdminPushMapper mapper, SsePushService sse) {
        this.mapper = mapper;
        this.sse = sse;
    }

    public int previewCount(String targetType, List<Long> memberList) {
        if ("ALL".equalsIgnoreCase(targetType)) {
            return mapper.countPreviewAll();
        }
        return (memberList == null || memberList.isEmpty())
                ? 0 : mapper.countPreviewList(memberList);
    }

    @Transactional
    public long createAndSend(String title, String content,
                              String targetType, List<Long> memberList, String adminId) {
        var row = new AdminPushRow();
        row.setTitle(title);
        row.setContent(content);
        row.setTargetType(targetType);
        row.setCreatedBy(adminId);
        mapper.insertPush(row); // RETURNING으로 pushNo 채워짐

        if ("MEMBER_LIST".equalsIgnoreCase(targetType) && memberList != null) {
            for (Long m : memberList) {
                mapper.insertPushTarget(row.getPushNo(), m);
            }
        }

        var recipients = mapper.selectRecipientsForPush(row.getPushNo());

        var payload = Map.<String,Object>of(
            "pushNo", row.getPushNo(),
            "title",  row.getTitle(),
            "body",   row.getContent(),
            "ts",     System.currentTimeMillis()
        );

        for (Long memberNo : recipients) {
            sse.sendToMember(memberNo, "marketing", payload, true);
        }
        return row.getPushNo();
    }

    public Map<String,Object> list(int page, int size) {
        int offset = page * size;
        var rows = mapper.selectPushList(offset, size);
        int total = mapper.countPushList();
        return Map.of("total", total, "page", page, "size", size, "rows", rows);
    }
}
