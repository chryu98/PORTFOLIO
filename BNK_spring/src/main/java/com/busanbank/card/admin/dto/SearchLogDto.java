package com.busanbank.card.admin.dto;

import java.util.Date;

import lombok.Data;

@Data
public class SearchLogDto {

	private Long searchLogNo;   // 검색어 로그 고유 번호
    private Long memberNo;      // 회원 고유 번호 null
    private String keyword;     // 검색어
    private String isProhibited;   // 금칙어 ('Y'/'N')
    private String isRecommended;  // 추천어 ('Y'/'N')
    private Date searchDate;       // 검색 시간
}
