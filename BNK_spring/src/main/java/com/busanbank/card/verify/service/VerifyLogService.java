package com.busanbank.card.verify.service;

import com.busanbank.card.verify.entity.VerifyLog;
import com.busanbank.card.verify.repository.VerifyLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class VerifyLogService {
    private final VerifyLogRepository repository;

    public void save(VerifyLog log) {
        repository.save(log);
    }
}
