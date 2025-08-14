// src/main/java/com/busanbank/card/admin/dto/FunnelSummary.java
package com.busanbank.card.admin.dto;

import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class FunnelSummary {
    private int draft;
    private int kycPassed;
    private int accountConfirmed;
    private int optionsSet;
    private int issued;
    private int cancelled;
}
