package com.busanbank.card.card.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.card.dto.ApplicationSignDTO;
import com.busanbank.card.card.dto.ApplicationTermsDTO;
import com.busanbank.card.card.dto.ApplicationUserInfoDTO;
import com.busanbank.card.card.dto.CardApplicationDTO;
import com.busanbank.card.card.dto.CardPdfMappingDTO;

@Mapper
public interface CardApplicationMapper {

    // Step 0. 카드 발급 신청 시작
    void insertCardApplication(CardApplicationDTO dto);

    // Step 1. 사용자 기본정보 저장
    void insertUserInfo(ApplicationUserInfoDTO dto);

    // Step 2. 사용자 약관 동의 저장
    void insertAgreement(ApplicationTermsDTO dto);

    // Step 3. 서명 및 인증 이미지 저장
    void insertSign(ApplicationSignDTO dto);

    // (선택) 카드번호로 해당 약관 PDF 목록 불러오기
    List<CardPdfMappingDTO> getCardTermsByCardNo(Long cardNo);
    
    Long selectCardNoByApplication(Long applicationNo);
}
