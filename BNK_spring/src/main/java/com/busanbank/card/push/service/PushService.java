// src/main/java/com/busanbank/card/push/service/PushService.java
package com.busanbank.card.push.service;

import com.busanbank.card.push.dto.PushDto;
import com.busanbank.card.push.mapper.MemberMapper;
import com.busanbank.card.push.mapper.PushMapper;
import com.busanbank.card.push.ws.PushWsService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PushService {
  private final PushMapper pushMapper;
  private final MemberMapper memberMapper;
  private final PushWsService ws;

  public long sendAll(String title, String content, String createdBy) {
    PushDto row = new PushDto();
    row.setTitle(title);
    row.setContent(content);
    row.setTargetType("ALL");
    row.setCreatedBy(createdBy);
    pushMapper.insert(row);

    List<Long> targets = memberMapper.findConsentMemberNos();
    ws.sendToMembers(targets, title, content);
    return row.getPushNo();
  }

  public long sendByAge(String title, String content, String createdBy, Integer ageFrom, Integer ageTo) {
    PushDto row = new PushDto();
    row.setTitle(title);
    row.setContent(content);
    row.setTargetType("ALL");
    row.setCreatedBy(createdBy);
    pushMapper.insert(row);

    List<Long> targets = memberMapper.findConsentMemberNosByAge(ageFrom, ageTo);
    ws.sendToMembers(targets, title, content);
    return row.getPushNo();
  }
}
