package com.busanbank.card.card.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CardDto {
	private Long cardNo;
	private String cardName;
	private String cardType;
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
	private String popularImgUrl;

	// ✅ cardUrl getter 오버라이딩
	public String getCardUrl() {
		if (cardUrl != null && cardUrl.contains("localhost")) {
			// 실제 PC의 IP 주소로 변경하세요!
			return cardUrl.replace("localhost", "192.168.100.106");
		}
		return cardUrl;
	}

	// ✅ popularImgUrl도 필요하다면 동일하게 처리
	public String getPopularImgUrl() {
		if (popularImgUrl != null && popularImgUrl.contains("localhost")) {
			return popularImgUrl.replace("localhost", "192.168.100.106");
		}
		return popularImgUrl;
	}
}
