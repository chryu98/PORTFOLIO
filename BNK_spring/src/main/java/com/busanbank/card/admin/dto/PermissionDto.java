package com.busanbank.card.admin.dto;

import java.util.Date;

import lombok.Data;

@Data
public class PermissionDto {
    private Long perNo;
    private Long cardNo;
    private String status;
    private String reason;
    private String admin;
    private String sAdmin;
    private Date regDate;
    private Date perDate;
    private String perContent;
}
