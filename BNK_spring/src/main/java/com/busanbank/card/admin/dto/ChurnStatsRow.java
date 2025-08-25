package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class ChurnStatsRow {
    private String fromStepCode;
    private String fromStepName;

    private Integer droppedBetween;
    private Double dropPct;

    private Integer maleCount;
    private Integer femaleCount;

    private Integer age20s;
    private Integer age30s;
    private Integer age40s;
    private Integer age50plus;
}
