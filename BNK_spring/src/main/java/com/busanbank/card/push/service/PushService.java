// src/main/java/com/busanbank/card/push/service/PushService.java
package com.busanbank.card.push.service;

import com.busanbank.card.push.dto.PushDto;
import com.busanbank.card.push.mapper.PushMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PushService {
    private final PushMapper mapper;

    public PushDto save(PushDto dto) {
        mapper.insert(dto);
        return dto;
    }
}
