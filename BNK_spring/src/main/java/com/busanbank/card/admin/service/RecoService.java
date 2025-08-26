package com.busanbank.card.admin.service;

import com.busanbank.card.admin.dao.RecoMapper;
import com.busanbank.card.admin.dto.CardInsightDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

//com.busanbank.card.admin.service.RecoService
@Service
@RequiredArgsConstructor
public class RecoService {
 private final RecoMapper mapper;

 public List<CardInsightDto> popular(int days, int limit) { return mapper.selectPopular(days, limit); }
 public List<CardInsightDto> similar(long cardNo, int days, int limit) { return mapper.selectSimilar(cardNo, days, limit); }

 public List<CardInsightDto> similarByName(String name, int days, int limit) {
     Long cardNo = mapper.findTopCardNoByName(name, days);
     if (cardNo == null) return Collections.emptyList();
     return mapper.selectSimilar(cardNo, days, limit);
 }

 public List<CardInsightDto> kpi(int days) { return mapper.selectKpi(days); }

 public List<CardInsightDto> logs(Long memberNo, Long cardNo, String type, String from, String to, int page, int size) {
     int offset = Math.max(0, (page - 1) * size);
     return mapper.selectLogs(memberNo, cardNo, type, from, to, offset, size);
 }

 // ★ 자동완성
 public List<CardInsightDto> searchCards(String q){ return mapper.searchCards(q); }
 public List<CardInsightDto> searchMembers(String q){ return mapper.searchMembers(q); }

 
//★ 추가: 행동 로그 INSERT
public void insertBehaviorLog(Long memberNo, Long cardNo, String type, String isoTime,
                              String device, String ua, String ip) {
  mapper.insertBehaviorLog(memberNo, cardNo, type, isoTime, device, ua, ip);
}

}

