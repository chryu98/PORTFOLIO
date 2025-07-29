package com.busanbank.card.faq.servlet;

import com.busanbank.card.faq.dto.FaqDto;
import com.busanbank.card.faq.service.FaqService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/admin/faq/faqList")
public class FAQListServlet extends HttpServlet {
    private FaqService faqService = new FaqService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String keyword = request.getParameter("keyword");
        List<FaqDto> faqList;

        if (keyword != null && !keyword.trim().isEmpty()) {
            faqList = faqService.searchFaqs(keyword);
        } else {
            faqList = faqService.getAllFaqs();
        }

        request.setAttribute("faqList", faqList);
        request.setAttribute("keyword", keyword);
        request.getRequestDispatcher("/faq/list.jsp").forward(request, response);
    }
}
