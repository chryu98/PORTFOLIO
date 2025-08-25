package com.busanbank.card.custom.service;

import com.busanbank.card.custom.dto.AiModerationRequestDto;
import com.busanbank.card.custom.dto.AiModerationResponseDto;
import com.busanbank.card.custom.mapper.CustomCardModerationMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

@Service
@RequiredArgsConstructor
public class AiModerationService {

    @Qualifier("aiModerationWebClient")
    private final WebClient aiModerationWebClient;

    private final CustomCardModerationMapper cardModerationMapper;

    public AiModerationResponseDto moderateByUrl(AiModerationRequestDto req) {
        MultipartBodyBuilder mb = new MultipartBodyBuilder();
        if (req.getImageUrl() != null) mb.part("imageUrl", req.getImageUrl());
        if (req.getCustomNo() != null) mb.part("customNo", String.valueOf(req.getCustomNo()));
        if (req.getMemberNo() != null) mb.part("memberNo", String.valueOf(req.getMemberNo()));

        AiModerationResponseDto res = aiModerationWebClient.post()
                .uri("/moderate")
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(mb.build()))
                .retrieve()
                .bodyToMono(AiModerationResponseDto.class)
                .block();

        if (req.getCustomNo() != null && res != null) {
            cardModerationMapper.updateAiResult(
                    req.getCustomNo(), res.getDecision(), res.getReason());
        }
        return res;
    }

    public AiModerationResponseDto moderateByFile(MultipartFile file, Long customNo, Long memberNo) {
        MultipartBodyBuilder mb = new MultipartBodyBuilder();
        mb.part("image", file.getResource())
          .filename(file.getOriginalFilename() == null ? "upload.jpg" : file.getOriginalFilename())
          .contentType(file.getContentType() == null
                  ? MediaType.IMAGE_JPEG : MediaType.parseMediaType(file.getContentType()));
        if (customNo != null) mb.part("customNo", String.valueOf(customNo));
        if (memberNo != null) mb.part("memberNo", String.valueOf(memberNo));

        AiModerationResponseDto res = aiModerationWebClient.post()
                .uri("/moderate")
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(mb.build()))
                .retrieve()
                .bodyToMono(AiModerationResponseDto.class)
                .block();

        if (customNo != null && res != null) {
            cardModerationMapper.updateAiResult(
                    customNo, res.getDecision(), res.getReason());
        }
        return res;
    }
}
