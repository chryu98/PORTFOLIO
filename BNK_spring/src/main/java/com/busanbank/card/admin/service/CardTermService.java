// src/main/java/com/busanbank/card/admin/service/CardTermService.java
package com.busanbank.card.admin.service;

import com.busanbank.card.card.dto.CardDto;
import com.busanbank.card.admin.dto.PdfFile;
import com.busanbank.card.admin.dto.CardTermDto;
import com.busanbank.card.admin.dao.CardTermMapper; // ✅ dao로 수정
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CardTermService {

    private final CardTermMapper mapper; // ✅ 타입 일치

    public List<CardDto> searchCards(String q){ return mapper.searchCards(q); }
    public List<PdfFile> searchPdfs(String q, String scope, String active){ return mapper.searchPdfs(q, scope, active); }

    public List<CardTermDto> listTermsByCard(Long cardNo){ return mapper.listTermsByCard(cardNo); }
    public void upsertCardTerm(CardTermDto t){ mapper.upsertCardTerm(t); }
    public void updateCardTerm(CardTermDto t){ mapper.updateCardTerm(t); }
    public void deleteCardTerm(Long cardNo, Long pdfNo){ mapper.deleteCardTerm(cardNo, pdfNo); }
}
