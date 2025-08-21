package com.busanbank.card.custom.dto;

import java.util.Date;

import lombok.Data;

@Data
public class CustomCardDto {
  private Long customNo;
  private Long memberNo;
  private byte[] imageBlob;     // BLOB
  private String status;        // PENDING/APPROVED/REJECTED
  private String reason;
  private String customService; // 혜택
  private Date createdAt;
  private Date updatedAt;
  private Date approvedAt;
  private String aiResult;      // ACCEPT/REJECT
  private String aiReason;
}