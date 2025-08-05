package com.busanbank.card.card.service;


import com.busanbank.card.card.dao.CardApplicationMapper;
import com.busanbank.card.card.dto.ApplicationSignDTO;
import com.busanbank.card.card.dto.ApplicationTermsDTO;
import com.busanbank.card.card.dto.ApplicationUserInfoDTO;
import com.busanbank.card.card.dto.CardApplicationDTO;
import com.busanbank.card.card.dto.CardPdfMappingDTO;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CardApplicationService {

    @Autowired
    private CardApplicationMapper mapper;

    /** Step 0. 신청 시작 (CARD_APPLICATION) */
    public void createApplication(CardApplicationDTO dto) {
        mapper.insertCardApplication(dto);
    }

    /** Step 1. 개인정보 입력 저장 (APPLICATION_USER_INFO) */
    public void saveUserInfo(ApplicationUserInfoDTO dto) {
        mapper.insertUserInfo(dto);
    }

    /** Step 2. 약관 동의 내역 저장 (APPLICATION_TERMS) */
    public void saveAgreements(List<ApplicationTermsDTO> terms) {
        for (ApplicationTermsDTO dto : terms) {
            mapper.insertAgreement(dto);
        }
    }

    /** Step 3. 서명 및 본인 인증 저장 (APPLICATION_SIGN) */
    public void saveSignature(ApplicationSignDTO dto) {
        mapper.insertSign(dto);
    }

    /** Step 2 - 추가: 카드에 연결된 약관 목록 조회 */
    public List<CardPdfMappingDTO> getCardTerms(Long cardNo) {
        return mapper.getCardTermsByCardNo(cardNo);
    }
}
