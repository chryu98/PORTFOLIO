package com.busanbank.card.verify.controller;

import com.busanbank.card.user.util.AESUtil;
import com.busanbank.card.verify.entity.VerifyLog;
import com.busanbank.card.verify.service.VerifyLogService;
import com.busanbank.card.verify.util.MultipartInputStreamFileResource;

import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;

@RestController
@RequestMapping("/api/verify")
@RequiredArgsConstructor
public class VerifyController {

    private final VerifyLogService verifyLogService;

    @PostMapping
    public ResponseEntity<?> verify(
            @RequestParam("idImage") MultipartFile idImage,
            @RequestParam("faceImage") MultipartFile faceImage,
            @RequestParam("encryptedRrn") String encryptedRrn,
            @RequestParam("userNo") String userNo
    ) {
        try {
            // 1. 주민번호 복호화
            String expectedRrn = AESUtil.decrypt(encryptedRrn);

            // 2. Python 서버 URL
            String pythonUrl = "http://127.0.0.1:8000/verify";

            // 3. Multipart 요청 생성
            RestTemplate restTemplate = new RestTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("id_image", new MultipartInputStreamFileResource(idImage.getInputStream(), idImage.getOriginalFilename()));
            body.add("face_image", new MultipartInputStreamFileResource(faceImage.getInputStream(), faceImage.getOriginalFilename()));
            body.add("expected_rrn", expectedRrn);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // 4. Python 호출
            ResponseEntity<Map> response = restTemplate.exchange(
                    pythonUrl,
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            Map<String, Object> result = response.getBody();

            // 5. DB 로그 기록
            String status = (String) result.get("status");
            String reason = (String) result.get("reason");
            VerifyLog log = new VerifyLog(userNo, status, reason);
            verifyLogService.save(log);

            // 6. 클라이언트에 결과 반환
            return ResponseEntity.ok(result);

        } catch (Exception e) {
            // 예외 발생 시 로그 저장
            VerifyLog log = new VerifyLog(userNo, "FAIL", "서버 오류: " + e.getMessage());
            verifyLogService.save(log);
            return ResponseEntity.status(500).body(Map.of("status", "ERROR", "reason", e.getMessage()));
        }
    }
}
