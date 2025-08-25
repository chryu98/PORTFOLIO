package com.busanbank.card.custom.service;

import org.springframework.stereotype.Service;

import com.busanbank.card.custom.dto.CustomCardDto;
import com.busanbank.card.custom.mapper.CustomCardMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CustomCardService {
  private final CustomCardMapper mapper;

  public Long save(Long memberNo, byte[] imageBytes, String customService) {
    Long id = mapper.nextId();

    CustomCardDto dto = new CustomCardDto();
    dto.setCustomNo(id);
    dto.setMemberNo(memberNo);
    dto.setImageBlob(imageBytes);
    dto.setStatus("PENDING");        // 기본 대기
    dto.setReason(null);
    dto.setCustomService(customService);
    dto.setAiResult(null);
    dto.setAiReason(null);

    mapper.insert(dto);
    return id;
  }
  
  public int updateAi(Long customNo, String aiResult, String aiReason) {
	  return mapper.updateAi(customNo, aiResult, aiReason);
	}
}

