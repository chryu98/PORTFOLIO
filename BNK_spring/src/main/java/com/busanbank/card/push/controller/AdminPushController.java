// src/main/java/com/busanbank/card/push/controller/AdminPushController.java
package com.busanbank.card.push.controller;

import com.busanbank.card.push.service.PushService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/push")
public class AdminPushController {
  private final PushService pushService;

  @PostMapping("/send")
  public Map<String,Object> createAndSend(@RequestBody Map<String,String> req) {
    String title = req.getOrDefault("title", "");
    String content = req.getOrDefault("content", "");
    String createdBy = req.getOrDefault("createdBy", "admin");
    long pushNo = pushService.sendAll(title, content, createdBy);
    return Map.of("pushNo", pushNo);
  }

  @PostMapping("/send/age")
  public Map<String,Object> sendByAge(@RequestBody Map<String,Object> req) {
    String title = (String) req.getOrDefault("title", "");
    String content = (String) req.getOrDefault("content", "");
    String createdBy = (String) req.getOrDefault("createdBy", "admin");
    Integer ageFrom = (Integer) req.getOrDefault("ageFrom", 20);
    Integer ageTo   = (Integer) req.getOrDefault("ageTo", 29);
    long pushNo = pushService.sendByAge(title, content, createdBy, ageFrom, ageTo);
    return Map.of("pushNo", pushNo, "ageFrom", ageFrom, "ageTo", ageTo);
  }
}
