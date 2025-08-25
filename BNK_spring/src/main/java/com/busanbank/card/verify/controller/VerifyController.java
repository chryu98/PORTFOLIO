// com.busanbank.card.verify.controller.VerifyController.java
package com.busanbank.card.verify.controller;

import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.verify.entity.VerifyLog;
import com.busanbank.card.verify.service.ExpectedRrnService;
import com.busanbank.card.verify.service.VerifyLogService;
import com.busanbank.card.verify.util.MultipartInputStreamFileResource;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/verify")
@RequiredArgsConstructor
public class VerifyController {

	private final VerifyLogService verifyLogService;
	private final ExpectedRrnService expectedRrnService;
	private final ICardApplyDao cardApplyDao;

	@Value("${chatbot.python.base-url:http://127.0.0.1:8000}")
	private String pythonBaseUrl;

	// 마스킹 모드는 기본 true (필요 시 설정으로 조절)
	@Value("${verify.rrn.masked:true}")
	private boolean maskedMode;

	@Value("${verify.face.threshold:0.65}") // 파이썬이 지원하면 사용
	private String faceThreshold;

	private String currentUserNo() {
		try {
			Authentication a = SecurityContextHolder.getContext().getAuthentication();
			if (a != null && a.isAuthenticated() && a.getName() != null)
				return a.getName();
		} catch (Exception ignore) {
		}
		return "ANON";
	}

	@PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<?> verify(@RequestParam("idImage") MultipartFile idImage,
			@RequestParam("faceImage") MultipartFile faceImage, @RequestParam("applicationNo") Long applicationNo // ←
																													// Long으로
																													// 통일
	) {
		String userNo = currentUserNo();
		try {
			// 1) 기대 주민번호 생성
			String expectedRrn = expectedRrnService.buildExpectedRrn(applicationNo, maskedMode);

			// 2) Python 호출
			String pythonUrl = pythonBaseUrl + "/verify";
			RestTemplate rt = new RestTemplate();

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.MULTIPART_FORM_DATA);

			MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
			// ※ 키 이름 통일: 파이썬이 기대하는 키로 맞추세요
			body.add("id_image", new MultipartInputStreamFileResource(idImage.getInputStream(),
					idImage.getOriginalFilename() != null ? idImage.getOriginalFilename() : "id.jpg"));
			body.add("face_image", new MultipartInputStreamFileResource(faceImage.getInputStream(),
					faceImage.getOriginalFilename() != null ? faceImage.getOriginalFilename() : "face.jpg"));
			body.add("expected_rrn", expectedRrn);
			body.add("face_threshold", faceThreshold);

			HttpEntity<MultiValueMap<String, Object>> req = new HttpEntity<>(body, headers);
			ResponseEntity<Map> res = rt.exchange(pythonUrl, HttpMethod.POST, req, Map.class);

			Map<String, Object> result = res.getBody();
			String status = result != null ? String.valueOf(result.getOrDefault("status", "ERROR")) : "ERROR";
			String reason = result != null ? String.valueOf(result.getOrDefault("reason", "")) : "";

			verifyLogService.save(new VerifyLog(userNo, status, reason));
			
			// 이대영이 추가함
			cardApplyDao.updateApplicationStatusByAppNo2(applicationNo, "PHOTO_UPLOADED");
			
			return ResponseEntity.status(res.getStatusCode()).body(result);

		} catch (Exception e) {
			log.error("[VERIFY] server error", e);
			verifyLogService.save(new VerifyLog(userNo, "FAIL", "서버 오류: " + e.getMessage()));
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body(Map.of("status", "ERROR", "reason", e.getMessage()));
		}
	}

	@PostMapping(path = "/ocr", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<?> ocrId(@RequestParam("idImage") MultipartFile idImage) {
		try {
			String pythonUrl = pythonBaseUrl + "/ocr-id";
			RestTemplate rt = new RestTemplate();

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.MULTIPART_FORM_DATA);

			MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
			body.add("idImage",
					new MultipartInputStreamFileResource(idImage.getInputStream(), idImage.getOriginalFilename()));

			HttpEntity<MultiValueMap<String, Object>> req = new HttpEntity<>(body, headers);
			ResponseEntity<Map> res = rt.exchange(pythonUrl, HttpMethod.POST, req, Map.class);
			return ResponseEntity.status(res.getStatusCode()).body(res.getBody());
		} catch (Exception e) {
			log.error("[OCR] server error", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body(Map.of("status", "ERROR", "reason", e.getMessage()));
		}
	}
}
