// src/main/java/com/busanbank/card/push/controller/ConsentController.java
package com.busanbank.card.push.controller;

import com.busanbank.card.push.mapper.MemberMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequiredArgsConstructor
public class ConsentController {
  private final MemberMapper memberMapper;

  @PutMapping("/me/push-consent")
  public Map<String,Object> setConsent(@RequestParam long memberNo, @RequestBody Map<String,String> req) {
    String pushYn = "Y".equalsIgnoreCase(req.getOrDefault("pushYn","N")) ? "Y" : "N";
    memberMapper.upsertConsent(memberNo, pushYn);
    return Map.of("memberNo", memberNo, "pushYn", pushYn);
  }
}
