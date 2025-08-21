package com.busanbank.card.admin.controller;

import com.busanbank.card.admin.dto.CardInsightDto;
import com.busanbank.card.admin.service.RecoService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

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
}

