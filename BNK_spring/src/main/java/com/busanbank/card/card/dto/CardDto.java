package com.busanbank.card.card.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.busanbank.card.card.common.NetworkUtil;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CardDto {
	private Long cardNo;
	private String cardName;
//	private String cardType;
	private String cardBrand;
	private Integer viewCount;
	private Integer annualFee;
	private String issuedTo;
	private String service;

	@JsonProperty("sService")
	private String sService;

	private String cardStatus;

	private String cardUrl; // ✅ 여기의 getter를 오버라이드할 예정

	private LocalDate cardIssueDate;
	private LocalDate cardDueDate;
	private String cardSlogan;
	private String cardNotice;
	private LocalDate regDate;
	private LocalDate editDate;
	@JsonProperty("popularImgUrl")
	private String popularImgUrl;


	 // 공통 처리 메서드
    private String replaceLocalhost(String url) {
        if (url != null && url.contains("localhost")) {
            return url.replace("localhost", NetworkUtil.getServerIp());
        }
        return url;
    }

    @JsonProperty("cardUrl")
    public String getCardUrl() {
        return replaceLocalhost(cardUrl);
    }

    @JsonProperty("popularImgUrl")
    public String getPopularImgUrl() {
        return replaceLocalhost(popularImgUrl);
    }
    
    @JsonProperty("cardType")
    private String cardType;
}
