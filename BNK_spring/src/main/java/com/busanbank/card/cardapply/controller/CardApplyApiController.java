// src/main/java/com/busanbank/card/cardapply/controller/CardApplyApiController.java
package com.busanbank.card.cardapply.controller;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import com.busanbank.card.cardapply.dto.PdfBytesRow;
import com.busanbank.card.cardapply.dto.TermsAgreementRequest;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/api/card/apply")
public class CardApplyApiController {

	private static final Logger log = LoggerFactory.getLogger(CardApplyApiController.class);

	@Autowired
	private IUserDao userDao;
	@Autowired
	private CardDao cardDao;
	@Autowired
	private ICardApplyDao cardApplyDao;

	/*
	 * ========================================================= 약관 목록 (메타만 반환; PDF
	 * 바이트는 /pdf/{pdfNo}로 스트리밍)
	 * =========================================================
	 */
	@GetMapping(value = "/card-terms", produces = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<?> getCardTerms(@RequestParam("cardNo") long cardNo) {
		try {
			List<PdfFilesDto> terms = cardApplyDao.getTermsByCardNo(cardNo);
			return ResponseEntity.ok(terms);
		} catch (Exception e) {
			log.error("getCardTerms failed", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body(Map.of("error", "TERMS_LOAD_FAILED", "message", e.getMessage()));
		}
	}

	/*
	 * ========================================================= 약관 동의 저장
	 * =========================================================
	 */
	@PostMapping("/terms-agree")
	public ResponseEntity<String> agreeTerms(@RequestBody TermsAgreementRequest request) {
		if (request.getPdfNos() == null || request.getPdfNos().isEmpty()) {
			return ResponseEntity.badRequest().body("동의한 약관이 없습니다.");
		}
		for (Long pdfNo : request.getPdfNos()) {
			cardApplyDao.insertAgreement(request.getMemberNo(), request.getCardNo(), pdfNo);
		}

		// ✅ STATUS 변경
		 cardApplyDao.updateApplicationStatus(request.getMemberNo(),
                 request.getCardNo(),
                 "TERMS_AGREED");
		 
		return ResponseEntity.ok("약관 동의 저장 완료");
	}

	/*
	 * ========================================================= (구) 세션 기반 사용자 정보
	 * =========================================================
	 */
	@GetMapping("/get-customer-info")
	public Map<String, Object> getCustomerInfo(@RequestParam("cardNo") int cardNo, HttpSession session) {
		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
		if (memberNo == null) {
			throw new RuntimeException("로그인이 필요한 서비스입니다.");
		}
		UserDto loginUser = userDao.findByMemberNo(memberNo);

		String rrnBack = null;
		try {
			String enc = loginUser.getRrnTailEnc();
			if (enc != null && !enc.isBlank()) {
				rrnBack = loginUser.getRrnGender() + AESUtil.decrypt(enc);
			}
		} catch (Exception e) {
			log.warn("RRN decrypt failed", e);
			rrnBack = loginUser.getRrnGender() + "******";
		}

		Map<String, Object> result = new HashMap<>();
		result.put("loginUser", loginUser);
		result.put("rrnBack", rrnBack);
		return result;
	}

	/*
	 * ========================================================= (신) JWT 기반 사용자 정보
	 * =========================================================
	 */
	@GetMapping("/customer-info")
	public ResponseEntity<?> getCustomerInfo(@RequestParam("cardNo") int cardNo, Authentication authentication) {
		if (authentication == null || authentication.getName() == null) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "로그인이 필요합니다."));
		}
		String username = authentication.getName();
		UserDto loginUser = userDao.findByUsername(username);
		if (loginUser == null) {
			return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "사용자 정보 없음"));
		}

		String rrnBack = null;
		try {
			String enc = loginUser.getRrnTailEnc();
			if (enc != null && !enc.isBlank()) {
				rrnBack = loginUser.getRrnGender() + AESUtil.decrypt(enc);
			}
		} catch (Exception e) {
			log.warn("RRN decrypt failed", e);
		}

		return ResponseEntity.ok(Map.of("loginUser", loginUser, "rrnBack", rrnBack, "cardNo", cardNo));
	}

	@PostMapping("/card-options")
	public ResponseEntity<?> saveCardOptions(@RequestBody CardOptionDto cardOption) {
		int updated = cardApplyDao.updateApplicationCardOptionTemp(cardOption);
		if (updated > 0) {
			cardApplyDao.updateApplicationStatusByAppNo(
		            cardOption.getApplicationNo(),
		            "CARD_OPTIONS_SET"   // ← 원하는 단계명으로
		        );
			return ResponseEntity.ok("카드 옵션이 저장되었습니다.");
		} else {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("저장 실패");
		}
	}

	/*
	 * ========================================================= 주소 프리필/저장
	 * =========================================================
	 */
	@GetMapping("/address-home")
	public ResponseEntity<?> getAddress(@RequestParam(value = "memberNo", required = false) Integer memberNo,
			Authentication authentication) {
		if (memberNo == null) {
			if (authentication == null || authentication.getName() == null) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "로그인이 필요합니다."));
			}
			String username = authentication.getName();
			UserDto loginUser = userDao.findByUsername(username);
			if (loginUser == null) {
				return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "사용자 정보 없음"));
			}
			memberNo = loginUser.getMemberNo();
		}

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
		address.setAddressType("H".equals(address.getAddressType()) ? "H" : "W");

		cardApplyDao.updateApplicationStatusByAppNo(
		        address.getApplicationNo(),
		        "ADDRESS_INPUT"   // 단계명: 배송지 입력 완료
		    );
		cardApplyDao.updateApplicationAddressTemp(address);
		return ResponseEntity.ok("주소 저장 완료");
	}

	/* ======================== 공통: PDF 정화 헬퍼 ======================== */
	private byte[] sanitizePdf(byte[] data) {
		if (data == null || data.length == 0)
			return data;

		int len = data.length, start = 0, end = len;

		// 1) UTF-8 BOM 제거
		if (len >= 3 && (data[0] & 0xFF) == 0xEF && (data[1] & 0xFF) == 0xBB && (data[2] & 0xFF) == 0xBF) {
			start = 3;
		}
		// 2) 앞쪽 공백류 제거
		while (start < len) {
			int b = data[start] & 0xFF;
			if (b == 0x09 || b == 0x0A || b == 0x0D || b == 0x20)
				start++;
			else
				break;
		}
		// 3) 앞에서 %PDF 시그니처 탐색(최대 8KB)
		byte[] sig = "%PDF".getBytes(StandardCharsets.US_ASCII);
		int searchLimit = Math.min(len, 8192);
		int idx = -1;
		outer: for (int i = start; i + sig.length <= searchLimit; i++) {
			for (int j = 0; j < sig.length; j++) {
				if (data[i + j] != sig[j])
					continue outer;
			}
			idx = i;
			break;
		}
		if (idx >= 0)
			start = idx;

		// 4) 뒤쪽 패딩/널/공백 제거
		while (end > start) {
			int b = data[end - 1] & 0xFF;
			if (b == 0x00 || b == 0x09 || b == 0x0A || b == 0x0D || b == 0x20)
				end--;
			else
				break;
		}
		// 5) %%EOF 뒤에 낀 것들 자르기
		byte[] eof = "%%EOF".getBytes(StandardCharsets.US_ASCII);
		for (int i = Math.min(end, len) - eof.length; i >= start; i--) {
			boolean hit = true;
			for (int j = 0; j < eof.length; j++) {
				if (data[i + j] != eof[j]) {
					hit = false;
					break;
				}
			}
			if (hit) {
				end = Math.min(len, i + eof.length);
				break;
			}
		}

		if (start == 0 && end == len)
			return data;
		byte[] out = new byte[end - start];
		System.arraycopy(data, start, out, 0, out.length);
		return out;
	}

	/*
	 * ========================================================= PDF 스트리밍 (뷰어용) —
	 * JWT 필요 =========================================================
	 */
	@GetMapping(value = "/pdf/{pdfNo}", produces = MediaType.APPLICATION_PDF_VALUE)
	public ResponseEntity<byte[]> streamPdf(@PathVariable("pdfNo") long pdfNo, Authentication authentication) {
		if (authentication == null || authentication.getName() == null) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		}

		byte[] data = null;
		try {
			PdfBytesRow row = cardApplyDao.getPdfRawRowByNo(pdfNo);
			if (row != null)
				data = row.getData();
		} catch (Exception e) {
			System.out.println("[PDF] raw route failed: " + e.getMessage());
		}
		if (data == null || data.length == 0) {
			try {
				PdfFilesDto dto = cardApplyDao.getPdfByNo(pdfNo);
				if (dto != null)
					data = dto.getPdfData();
			} catch (Exception e) {
				System.out.println("[PDF] dto route failed: " + e.getMessage());
			}
		}
		if (data == null || data.length == 0)
			return ResponseEntity.status(HttpStatus.NOT_FOUND).build();

		// 필요할 때만 Base64 복구 (앞/뒤 바이트는 절대 자르지 않음)
		if (!(data.length >= 4 && data[0] == 0x25 && data[1] == 0x50 && data[2] == 0x44 && data[3] == 0x46)) {
			try {
				String s = new String(data, java.nio.charset.StandardCharsets.ISO_8859_1).trim();
				int comma = s.indexOf(',');
				if (comma > 0 && s.substring(0, comma).toLowerCase().contains("base64")) {
					s = s.substring(comma + 1);
				}
				data = java.util.Base64.getDecoder().decode(s);
			} catch (IllegalArgumentException ignore) {
			}
		}

		HttpHeaders headers = new HttpHeaders();
		headers.setContentType(MediaType.APPLICATION_PDF);
		headers.setContentDisposition(ContentDisposition.inline().filename("term-" + pdfNo + ".pdf").build());
		return new ResponseEntity<>(data, headers, HttpStatus.OK);
	}

	/*
	 * ========================================================= PDF 다운로드 — JWT 필요
	 * (첨부) =========================================================
	 */
	@GetMapping("/pdf/download/{pdfNo}")
	public ResponseEntity<byte[]> downloadPdf(@PathVariable("pdfNo") long pdfNo, Authentication authentication) {
		if (authentication == null || authentication.getName() == null) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		}

		byte[] data = null;
		try {
			PdfBytesRow row = cardApplyDao.getPdfRawRowByNo(pdfNo);
			if (row != null)
				data = row.getData();
		} catch (Exception ignore) {
		}
		if (data == null || data.length == 0) {
			try {
				PdfFilesDto dto = cardApplyDao.getPdfByNo(pdfNo);
				if (dto != null)
					data = dto.getPdfData();
			} catch (Exception ignore) {
			}
		}
		if (data == null || data.length == 0)
			return ResponseEntity.notFound().build();

		if (!(data.length >= 4 && data[0] == 0x25 && data[1] == 0x50 && data[2] == 0x44 && data[3] == 0x46)) {
			try {
				String s = new String(data, java.nio.charset.StandardCharsets.ISO_8859_1).trim();
				int comma = s.indexOf(',');
				if (comma > 0 && s.substring(0, comma).toLowerCase().contains("base64"))
					s = s.substring(comma + 1);
				data = java.util.Base64.getDecoder().decode(s);
			} catch (IllegalArgumentException ignore) {
			}
		}

		return ResponseEntity.ok().contentType(MediaType.APPLICATION_PDF)
				.header(HttpHeaders.CONTENT_DISPOSITION,
						ContentDisposition.attachment().filename("term-" + pdfNo + ".pdf").build().toString())
				.body(data);
	}
}
