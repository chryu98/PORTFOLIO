package com.busanbank.card.admin.service;

import java.util.Collections;
import java.util.List;

import org.springframework.stereotype.Service;

import com.busanbank.card.admin.dao.RecoMapper;
import com.busanbank.card.admin.dto.CardInsightDto;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RecoService {
    private final RecoMapper mapper;

    public List<CardInsightDto> popular(int days, int limit) {
        return mapper.selectPopular(days, limit);
    }

    public List<CardInsightDto> similar(long cardNo, int days, int limit) {
        return mapper.selectSimilar(cardNo, days, limit);
    }

    // 새로 추가: 이름으로 기준 카드 해석
    public List<CardInsightDto> similarByName(String name, int days, int limit) {
        Long cardNo = mapper.findTopCardNoByName(name, days);
        if (cardNo == null) return Collections.emptyList();
        return mapper.selectSimilar(cardNo, days, limit);
    }

    public List<CardInsightDto> kpi(int days) {
        return mapper.selectKpi(days);
    }

    public List<CardInsightDto> logs(Long memberNo, Long cardNo, String type, String from, String to, int page, int size) {
        int offset = Math.max(0, (page - 1) * size);
        return mapper.selectLogs(memberNo, cardNo, type, from, to, offset, size);
    }
}
