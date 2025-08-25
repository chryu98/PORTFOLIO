package com.busanbank.card.admin.dto;

import java.math.BigDecimal;

import lombok.Data;


@Data
public class JourneyChurnStatDto {
    private String fromStepCode;
    private String fromStepName;
    private Integer droppedBetween;
    private BigDecimal dropPct;
    private Integer maleCount;
    private Integer femaleCount;
    private Integer age20s;
    private Integer age30s;
    private Integer age40s;
    private Integer age50plus;
}
