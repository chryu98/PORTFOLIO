package com.busanbank.card.custom.controller;

import com.busanbank.card.custom.dto.AiModerationRequestDto;
import com.busanbank.card.custom.dto.AiModerationResponseDto;
import com.busanbank.card.custom.service.AiModerationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/ai/moderation")
@RequiredArgsConstructor
public class AICustomModerationController {

    private final AiModerationService aiModerationService;

    // (1) 이미지 URL로 검증
    @PostMapping("/by-url")
    public AiModerationResponseDto moderateByUrl(@RequestBody AiModerationRequestDto req) {
        return aiModerationService.moderateByUrl(req);
    }

    // (2) 파일 업로드로 검증 (Swagger/JS에서 multipart 전송)
    @PostMapping(value = "/by-file", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public AiModerationResponseDto moderateByFile(
            @RequestPart("image") MultipartFile image,
            @RequestParam(value = "customNo", required = false) Long customNo,
            @RequestParam(value = "memberNo", required = false) Long memberNo
    ) {
        return aiModerationService.moderateByFile(image, customNo, memberNo);
    }
}
