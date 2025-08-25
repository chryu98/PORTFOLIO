// com.busanbank.card.admin.controller.ModerationAdminViewController
package com.busanbank.card.admin.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ModerationAdminViewController {

    @GetMapping("/admin/custom-cards")
    public String customCardsPage() {
        // /WEB-INF/views/admin/custom_cards.jsp 로 forward
        return "admin/custom_cards";
    }
}
