package com.busanbank.card.admin.dto;

import java.util.Date;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

//com.busanbank.card.admin.dto.CardInsightDto
@JsonInclude(JsonInclude.Include.NON_NULL)
@Data
public class CardInsightDto {
 private Long cardNo;
 private String cardName;
 private String cardUrl;
 private String cardProductUrl;

 private Long views;
 private Long clicks;
 private Long applies;
 private Double score;
 private Double ctr;
 private Double cvr;

 private Long otherCardNo;
 private String otherCardName;
 private String otherCardImageUrl;
 private String otherCardProductUrl;
 private Double simScore;

 private Long logNo;
 private Long memberNo;
 private String behaviorType;
 private Date behaviorTime;
 private String deviceType;
 private String userAgent;
 private String ipAddress;

 // ★ 추가: 로그 테이블에 이름 직접 내려줄 거라 필요
 private String memberName;

 private String metricType;
 private Date fromDate;
 private Date toDate;
}

