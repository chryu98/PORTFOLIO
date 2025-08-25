package com.busanbank.card.admin.controller;

import com.busanbank.card.admin.dao.JourneyChurnMapper;
import com.busanbank.card.admin.dto.CardOption;
import com.busanbank.card.admin.dto.DropMemberRow;
import com.busanbank.card.admin.dto.StepChurnRow;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/admin/api/journey")
@RequiredArgsConstructor
public class JourneyChurnRestController {

    private final JourneyChurnMapper mapper;

    private Date toDate(LocalDate d) {
        return d == null ? null : Date.from(d.atStartOfDay(ZoneId.systemDefault()).toInstant());
    }

    @GetMapping("/cards")
    public List<CardOption> cards(@RequestParam(name = "activeOnly", required = false) String activeOnly) {
        return mapper.selectCards(activeOnly);
    }

    // ✅ LEGACY 요약 엔드포인트 (발급/취소 옵션 제거, isCredit 제거)
    @GetMapping("/drop-legacy/by-card")
    public List<StepChurnRow> byCardLegacy(
            @RequestParam(name = "cardNo") Long cardNo,
            @RequestParam(name = "from", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(name = "to", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(name = "limitPerCard", defaultValue = "20") Integer limitPerCard
    ) {
        return mapper.selectCardStepChurnSummary(
                toDate(from), toDate(to), cardNo, limitPerCard
        );
    }

    // ✅ 상세 엔드포인트 (성별/나이 포함, isCredit 제거)
    @GetMapping("/drop-legacy/by-card/details")
    public List<DropMemberRow> detailsLegacy(
            @RequestParam(name = "cardNo") Long cardNo,
            @RequestParam(name = "fromStepCode") String fromStepCode,
            @RequestParam(name = "from", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(name = "to", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to
    ) {
        return mapper.selectChurnMembersAtStep(cardNo, fromStepCode, toDate(from), toDate(to));
    }
}
