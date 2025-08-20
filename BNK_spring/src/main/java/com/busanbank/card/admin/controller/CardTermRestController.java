// src/main/java/com/busanbank/card/admin/controller/CardTermRestController.java
package com.busanbank.card.admin.controller;

import com.busanbank.card.card.dto.CardDto;
import com.busanbank.card.admin.dto.PdfFile;
import com.busanbank.card.admin.dto.CardTermDto;
import com.busanbank.card.admin.service.CardTermService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/api")
public class CardTermRestController {

    private final CardTermService svc;

    @GetMapping("/cards")
    public List<CardDto> searchCards(@RequestParam(name = "q", required = false) String q){
        return svc.searchCards(q);
    }

    @GetMapping("/pdfs")
    public List<PdfFile> searchPdfs(@RequestParam(name = "q", required = false) String q,
                                    @RequestParam(name = "scope", required = false) String scope,
                                    @RequestParam(name = "active", required = false) String active){
        return svc.searchPdfs(q, scope, active);
    }

    @GetMapping("/cards/{cardNo}/terms")
    public List<CardTermDto> listTerms(@PathVariable("cardNo") Long cardNo){
        return svc.listTermsByCard(cardNo);
    }

    @PostMapping("/cards/{cardNo}/terms")
    public void upsertTerm(@PathVariable("cardNo") Long cardNo, @RequestBody CardTermDto req){
        req.setCardNo(cardNo);
        if(req.getIsRequired()==null) req.setIsRequired("Y");
        svc.upsertCardTerm(req);
    }

    @PutMapping("/cards/{cardNo}/terms/{pdfNo}")
    public void updateTerm(@PathVariable("cardNo") Long cardNo,
                           @PathVariable("pdfNo") Long pdfNo,
                           @RequestBody CardTermDto req){
        req.setCardNo(cardNo);
        req.setPdfNo(pdfNo);
        svc.updateCardTerm(req);
    }

    @DeleteMapping("/cards/{cardNo}/terms/{pdfNo}")
    public void deleteTerm(@PathVariable("cardNo") Long cardNo,
                           @PathVariable("pdfNo") Long pdfNo){
        svc.deleteCardTerm(cardNo, pdfNo);
    }
}

