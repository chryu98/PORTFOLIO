package com.busanbank.card.card.controller;

import java.io.IOException;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import com.busanbank.card.card.dto.ApplicationSignDTO;
import com.busanbank.card.card.dto.ApplicationUserInfoDTO;
import com.busanbank.card.card.dto.CardApplicationDTO;
import com.busanbank.card.card.dto.CardPdfMappingDTO;
import com.busanbank.card.card.service.CardApplicationService;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.service.SessionService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/application")
public class CardApplicationController {

    @Autowired
    private CardApplicationService service;
    @Autowired
    private SessionService sessionService;

    // ✅ [GET] Step 0 - 카드 신청 시작 페이지
    @GetMapping("/startForm")
    public String applicationStartForm(@RequestParam("cardNo") Long cardNo, Model model) {
        model.addAttribute("cardNo", cardNo);
        return "applicationStartForm";
    }

    // ✅ [POST] Step 0 - 카드 신청 시작 처리
    @PostMapping("/start")
    public String insertApplication(CardApplicationDTO dto) {
        Long appNo = service.createApplication(dto);
        return "redirect:/application/userInfoForm?applicationNo=" + appNo;
    }

    // ✅ [GET] Step 1 - 개인정보 입력 페이지
    @GetMapping("/userInfoForm")
    public String userInfoForm(HttpSession session, Model model) {
        UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
        if (loginUser == null) {
            return "user/userInfoForm";
        }
        return "user/userInfoForm";
    }

    // ✅ [POST] Step 1 - 개인정보 입력 저장 처리
    @PostMapping("/userInfoSubmit")
    public String insertUserInfo(@ModelAttribute ApplicationUserInfoDTO dto) {
        service.saveUserInfo(dto);
        return "redirect:/application/termsForm?applicationNo=" + dto.getApplicationNo();
    }

    // ✅ [GET] Step 2 - 약관 동의 페이지
    @GetMapping("/termsForm")
    public String termsForm(@RequestParam("applicationNo") Long applicationNo, Model model) {
        model.addAttribute("applicationNo", applicationNo);

        // 카드 번호 가져오기
        Long cardNo = service.getCardNoByApplication(applicationNo);

        // 카드에 해당하는 약관 리스트 가져오기
        List<CardPdfMappingDTO> terms = service.getCardTerms(cardNo);
        model.addAttribute("terms", terms);

        return "termsForm";
    }

    // ✅ [POST] Step 2 - 약관 동의 처리
    @PostMapping("/termsSubmit")
    public String insertTerms(@RequestParam("applicationNo") Long applicationNo,
                              @RequestParam("termNos") List<Long> termNos) {
        service.saveAgreementTerms(applicationNo, termNos);
        return "redirect:/application/signForm?applicationNo=" + applicationNo;
    }

    // ✅ [GET] Step 3 - 서명 페이지
    @GetMapping("/signForm")
    public String signForm(@RequestParam("applicationNo") Long applicationNo, Model model) {
        model.addAttribute("applicationNo", applicationNo);
        return "signForm";
    }

    // ✅ [POST] Step 3 - 서명 제출 처리
    @PostMapping("/signSubmit")
    public String insertSign(@ModelAttribute ApplicationSignDTO dto,
                             @RequestParam("signFile") MultipartFile signFile,
                             @RequestParam("idFile") MultipartFile idFile) throws IOException {
        dto.setSignImage(signFile.getBytes());
        dto.setIdImage(idFile.getBytes());
        service.saveSign(dto);
        return "redirect:/cardList";
    }
}
