package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class KpiDto {
    private int newApps;               // 기간 신규 신청
    private int issuedApps;            // 기간 발급
    private int inProgress;            // 현재 진행중(DRAFT)
    private int cohortSize;            // 기간 코호트 크기(신규 신청)
    private int cohortIssued;          // 코호트 중 발급 수(현재 시점)
    private double cohortConversionPct;// 코호트 전환율(%)
    private double avgIssueDays;       // 평균 발급 소요일
}
	