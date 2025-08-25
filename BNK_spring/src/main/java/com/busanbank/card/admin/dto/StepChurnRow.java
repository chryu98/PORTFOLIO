// StepChurnRow.java
package com.busanbank.card.admin.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class StepChurnRow {
    private Long cardNo;
    private String cardName;
    private String fromStepCode;
    private String fromStepName;
    private String toStepCode;
    private String toStepName;
    private Integer toStepOrder;
    private Integer droppedBetween; // 이탈 수
    private BigDecimal dropPct;     // 이탈률(%)
}
