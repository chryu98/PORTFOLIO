package com.busanbank.card.cardapply.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class SignTestController {

  @GetMapping("/sign/test")
  public String signTest() {
    // /WEB-INF/views/signTest.jsp 로 렌더 (prefix/suffix 설정 가정)
    return "signTest";
  }
}
