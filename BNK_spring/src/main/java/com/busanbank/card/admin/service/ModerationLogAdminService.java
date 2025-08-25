package com.busanbank.card.admin.service;

import com.busanbank.card.admin.dto.ModerationLogDto;
import com.busanbank.card.admin.dto.ModerationLogSearchDto;
import com.busanbank.card.admin.mapper.ModerationLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ModerationLogAdminService {

    private final ModerationLogMapper mapper;

    private String plusOneDay(String to) {
        if (to == null || to.isBlank()) return null;
        LocalDate d = LocalDate.parse(to, DateTimeFormatter.ISO_DATE);
        return d.plusDays(1).format(DateTimeFormatter.ISO_DATE);
    }

    public int count(ModerationLogSearchDto s) {
        return mapper.countLogs(s, plusOneDay(s.getTo()));
    }

    public List<ModerationLogDto> list(ModerationLogSearchDto s) {
        int page = (s.getPage() == null || s.getPage() < 1) ? 1 : s.getPage();
        int size = (s.getSize() == null || s.getSize() < 1) ? 20 : s.getSize();
        int offset = (page - 1) * size;
        return mapper.findLogs(s, offset, size, plusOneDay(s.getTo()));
    }
}
