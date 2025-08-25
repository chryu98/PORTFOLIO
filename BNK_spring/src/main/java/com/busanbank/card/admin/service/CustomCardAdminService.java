package com.busanbank.card.admin.service;

import com.busanbank.card.admin.mapper.CustomCardAdminMapper;
import com.busanbank.card.custom.dto.CustomCardDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CustomCardAdminService {

    private final CustomCardAdminMapper mapper;

    public int count(String aiResult, Long memberNo, String status) {
        return mapper.countCards(aiResult, memberNo, status);
    }

    public List<CustomCardDto> list(String aiResult, Long memberNo, String status, int page, int size) {
        int offset = Math.max(page, 0) * Math.max(size, 1);
        return mapper.findCards(aiResult, memberNo, status, offset, size);
    }

    public CustomCardDto detail(Long customNo) {
        return mapper.findOne(customNo);
    }

    // 선택: 추후 승인/반려
    public int updateStatus(Long customNo, String status, String reason) {
        return mapper.updateStatus(customNo, status, reason);
    }
}
