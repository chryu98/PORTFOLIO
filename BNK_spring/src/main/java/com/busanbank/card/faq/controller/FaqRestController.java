package com.busanbank.card.faq.controller;

import com.busanbank.card.faq.dao.FaqDao;
import com.busanbank.card.faq.dto.FaqDto;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/faq")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FaqRestController {

    private final FaqDao faqDao;

    // 1) 경로/스캔 확인용 핑
    @GetMapping("/ping")
    public Map<String, Object> ping() {
        return Map.of("ok", true, "ts", System.currentTimeMillis());
    }

    // 2) FAQ 목록 (query, page, size만)
    @GetMapping
    public Map<String, Object> list(
        @RequestParam(value = "query", required = false, defaultValue = "") String query,
        @RequestParam(value = "page",  required = false, defaultValue = "0") Integer page,
        @RequestParam(value = "size",  required = false, defaultValue = "20") Integer size
    ) {
        int startRow = page * size + 1;
        int endRow   = (page + 1) * size;

        List<FaqDto> content = faqDao.searchFaqsWithPaging(query, startRow, endRow);
        int total = faqDao.countFaqs(query);
        boolean last = (page + 1) * size >= total;

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("content", content);
        resp.put("last", last);
        resp.put("totalElements", total);
        resp.put("page", page);
        resp.put("size", size);
        return resp;
    }
}
