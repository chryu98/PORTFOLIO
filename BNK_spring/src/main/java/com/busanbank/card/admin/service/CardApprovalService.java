package com.busanbank.card.admin.service;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.ApplicationPersonDto;
import com.busanbank.card.cardapply.dto.CardApplicationDto;

@Service
public class CardApprovalService {

    private final ICardApplyDao cardApplyDao;

    public CardApprovalService(ICardApplyDao cardApplyDao) {
        this.cardApplyDao = cardApplyDao;
    }

    public List<CardApplicationDto> getCardApplicationsWithRecommendation() {
        List<CardApplicationDto> cards = cardApplyDao.findCreditCard();

        if(cards.isEmpty()) return Collections.emptyList();

        List<ApplicationPersonDto> persons = cardApplyDao.findPersonForApplications(
                cards.stream().map(CardApplicationDto::getApplicationNo).toList()
        );

        Map<Integer, ApplicationPersonDto> personMap = persons.stream()
                .collect(Collectors.toMap(ApplicationPersonDto::getApplicationNo, Function.identity()));

        // 추천 로직
        for(CardApplicationDto card : cards) {
            ApplicationPersonDto person = personMap.get(card.getApplicationNo());
            card.setRecommendation(calculateRecommendation(person));
        }

        return cards;
    }

    private String calculateRecommendation(ApplicationPersonDto person) {
        if(person == null) return "HOLD";

        String job = person.getJob();
        String purpose = person.getPurpose();
        String fundSource = person.getFundSource();

        // 예시 로직
        if("무직".equals(job)) {
            if("투자".equals(purpose) || "고액결제".equals(purpose)) return "REJECT";
            return "APPROVE";
        }

        if("학생".equals(job)) {
            if(Arrays.asList("급여이체","투자","고액결제").contains(purpose)) return "REJECT";
            return "APPROVE";
        }

        if("주부".equals(job)) {
            if(Arrays.asList("투자","고액결제").contains(purpose)) return "HOLD";
            return "APPROVE";
        }

        // 직장인/자영업/프리랜서
        if(Arrays.asList("직장인","자영업자","프리랜서").contains(job)) {
            if(Arrays.asList("투자","고액결제").contains(purpose) 
               && !"근로소득".equals(fundSource) && !"사업소득".equals(fundSource)
               && !"금융소득".equals(fundSource)) return "HOLD";
            return "APPROVE";
        }

        // 기타 소득 체크
        if("기타소득".equals(fundSource) && (person.getPurpose() == null || person.getPurpose().isEmpty())) {
            return "REJECT";
        }

        return "HOLD"; // 기본 보류
    }
}

