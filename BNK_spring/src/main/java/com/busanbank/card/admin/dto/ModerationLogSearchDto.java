package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class ModerationLogSearchDto {
    private String decision;   // ACCEPT / REJECT / null
    private Long memberNo;
    private Long customNo;
    private String from;       // yyyy-MM-dd
    private String to;         // yyyy-MM-dd

    private Integer page = 1;  // 1-based
    private Integer size = 20; // rows/page
}
