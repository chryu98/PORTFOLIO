package com.busanbank.card.admin.service;

import com.busanbank.card.admin.dao.AdminPushMapper;
import com.busanbank.card.admin.dto.AdminPushRow;
import com.busanbank.card.sse.SsePushService;
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

        // 키 생성: IDENTITY면 useGeneratedKeys로 자동 주입, 시퀀스면 selectKey로 주입
        mapper.insertPush(row);

        if ("MEMBER_LIST".equalsIgnoreCase(targetType) && memberList != null && !memberList.isEmpty()) {
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

    @Transactional(readOnly = true)
    public Map<String,Object> list(int page, int size) {
        int safePage = Math.max(0, page);
        int safeSize = Math.max(1, size);
        int offset = safePage * safeSize;
        var rows = mapper.selectPushList(offset, safeSize);
        int total = mapper.countPushList();
        return Map.of("total", total, "page", safePage, "size", safeSize, "rows", rows);
    }
}
