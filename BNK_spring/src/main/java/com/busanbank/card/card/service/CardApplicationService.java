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

    /** Step 0. 신청 시작 */
    public Long createApplication(CardApplicationDTO dto) {
        mapper.insertCardApplication(dto);
        return dto.getApplicationNo(); // selectKey로 채워짐
    }

    /** Step 1. 개인정보 입력 저장 */
    public void saveUserInfo(ApplicationUserInfoDTO dto) {
        mapper.insertUserInfo(dto);
    }

    /** Step 2. 약관 동의 리스트 저장 (List 버전) */
    public void saveAgreements(List<ApplicationTermsDTO> terms) {
        for (ApplicationTermsDTO dto : terms) {
            mapper.insertAgreement(dto);
        }
    }

    /** Step 2. 약관 동의 (applicationNo + termNos로 받는 JSP용 버전) */
    public void saveAgreementTerms(Long applicationNo, List<Long> termNos) {
        for (Long termNo : termNos) {
            ApplicationTermsDTO dto = new ApplicationTermsDTO();
            dto.setApplicationNo(applicationNo);
            dto.setTermNo(termNo);
            mapper.insertAgreement(dto);
        }
    }

    /** Step 3. 서명 저장 */
    public void saveSign(ApplicationSignDTO dto) {
        mapper.insertSign(dto);
    }

    /** 카드별 약관 매핑 불러오기 */
    public List<CardPdfMappingDTO> getCardTerms(Long cardNo) {
        return mapper.getCardTermsByCardNo(cardNo);
    }
    
    public Long getCardNoByApplication(Long applicationNo) {
        return mapper.selectCardNoByApplication(applicationNo);
    }

}
