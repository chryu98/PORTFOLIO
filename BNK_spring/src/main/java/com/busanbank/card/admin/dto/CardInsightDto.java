package com.busanbank.card.admin.dto;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonInclude;

import lombok.Data;

@JsonInclude(JsonInclude.Include.NON_NULL)
@Data
public class CardInsightDto {
    // 공통/카드 식별
    private Long cardNo;
    private String cardName;
    private String cardUrl;      // 추가
    private String cardProductUrl;     // 추가(선택)

    // 집계 지표
    private Long views;
    private Long clicks;
    private Long applies;
    private Double score;
    private Double ctr;
    private Double cvr;

    // 유사 추천 전용
    private Long otherCardNo;
    private String otherCardName;
    private String otherCardImageUrl;   // 추가
    private String otherCardProductUrl; // 추가(선택)
    private Double simScore;

    // 로그 전용
    private Long logNo;
    private Long memberNo;
    private String behaviorType;
    private Date behaviorTime;
    private String deviceType;
    private String userAgent;
    private String ipAddress;

    // 메타
    private String metricType;
    private Date fromDate;
    private Date toDate;
}
