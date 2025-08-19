package com.busanbank.card.custom;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class CardEditorController {
	@GetMapping("/editor/card")
    public String cardEditor() {
        return "custom"; 
    }
}
