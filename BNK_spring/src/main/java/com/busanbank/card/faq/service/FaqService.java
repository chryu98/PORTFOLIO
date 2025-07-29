package com.busanbank.card.faq.service;

import com.busanbank.card.faq.dao.FaqDao;
import com.busanbank.card.faq.dto.FaqDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FaqService {

    @Autowired
    private FaqDao faqDao;

    public List<FaqDto> getAllFaqs() {
        return faqDao.getAllFaqs();
    }

    public List<FaqDto> searchFaqs(String keyword) {
        return faqDao.searchFaqs(keyword);
    }

    public void insertFaq(FaqDto dto) {
        faqDao.insertFaq(dto);
    }

    public void updateFaq(FaqDto dto) {
        faqDao.updateFaq(dto);
    }

    public void deleteFaq(Long faqNo) {
        faqDao.deleteFaq(faqNo);
    }

    public FaqDto getFaqById(int faqNo) {
        return faqDao.getFaqById(faqNo);
    }
}
