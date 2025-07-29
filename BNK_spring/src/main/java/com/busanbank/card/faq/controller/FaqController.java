package com.busanbank.card.faq.controller;

import com.busanbank.card.faq.dao.FaqDao;
import com.busanbank.card.faq.dto.FaqDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Controller
@RequestMapping("/faq")
public class FaqController {

    @Autowired
    private FaqDao faqDao;

    @GetMapping("/list")
    public String getUserFaqList(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "page", defaultValue = "1") int page,
            Model model) {

        int pageSize = 10;
        int startRow = (page - 1) * pageSize + 1;
        int endRow = page * pageSize;

        System.out.println("keyword = " + keyword);

        List<FaqDto> list = faqDao.searchFaqsWithPaging(
                (keyword != null) ? keyword : "",
                startRow,
                endRow
        );

    
        int totalCount = faqDao.countFaqs(keyword != null ? keyword : "");
        int totalPage = (int) Math.ceil(totalCount / (double) pageSize);

        model.addAttribute("faqList", list);
        model.addAttribute("keyword", keyword);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPage", totalPage);

        return "faq";
    }
    
    

}
