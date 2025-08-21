package com.busanbank.card.cardapply.controller;

import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

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

    @Autowired private IUserDao userDao;
    @Autowired private CardDao cardDao;
    @Autowired private ICardApplyDao cardApplyDao;

    // ─────────────────────────────────────────────────────────────────────
    // 약관 목록 (메타 + Base64 데이터 포함: 프론트 호환용)
    // ─────────────────────────────────────────────────────────────────────
    @GetMapping("/card-terms")
    public List<PdfFilesDto> getCardTerms(@RequestParam("cardNo") long cardNo) {
        List<PdfFilesDto> terms = cardApplyDao.getTermsByCardNo(cardNo);
        for (PdfFilesDto term : terms) {
            if (term.getPdfData() != null) {
                term.setPdfDataBase64(Base64.getEncoder().encodeToString(term.getPdfData()));
                term.setPdfData(null); // JSON 전송 시 byte[] 제거
            }
        }
        return terms;
    }

    // ─────────────────────────────────────────────────────────────────────
    // 약관 동의 저장
    // ─────────────────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────────────────
    // (구) 세션 기반 사용자 정보
    // ─────────────────────────────────────────────────────────────────────
    @GetMapping("/get-customer-info")
    public Map<String, Object> getCustomerInfo(@RequestParam("cardNo") int cardNo,
                                               HttpSession session) throws Exception {
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
        return result;
    }

    // ─────────────────────────────────────────────────────────────────────
    // (신) JWT 기반 사용자 정보
    // ─────────────────────────────────────────────────────────────────────
    @GetMapping("/customer-info")
    public ResponseEntity<?> getCustomerInfo(@RequestParam("cardNo") int cardNo,
                                             Authentication authentication) throws Exception {
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "로그인이 필요합니다."));
        }
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

    // ─────────────────────────────────────────────────────────────────────
    // 주소 프리필
    // ─────────────────────────────────────────────────────────────────────
    @GetMapping("/address-home")
    public ResponseEntity<?> getAddress(@RequestParam(value = "memberNo", required = false) Integer memberNo,
                                        Authentication authentication) {
        if (memberNo == null) {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "로그인이 필요합니다."));
            }
            String username = authentication.getName();
            UserDto loginUser = userDao.findByUsername(username);
            if (loginUser == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "사용자 정보 없음"));
            }
            memberNo = loginUser.getMemberNo();
        }

        AddressDto address = cardApplyDao.findAddressByMemberNo(memberNo);
        if (address == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(address);
    }

    // ─────────────────────────────────────────────────────────────────────
    // 주소 저장 (임시)
    // ─────────────────────────────────────────────────────────────────────
    @PostMapping("/address-save")
    public ResponseEntity<?> saveAddress(@RequestBody AddressDto address) {
        String address1 = address.getAddress1() + " " + address.getExtraAddress();
        address.setAddress1(address1);
        address.setAddressType("H".equals(address.getAddressType()) ? "H" : "W");

        cardApplyDao.updateApplicationAddressTemp(address);
        return ResponseEntity.ok("주소 저장 완료");
    }

    // ─────────────────────────────────────────────────────────────────────
    // 카드 옵션 저장 (임시)
    // ─────────────────────────────────────────────────────────────────────
    @PostMapping("/card-options")
    public ResponseEntity<?> saveCardOptions(@RequestBody CardOptionDto cardOption) {
        int updated = cardApplyDao.updateApplicationCardOptionTemp(cardOption);
        if (updated > 0) {
            return ResponseEntity.ok("카드 옵션이 저장되었습니다.");
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("저장 실패");
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // PDF 스트리밍 (뷰어용) — JWT 필요
    // ─────────────────────────────────────────────────────────────────────
    @GetMapping("/pdf/{pdfNo}")
    public ResponseEntity<byte[]> streamPdf(@PathVariable long pdfNo,
                                            Authentication authentication) {
      if (authentication == null || authentication.getName() == null) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
      }

      System.out.println("[PDF] req pdfNo=" + pdfNo);
      java.sql.Blob blob = cardApplyDao.getPdfBlobByNo(pdfNo); // ← 이거여야 함!
      if (blob == null) return ResponseEntity.status(HttpStatus.NOT_FOUND).build();

      byte[] data;
      try (var is = blob.getBinaryStream()) {
        data = is.readAllBytes();
      } catch (Exception e) {
        e.printStackTrace();
        return ResponseEntity.internalServerError().build();
      } finally {
        try { blob.free(); } catch (Exception ignore) {}
      }

      // (옵션) base64로 저장된 경우 방탄
      if (!(data.length >= 4 && data[0]==0x25 && data[1]==0x50 && data[2]==0x44 && data[3]==0x46)) {
        try {
          String s = new String(data, java.nio.charset.StandardCharsets.ISO_8859_1).trim();
          int comma = s.indexOf(',');
          if (comma > 0 && s.substring(0, comma).toLowerCase().contains("base64")) s = s.substring(comma+1);
          data = java.util.Base64.getDecoder().decode(s);
        } catch (IllegalArgumentException ignore) {}
      }

      var headers = new HttpHeaders();
      headers.setContentType(MediaType.APPLICATION_PDF);
      headers.setContentDisposition(ContentDisposition.inline().filename("term-"+pdfNo+".pdf").build());
      System.out.println("[PDF] bytes=" + data.length);
      return new ResponseEntity<>(data, headers, HttpStatus.OK);
    }



    // ─────────────────────────────────────────────────────────────────────
    // PDF 다운로드 — JWT 필요 (첨부 다운로드)
    // ─────────────────────────────────────────────────────────────────────
    @GetMapping("/pdf/download/{pdfNo}")
    public ResponseEntity<byte[]> downloadPdf(@PathVariable("pdfNo") long pdfNo,
                                              Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // 메타 DTO로 읽는 기존 방식 유지 (Mapper에서 pdf_data를 byte[]로 매핑해야 함)
        PdfFilesDto file = cardApplyDao.getPdfByNo(pdfNo);
        if (file == null || file.getPdfData() == null || file.getPdfData().length == 0) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"term-" + pdfNo + ".pdf\"")
                .body(file.getPdfData());
    }
}
