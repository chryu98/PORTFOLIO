package com.busanbank.card.cardapply.controller;

import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.card.dao.CardDao;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.AddressDto;
import com.busanbank.card.cardapply.dto.CardOptionDto;
import com.busanbank.card.cardapply.dto.PdfFilesDto;
import com.busanbank.card.cardapply.dto.TermsAgreementRequest;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/api/card/apply")
public class CardApplyApiController {

    @Autowired
    private IUserDao userDao;
    @Autowired
    private CardDao cardDao;
    @Autowired
    private ICardApplyDao cardApplyDao;

    @GetMapping("/card-terms")
    public List<PdfFilesDto> getCardTerms(@RequestParam("cardNo") long cardNo) {
    	List<PdfFilesDto> terms = cardApplyDao.getTermsByCardNo(cardNo);

        for (PdfFilesDto term : terms) {
            if (term.getPdfData() != null) {
                // byte[] → Base64 문자열
                term.setPdfDataBase64(Base64.getEncoder().encodeToString(term.getPdfData()));
                term.setPdfData(null); // JSON 전송 시 byte[] 제거
            }
        }
        return terms;
    }
    
    @PostMapping("/terms-agree")
    public ResponseEntity<String> agreeTerms(@RequestBody TermsAgreementRequest request) {
        if (request.getPdfNos() == null || request.getPdfNos().isEmpty()) {
            return ResponseEntity.badRequest().body("동의한 약관이 없습니다.");
        }

        for (Long pdfNo : request.getPdfNos()) {
            cardApplyDao.insertAgreement(request.getMemberNo(), request.getCardNo(), pdfNo);
        }

        return ResponseEntity.ok("약관 동의 저장 완료");
    }
    
    @GetMapping("/get-customer-info")
    public Map<String, Object> getCustomerInfo(@RequestParam("cardNo") int cardNo, HttpSession session) throws Exception {
        Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
        
        if (memberNo == null) {
            throw new RuntimeException("로그인이 필요한 서비스입니다.");
        }

        UserDto loginUser = userDao.findByMemberNo(memberNo);
        String rrnTailEnc = AESUtil.decrypt(loginUser.getRrnTailEnc());
        String rrnBack = loginUser.getRrnGender() + rrnTailEnc;

        Map<String, Object> result = new HashMap<>();
        result.put("loginUser", loginUser);
        result.put("rrnBack", rrnBack);

        return result; // JSON 반환
    }
    
    @GetMapping("/customer-info")
    public ResponseEntity<?> getCustomerInfo(
            @RequestParam("cardNo") int cardNo,
            Authentication authentication) throws Exception {

        // JWT 인증이 안 됐을 경우
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                 .body(Map.of("error", "로그인이 필요합니다."));
        }

        // JWT에서 추출된 사용자 ID
        String username = authentication.getName();
        UserDto loginUser = userDao.findByUsername(username);

        if (loginUser == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                                 .body(Map.of("error", "사용자 정보 없음"));
        }

        String rrnTailEnc = AESUtil.decrypt(loginUser.getRrnTailEnc());
        String rrnBack = loginUser.getRrnGender() + rrnTailEnc;

        return ResponseEntity.ok(Map.of(
            "loginUser", loginUser,
            "rrnBack", rrnBack,
            "cardNo", cardNo
        ));
    }
    
    @GetMapping("/address-home")
    public ResponseEntity<?> getAddress(@RequestParam("memberNo")int memberNo) {
    	AddressDto address = cardApplyDao.findAddressByMemberNo(memberNo);
    	
    	if (address == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(address);
    }
    
    @PostMapping("/address-save")
    public ResponseEntity<?> saveAddress(@RequestBody AddressDto address) {
        
    	String address1 = address.getAddress1() + " " + address.getExtraAddress();
    	address.setAddress1(address1);
    	
    	if (address.getAddressType().equals("H")) {
        	address.setAddressType("H");
        } else {
        	address.setAddressType("W");
        }
    	
    	System.out.println(address);
    	
        cardApplyDao.updateApplicationAddressTemp(address);
        
        return ResponseEntity.ok("주소 저장 완료");
    }
    
    @PostMapping("/card-options")
    public ResponseEntity<?> saveCardOptions(@RequestBody CardOptionDto cardOption) {
    	
    	int updated = cardApplyDao.updateApplicationCardOptionTemp(cardOption);
    	
        if (updated > 0) {
            return ResponseEntity.ok("카드 옵션이 저장되었습니다.");
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                                 .body("저장 실패");
        }
    }
}
