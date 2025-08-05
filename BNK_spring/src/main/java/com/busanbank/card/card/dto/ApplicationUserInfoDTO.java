package com.busanbank.card.card.dto;

import java.util.Date;

import lombok.Data;

@Data
public class ApplicationUserInfoDTO {
    private Long infoNo;
    private Long applicationNo;
    private String name;
    private String nameEng;
    private String rrnFront;
    private String rrnTailEnc;
    private String isExistingAccount;  // 'Y' or 'N'
    private Date createdAt;

    
}