package com.busanbank.card.card.controller;

import com.busanbank.card.card.dto.*;
import com.busanbank.card.card.service.CardApplicationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/application")
public class CardApplicationController {

    @Autowired
    private CardApplicationService service;

    /** Step 0. 카드 발급 신청 시작 */
    @PostMapping("/start")
    public String startApplication(@RequestBody CardApplicationDTO dto) {
        service.createApplication(dto);
        return "신청 등록 완료";
    }

    /** Step 1. 사용자 기본정보 입력 */
    @PostMapping("/userinfo")
    public String saveUserInfo(@RequestBody ApplicationUserInfoDTO dto) {
        service.saveUserInfo(dto);
        return "기본 정보 저장 완료";
    }

    /** Step 2. 약관 동의 저장 */
    @PostMapping("/terms")
    public String saveAgreements(@RequestBody List<ApplicationTermsDTO> agreements) {
        service.saveAgreements(agreements);
        return "약관 동의 완료";
    }

    /** Step 2-1. 카드에 해당하는 약관 PDF 목록 조회 */
    @GetMapping("/terms/{cardNo}")
    public List<CardPdfMappingDTO> getTermsByCard(@PathVariable Long cardNo) {
        return service.getCardTerms(cardNo);
    }

    /** Step 3. 서명 및 신분증 이미지 업로드 */
    @PostMapping("/sign")
    public String saveSignature(@ModelAttribute ApplicationSignDTO dto) {
        service.saveSignature(dto);
        return "서명 및 인증 완료";
    }
}
