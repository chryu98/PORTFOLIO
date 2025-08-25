package com.busanbank.card.admin.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.dto.CardInsightDto;
import com.busanbank.card.admin.service.RecoService;

import jakarta.servlet.http.HttpServletRequest;
import lombok.Data;
import lombok.RequiredArgsConstructor;

//com.busanbank.card.admin.controller.RecoController
@RestController
@RequestMapping("/admin/reco")
@RequiredArgsConstructor
public class RecoController {
 private final RecoService service;

 @GetMapping("/popular")
 public List<CardInsightDto> popular(@RequestParam(name="days", defaultValue="30") int days,
                                     @RequestParam(name="limit", defaultValue="10") int limit) {
     return service.popular(days, limit);
 }

 @GetMapping("/kpi")
 public List<CardInsightDto> kpi(@RequestParam(name="days", defaultValue="30") int days) {
     return service.kpi(days);
 }

 @GetMapping("/logs")
 public List<CardInsightDto> logs(@RequestParam(name="memberNo", required=false) Long memberNo,
                                  @RequestParam(name="cardNo",   required=false) Long cardNo,
                                  @RequestParam(name="type",     required=false) String type,
                                  @RequestParam(name="from",     required=false) String from,
                                  @RequestParam(name="to",       required=false) String to,
                                  @RequestParam(name="page", defaultValue="1") int page,
                                  @RequestParam(name="size", defaultValue="20") int size) {
     return service.logs(memberNo, cardNo, type, from, to, page, size);
 }

 @GetMapping("/similar/{key}")
 public List<CardInsightDto> similar(@PathVariable("key") String key,
                                     @RequestParam(name="days", defaultValue="30") int days,
                                     @RequestParam(name="limit", defaultValue="10") int limit) {
     if (key != null && key.matches("\\d+")) {
         return service.similar(Long.parseLong(key), days, limit);
     }
     return service.similarByName(key, days, limit);
 }

 // ★ 자동완성 (JSP가 호출)
 @GetMapping("/search/cards")
 public List<CardInsightDto> searchCards(@RequestParam(name="q", required=false) String q) {
     return service.searchCards(q);
 }
 @GetMapping("/search/members")
 public List<CardInsightDto> searchMembers(@RequestParam(name="q", required=false) String q) {
     return service.searchMembers(q);
 }
 
 
 
 
 
 /**
  * 앱에서 행동 로그를 적재하는 엔드포인트.
  * Flutter에서 POST ${API.baseUrl}/admin/reco/log 로 호출하면 CARD_BEHAVIOR_LOG 에 INSERT 됩니다.
  * - 시퀀스: SEQ_CARD_BEHAVIOR_LOG.NEXTVAL 사용 (XML에 반영되어 있어야 함)
  * - behaviorTime 은 ISO8601(UTC) 문자열을 기대 (예: 2025-08-26T02:30:00Z)
  */
 @PostMapping("/log")
 public void insertBehaviorLog(@RequestBody BehaviorLogReq req, HttpServletRequest http) {
   String ip = http.getHeader("X-Forwarded-For");
   if (ip == null || ip.isEmpty()) ip = http.getRemoteAddr();

   service.insertBehaviorLog(
       req.getMemberNo(),
       req.getCardNo(),
       req.getBehaviorType(),
       req.getBehaviorTime(),
       req.getDeviceType(),
       req.getUserAgent(),
       ip
   );
 }

 @Data
 public static class BehaviorLogReq {
   private Long memberNo;       // 로그인 전이면 null 허용
   private Long cardNo;         // 필수
   private String behaviorType; // VIEW | CLICK | APPLY
   private String behaviorTime; // ISO8601(UTC) 문자열 (예: 2025-08-26T02:30:00Z)
   private String deviceType;   // MOBILE | PC ...
   private String userAgent;
 }
}

